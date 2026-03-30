export interface WorkflowFrontmatter {
  description: string;
  inputs: Record<string, string>;
  "confirm-before-run"?: boolean;
  then?: string;
  "chain-only"?: boolean;
}

export interface Workflow {
  type: string;
  domain: string;
  name: string;
  frontmatter: WorkflowFrontmatter;
  body: string;
  outputs: Record<string, string>;
}

export type TaskStatus = "running" | "done" | "rejected";

export interface Task {
  id: string;
  type: string;
  title: string;
  inputs: Record<string, string>;
  status: TaskStatus;
  output?: Record<string, string>;
  reason?: string;
  then?: string;
  chainParent?: string;
}

export interface LintError {
  file: string;
  message: string;
}

export function exhaustive(_value: never): never {
  throw new Error(`Unhandled value: ${String(_value)}`);
}
