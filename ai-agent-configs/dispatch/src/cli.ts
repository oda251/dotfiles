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

import type { Result } from "neverthrow"
import * as v from "valibot"
import { createDb } from "./db.ts"
import * as db from "./db.ts"
import * as runner from "./runner.ts"
import {
  CreateWorkspaceInput,
  EditWorkspaceInput,
  AddTaskInput,
  EditTaskInput,
} from "./schema.ts"
import { WorkspaceId, TaskId, TaskType } from "./types.ts"

const ENV_TASK_ID = "DISPATCH_TASK_ID"
const ENV_WS_ID = "DISPATCH_WS_ID"

const printJson = (obj: unknown): void => {
  console.log(JSON.stringify(obj, null, 2))
}

const die = (message: string): never => {
  console.error(message)
  process.exit(1)
}

const unwrapResult = <T>(result: Result<T, string>): T => {
  if (result.isErr()) return die(result.error)
  return result.value
}

const unwrapParse = <T>(schema: v.GenericSchema<unknown, T>, input: unknown): T => {
  const result = v.safeParse(schema, input)
  if (!result.success) return die(`Validation error: ${JSON.stringify(result.issues)}`)
  return result.output
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
          const data = unwrapParse(CreateWorkspaceInput, {
            title: args.get("title"),
            background: args.get("background") ?? "",
            goals: collectMultiple(argv, "goal"),
            constraints: collectMultiple(argv, "constraint"),
          })
          printJson(db.createWorkspace(database, data))
          break
        }
        case "show": {
          const wsId = resolveWsId(args)
          const ws = unwrapResult(db.getWorkspace(database, wsId))
          printJson({ ...ws, tasks: db.listTasks(database, wsId) })
          break
        }
        case "list": {
          printJson(db.listWorkspaces(database))
          break
        }
        case "edit": {
          const wsId = resolveWsId(args)
          const data = unwrapParse(EditWorkspaceInput, {
            wsId: WorkspaceId.unwrap(wsId),
            title: args.get("title"),
            background: args.get("background"),
            addGoal: args.get("add-goal"),
            removeGoal: args.get("remove-goal"),
            addConstraint: args.get("add-constraint"),
            removeConstraint: args.get("remove-constraint"),
          })
          printJson(unwrapResult(db.editWorkspace(database, wsId, data)))
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
          const data = unwrapParse(AddTaskInput, {
            wsId: WorkspaceId.unwrap(wsId),
            title: args.get("title"),
            type: args.get("type"),
            dependsOn,
          })
          printJson(db.addTask(database, {
            wsId,
            title: data.title,
            type: TaskType.from(data.type),
            dependsOn: dependsOn.map(TaskId.from),
          }))
          break
        }
        case "edit": {
          const taskId = resolveTaskId(args)
          const data = unwrapParse(EditTaskInput, {
            id: TaskId.unwrap(taskId),
            title: args.get("title"),
            type: args.get("type"),
            addDep: args.get("add-dep"),
            removeDep: args.get("remove-dep"),
          })
          unwrapResult(db.editTask(database, taskId, {
            title: data.title,
            type: data.type ? TaskType.from(data.type) : undefined,
            addDep: data.addDep ? TaskId.from(data.addDep) : undefined,
            removeDep: data.removeDep ? TaskId.from(data.removeDep) : undefined,
          }))
          printJson(unwrapResult(db.getTaskWithContext(database, taskId)))
          break
        }
        case "current": {
          const taskId = process.env[ENV_TASK_ID]
          if (!taskId) return die("No current task (DISPATCH_TASK_ID not set).")
          printJson(unwrapResult(db.getTaskWithContext(database, TaskId.from(taskId))))
          break
        }
        case "done": {
          const taskId = resolveTaskId(args)
          const resultText = args.get("result")
          if (args.has("auto")) {
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
      if (args.has("auto")) {
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
