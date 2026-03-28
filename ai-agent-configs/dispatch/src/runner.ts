/**
 * Task runner: executes tasks via Claude Agent SDK query().
 */

import { query } from "@anthropic-ai/claude-agent-sdk"
import type { BunSQLiteDatabase } from "drizzle-orm/bun-sqlite"
import { ok, err, type Result } from "neverthrow"
import type * as schemaModule from "./schema.ts"
import {
  type WorkspaceId,
  type TaskId,
  type TaskRecord,
  type RunResult,
} from "./types.ts"
import * as db from "./db.ts"
import { getSkillContent, getGuidelineContent } from "./config.ts"

type Db = BunSQLiteDatabase<typeof schemaModule>

const buildPrompt = (database: Db, task: TaskRecord): string => {
  const ctxResult = db.getTaskWithContext(database, task.id)
  if (ctxResult.isErr()) return ""
  const ctx = ctxResult.value
  const ws = ctx.workspace

  const depContext = ctx.dependencies
    .filter((dep) => dep.result)
    .map((dep) => `- ${dep.title}: ${dep.result}`)
    .join("\n")

  const guideline = getGuidelineContent(task.type)
  const skill = getSkillContent(task.type)

  let prompt = `## ワークスペース
タイトル: ${ws.title}
背景: ${ws.background}
ゴール: ${JSON.stringify(ws.goals)}
制約: ${JSON.stringify(ws.constraints)}

## タスク
ID: ${task.id}
タイトル: ${task.title}
タイプ: ${task.type}

`
  if (depContext) prompt += `## 先行タスクの成果物\n${depContext}\n\n`
  if (guideline) prompt += `## ガイドライン\n${guideline}\n\n`
  if (skill) prompt += `## スキル\n${skill}\n`

  return prompt
}

const executeTask = async (database: Db, task: TaskRecord): Promise<string | null> => {
  const prompt = buildPrompt(database, task)
  let result: string | null = null

  for await (const message of query({
    prompt,
    options: {
      permissionMode: "bypassPermissions",
      allowDangerouslySkipPermissions: true,
      allowedTools: ["Read", "Edit", "Write", "Bash", "Glob", "Grep", "WebSearch", "WebFetch"],
      cwd: process.cwd(),
      settingSources: [],
      systemPrompt: { type: "preset", preset: "claude_code" },
    },
  })) {
    if ("result" in message) {
      result = message.result as string
    }
  }

  return result
}

export const runNext = (database: Db, wsId: WorkspaceId): RunResult => {
  const task = db.getNextTask(database, wsId)
  if (!task) {
    if (db.isWorkspaceComplete(database, wsId)) {
      return { status: "complete", message: "All tasks done." }
    }
    return { status: "blocked", message: "No runnable tasks. Dependencies not met." }
  }

  db.startTask(database, task.id)
  return { status: "ready", task, prompt: buildPrompt(database, task) }
}

export const runAuto = async (database: Db, wsId: WorkspaceId): Promise<RunResult> => {
  while (true) {
    const tasks = db.getAllRunnableTasks(database, wsId)
    if (tasks.length === 0) {
      if (db.isWorkspaceComplete(database, wsId)) {
        return { status: "complete", message: "All tasks done." }
      }
      return { status: "blocked", message: "No runnable tasks. Dependencies not met." }
    }

    for (const t of tasks) {
      db.startTask(database, t.id)
    }

    const results = await Promise.all(
      tasks.map(async (t) => {
        const result = await executeTask(database, t)
        return { id: t.id, result }
      }),
    )

    for (const { id, result } of results) {
      db.completeTask(database, id, result ?? undefined)
    }
  }
}

export const completeAndContinue = (
  database: Db,
  taskId: TaskId,
  result?: string,
): RunResult => {
  const taskResult = db.completeTask(database, taskId, result)
  if (taskResult.isErr()) {
    return { status: "error", message: taskResult.error }
  }

  return runNext(database, taskResult.value.workspaceId)
}

export const completeAndContinueAuto = async (
  database: Db,
  taskId: TaskId,
  result?: string,
): Promise<RunResult> => {
  const taskResult = db.completeTask(database, taskId, result)
  if (taskResult.isErr()) {
    return { status: "error", message: taskResult.error }
  }

  return runAuto(database, taskResult.value.workspaceId)
}
