#!/usr/bin/env bun
/**
 * dispatch - Task orchestration CLI for AI agent workflows.
 *
 * Usage:
 *   dispatch ws create --title "X" [--background "Y"] [--goal "Z"] [--constraint "C"]
 *   dispatch ws show [--ws ID]
 *   dispatch ws list
 *   dispatch ws edit --ws ID [--title "X"] [--add-goal "Y"] [--remove-goal "Z"]
 *   dispatch task add --ws ID --title "T" --type TYPE [--depends-on ID1,ID2]
 *   dispatch task edit --id ID [--title "T"] [--type TYPE] [--add-dep ID] [--remove-dep ID]
 *   dispatch task current
 *   dispatch task done [--id ID] [--result "OUTPUT"] [--auto]
 *   dispatch run [--ws ID] [--auto]
 */

import { createDb } from "./db.ts"
import * as db from "./db.ts"
import * as runner from "./runner.ts"
import {
  CreateWorkspaceInput,
  EditWorkspaceInput,
  AddTaskInput,
  EditTaskInput,
} from "./schema.ts"
import { WorkspaceId, TaskId, type TaskType } from "./types.ts"

const ENV_TASK_ID = "DISPATCH_TASK_ID"
const ENV_WS_ID = "DISPATCH_WS_ID"

const printJson = (obj: unknown): void => {
  console.log(JSON.stringify(obj, null, 2))
}

const die = (message: string): never => {
  console.error(message)
  process.exit(1)
}

const parseArgs = (argv: string[]): Map<string, string> => {
  const args = new Map<string, string>()
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i]!
    if (arg.startsWith("--")) {
      const key = arg.slice(2)
      const next = argv[i + 1]
      if (next && !next.startsWith("--")) {
        args.set(key, next)
        i++
      } else {
        args.set(key, "true")
      }
    }
  }
  return args
}

const resolveWsId = (args: Map<string, string>): WorkspaceId => {
  const raw = args.get("ws") ?? process.env[ENV_WS_ID]
  if (!raw) return die("Error: --ws required (or set DISPATCH_WS_ID env)")
  return WorkspaceId.from(raw)
}

const resolveTaskId = (args: Map<string, string>): TaskId => {
  const raw = args.get("id") ?? process.env[ENV_TASK_ID]
  if (!raw) return die("Error: --id required (or set DISPATCH_TASK_ID env)")
  return TaskId.from(raw)
}

const collectMultiple = (argv: string[], flag: string): string[] => {
  const values: string[] = []
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === `--${flag}` && argv[i + 1] && !argv[i + 1]!.startsWith("--")) {
      values.push(argv[i + 1]!)
    }
  }
  return values
}

const main = async (): Promise<void> => {
  const argv = process.argv.slice(2)
  const [command, subcommand] = argv

  if (!command) {
    console.log("Usage: dispatch <ws|task|run> <subcommand> [options]")
    process.exit(1)
  }

  const database = createDb()
  const args = parseArgs(argv.slice(2))

  switch (command) {
    case "ws": {
      switch (subcommand) {
        case "create": {
          const goals = collectMultiple(argv, "goal")
          const constraints = collectMultiple(argv, "constraint")
          const parsed = CreateWorkspaceInput.safeParse({
            title: args.get("title"),
            background: args.get("background") ?? "",
            goals,
            constraints,
          })
          if (!parsed.success) return die(`Validation error: ${JSON.stringify(parsed.error.issues)}`)
          printJson(db.createWorkspace(database, parsed.data))
          break
        }
        case "show": {
          const wsId = resolveWsId(args)
          const wsResult = db.getWorkspace(database, wsId)
          if (wsResult.isErr()) return die(wsResult.error)
          const tasks = db.listTasks(database, wsId)
          printJson({ ...wsResult.value, tasks })
          break
        }
        case "list": {
          printJson(db.listWorkspaces(database))
          break
        }
        case "edit": {
          const wsId = resolveWsId(args)
          const parsed = EditWorkspaceInput.safeParse({
            wsId: wsId as string,
            title: args.get("title"),
            background: args.get("background"),
            addGoal: args.get("add-goal"),
            removeGoal: args.get("remove-goal"),
            addConstraint: args.get("add-constraint"),
            removeConstraint: args.get("remove-constraint"),
          })
          if (!parsed.success) return die(`Validation error: ${JSON.stringify(parsed.error.issues)}`)
          const result = db.editWorkspace(database, wsId, parsed.data)
          if (result.isErr()) return die(result.error)
          printJson(result.value)
          break
        }
        default:
          return die(`Unknown ws subcommand: ${subcommand}`)
      }
      break
    }
    case "task": {
      switch (subcommand) {
        case "add": {
          const wsId = resolveWsId(args)
          const dependsOnRaw = args.get("depends-on")
          const dependsOn = dependsOnRaw ? dependsOnRaw.split(",") : []
          const parsed = AddTaskInput.safeParse({
            wsId: wsId as string,
            title: args.get("title"),
            type: args.get("type"),
            dependsOn,
          })
          if (!parsed.success) return die(`Validation error: ${JSON.stringify(parsed.error.issues)}`)
          printJson(
            db.addTask(database, {
              wsId,
              title: parsed.data.title,
              type: parsed.data.type as TaskType,
              dependsOn: dependsOn.map(TaskId.from),
            }),
          )
          break
        }
        case "edit": {
          const taskId = resolveTaskId(args)
          const parsed = EditTaskInput.safeParse({
            id: taskId as string,
            title: args.get("title"),
            type: args.get("type"),
            addDep: args.get("add-dep"),
            removeDep: args.get("remove-dep"),
          })
          if (!parsed.success) return die(`Validation error: ${JSON.stringify(parsed.error.issues)}`)
          const editResult = db.editTask(database, taskId, {
            title: parsed.data.title,
            type: parsed.data.type as TaskType | undefined,
            addDep: parsed.data.addDep ? TaskId.from(parsed.data.addDep) : undefined,
            removeDep: parsed.data.removeDep ? TaskId.from(parsed.data.removeDep) : undefined,
          })
          if (editResult.isErr()) return die(editResult.error)
          const ctx = db.getTaskWithContext(database, taskId)
          if (ctx.isErr()) return die(ctx.error)
          printJson(ctx.value)
          break
        }
        case "current": {
          const taskId = process.env[ENV_TASK_ID]
          if (!taskId) return die("No current task (DISPATCH_TASK_ID not set).")
          const ctx = db.getTaskWithContext(database, TaskId.from(taskId))
          if (ctx.isErr()) return die(ctx.error)
          printJson(ctx.value)
          break
        }
        case "done": {
          const taskId = resolveTaskId(args)
          const resultText = args.get("result")
          const auto = args.has("auto")
          if (auto) {
            printJson(await runner.completeAndContinueAuto(database, taskId, resultText))
          } else {
            printJson(runner.completeAndContinue(database, taskId, resultText))
          }
          break
        }
        default:
          return die(`Unknown task subcommand: ${subcommand}`)
      }
      break
    }
    case "run": {
      const wsId = resolveWsId(args)
      const auto = args.has("auto")
      if (auto) {
        printJson(await runner.runAuto(database, wsId))
      } else {
        printJson(runner.runNext(database, wsId))
      }
      break
    }
    default:
      return die(`Unknown command: ${command}`)
  }
}

await main()
