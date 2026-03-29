import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
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

function textResponse(text: string) {
  return { content: [{ type: "text" as const, text }] };
}

function errorResponse(text: string) {
  return { content: [{ type: "text" as const, text }], isError: true as const };
}

function jsonResponse(data: unknown) {
  return textResponse(JSON.stringify(data, null, 2));
}

export function createServer(workflowsDir: string) {
  const { workflows, errors } = loadWorkflows(workflowsDir);

  if (errors.length > 0) {
    for (const e of errors) {
      console.error(`[juggler] workflow error: ${e.file}: ${e.message}`);
    }
  }

  const store = new TaskStore();

  const server = new Server(
    { name: "juggler", version: "0.1.0" },
    {
      capabilities: {
        tools: {},
        experimental: { "claude/channel": {} },
      },
    },
  );

  server.setRequestHandler(ListToolsRequestSchema, async () => ({
    tools: [
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
            type: {
              type: "string",
              description: "Workflow type (e.g. dev/impl)",
            },
            title: { type: "string", description: "Task title" },
            inputs: {
              type: "object",
              description: "Input parameters for the workflow",
            },
          },
          required: ["type", "title", "inputs"],
        },
      },
      {
        name: "status",
        description: "Get status of tasks",
        inputSchema: {
          type: "object" as const,
          properties: {
            taskId: {
              type: "string",
              description: "Optional task ID to filter by",
            },
          },
        },
      },
    ],
  }));

  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;

    switch (name) {
      case "workflows":
        return handleWorkflows(workflows);
      case "run":
        return handleRun(workflows, store, args);
      case "status":
        return handleStatus(store, args);
      default:
        return errorResponse(`Unknown tool: ${name}`);
    }
  });

  return { server, store, workflows };
}

function validationError(issues: v.BaseIssue<unknown>[]) {
  return errorResponse(`Invalid arguments: ${issues.map((i) => i.message).join("; ")}`);
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

export async function startServer(workflowsDir: string) {
  const { server } = createServer(workflowsDir);
  const transport = new StdioServerTransport();
  await server.connect(transport);
}
