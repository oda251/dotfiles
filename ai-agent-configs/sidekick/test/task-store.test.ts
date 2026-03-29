import { describe, it, expect } from "vitest";
import { TaskStore } from "../src/task-store.js";

describe("TaskStore", () => {
  it("creates a task", () => {
    const store = new TaskStore();
    const task = store.create({
      type: "dev/impl",
      title: "Implement auth",
      inputs: { what: "JWT middleware", where: "src/auth/" },
    });

    expect(task.id).toBeDefined();
    expect(task.status).toBe("running");
    expect(task.type).toBe("dev/impl");
    expect(task.inputs.what).toBe("JWT middleware");
  });

  it("completes a task", () => {
    const store = new TaskStore();
    const task = store.create({
      type: "dev/impl",
      title: "Test",
      inputs: { what: "test" },
    });

    const completed = store.complete(task.id, {
      changes: "src/auth/middleware.ts",
    });
    expect(completed.status).toBe("done");
    expect(completed.output).toEqual({ changes: "src/auth/middleware.ts" });
  });

  it("rejects a task", () => {
    const store = new TaskStore();
    const task = store.create({
      type: "dev/impl",
      title: "Test",
      inputs: { what: "test" },
    });

    const rejected = store.reject(task.id, "Missing spec");
    expect(rejected.status).toBe("rejected");
    expect(rejected.reason).toBe("Missing spec");
  });

  it("throws on completing non-running task", () => {
    const store = new TaskStore();
    const task = store.create({
      type: "dev/impl",
      title: "Test",
      inputs: { what: "test" },
    });
    store.complete(task.id, {});

    expect(() => store.complete(task.id, {})).toThrow("not running");
  });

  it("throws on unknown task id", () => {
    const store = new TaskStore();
    expect(() => store.complete("nonexistent", {})).toThrow("not found");
  });

  it("lists tasks", () => {
    const store = new TaskStore();
    store.create({ type: "dev/impl", title: "A", inputs: {} });
    store.create({ type: "dev/impl", title: "B", inputs: {} });

    expect(store.list()).toHaveLength(2);
  });

  it("filters running tasks", () => {
    const store = new TaskStore();
    const a = store.create({ type: "dev/impl", title: "A", inputs: {} });
    store.create({ type: "dev/impl", title: "B", inputs: {} });
    store.complete(a.id, {});

    expect(store.getRunning()).toHaveLength(1);
  });
});
