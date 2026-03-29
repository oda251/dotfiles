#!/usr/bin/env node

import { resolve } from "node:path";
import { lint } from "./workflow-loader.js";
import { startServer } from "./server.js";

const WORKFLOWS_DIR =
  process.env.SIDEKICK_WORKFLOWS_DIR ??
  resolve(process.env.HOME ?? "~", ".claude", "workflows");

const args = process.argv.slice(2);
const command = args[0];

switch (command) {
  case "serve":
    await startServer(WORKFLOWS_DIR);
    break;

  case "lint":
    runLint(args[1] ?? WORKFLOWS_DIR);
    break;

  case "done":
    await runDone(args.slice(1));
    break;

  case "reject":
    await runReject(args.slice(1));
    break;

  default:
    printUsage();
    process.exit(command ? 1 : 0);
}

function runLint(dir: string) {
  const errors = lint(dir);

  if (errors.length === 0) {
    console.log("✓ All workflows valid");
    process.exit(0);
  }

  for (const err of errors) {
    console.error(`✗ ${err.file}: ${err.message}`);
  }
  process.exit(1);
}

async function runDone(args: string[]) {
  const output: Record<string, string> = {};

  for (const arg of args) {
    if (arg.startsWith("--output")) continue;
    const eqIndex = arg.indexOf("=");
    if (eqIndex === -1) {
      console.error(`Invalid output format: ${arg} (expected key=value)`);
      process.exit(1);
    }
    output[arg.slice(0, eqIndex)] = arg.slice(eqIndex + 1);
  }

  // Parse --output key=value pairs
  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--output" && args[i + 1]) {
      const pair = args[i + 1];
      const eqIndex = pair.indexOf("=");
      if (eqIndex === -1) {
        console.error(
          `Invalid output format: ${pair} (expected key=value)`,
        );
        process.exit(1);
      }
      output[pair.slice(0, eqIndex)] = pair.slice(eqIndex + 1);
      i++;
    }
  }

  // In daemon mode, this would communicate with the running server.
  // For now, write to stdout for the server to capture.
  console.log(JSON.stringify({ action: "done", output }));
}

async function runReject(args: string[]) {
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
  serve                         Start MCP server
  lint [dir]                    Validate workflow definitions
  done --output key=value ...   Complete current task with outputs
  reject --reason "..."         Reject current task with reason`);
}
