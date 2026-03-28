/**
 * Drizzle schema + Zod validation for dispatch DB.
 */

import { sqliteTable, text, primaryKey } from "drizzle-orm/sqlite-core"
import { z } from "zod/v4"
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

// --- Zod Schemas (CLI input validation) ---

const taskTypeSchema = z.string().refine(isValidTaskType, { message: "Unknown task type" })

export const CreateWorkspaceInput = z.object({
  title: z.string().min(1),
  background: z.string().optional().default(""),
  goals: z.array(z.string()).optional().default([]),
  constraints: z.array(z.string()).optional().default([]),
})
export type CreateWorkspaceInput = z.infer<typeof CreateWorkspaceInput>

export const EditWorkspaceInput = z.object({
  wsId: z.string().min(1),
  title: z.string().optional(),
  background: z.string().optional(),
  addGoal: z.string().optional(),
  removeGoal: z.string().optional(),
  addConstraint: z.string().optional(),
  removeConstraint: z.string().optional(),
})
export type EditWorkspaceInput = z.infer<typeof EditWorkspaceInput>

export const AddTaskInput = z.object({
  wsId: z.string().min(1),
  title: z.string().min(1),
  type: taskTypeSchema,
  dependsOn: z.array(z.string()).optional().default([]),
})
export type AddTaskInput = z.infer<typeof AddTaskInput>

export const EditTaskInput = z.object({
  id: z.string().min(1),
  title: z.string().optional(),
  type: taskTypeSchema.optional(),
  addDep: z.string().optional(),
  removeDep: z.string().optional(),
})
export type EditTaskInput = z.infer<typeof EditTaskInput>
