import { describe, it, expect } from "bun:test";
import { TaskStore } from "../src/task-store.js";
import {
  listWorkflows,
  runWorkflow,
  completeTask,
  rejectTask,
  getStatus,
} from "../src/handlers.js";
import type { Workflow } from "../src/types.js";

function makeWorkflows(): Map<string, Workflow> {
  const map = new Map<string, Workflow>();
  map.set("dev/impl", {
    type: "dev/impl",
    domain: "dev",
    name: "impl",
    frontmatter: {
      description: "Implement code",
      inputs: { what: "What to implement", where: "Target file" },
      "confirm-before-run": true,
      next: "review",
    },
    body: "Write the code.",
    outputs: { changes: "Changed files" },
  });
  map.set("dev/review", {
    type: "dev/review",
    domain: "dev",
    name: "review",
    frontmatter: {
      description: "Review implementation",
      inputs: { changes: "Changed files" },
      internal: true,
    },
    body: "Review the changes.",
    outputs: {},
  });
  return map;
}

describe("listWorkflows", () => {
  it("returns only runnable workflows with summary", () => {
    const result = listWorkflows(makeWorkflows());
    expect(result).toHaveLength(1);
    expect(result[0].type).toBe("dev/impl");
    expect(result[0].description).toBe("Implement code");
    expect(result[0]["confirm-before-run"]).toBe(true);
  });

  it("returns empty array when no workflows", () => {
    const result = listWorkflows(new Map());
    expect(result).toEqual([]);
  });
});

describe("runWorkflow", () => {
  it("creates task and returns prompt", () => {
    const store = new TaskStore();
    const result = runWorkflow(makeWorkflows(), store, {
      type: "dev/impl",
      title: "Add auth",
      inputs: { what: "JWT", where: "src/" },
    });

    expect(result.isOk()).toBe(true);
    const data = result._unsafeUnwrap();
    expect(data.status).toBe("running");
    expect(data.prompt).toContain("JWT");
    expect(data.taskId).toBeDefined();
  });

  it("errors on unknown workflow type", () => {
    const store = new TaskStore();
    const result = runWorkflow(makeWorkflows(), store, {
      type: "unknown/type",
      title: "Test",
      inputs: {},
    });

    expect(result.isErr()).toBe(true);
    expect(result._unsafeUnwrapErr()).toContain("Unknown workflow type");
  });

  it("errors on internal workflow", () => {
    const store = new TaskStore();
    const result = runWorkflow(makeWorkflows(), store, {
      type: "dev/review",
      title: "Test",
      inputs: { changes: "file.ts" },
    });

    expect(result.isErr()).toBe(true);
    expect(result._unsafeUnwrapErr()).toContain("internal");
  });

  it("errors on missing required inputs", () => {
    const store = new TaskStore();
    const result = runWorkflow(makeWorkflows(), store, {
      type: "dev/impl",
      title: "Test",
      inputs: { what: "something" },
    });

    expect(result.isErr()).toBe(true);
    expect(result._unsafeUnwrapErr()).toContain("where");
  });

  it("errors on empty string input value", () => {
    const store = new TaskStore();
    const result = runWorkflow(makeWorkflows(), store, {
      type: "dev/impl",
      title: "Test",
      inputs: { what: "something", where: "" },
    });

    expect(result.isErr()).toBe(true);
    expect(result._unsafeUnwrapErr()).toContain("where");
  });
});

describe("completeTask", () => {
  it("completes a running task", () => {
    const store = new TaskStore();
    const task = store.create({ type: "dev/impl", title: "T", inputs: {} });

    const result = completeTask(store, {
      taskId: task.id,
      output: { changes: "src/foo.ts" },
    });

    expect(result.isOk()).toBe(true);
    const data = result._unsafeUnwrap();
    expect(data.status).toBe("done");
    expect(data.output.changes).toBe("src/foo.ts");
  });

  it("errors on already-completed task", () => {
    const store = new TaskStore();
    const task = store.create({ type: "dev/impl", title: "T", inputs: {} });
    store.complete(task.id, {});

    const result = completeTask(store, {
      taskId: task.id,
      output: {},
    });

    expect(result.isErr()).toBe(true);
    expect(result._unsafeUnwrapErr()).toContain("not running");
  });

  it("errors on nonexistent task", () => {
    const store = new TaskStore();
    const result = completeTask(store, {
      taskId: "no-such-id",
      output: {},
    });

    expect(result.isErr()).toBe(true);
    expect(result._unsafeUnwrapErr()).toContain("not found");
  });
});

describe("rejectTask", () => {
  it("rejects a running task", () => {
    const store = new TaskStore();
    const task = store.create({ type: "dev/impl", title: "T", inputs: {} });

    const result = rejectTask(store, {
      taskId: task.id,
      reason: "Bad spec",
    });

    expect(result.isOk()).toBe(true);
    const data = result._unsafeUnwrap();
    expect(data.status).toBe("rejected");
    expect(data.reason).toBe("Bad spec");
  });

  it("errors on already-done task", () => {
    const store = new TaskStore();
    const task = store.create({ type: "dev/impl", title: "T", inputs: {} });
    store.complete(task.id, {});

    const result = rejectTask(store, {
      taskId: task.id,
      reason: "Too late",
    });

    expect(result.isErr()).toBe(true);
    expect(result._unsafeUnwrapErr()).toContain("not running");
  });

  it("errors on nonexistent task", () => {
    const store = new TaskStore();
    const result = rejectTask(store, {
      taskId: "no-such-id",
      reason: "whatever",
    });

    expect(result.isErr()).toBe(true);
    expect(result._unsafeUnwrapErr()).toContain("not found");
  });
});

describe("getStatus", () => {
  it("returns all tasks when no taskId", () => {
    const store = new TaskStore();
    store.create({ type: "dev/impl", title: "A", inputs: {} });
    store.create({ type: "dev/impl", title: "B", inputs: {} });

    const result = getStatus(store);
    expect(result.isOk()).toBe(true);
    expect(result._unsafeUnwrap()).toHaveLength(2);
  });

  it("returns empty array when no tasks", () => {
    const store = new TaskStore();
    const result = getStatus(store);
    expect(result.isOk()).toBe(true);
    expect(result._unsafeUnwrap()).toEqual([]);
  });

  it("returns specific task by id", () => {
    const store = new TaskStore();
    const task = store.create({ type: "dev/impl", title: "A", inputs: {} });

    const result = getStatus(store, task.id);
    expect(result.isOk()).toBe(true);
    const data = result._unsafeUnwrap();
    expect((data as { id: string }).id).toBe(task.id);
  });

  it("errors on unknown task id", () => {
    const store = new TaskStore();
    const result = getStatus(store, "nonexistent");
    expect(result.isErr()).toBe(true);
    expect(result._unsafeUnwrapErr()).toContain("not found");
  });
});
