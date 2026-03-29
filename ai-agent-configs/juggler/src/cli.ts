#!/usr/bin/env node

import { resolve } from "node:path";
import * as v from "valibot";
import { lint } from "./workflow-loader.js";
import { startServer } from "./server.js";
import { exhaustive } from "./types.js";

const EnvSchema = v.object({
  JUGGLER_WORKFLOWS_DIR: v.optional(v.string()),
  HOME: v.optional(v.string()),
});

const env = v.parse(EnvSchema, process.env);

function resolveWorkflowsDir(args: string[]): string {
  const dirIndex = args.indexOf("--dir");
  if (dirIndex !== -1 && args[dirIndex + 1]) {
    return resolve(args[dirIndex + 1]);
  }
  return env.JUGGLER_WORKFLOWS_DIR ?? resolve(env.HOME ?? "~", ".claude", "workflows");
}

const COMMANDS = ["serve", "lint", "done", "reject"] as const;
type Command = (typeof COMMANDS)[number];

const args = process.argv.slice(2);
const command = args[0];

if (!command) {
  printUsage();
} else if (!COMMANDS.includes(command as Command)) {
  console.error(`Unknown command: ${command}`);
  process.exit(1);
} else {
  const cmd = command as Command;
  switch (cmd) {
    case "serve":
      await startServer(resolveWorkflowsDir(args));
      break;
    case "lint":
      runLint(resolveWorkflowsDir(args));
      break;
    case "done":
      runDone(args.slice(1));
      break;
    case "reject":
      runReject(args.slice(1));
      break;
    default:
      exhaustive(cmd);
  }
}

function runLint(dir: string) {
  const errors = lint(dir);

  if (errors.length === 0) {
    console.log("✓ All workflows valid");
    process.exit(0);
  }

  for (const e of errors) {
    console.error(`✗ ${e.file}: ${e.message}`);
  }
  process.exit(1);
}

function runDone(args: string[]) {
  const json = args[0];
  if (!json) {
    console.error("Usage: juggler done '{\"key\": \"value\"}'");
    process.exit(1);
  }

  let output: unknown;
  try {
    output = JSON.parse(json);
  } catch {
    console.error(`Invalid JSON: ${json}`);
    process.exit(1);
  }

  const parsed = v.safeParse(v.record(v.string(), v.string()), output);
  if (!parsed.success) {
    console.error("Output must be a JSON object with string values");
    process.exit(1);
  }

  console.log(JSON.stringify({ action: "done", output: parsed.output }));
}

function runReject(args: string[]) {
  const json = args[0];
  if (!json) {
    console.error('Usage: juggler reject \'{"reason": "..."}\'');
    process.exit(1);
  }

  let data: unknown;
  try {
    data = JSON.parse(json);
  } catch {
    console.error(`Invalid JSON: ${json}`);
    process.exit(1);
  }

  const parsed = v.safeParse(v.object({ reason: v.pipe(v.string(), v.minLength(1)) }), data);
  if (!parsed.success) {
    console.error('JSON must have a non-empty "reason" field');
    process.exit(1);
  }

  console.log(JSON.stringify({ action: "reject", reason: parsed.output.reason }));
}

function printUsage() {
  console.log(`juggler - Agent workflow orchestrator

Commands:
  serve [--dir path]            Start MCP server
  lint [--dir path]             Validate workflow definitions
  done '<json>'                 Complete current task with JSON outputs
  reject '<json>'               Reject current task (requires "reason" field)`);
}
