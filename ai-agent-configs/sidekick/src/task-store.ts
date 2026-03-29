import { nanoid } from "nanoid";
import type { Task } from "./types.js";

export class TaskStore {
  private tasks = new Map<string, Task>();

  create(params: {
    type: string;
    title: string;
    inputs: Record<string, string>;
    then?: string;
    chainParent?: string;
  }): Task {
    const task: Task = {
      id: nanoid(12),
      type: params.type,
      title: params.title,
      inputs: params.inputs,
      status: "running",
      then: params.then,
      chainParent: params.chainParent,
    };
    this.tasks.set(task.id, task);
    return task;
  }

  get(id: string): Task | undefined {
    return this.tasks.get(id);
  }

  complete(id: string, output: Record<string, string>): Task {
    const task = this.tasks.get(id);
    if (!task) throw new Error(`Task not found: ${id}`);
    if (task.status !== "running")
      throw new Error(`Task ${id} is not running (status: ${task.status})`);
    task.status = "done";
    task.output = output;
    return task;
  }

  reject(id: string, reason: string): Task {
    const task = this.tasks.get(id);
    if (!task) throw new Error(`Task not found: ${id}`);
    if (task.status !== "running")
      throw new Error(`Task ${id} is not running (status: ${task.status})`);
    task.status = "rejected";
    task.reason = reason;
    return task;
  }

  list(): Task[] {
    return [...this.tasks.values()];
  }

  getRunning(): Task[] {
    return this.list().filter((t) => t.status === "running");
  }
}
