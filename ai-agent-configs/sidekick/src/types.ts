export interface WorkflowFrontmatter {
  description: string;
  inputs: Record<string, string>;
  "requires-approval"?: boolean;
  then?: string;
  callable?: boolean;
}

export interface Workflow {
  /** e.g. "dev/impl" */
  type: string;
  /** e.g. "dev" */
  domain: string;
  /** e.g. "impl" */
  name: string;
  /** Parsed frontmatter */
  frontmatter: WorkflowFrontmatter;
  /** Markdown body (after frontmatter) */
  body: string;
  /** Resolved outputs (derived from then-target's inputs) */
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
