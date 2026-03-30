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

describe("valibot validation", () => {
  it("rejects run with empty type", async () => {
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

  it("rejects done with missing arguments", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "done", {});

    expect(result.isError).toBe(true);
    expect(result.content[0].text).toContain("Invalid arguments");
  });

  it("rejects reject with empty reason", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "reject", {
      taskId: "some-id",
      reason: "",
    });

    expect(result.isError).toBe(true);
    expect(result.content[0].text).toContain("Invalid arguments");
  });
});

describe("MCP response format", () => {
  it("returns JSON text content for success", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "workflows");

    expect(result.content).toHaveLength(1);
    expect(result.content[0].type).toBe("text");
    expect(() => JSON.parse(result.content[0].text)).not.toThrow();
    expect(result.isError).toBeUndefined();
  });

  it("returns isError true for business errors", async () => {
    setupWorkflows();
    const server = createServer(tmpDir);
    const result = await callTool(server, "run", {
      type: "unknown/type",
      title: "Test",
      inputs: {},
    });

    expect(result.isError).toBe(true);
    expect(result.content[0].type).toBe("text");
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

  it("returns 404 for non-/mcp paths", async () => {
    setupWorkflows();
    const port = 44312 + Math.floor(Math.random() * 1000);
    const stop = await startServer(tmpDir, port);
    stopServer = stop;

    const res = await fetch(`http://127.0.0.1:${port}/other`);
    expect(res.status).toBe(404);
  });

  it("returns 400 for non-initialize POST without session", async () => {
    setupWorkflows();
    const port = 44312 + Math.floor(Math.random() * 1000);
    const stop = await startServer(tmpDir, port);
    stopServer = stop;

    const res = await fetch(`http://127.0.0.1:${port}/mcp`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        jsonrpc: "2.0",
        method: "tools/list",
        id: 1,
      }),
    });
    expect(res.status).toBe(400);
  });
});
