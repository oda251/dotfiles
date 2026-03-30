import { describe, it, expect, beforeEach, afterEach } from "bun:test";
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StreamableHTTPClientTransport } from "@modelcontextprotocol/sdk/client/streamableHttp.js";
import { startServer } from "../src/server.js";

let tmpDir: string;
let stopServer: (() => void) | undefined;

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
then: review
---

Write the code.`,
  );

  createWorkflow(
    "dev",
    "review",
    `---
description: Review implementation
chain-only: true
inputs:
  changes: Changed files
---

Review the changes.`,
  );
}

function randomPort() {
  return 44312 + Math.floor(Math.random() * 1000);
}

async function connectHttpClient(port: number) {
  const client = new Client({ name: "test-client", version: "1.0.0" });
  const transport = new StreamableHTTPClientTransport(
    new URL(`http://127.0.0.1:${port}/mcp`),
  );
  await client.connect(transport);
  return client;
}

function parseText(result: Awaited<ReturnType<Client["callTool"]>>) {
  return JSON.parse((result.content as Array<{ text: string }>)[0].text);
}

beforeEach(() => {
  tmpDir = mkdtempSync(join(tmpdir(), "juggler-http-test-"));
});

afterEach(() => {
  stopServer?.();
  stopServer = undefined;
  rmSync(tmpDir, { recursive: true, force: true });
});

describe("HTTP transport", () => {
  it("accepts MCP client connections", async () => {
    setupWorkflows();
    const port = randomPort();
    stopServer = await startServer(tmpDir, port);

    const client = await connectHttpClient(port);

    const tools = await client.listTools();
    expect(tools.tools).toHaveLength(5);

    const result = await client.callTool({
      name: "workflows",
      arguments: {},
    });
    const data = parseText(result);
    expect(data).toHaveLength(1);
    expect(data[0].type).toBe("dev/impl");

    await client.close();
  });

  it("shares TaskStore across multiple clients", async () => {
    setupWorkflows();
    const port = randomPort();
    stopServer = await startServer(tmpDir, port);

    const client1 = await connectHttpClient(port);
    const client2 = await connectHttpClient(port);

    // Client 1 creates a task
    const runResult = await client1.callTool({
      name: "run",
      arguments: {
        type: "dev/impl",
        title: "Shared task",
        inputs: { what: "feature", where: "src/" },
      },
    });
    const { taskId } = parseText(runResult);

    // Client 2 completes the task
    const doneResult = await client2.callTool({
      name: "done",
      arguments: { taskId, output: { changes: "done by client 2" } },
    });
    expect(parseText(doneResult).status).toBe("done");

    // Client 1 verifies
    const statusResult = await client1.callTool({
      name: "status",
      arguments: { taskId },
    });
    expect(parseText(statusResult).status).toBe("done");

    await client1.close();
    await client2.close();
  });
});

describe("HTTP routing", () => {
  it("returns 404 for non-/mcp paths", async () => {
    setupWorkflows();
    const port = randomPort();
    stopServer = await startServer(tmpDir, port);

    const res = await fetch(`http://127.0.0.1:${port}/other`);
    expect(res.status).toBe(404);
  });

  it("returns 400 for non-initialize POST without session", async () => {
    setupWorkflows();
    const port = randomPort();
    stopServer = await startServer(tmpDir, port);

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
