import { nanoid } from "nanoid";
import { ok, err, type Result } from "neverthrow";
import type { Task } from "./types.js";

export class TaskStore {
  private tasks = new Map<string, Task>();

  create(params: {
    type: string;
    title: string;
    inputs: Record<string, string>;
    next?: string;
    chainParent?: string;
  }): Task {
    const task: Task = {
      id: nanoid(12),
      type: params.type,
      title: params.title,
      inputs: params.inputs,
      status: "running",
      next: params.next,
      chainParent: params.chainParent,
    };
    this.tasks.set(task.id, task);
    return task;
  }

  get(id: string): Task | undefined {
    return this.tasks.get(id);
  }

  complete(id: string, output: Record<string, string>): Result<Task, string> {
    return this.ensureRunning(id).map((task) => {
      task.status = "done";
      task.output = output;
      return task;
    });
  }

  reject(id: string, reason: string): Result<Task, string> {
    return this.ensureRunning(id).map((task) => {
      task.status = "rejected";
      task.reason = reason;
      return task;
    });
  }

  list(): Task[] {
    return [...this.tasks.values()];
  }

  getRunning(): Task[] {
    return this.list().filter((t) => t.status === "running");
  }

  private ensureRunning(id: string): Result<Task, string> {
    const task = this.tasks.get(id);
    if (!task) return err(`Task not found: ${id}`);
    if (task.status !== "running")
      return err(`Task ${id} is not running (status: ${task.status})`);
    return ok(task);
  }
}
