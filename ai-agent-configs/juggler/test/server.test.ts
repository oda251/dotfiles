import { describe, it, expect, beforeEach, afterEach } from "bun:test";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { createServer, startServer } from "../src/server.js";

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

// eslint-disable-next-line @typescript-eslint/no-explicit-any -- accessing SDK internals for testing
function getHandler(server: ReturnType<typeof createServer>, method: string) {
  const s = server.server as Record<string, unknown>;
  const handlers = s._requestHandlers as Map<string, Function> | undefined;
  const handler = handlers?.get(method);
  if (!handler) throw new Error(`No ${method} handler registered`);
  return handler;
}

async function callTool(
  server: ReturnType<typeof createServer>,
  name: string,
  args: Record<string, unknown> = {},
) {
  const handler = getHandler(server, "tools/call");
  return handler({
    method: "tools/call",
    params: { name, arguments: args },
  });
}

async function listTools(server: ReturnType<typeof createServer>) {
  const handler = getHandler(server, "tools/list");
  return handler({ method: "tools/list" });
}

beforeEach(() => {
  tmpDir = mkdtempSync(join(tmpdir(), "juggler-server-test-"));
});

afterEach(() => {
  rmSync(tmpDir, { recursive: true, force: true });
});

describe("workflows tool", () => {
  it("lists only callable workflows", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "workflows");
    const data = JSON.parse(result.content[0].text);

    expect(data).toHaveLength(1);
    expect(data[0].type).toBe("dev/impl");
    expect(data[0]["requires-approval"]).toBe(true);
  });
});

describe("run tool", () => {
  it("creates task and returns prompt", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "run", {
      type: "dev/impl",
      title: "Add auth",
      inputs: { what: "JWT middleware", where: "src/auth/" },
    });

    expect(result.isError).toBeUndefined();
    const data = JSON.parse(result.content[0].text);
    expect(data.taskId).toBeDefined();
    expect(data.status).toBe("running");
    expect(data.prompt).toContain("JWT middleware");
  });

  it("rejects unknown workflow type", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "run", {
      type: "unknown/type",
      title: "Test",
      inputs: {},
    });

    expect(result.isError).toBe(true);
    expect(result.content[0].text).toContain("Unknown workflow type");
  });

  it("rejects non-callable workflow", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "run", {
      type: "dev/review",
      title: "Test",
      inputs: { changes: "file.ts" },
    });

    expect(result.isError).toBe(true);
    expect(result.content[0].text).toContain("not callable");
  });

  it("rejects missing required inputs", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "run", {
      type: "dev/impl",
      title: "Test",
      inputs: { what: "something" },
    });

    expect(result.isError).toBe(true);
    expect(result.content[0].text).toContain("Missing required inputs");
    expect(result.content[0].text).toContain("where");
  });

  it("rejects invalid arguments", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "run", {
      type: "",
      title: "Test",
      inputs: {},
    });

    expect(result.isError).toBe(true);
    expect(result.content[0].text).toContain("Invalid arguments");
  });
});

describe("status tool", () => {
  it("returns all tasks", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);

    await callTool(server, "run", {
      type: "dev/impl",
      title: "Task A",
      inputs: { what: "a", where: "b" },
    });

    const result = await callTool(server, "status");
    const data = JSON.parse(result.content[0].text);
    expect(data).toHaveLength(1);
    expect(data[0].title).toBe("Task A");
  });

  it("returns specific task by ID", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);

    const runResult = await callTool(server, "run", {
      type: "dev/impl",
      title: "Task A",
      inputs: { what: "a", where: "b" },
    });
    const { taskId } = JSON.parse(runResult.content[0].text);

    const result = await callTool(server, "status", { taskId });
    const data = JSON.parse(result.content[0].text);
    expect(data.id).toBe(taskId);
    expect(data.status).toBe("running");
  });

  it("returns error for unknown task ID", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "status", {
      taskId: "nonexistent",
    });

    expect(result.isError).toBe(true);
    expect(result.content[0].text).toContain("Task not found");
  });
});

describe("done tool", () => {
  it("completes a running task", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const runResult = await callTool(server, "run", {
      type: "dev/impl",
      title: "Task A",
      inputs: { what: "a", where: "b" },
    });
    const { taskId } = JSON.parse(runResult.content[0].text);

    const result = await callTool(server, "done", {
      taskId,
      output: { changes: "src/foo.ts" },
    });

    expect(result.isError).toBeUndefined();
    const data = JSON.parse(result.content[0].text);
    expect(data.status).toBe("done");
    expect(data.output.changes).toBe("src/foo.ts");
  });

  it("rejects invalid task ID", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "done", {
      taskId: "nonexistent",
      output: { changes: "x" },
    });

    expect(result.isError).toBe(true);
  });

  it("rejects missing arguments", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "done", {});

    expect(result.isError).toBe(true);
    expect(result.content[0].text).toContain("Invalid arguments");
  });
});

