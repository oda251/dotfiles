import { describe, test, expect, beforeEach } from "bun:test"
import { createDb } from "../src/db.ts"
import * as db from "../src/db.ts"
import * as runner from "../src/runner.ts"
import { WorkspaceId, TaskId, TaskType, TaskStatus, type WorkspaceRecord, type TaskRecord } from "../src/types.ts"
import type { BunSQLiteDatabase } from "drizzle-orm/bun-sqlite"
import type * as schema from "../src/schema.ts"

type Db = BunSQLiteDatabase<typeof schema>

let database: Db

beforeEach(() => {
  database = createDb(":memory:")
})

const createTestWorkspace = (): WorkspaceRecord =>
  db.createWorkspace(database, {
    title: "Test Project",
    background: "Testing dispatch CLI",
    goals: ["Goal A", "Goal B"],
    constraints: ["Constraint 1"],
  })

const createTestDag = (): { ws: WorkspaceRecord; t1: TaskRecord; t2: TaskRecord } => {
  const ws = createTestWorkspace()
  const t1 = db.addTask(database, { wsId: ws.id, title: "Research auth patterns", type: TaskType.from("exec-research") })
  const t2 = db.addTask(database, { wsId: ws.id, title: "Implement auth API", type: TaskType.from("exec-dev"), dependsOn: [t1.id] })
  return { ws, t1, t2 }
}

// --- Workspace tests ---

describe("Workspace", () => {
  test("create", () => {
    const ws = db.createWorkspace(database, { title: "Test", background: "bg", goals: ["g1"], constraints: ["c1"] })
    expect(ws.title).toBe("Test")
    expect(ws.goals).toEqual(["g1"])
    expect(ws.constraints).toEqual(["c1"])
    expect((ws.id as string).length).toBe(8)
  })

  test("show", () => {
    const ws = createTestWorkspace()
    const result = db.getWorkspace(database, ws.id)
    expect(result.isOk()).toBe(true)
    if (result.isOk()) {
      expect(result.value.title).toBe("Test Project")
      expect(result.value.goals).toEqual(["Goal A", "Goal B"])
    }
  })

  test("list", () => {
    createTestWorkspace()
    db.createWorkspace(database, { title: "Second" })
    const result = db.listWorkspaces(database)
    expect(result.length).toBe(2)
  })

  test("edit title", () => {
    const ws = createTestWorkspace()
    const result = db.editWorkspace(database, ws.id, { title: "New Title" })
    expect(result.isOk()).toBe(true)
    if (result.isOk()) expect(result.value.title).toBe("New Title")
  })

  test("edit add goal", () => {
    const ws = createTestWorkspace()
    const result = db.editWorkspace(database, ws.id, { addGoal: "Goal C" })
    expect(result.isOk()).toBe(true)
    if (result.isOk()) {
      expect(result.value.goals).toContain("Goal C")
      expect(result.value.goals.length).toBe(3)
    }
  })

  test("edit remove goal", () => {
    const ws = createTestWorkspace()
    const result = db.editWorkspace(database, ws.id, { removeGoal: "Goal A" })
    expect(result.isOk()).toBe(true)
    if (result.isOk()) {
      expect(result.value.goals).not.toContain("Goal A")
      expect(result.value.goals.length).toBe(1)
    }
  })

  test("edit nonexistent", () => {
    const result = db.editWorkspace(database, WorkspaceId.from("nonexist"), { title: "x" })
    expect(result.isErr()).toBe(true)
  })
})

// --- Task tests ---

