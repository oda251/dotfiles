import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  isInitializeRequest,
} from "@modelcontextprotocol/sdk/types.js";
import * as v from "valibot";
import { loadWorkflows } from "./workflow-loader.js";
import { TaskStore } from "./task-store.js";
import {
  listWorkflows,
  runWorkflow,
  completeTask,
  rejectTask,
  getStatus,
} from "./handlers.js";
import type { Workflow } from "./types.js";

// --- Valibot schemas (input validation) ---

const RunArgsSchema = v.object({
  type: v.pipe(v.string(), v.minLength(1)),
  title: v.pipe(v.string(), v.minLength(1)),
  inputs: v.record(v.string(), v.string()),
});

const StatusArgsSchema = v.object({
  taskId: v.optional(v.string()),
});

const DoneArgsSchema = v.object({
  taskId: v.pipe(v.string(), v.minLength(1)),
  output: v.record(v.string(), v.string()),
});

const RejectArgsSchema = v.object({
  taskId: v.pipe(v.string(), v.minLength(1)),
  reason: v.pipe(v.string(), v.minLength(1)),
});

// --- MCP response helpers ---

function textResponse(text: string) {
  return { content: [{ type: "text" as const, text }] };
}

function errorResponse(text: string) {
  return { content: [{ type: "text" as const, text }], isError: true as const };
}

function jsonResponse(data: unknown) {
  return textResponse(JSON.stringify(data, null, 2));
}

function validationError(issues: v.BaseIssue<unknown>[]) {
  return errorResponse(`Invalid arguments: ${issues.map((i) => i.message).join("; ")}`);
}

// --- MCP tool definitions ---

const TOOL_DEFINITIONS = [
  {
    name: "workflows",
    description:
      "List available workflow types with their descriptions and required inputs",
    inputSchema: { type: "object" as const, properties: {} },
  },
  {
    name: "run",
    description: "Start a task with a specific workflow type",
    inputSchema: {
      type: "object" as const,
      properties: {
        type: { type: "string", description: "Workflow type (e.g. dev/impl)" },
        title: { type: "string", description: "Task title" },
        inputs: { type: "object", description: "Input parameters for the workflow" },
      },
      required: ["type", "title", "inputs"],
    },
  },
  {
    name: "done",
    description: "Complete a running task with output values",
    inputSchema: {
      type: "object" as const,
      properties: {
        taskId: { type: "string", description: "Task ID to complete" },
        output: { type: "object", description: "Output key-value pairs" },
      },
      required: ["taskId", "output"],
    },
  },
  {
    name: "reject",
    description: "Reject a running task with a reason",
    inputSchema: {
      type: "object" as const,
      properties: {
        taskId: { type: "string", description: "Task ID to reject" },
        reason: { type: "string", description: "Rejection reason" },
      },
      required: ["taskId", "reason"],
    },
  },
  {
    name: "status",
    description: "Get status of tasks",
    inputSchema: {
      type: "object" as const,
      properties: {
        taskId: { type: "string", description: "Optional task ID to filter by" },
      },
    },
  },
];

// --- MCP server wiring ---

function configureMcpServer(
  server: Server,
  workflows: Map<string, Workflow>,
  store: TaskStore,
) {
  server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: TOOL_DEFINITIONS,
  }));

  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;

    switch (name) {
      case "workflows":
        return jsonResponse(listWorkflows(workflows));

      case "run": {
        const parsed = v.safeParse(RunArgsSchema, args);
        if (!parsed.success) return validationError(parsed.issues);
        return runWorkflow(workflows, store, parsed.output).match(
          (data) => jsonResponse(data),
          (e) => errorResponse(e),
        );
      }

      case "done": {
        const parsed = v.safeParse(DoneArgsSchema, args);
        if (!parsed.success) return validationError(parsed.issues);
        return completeTask(store, parsed.output).match(
          (data) => jsonResponse(data),
          (e) => errorResponse(e),
        );
      }

      case "reject": {
        const parsed = v.safeParse(RejectArgsSchema, args);
        if (!parsed.success) return validationError(parsed.issues);
        return rejectTask(store, parsed.output).match(
          (data) => jsonResponse(data),
          (e) => errorResponse(e),
        );
      }

      case "status": {
        const parsed = v.safeParse(StatusArgsSchema, args);
        if (!parsed.success) return validationError(parsed.issues);
        return getStatus(store, parsed.output.taskId).match(
          (data) => jsonResponse(data),
          (e) => errorResponse(e),
        );
      }

      default:
        return errorResponse(`Unknown tool: ${name}`);
    }
  });
}

function newMcpServer() {
  return new Server(
    { name: "juggler", version: "0.1.0" },
    { capabilities: { tools: {} } },
  );
}

// --- Exports ---

export function createServer(workflowsDir: string) {
  const { workflows, errors } = loadWorkflows(workflowsDir);

  if (errors.length > 0) {
    for (const e of errors) {
      console.error(`[juggler] workflow error: ${e.file}: ${e.message}`);
    }
  }

  const store = new TaskStore();
  const server = newMcpServer();
  configureMcpServer(server, workflows, store);

  return { server, store, workflows };
}

export async function startServer(workflowsDir: string, port: number) {
  const { workflows, errors } = loadWorkflows(workflowsDir);

  if (errors.length > 0) {
    for (const e of errors) {
      console.error(`[juggler] workflow error: ${e.file}: ${e.message}`);
    }
  }

  const store = new TaskStore();
  const sessions = new Map<string, WebStandardStreamableHTTPServerTransport>();

  function createSession(): WebStandardStreamableHTTPServerTransport {
    const transport = new WebStandardStreamableHTTPServerTransport({
      sessionIdGenerator: () => crypto.randomUUID(),
      onsessioninitialized: (sessionId) => {
        sessions.set(sessionId, transport);
      },
    });

    transport.onclose = () => {
      if (transport.sessionId) sessions.delete(transport.sessionId);
    };

    const server = newMcpServer();
    configureMcpServer(server, workflows, store);
    server.connect(transport);

    return transport;
  }

  const httpServer = Bun.serve({
    port,
    hostname: "127.0.0.1",
    async fetch(req) {
      const url = new URL(req.url);
      if (url.pathname !== "/mcp") {
        return new Response("Not Found", { status: 404 });
      }

      const sessionId = req.headers.get("mcp-session-id");

      const existing = sessionId ? sessions.get(sessionId) : undefined;
      if (existing) {
        return existing.handleRequest(req);
      }

      if (req.method === "POST") {
        const body = await req.json();
        if (isInitializeRequest(body)) {
          const transport = createSession();
          return transport.handleRequest(req, { parsedBody: body });
        }
      }

      return new Response("Bad Request", { status: 400 });
    },
  });

  console.log(`[juggler] listening on http://127.0.0.1:${httpServer.port}/mcp`);

  return function stop() {
    for (const transport of sessions.values()) {
      transport.close();
    }
    httpServer.stop();
  };
}
