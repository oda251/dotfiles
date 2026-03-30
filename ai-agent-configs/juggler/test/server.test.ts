import { describe, it, expect, beforeEach, afterEach } from "bun:test";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { InMemoryTransport } from "@modelcontextprotocol/sdk/inMemory.js";
import { createServer } from "../src/server.js";

let tmpDir: string;

function createWorkflow(domain: string, name: string, content: string) {
  const dir = join(tmpDir, domain);
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, `${name}.md`), content);
}

function setupWorkflows() {
  createWorkflow(
    "dev",
    "impl",
    `---
description: Implement code
inputs:
  what: What to implement
  where: Target file
requires-approval: true
then: review
---

Write the code.`,
  );

  createWorkflow(
    "dev",
    "review",
    `---
description: Review implementation
callable: false
inputs:
  changes: Changed files
---

Review the changes.`,
  );
}

async function connectClient(workflowsDir: string) {
  const { server } = createServer(workflowsDir);
  const [clientTransport, serverTransport] = InMemoryTransport.createLinkedPair();
  await server.connect(serverTransport);

  const client = new Client({ name: "test-client", version: "1.0.0" });
  await client.connect(clientTransport);

  return client;
}

function parseText(result: Awaited<ReturnType<Client["callTool"]>>) {
  return JSON.parse((result.content as Array<{ text: string }>)[0].text);
}

beforeEach(() => {
  tmpDir = mkdtempSync(join(tmpdir(), "juggler-server-test-"));
});

afterEach(() => {
  rmSync(tmpDir, { recursive: true, force: true });
});

describe("tools list", () => {
  it("exposes five tools", async () => {
    setupWorkflows();
    const client = await connectClient(tmpDir);

    const result = await client.listTools();
    expect(result.tools).toHaveLength(5);

    const names = result.tools.map((t) => t.name);
    expect(names).toContain("workflows");
    expect(names).toContain("run");
    expect(names).toContain("done");
    expect(names).toContain("reject");
    expect(names).toContain("status");

    await client.close();
  });
});

describe("valibot validation", () => {
  it("rejects run with empty type", async () => {
    setupWorkflows();
    const client = await connectClient(tmpDir);

    const result = await client.callTool({
      name: "run",
      arguments: { type: "", title: "Test", inputs: {} },
    });

    expect(result.isError).toBe(true);
    expect((result.content as Array<{ text: string }>)[0].text).toContain(
      "Invalid arguments",
    );

    await client.close();
  });

  it("rejects done with missing arguments", async () => {
    setupWorkflows();
    const client = await connectClient(tmpDir);

    const result = await client.callTool({
      name: "done",
      arguments: {},
    });

    expect(result.isError).toBe(true);
    expect((result.content as Array<{ text: string }>)[0].text).toContain(
      "Invalid arguments",
    );

    await client.close();
  });

  it("rejects reject with empty reason", async () => {
    setupWorkflows();
    const client = await connectClient(tmpDir);

    const result = await client.callTool({
      name: "reject",
      arguments: { taskId: "some-id", reason: "" },
    });

    expect(result.isError).toBe(true);
    expect((result.content as Array<{ text: string }>)[0].text).toContain(
      "Invalid arguments",
    );

    await client.close();
  });
});

describe("MCP response format", () => {
  it("returns JSON text content for success", async () => {
    setupWorkflows();
    const client = await connectClient(tmpDir);

    const result = await client.callTool({
      name: "workflows",
      arguments: {},
    });

    expect(result.isError).toBeUndefined();
    const data = parseText(result);
    expect(data).toHaveLength(1);
    expect(data[0].type).toBe("dev/impl");

    await client.close();
  });

  it("returns isError true for business errors", async () => {
    setupWorkflows();
    const client = await connectClient(tmpDir);

    const result = await client.callTool({
      name: "run",
      arguments: { type: "unknown/type", title: "Test", inputs: {} },
    });

    expect(result.isError).toBe(true);

    await client.close();
  });
});

describe("MCP tool pipeline", () => {
  it("run → done full cycle", async () => {
    setupWorkflows();
    const client = await connectClient(tmpDir);

    const runResult = await client.callTool({
      name: "run",
      arguments: {
        type: "dev/impl",
        title: "Add auth",
        inputs: { what: "JWT", where: "src/" },
      },
    });

    expect(runResult.isError).toBeUndefined();
    const runData = parseText(runResult);
    expect(runData.status).toBe("running");
    expect(runData.prompt).toContain("JWT");

    const doneResult = await client.callTool({
      name: "done",
      arguments: { taskId: runData.taskId, output: { changes: "src/auth.ts" } },
    });

    expect(doneResult.isError).toBeUndefined();
    const doneData = parseText(doneResult);
    expect(doneData.status).toBe("done");

    const statusResult = await client.callTool({
      name: "status",
      arguments: { taskId: runData.taskId },
    });
    const statusData = parseText(statusResult);
    expect(statusData.status).toBe("done");

    await client.close();
  });

  it("run → reject full cycle", async () => {
    setupWorkflows();
    const client = await connectClient(tmpDir);

    const runResult = await client.callTool({
      name: "run",
      arguments: {
        type: "dev/impl",
        title: "Task",
        inputs: { what: "x", where: "y" },
      },
    });
    const { taskId } = parseText(runResult);

    const rejectResult = await client.callTool({
      name: "reject",
      arguments: { taskId, reason: "Spec unclear" },
    });

    expect(rejectResult.isError).toBeUndefined();
    const data = parseText(rejectResult);
    expect(data.status).toBe("rejected");
    expect(data.reason).toBe("Spec unclear");

    await client.close();
  });

  it("done on already-completed task returns error", async () => {
    setupWorkflows();
    const client = await connectClient(tmpDir);

    const runResult = await client.callTool({
      name: "run",
      arguments: {
        type: "dev/impl",
        title: "Task",
        inputs: { what: "x", where: "y" },
      },
    });
    const { taskId } = parseText(runResult);

    await client.callTool({
      name: "done",
      arguments: { taskId, output: {} },
    });

    const secondDone = await client.callTool({
      name: "done",
      arguments: { taskId, output: {} },
    });
    expect(secondDone.isError).toBe(true);
    expect((secondDone.content as Array<{ text: string }>)[0].text).toContain(
      "not running",
    );

    await client.close();
  });

  it("unknown tool returns error", async () => {
    setupWorkflows();
    const client = await connectClient(tmpDir);

    const result = await client.callTool({
      name: "nonexistent",
      arguments: {},
    });

    expect(result.isError).toBe(true);
    expect((result.content as Array<{ text: string }>)[0].text).toContain(
      "Unknown tool",
    );

    await client.close();
  });

  it("status returns empty list when no tasks", async () => {
    setupWorkflows();
    const client = await connectClient(tmpDir);

    const result = await client.callTool({
      name: "status",
      arguments: {},
    });

    expect(result.isError).toBeUndefined();
    expect(parseText(result)).toEqual([]);

    await client.close();
  });
});
