import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { WebStandardStreamableHTTPServerTransport } from "@modelcontextprotocol/sdk/server/webStandardStreamableHttp.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  isInitializeRequest,
} from "@modelcontextprotocol/sdk/types.js";
import * as v from "valibot";
import { loadWorkflows, getCallableWorkflows } from "./workflow-loader.js";
import { TaskStore } from "./task-store.js";
import { buildWorkerPrompt } from "./prompt-builder.js";
import type { Workflow } from "./types.js";

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
        return handleWorkflows(workflows);
      case "run":
        return handleRun(workflows, store, args);
      case "done":
        return handleDone(store, args);
      case "reject":
        return handleReject(store, args);
      case "status":
        return handleStatus(store, args);
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

function handleWorkflows(workflows: Map<string, Workflow>) {
  const callable = getCallableWorkflows(workflows);
  const result = callable.map((w) => ({
    type: w.type,
    description: w.frontmatter.description,
    inputs: w.frontmatter.inputs,
    "requires-approval": w.frontmatter["requires-approval"] ?? false,
  }));

  return jsonResponse(result);
}

function handleRun(
  workflows: Map<string, Workflow>,
  store: TaskStore,
  args: unknown,
) {
  const parsed = v.safeParse(RunArgsSchema, args);
  if (!parsed.success) return validationError(parsed.issues);

  const { type, title, inputs } = parsed.output;
  const workflow = workflows.get(type);
  if (!workflow) return errorResponse(`Unknown workflow type: ${type}`);

  if (workflow.frontmatter.callable === false) {
    return errorResponse(`Workflow ${type} is not callable (internal chain step)`);
  }

  const missingInputs: string[] = [];
  for (const key of Object.keys(workflow.frontmatter.inputs)) {
    if (!(key in inputs) || !inputs[key]) {
      missingInputs.push(key);
    }
  }

  if (missingInputs.length > 0) {
    return errorResponse(`Missing required inputs: ${missingInputs.join(", ")}`);
  }

  const task = store.create({
    type,
    title,
    inputs,
    then: workflow.frontmatter.then,
  });

  const prompt = buildWorkerPrompt(workflow, inputs, task.id);

  return jsonResponse({ taskId: task.id, status: "running", prompt });
}

function handleDone(store: TaskStore, args: unknown) {
  const parsed = v.safeParse(DoneArgsSchema, args);
  if (!parsed.success) return validationError(parsed.issues);

  const { taskId, output } = parsed.output;
  const result = store.complete(taskId, output);

  if (result.isErr()) return errorResponse(result.error);

  return jsonResponse({ taskId, status: "done", output });
}

function handleReject(store: TaskStore, args: unknown) {
  const parsed = v.safeParse(RejectArgsSchema, args);
  if (!parsed.success) return validationError(parsed.issues);

  const { taskId, reason } = parsed.output;
  const result = store.reject(taskId, reason);

  if (result.isErr()) return errorResponse(result.error);

  return jsonResponse({ taskId, status: "rejected", reason });
}

function handleStatus(store: TaskStore, args: unknown) {
  const parsed = v.safeParse(StatusArgsSchema, args);
  if (!parsed.success) return validationError(parsed.issues);

  const { taskId } = parsed.output;
  if (taskId) {
    const task = store.get(taskId);
    if (!task) return errorResponse(`Task not found: ${taskId}`);
    return jsonResponse(task);
  }

  return jsonResponse(store.list());
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
