import { describe, it, expect } from "bun:test";
import { buildWorkerPrompt } from "../src/prompt-builder.js";
import type { Workflow } from "../src/types.js";

describe("buildWorkerPrompt", () => {
  it("builds prompt with inputs and workflow body", () => {
    const workflow: Workflow = {
      type: "dev/impl",
      domain: "dev",
      name: "impl",
      frontmatter: {
        description: "Implement code",
        inputs: { what: "What to implement", where: "Target file" },
        then: "review",
      },
      body: "Write the code following TDD.",
      outputs: { changes: "Changed files" },
    };

    const prompt = buildWorkerPrompt(
      workflow,
      { what: "JWT middleware", where: "src/auth/" },
      "task-123",
    );

    expect(prompt).toContain("task-123");
    expect(prompt).toContain("JWT middleware");
    expect(prompt).toContain("src/auth/");
    expect(prompt).toContain("Write the code following TDD.");
    expect(prompt).toContain("changes");
    expect(prompt).toContain("done ツール");
    expect(prompt).toContain("reject ツール");
  });

  it("omits outputs section when no then chain", () => {
    const workflow: Workflow = {
      type: "dev/review",
      domain: "dev",
      name: "review",
      frontmatter: {
        description: "Review code",
        inputs: { changes: "Changed files" },
        callable: false,
      },
      body: "Review the changes.",
      outputs: {},
    };

    const prompt = buildWorkerPrompt(
      workflow,
      { changes: "src/auth/middleware.ts" },
      "task-456",
    );

    expect(prompt).not.toContain("完了時に返す Outputs");
    expect(prompt).toContain("src/auth/middleware.ts");
  });
});
