/**
 * Database operations for dispatch.
 * All queries use drizzle-orm over bun:sqlite.
 */

import { Database } from "bun:sqlite"
import { drizzle, type BunSQLiteDatabase } from "drizzle-orm/bun-sqlite"
import { eq, and, sql } from "drizzle-orm"
import { ok, err, type Result } from "neverthrow"
import * as schema from "./schema.ts"
import {
  type WorkspaceId,
  type TaskId,
  type WorkspaceRecord,
  type TaskRecord,
  type TaskWithContext,
  type TaskType,
  TaskStatus,
  WorkspaceId as WorkspaceIdCompanion,
  TaskId as TaskIdCompanion,
} from "./types.ts"

const DB_NAME = ".dispatch.db"

type Db = BunSQLiteDatabase<typeof schema>

export const createDb = (path?: string): Db => {
  const sqlite = new Database(path ?? DB_NAME)
  sqlite.exec("PRAGMA journal_mode=WAL")
  sqlite.exec("PRAGMA foreign_keys=ON")
  const db = drizzle(sqlite, { schema })
  migrate(db)
  return db
}

const migrate = (db: Db): void => {
  db.run(sql`
    CREATE TABLE IF NOT EXISTS workspaces (
      id TEXT PRIMARY KEY,
      title TEXT NOT NULL,
      background TEXT NOT NULL DEFAULT '',
      goals TEXT NOT NULL DEFAULT '[]',
      constraints TEXT NOT NULL DEFAULT '[]',
      created_at TEXT NOT NULL
    )
  `)
  db.run(sql`
    CREATE TABLE IF NOT EXISTS tasks (
      id TEXT PRIMARY KEY,
      workspace_id TEXT NOT NULL REFERENCES workspaces(id),
      title TEXT NOT NULL,
      type TEXT NOT NULL,
      status TEXT NOT NULL DEFAULT 'pending',
      result TEXT,
      created_at TEXT NOT NULL
    )
  `)
  db.run(sql`
    CREATE TABLE IF NOT EXISTS dependencies (
      task_id TEXT NOT NULL REFERENCES tasks(id),
      depends_on TEXT NOT NULL REFERENCES tasks(id),
      PRIMARY KEY (task_id, depends_on)
    )
  `)
}

const now = (): string => new Date().toISOString()

const toWorkspaceRecord = (row: typeof schema.workspaces.$inferSelect): WorkspaceRecord => ({
  id: WorkspaceIdCompanion.from(row.id),
  title: row.title,
  background: row.background,
  goals: row.goals as string[],
  constraints: row.constraints as string[],
  createdAt: row.createdAt,
})

const toTaskRecord = (row: typeof schema.tasks.$inferSelect): TaskRecord => ({
  id: TaskIdCompanion.from(row.id),
  workspaceId: WorkspaceIdCompanion.from(row.workspaceId),
  title: row.title,
  type: row.type,
  status: row.status,
  result: row.result,
  createdAt: row.createdAt,
})

// --- Workspace operations ---

export const createWorkspace = (
  db: Db,
  input: { title: string; background?: string; goals?: string[]; constraints?: string[] },
): WorkspaceRecord => {
  const id = WorkspaceIdCompanion.generate()
  const record = {
    id: id as string,
    title: input.title,
    background: input.background ?? "",
    goals: input.goals ?? [],
    constraints: input.constraints ?? [],
    createdAt: now(),
  }
  db.insert(schema.workspaces).values(record).run()
  return toWorkspaceRecord(record)
}

export const getWorkspace = (db: Db, id: WorkspaceId): Result<WorkspaceRecord, string> => {
  const row = db.select().from(schema.workspaces).where(eq(schema.workspaces.id, id as string)).get()
  return row ? ok(toWorkspaceRecord(row)) : err(`Workspace ${id} not found`)
}

export const listWorkspaces = (db: Db): WorkspaceRecord[] =>
  db
    .select()
    .from(schema.workspaces)
    .orderBy(sql`created_at DESC`)
    .all()
    .map(toWorkspaceRecord)

export const editWorkspace = (
  db: Db,
  id: WorkspaceId,
  changes: {
    title?: string
    background?: string
    addGoal?: string
    removeGoal?: string
    addConstraint?: string
    removeConstraint?: string
  },
): Result<WorkspaceRecord, string> => {
  const existing = db
    .select()
    .from(schema.workspaces)
    .where(eq(schema.workspaces.id, id as string))
    .get()
  if (!existing) return err(`Workspace ${id} not found`)

  const current = toWorkspaceRecord(existing)
  const goals = [...current.goals]
  const constraints = [...current.constraints]

  if (changes.addGoal) goals.push(changes.addGoal)
  if (changes.removeGoal) {
    const idx = goals.indexOf(changes.removeGoal)
    if (idx >= 0) goals.splice(idx, 1)
  }
  if (changes.addConstraint) constraints.push(changes.addConstraint)
  if (changes.removeConstraint) {
    const idx = constraints.indexOf(changes.removeConstraint)
    if (idx >= 0) constraints.splice(idx, 1)
  }

  db.update(schema.workspaces)
    .set({
      title: changes.title ?? current.title,
      background: changes.background ?? current.background,
      goals,
      constraints,
    })
    .where(eq(schema.workspaces.id, id as string))
    .run()

  return getWorkspace(db, id)
}

// --- Task operations ---

