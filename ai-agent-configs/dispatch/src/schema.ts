/**
 * Drizzle schema + Valibot validation for dispatch DB.
 * DTOs are derived from drizzle-valibot's createInsertSchema (single source of truth).
 */

import { sqliteTable, text, primaryKey } from "drizzle-orm/sqlite-core"
import * as v from "valibot"
import { createInsertSchema } from "drizzle-valibot"
import { TaskStatus } from "./types.ts"
import type { TaskType } from "./types.ts"
import { isValidTaskType } from "./config.ts"

// --- Drizzle Schema ---

export const workspaces = sqliteTable("workspaces", {
  id: text("id").primaryKey(),
  title: text("title").notNull(),
  background: text("background").notNull().default(""),
  goals: text("goals", { mode: "json" }).notNull().default("[]").$type<string[]>(),
  constraints: text("constraints", { mode: "json" }).notNull().default("[]").$type<string[]>(),
  createdAt: text("created_at").notNull(),
})

export const tasks = sqliteTable("tasks", {
  id: text("id").primaryKey(),
  workspaceId: text("workspace_id")
    .notNull()
    .references(() => workspaces.id),
  title: text("title").notNull(),
  type: text("type").notNull().$type<TaskType>(),
  status: text("status").notNull().default(TaskStatus.Pending).$type<TaskStatus>(),
  result: text("result"),
  createdAt: text("created_at").notNull(),
})

export const dependencies = sqliteTable(
  "dependencies",
  {
    taskId: text("task_id")
      .notNull()
      .references(() => tasks.id),
    dependsOn: text("depends_on")
      .notNull()
      .references(() => tasks.id),
  },
  (table) => [primaryKey({ columns: [table.taskId, table.dependsOn] })],
)

// --- Base schemas from drizzle-valibot ---

const baseWorkspaceInsert = createInsertSchema(workspaces, {
  title: v.pipe(v.string(), v.minLength(1)),
})

const taskTypeSchema = v.pipe(v.string(), v.check(isValidTaskType, "Unknown task type"))

const baseTaskInsert = createInsertSchema(tasks, {
  title: v.pipe(v.string(), v.minLength(1)),
  type: taskTypeSchema,
})

// --- CLI input DTOs (derived from base schemas) ---

export const CreateWorkspaceInput = v.object({
  ...v.omit(baseWorkspaceInsert, ["id", "createdAt"]).entries,
  background: v.optional(v.string(), ""),
  goals: v.optional(v.array(v.string()), []),
  constraints: v.optional(v.array(v.string()), []),
})
export type CreateWorkspaceInput = v.InferOutput<typeof CreateWorkspaceInput>

export const EditWorkspaceInput = v.object({
  wsId: v.pipe(v.string(), v.minLength(1)),
  title: v.optional(v.string()),
  background: v.optional(v.string()),
  addGoal: v.optional(v.string()),
  removeGoal: v.optional(v.string()),
  addConstraint: v.optional(v.string()),
  removeConstraint: v.optional(v.string()),
})
export type EditWorkspaceInput = v.InferOutput<typeof EditWorkspaceInput>

export const AddTaskInput = v.object({
  ...v.omit(baseTaskInsert, ["id", "workspaceId", "status", "result", "createdAt"]).entries,
  wsId: v.pipe(v.string(), v.minLength(1)),
  dependsOn: v.optional(v.array(v.string()), []),
})
export type AddTaskInput = v.InferOutput<typeof AddTaskInput>

export const EditTaskInput = v.object({
  id: v.pipe(v.string(), v.minLength(1)),
  title: v.optional(v.string()),
  type: v.optional(taskTypeSchema),
  addDep: v.optional(v.string()),
  removeDep: v.optional(v.string()),
})
export type EditTaskInput = v.InferOutput<typeof EditTaskInput>
