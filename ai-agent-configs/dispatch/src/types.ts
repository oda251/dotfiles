/**
 * Core domain types for dispatch.
 */

// --- Branded Types ---

const generateShortId = (): string => crypto.randomUUID().slice(0, 8)

export type WorkspaceId = string & { readonly __brand: unique symbol }

export const WorkspaceId = {
  from: (value: string): WorkspaceId => value as WorkspaceId,
  generate: (): WorkspaceId => generateShortId() as unknown as WorkspaceId,
  unwrap: (id: WorkspaceId): string => id as string,
} as const

export type TaskId = string & { readonly __brand: unique symbol }

export const TaskId = {
  from: (value: string): TaskId => value as TaskId,
  generate: (): TaskId => generateShortId() as unknown as TaskId,
  unwrap: (id: TaskId): string => id as string,
} as const

// --- Task Status ---

const TaskStatus = {
  Pending: "pending",
  Running: "running",
  Done: "done",
} as const

type TaskStatus = (typeof TaskStatus)[keyof typeof TaskStatus]

export { TaskStatus }

// --- Task Type ---

const TaskType = {
  ExecDev: "exec-dev",
  ExecResearch: "exec-research",
  ExecResearchWrite: "exec-research-write",
  PlanDev: "plan-dev",
  PlanResearch: "plan-research",
} as const

type TaskType = (typeof TaskType)[keyof typeof TaskType]

export { TaskType }

// --- Run Result (Discriminated Union) ---

export type RunResult =
  | { readonly status: "ready"; readonly task: TaskRecord; readonly prompt: string }
  | { readonly status: "complete"; readonly message: string }
  | { readonly status: "blocked"; readonly message: string }
  | { readonly status: "error"; readonly message: string }

// --- Domain Records ---

export type WorkspaceRecord = {
  readonly id: WorkspaceId
  readonly title: string
  readonly background: string
  readonly goals: readonly string[]
  readonly constraints: readonly string[]
  readonly createdAt: string
}

export type TaskRecord = {
  readonly id: TaskId
  readonly workspaceId: WorkspaceId
  readonly title: string
  readonly type: TaskType
  readonly status: TaskStatus
  readonly result: string | null
  readonly createdAt: string
}

export type TaskWithContext = TaskRecord & {
  readonly workspace: WorkspaceRecord
  readonly dependencies: readonly TaskRecord[]
  readonly dependedBy: readonly TaskRecord[]
}