export const addTask = (
  db: Db,
  input: { wsId: WorkspaceId; title: string; type: TaskType; dependsOn?: TaskId[] },
): TaskRecord => {
  const id = TaskIdCompanion.generate()
  const record = {
    id: id as string,
    workspaceId: input.wsId as string,
    title: input.title,
    type: input.type,
    status: TaskStatus.Pending,
    result: null,
    createdAt: now(),
  }
  db.insert(schema.tasks).values(record).run()

  for (const depId of input.dependsOn ?? []) {
    db.insert(schema.dependencies)
      .values({ taskId: id as string, dependsOn: depId as string })
      .run()
  }

  return toTaskRecord(record)
}

export const editTask = (
  db: Db,
  id: TaskId,
  changes: { title?: string; type?: TaskType; addDep?: TaskId; removeDep?: TaskId },
): Result<TaskRecord, string> => {
  const existing = db
    .select()
    .from(schema.tasks)
    .where(eq(schema.tasks.id, id as string))
    .get()
  if (!existing) return err(`Task ${id} not found`)

  if (changes.title || changes.type) {
    db.update(schema.tasks)
      .set({
        title: changes.title ?? existing.title,
        type: changes.type ?? existing.type,
      })
      .where(eq(schema.tasks.id, id as string))
      .run()
  }

  if (changes.addDep) {
    db.insert(schema.dependencies)
      .values({ taskId: id as string, dependsOn: changes.addDep as string })
      .onConflictDoNothing()
      .run()
  }
  if (changes.removeDep) {
    db.delete(schema.dependencies)
      .where(
        and(
          eq(schema.dependencies.taskId, id as string),
          eq(schema.dependencies.dependsOn, changes.removeDep as string),
        ),
      )
      .run()
  }

  return ok(toTaskRecord(
    db.select().from(schema.tasks).where(eq(schema.tasks.id, id as string)).get()!,
  ))
}

export const listTasks = (db: Db, wsId: WorkspaceId, status?: TaskStatus): TaskRecord[] => {
  const base = db.select().from(schema.tasks)
  const rows = status
    ? base
        .where(and(eq(schema.tasks.workspaceId, wsId as string), eq(schema.tasks.status, status)))
        .orderBy(sql`created_at`)
        .all()
    : base
        .where(eq(schema.tasks.workspaceId, wsId as string))
        .orderBy(sql`created_at`)
        .all()
  return rows.map(toTaskRecord)
}

export const getTaskWithContext = (db: Db, id: TaskId): Result<TaskWithContext, string> => {
  const task = db
    .select()
    .from(schema.tasks)
    .where(eq(schema.tasks.id, id as string))
    .get()
  if (!task) return err(`Task ${id} not found`)

  const ws = db
    .select()
    .from(schema.workspaces)
    .where(eq(schema.workspaces.id, task.workspaceId))
    .get()
  if (!ws) return err(`Workspace ${task.workspaceId} not found`)

  const deps = db
    .select({ task: schema.tasks })
    .from(schema.dependencies)
    .innerJoin(schema.tasks, eq(schema.tasks.id, schema.dependencies.dependsOn))
    .where(eq(schema.dependencies.taskId, id as string))
    .all()
    .map((r) => toTaskRecord(r.task))

  const dependedBy = db
    .select({ task: schema.tasks })
    .from(schema.dependencies)
    .innerJoin(schema.tasks, eq(schema.tasks.id, schema.dependencies.taskId))
    .where(eq(schema.dependencies.dependsOn, id as string))
    .all()
    .map((r) => toTaskRecord(r.task))

  return ok({
    ...toTaskRecord(task),
    workspace: toWorkspaceRecord(ws),
    dependencies: deps,
    dependedBy,
  })
}

export const getAllRunnableTasks = (db: Db, wsId: WorkspaceId): TaskRecord[] => {
  const sqlite = (db as unknown as { session: { client: Database } }).session.client
  const rows = sqlite
    .prepare(
      `SELECT t.* FROM tasks t
       WHERE t.workspace_id = ?
         AND t.status = ?
         AND NOT EXISTS (
           SELECT 1 FROM dependencies d
           JOIN tasks dep ON dep.id = d.depends_on
           WHERE d.task_id = t.id AND dep.status != ?
         )
       ORDER BY t.created_at`,
    )
    .all(wsId as string, TaskStatus.Pending, TaskStatus.Done) as Array<typeof schema.tasks.$inferSelect>

  return rows.map(toTaskRecord)
}

export const getNextTask = (db: Db, wsId: WorkspaceId): TaskRecord | null => {
  const tasks = getAllRunnableTasks(db, wsId)
  return tasks[0] ?? null
}

export const startTask = (db: Db, id: TaskId): void => {
  db.update(schema.tasks)
    .set({ status: TaskStatus.Running })
    .where(eq(schema.tasks.id, id as string))
    .run()
}

export const completeTask = (db: Db, id: TaskId, result?: string): Result<TaskRecord, string> => {
  db.update(schema.tasks)
    .set({ status: TaskStatus.Done, result: result ?? null })
    .where(eq(schema.tasks.id, id as string))
    .run()

  const task = db
    .select()
    .from(schema.tasks)
    .where(eq(schema.tasks.id, id as string))
    .get()
  return task ? ok(toTaskRecord(task)) : err(`Task ${id} not found`)
}

export const isWorkspaceComplete = (db: Db, wsId: WorkspaceId): boolean => {
  const row = db
    .select({ count: sql<number>`COUNT(*)` })
    .from(schema.tasks)
    .where(
      and(eq(schema.tasks.workspaceId, wsId as string), sql`status != ${TaskStatus.Done}`),
    )
    .get()
  return (row?.count ?? 0) === 0
}
