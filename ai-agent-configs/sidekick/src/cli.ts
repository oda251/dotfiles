#!/usr/bin/env node

import { resolve } from "node:path";
import * as v from "valibot";
import { lint } from "./workflow-loader.js";
import { startServer } from "./server.js";
import { exhaustive } from "./types.js";

const EnvSchema = v.object({
  SIDEKICK_WORKFLOWS_DIR: v.optional(v.string()),
  HOME: v.optional(v.string()),
});

const env = v.parse(EnvSchema, process.env);

function resolveWorkflowsDir(args: string[]): string {
  const dirIndex = args.indexOf("--dir");
  if (dirIndex !== -1 && args[dirIndex + 1]) {
    return resolve(args[dirIndex + 1]);
  }
  return env.SIDEKICK_WORKFLOWS_DIR ?? resolve(env.HOME ?? "~", ".claude", "workflows");
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
  const output: Record<string, string> = {};

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--output" && args[i + 1]) {
      const pair = args[i + 1];
      const eq = pair.indexOf("=");
      if (eq === -1) {
        console.error(`Invalid output format: ${pair} (expected key=value)`);
        process.exit(1);
      }
      output[pair.slice(0, eq)] = pair.slice(eq + 1);
      i++;
    }
  }

  console.log(JSON.stringify({ action: "done", output }));
}

function runReject(args: string[]) {
  let reason = "";

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--reason" && args[i + 1]) {
      reason = args[i + 1];
      break;
    }
  }

  if (!reason) {
    console.error("--reason is required");
    process.exit(1);
  }

  console.log(JSON.stringify({ action: "reject", reason }));
}

function printUsage() {
  console.log(`sidekick - Agent workflow orchestrator

Commands:
  serve [--dir path]            Start MCP server
  lint [--dir path]             Validate workflow definitions
  done --output key=value ...   Complete current task with outputs
  reject --reason "..."         Reject current task with reason`);
}