describe("reject tool", () => {
  it("rejects a running task", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const runResult = await callTool(server, "run", {
      type: "dev/impl",
      title: "Task A",
      inputs: { what: "a", where: "b" },
    });
    const { taskId } = JSON.parse(runResult.content[0].text);

    const result = await callTool(server, "reject", {
      taskId,
      reason: "Requirements unclear",
    });

    expect(result.isError).toBeUndefined();
    const data = JSON.parse(result.content[0].text);
    expect(data.status).toBe("rejected");
    expect(data.reason).toBe("Requirements unclear");
  });

  it("rejects invalid task ID", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "reject", {
      taskId: "nonexistent",
      reason: "bad",
    });

    expect(result.isError).toBe(true);
  });

  it("rejects missing arguments", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "reject", {});

    expect(result.isError).toBe(true);
    expect(result.content[0].text).toContain("Invalid arguments");
  });
});

describe("unknown tool", () => {
  it("returns error", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "nonexistent");

    expect(result.isError).toBe(true);
    expect(result.content[0].text).toContain("Unknown tool");
  });
});

describe("tools list", () => {
  it("exposes five tools", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await listTools(server);

    expect(result.tools).toHaveLength(5);
    const names = result.tools.map((t: { name: string }) => t.name);
    expect(names).toContain("workflows");
    expect(names).toContain("run");
    expect(names).toContain("done");
    expect(names).toContain("reject");
    expect(names).toContain("status");
  });
});

describe("HTTP server", () => {
  let stopServer: (() => void) | undefined;

  afterEach(() => {
    stopServer?.();
    stopServer = undefined;
  });

  it("accepts MCP client connections via HTTP", async () => {
    setupWorkflows();
    const port = 44312 + Math.floor(Math.random() * 1000);
    const stop = await startServer(tmpDir, port);
    stopServer = stop;

    const client = new Client({ name: "test-client", version: "1.0.0" });
    const transport = new StreamableHTTPClientTransport(
      new URL(`http://127.0.0.1:${port}/mcp`),
    );
    await client.connect(transport);

    const tools = await client.listTools();
    expect(tools.tools).toHaveLength(5);

    const result = await client.callTool({
      name: "workflows",
      arguments: {},
    });
    const data = JSON.parse((result.content as Array<{ text: string }>)[0].text);
    expect(data).toHaveLength(1);
    expect(data[0].type).toBe("dev/impl");

    await client.close();
  });

  it("supports multiple concurrent clients sharing state", async () => {
    setupWorkflows();
    const port = 44312 + Math.floor(Math.random() * 1000);
    const stop = await startServer(tmpDir, port);
    stopServer = stop;

    const client1 = new Client({ name: "client-1", version: "1.0.0" });
    const transport1 = new StreamableHTTPClientTransport(
      new URL(`http://127.0.0.1:${port}/mcp`),
    );
    await client1.connect(transport1);

    const client2 = new Client({ name: "client-2", version: "1.0.0" });
    const transport2 = new StreamableHTTPClientTransport(
      new URL(`http://127.0.0.1:${port}/mcp`),
    );
    await client2.connect(transport2);

    // Client 1 creates a task
    const runResult = await client1.callTool({
      name: "run",
      arguments: {
        type: "dev/impl",
        title: "Shared task",
        inputs: { what: "feature", where: "src/" },
      },
    });
    const { taskId } = JSON.parse(
      (runResult.content as Array<{ text: string }>)[0].text,
    );

    // Client 2 can see and complete the task
    const doneResult = await client2.callTool({
      name: "done",
      arguments: { taskId, output: { changes: "done by client 2" } },
    });
    const doneData = JSON.parse(
      (doneResult.content as Array<{ text: string }>)[0].text,
    );
    expect(doneData.status).toBe("done");

    // Client 1 can verify the status
    const statusResult = await client1.callTool({
      name: "status",
      arguments: { taskId },
    });
    const statusData = JSON.parse(
      (statusResult.content as Array<{ text: string }>)[0].text,
    );
    expect(statusData.status).toBe("done");

    await client1.close();
    await client2.close();
  });
});
