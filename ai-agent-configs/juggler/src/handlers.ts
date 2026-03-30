import { ok, err, type Result } from "neverthrow";
import type { Workflow, Task } from "./types.js";
import type { TaskStore } from "./task-store.js";
import { getCallableWorkflows } from "./workflow-loader.js";
import { buildWorkerPrompt } from "./prompt-builder.js";

export interface WorkflowSummary {
  type: string;
  description: string;
  inputs: Record<string, string>;
  "requires-approval": boolean;
}

export interface RunResult {
  taskId: string;
  status: "running";
  prompt: string;
}

export interface DoneResult {
  taskId: string;
  status: "done";
  output: Record<string, string>;
}

export interface RejectResult {
  taskId: string;
  status: "rejected";
  reason: string;
}

export function listWorkflows(
  workflows: Map<string, Workflow>,
): WorkflowSummary[] {
  return getCallableWorkflows(workflows).map((w) => ({
    type: w.type,
    description: w.frontmatter.description,
    inputs: w.frontmatter.inputs,
    "requires-approval": w.frontmatter["requires-approval"] ?? false,
  }));
}

export function runWorkflow(
  workflows: Map<string, Workflow>,
  store: TaskStore,
  params: { type: string; title: string; inputs: Record<string, string> },
): Result<RunResult, string> {
  const workflow = workflows.get(params.type);
  if (!workflow) return err(`Unknown workflow type: ${params.type}`);

  if (workflow.frontmatter.callable === false) {
    return err(`Workflow ${params.type} is not callable (internal chain step)`);
  }

  const missingInputs: string[] = [];
  for (const key of Object.keys(workflow.frontmatter.inputs)) {
    if (!(key in params.inputs) || !params.inputs[key]) {
      missingInputs.push(key);
    }
  }

  if (missingInputs.length > 0) {
    return err(`Missing required inputs: ${missingInputs.join(", ")}`);
  }

  const task = store.create({
    type: params.type,
    title: params.title,
    inputs: params.inputs,
    then: workflow.frontmatter.then,
  });

  const prompt = buildWorkerPrompt(workflow, params.inputs, task.id);
  return ok({ taskId: task.id, status: "running" as const, prompt });
}

export function completeTask(
  store: TaskStore,
  params: { taskId: string; output: Record<string, string> },
): Result<DoneResult, string> {
  return store
    .complete(params.taskId, params.output)
    .map(() => ({
      taskId: params.taskId,
      status: "done" as const,
      output: params.output,
    }));
}

export function rejectTask(
  store: TaskStore,
  params: { taskId: string; reason: string },
): Result<RejectResult, string> {
  return store
    .reject(params.taskId, params.reason)
    .map(() => ({
      taskId: params.taskId,
      status: "rejected" as const,
      reason: params.reason,
    }));
}

export function getStatus(
  store: TaskStore,
  taskId?: string,
): Result<Task | Task[], string> {
  if (taskId) {
    const task = store.get(taskId);
    if (!task) return err(`Task not found: ${taskId}`);
    return ok(task);
  }
  return ok(store.list());
}