describe("Task", () => {
  test("add", () => {
    const ws = createTestWorkspace()
    const task = db.addTask(database, { wsId: ws.id, title: "Test task", type: TaskType.from("exec-dev") })
    expect(task.title).toBe("Test task")
    expect(task.status).toBe(TaskStatus.Pending)
  })

  test("add with deps", () => {
    const ws = createTestWorkspace()
    const t1 = db.addTask(database, { wsId: ws.id, title: "First", type: TaskType.from("exec-research") })
    const t2 = db.addTask(database, { wsId: ws.id, title: "Second", type: TaskType.from("exec-dev"), dependsOn: [t1.id] })
    const ctx = db.getTaskWithContext(database, t2.id)
    expect(ctx.isOk()).toBe(true)
    if (ctx.isOk()) {
      expect(ctx.value.dependencies.length).toBe(1)
      expect(ctx.value.dependencies[0]!.id).toBe(t1.id)
    }
  })

  test("edit title", () => {
    const ws = createTestWorkspace()
    const task = db.addTask(database, { wsId: ws.id, title: "Old", type: TaskType.from("exec-dev") })
    const result = db.editTask(database, task.id, { title: "New" })
    expect(result.isOk()).toBe(true)
    if (result.isOk()) expect(result.value.title).toBe("New")
  })

  test("edit add dep", () => {
    const ws = createTestWorkspace()
    const t1 = db.addTask(database, { wsId: ws.id, title: "A", type: TaskType.from("exec-research") })
    const t2 = db.addTask(database, { wsId: ws.id, title: "B", type: TaskType.from("exec-dev") })
    db.editTask(database, t2.id, { addDep: t1.id })
    const ctx = db.getTaskWithContext(database, t2.id)
    expect(ctx.isOk()).toBe(true)
    if (ctx.isOk()) expect(ctx.value.dependencies.length).toBe(1)
  })

  test("edit remove dep", () => {
    const { t1, t2 } = createTestDag()
    db.editTask(database, t2.id, { removeDep: t1.id })
    const ctx = db.getTaskWithContext(database, t2.id)
    expect(ctx.isOk()).toBe(true)
    if (ctx.isOk()) expect(ctx.value.dependencies.length).toBe(0)
  })

  test("list", () => {
    const { ws } = createTestDag()
    const tasks = db.listTasks(database, ws.id)
    expect(tasks.length).toBe(2)
  })

  test("list by status", () => {
    const { ws, t1 } = createTestDag()
    db.startTask(database, t1.id)
    const running = db.listTasks(database, ws.id, TaskStatus.Running)
    expect(running.length).toBe(1)
  })
})

// --- DAG dependency resolution ---

describe("DAG", () => {
  test("next picks no deps", () => {
    const { ws, t1 } = createTestDag()
    const nxt = db.getNextTask(database, ws.id)
    expect(nxt?.id).toBe(t1.id)
  })

  test("next blocked when dep pending", () => {
    const { ws, t1 } = createTestDag()
    db.startTask(database, t1.id)
    const nxt = db.getNextTask(database, ws.id)
    expect(nxt).toBeNull()
  })

  test("next unblocked after dep done", () => {
    const { ws, t1, t2 } = createTestDag()
    db.startTask(database, t1.id)
    db.completeTask(database, t1.id, "result.md")
    const nxt = db.getNextTask(database, ws.id)
    expect(nxt?.id).toBe(t2.id)
  })

  test("all runnable parallel", () => {
    const ws = createTestWorkspace()
    const t1 = db.addTask(database, { wsId: ws.id, title: "A", type: TaskType.from("exec-research") })
    const t2 = db.addTask(database, { wsId: ws.id, title: "B", type: TaskType.from("exec-research") })
    const t3 = db.addTask(database, { wsId: ws.id, title: "C", type: TaskType.from("exec-dev"), dependsOn: [t1.id, t2.id] })
    const runnable = db.getAllRunnableTasks(database, ws.id)
    expect(runnable.length).toBe(2)
    const ids = new Set(runnable.map((t) => t.id))
    expect(ids.has(t1.id)).toBe(true)
    expect(ids.has(t2.id)).toBe(true)
    expect(ids.has(t3.id)).toBe(false)
  })

  test("diamond dag", () => {
    const ws = createTestWorkspace()
    //   A
    //  / \
    // B   C
    //  \ /
    //   D
    const a = db.addTask(database, { wsId: ws.id, title: "A", type: TaskType.from("exec-research") })
    const b = db.addTask(database, { wsId: ws.id, title: "B", type: TaskType.from("exec-dev"), dependsOn: [a.id] })
    const c = db.addTask(database, { wsId: ws.id, title: "C", type: TaskType.from("exec-dev"), dependsOn: [a.id] })
    const d = db.addTask(database, { wsId: ws.id, title: "D", type: TaskType.from("exec-dev"), dependsOn: [b.id, c.id] })

    // Only A is runnable
    expect(db.getNextTask(database, ws.id)?.id).toBe(a.id)

    // Complete A → B, C runnable
    db.startTask(database, a.id)
    db.completeTask(database, a.id)
    const runnable = db.getAllRunnableTasks(database, ws.id)
    expect(runnable.length).toBe(2)

    // Complete B only → D still blocked
    db.startTask(database, b.id)
    db.completeTask(database, b.id)
    expect(db.getNextTask(database, ws.id)?.id).toBe(c.id)

    // Complete C → D runnable
    db.startTask(database, c.id)
    db.completeTask(database, c.id)
    expect(db.getNextTask(database, ws.id)?.id).toBe(d.id)
  })
})

