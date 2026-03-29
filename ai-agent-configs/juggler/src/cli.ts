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

const COMMANDS = ["serve", "lint"] as const;
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

function printUsage() {
  console.log(`juggler - Agent workflow orchestrator

Commands:
  serve [--dir path]            Start MCP server
  lint [--dir path]             Validate workflow definitions`);
}