// --- Workspace completion ---

describe("Completion", () => {
  test("not complete", () => {
    const { ws } = createTestDag()
    expect(db.isWorkspaceComplete(database, ws.id)).toBe(false)
  })

  test("complete after all done", () => {
    const { ws, t1, t2 } = createTestDag()
    db.startTask(database, t1.id)
    db.completeTask(database, t1.id)
    db.startTask(database, t2.id)
    db.completeTask(database, t2.id)
    expect(db.isWorkspaceComplete(database, ws.id)).toBe(true)
  })
})

// --- Task context ---

describe("Context", () => {
  test("includes workspace", () => {
    const { t2 } = createTestDag()
    const ctx = db.getTaskWithContext(database, t2.id)
    expect(ctx.isOk()).toBe(true)
    if (ctx.isOk()) {
      expect(ctx.value.workspace.title).toBe("Test Project")
      expect(ctx.value.workspace.goals).toEqual(["Goal A", "Goal B"])
    }
  })

  test("includes deps", () => {
    const { t1, t2 } = createTestDag()
    const ctx = db.getTaskWithContext(database, t2.id)
    expect(ctx.isOk()).toBe(true)
    if (ctx.isOk()) {
      expect(ctx.value.dependencies.length).toBe(1)
      expect(ctx.value.dependencies[0]!.title).toBe("Research auth patterns")
    }
  })

  test("includes dependents", () => {
    const { t1 } = createTestDag()
    const ctx = db.getTaskWithContext(database, t1.id)
    expect(ctx.isOk()).toBe(true)
    if (ctx.isOk()) {
      expect(ctx.value.dependedBy.length).toBe(1)
      expect(ctx.value.dependedBy[0]!.title).toBe("Implement auth API")
    }
  })
})

// --- Runner (sync operations only, no SDK calls) ---

describe("Runner", () => {
  test("runNext picks task", () => {
    const { ws, t1 } = createTestDag()
    const result = runner.runNext(database, ws.id)
    expect(result.status).toBe("ready")
    if (result.status === "ready") {
      expect(result.task.id).toBe(t1.id)
    }
  })

  test("runNext complete", () => {
    const ws = createTestWorkspace()
    const t = db.addTask(database, { wsId: ws.id, title: "Only", type: TaskType.from("exec-dev") })
    db.startTask(database, t.id)
    db.completeTask(database, t.id)
    const result = runner.runNext(database, ws.id)
    expect(result.status).toBe("complete")
  })

  test("runNext blocked", () => {
    const { ws, t1 } = createTestDag()
    db.startTask(database, t1.id)
    const result = runner.runNext(database, ws.id)
    expect(result.status).toBe("blocked")
  })

  test("completeAndContinue", () => {
    const { t1, t2 } = createTestDag()
    db.startTask(database, t1.id)
    const result = runner.completeAndContinue(database, t1.id, "res.md")
    expect(result.status).toBe("ready")
    if (result.status === "ready") {
      expect(result.task.id).toBe(t2.id)
    }
  })

  test("completeAndContinue all done", () => {
    const ws = createTestWorkspace()
    const t = db.addTask(database, { wsId: ws.id, title: "Only", type: TaskType.from("exec-dev") })
    db.startTask(database, t.id)
    const result = runner.completeAndContinue(database, t.id)
    expect(result.status).toBe("complete")
  })

  test("prompt includes workspace", () => {
    const { ws, t1 } = createTestDag()
    const result = runner.runNext(database, ws.id)
    if (result.status === "ready") {
      expect(result.prompt).toContain("Test Project")
      expect(result.prompt).toContain("Goal A")
    }
  })

  test("prompt includes dep results", () => {
    const { ws, t1 } = createTestDag()
    db.startTask(database, t1.id)
    db.completeTask(database, t1.id, "docs/research.md")
    const result = runner.runNext(database, ws.id)
    if (result.status === "ready") {
      expect(result.prompt).toContain("docs/research.md")
    }
  })
})
