/**
 * Dynamic configuration: scan skills/ and policy/ directories.
 */

import { join } from "node:path"
import { homedir } from "node:os"
import { readFileSync, readdirSync } from "node:fs"
import { ok, err, type Result } from "neverthrow"
import * as v from "valibot"
import type { TaskType } from "./types.ts"

const EnvSchema = v.object({
  CLAUDE_HOME: v.optional(v.string(), join(homedir(), ".claude")),
  DISPATCH_TASK_ID: v.optional(v.string()),
  DISPATCH_WS_ID: v.optional(v.string()),
})

export type Env = v.InferOutput<typeof EnvSchema>

export const loadEnv = (): Env => v.parse(EnvSchema, process.env)

const getClaudeHome = (): string => loadEnv().CLAUDE_HOME

const getSkillsDir = () => join(getClaudeHome(), "skills")
const getPolicyDir = () => join(getClaudeHome(), "references", "policy")

const readIfExists = (path: string): string => {
  try {
    return readFileSync(path, "utf-8")
  } catch {
    return ""
  }
}

const parseFrontmatter = (content: string): Record<string, unknown> => {
  const match = content.match(/^---\n([\s\S]*?)\n---/)
  if (!match?.[1]) return {}
  const result: Record<string, unknown> = {}
  for (const line of match[1].split("\n")) {
    const colonIdx = line.indexOf(":")
    if (colonIdx < 0) continue
    const key = line.slice(0, colonIdx).trim()
    const raw = line.slice(colonIdx + 1).trim()
    const arrayMatch = raw.match(/^\[(.*)\]$/)
    if (arrayMatch) {
      result[key] = arrayMatch[1]!.split(",").map((s) => s.trim())
    } else {
      result[key] = raw
    }
  }
  return result
}

type ConfigCache = {
  typeToSkill: Map<string, string>
  skillContent: Map<string, string>
  policy: string
}

const scanConfig = (): ConfigCache => {
  const typeToSkill = new Map<string, string>()
  const skillContent = new Map<string, string>()
  try {
    const skillsDir = getSkillsDir()
    const dirs = readdirSync(skillsDir, { withFileTypes: true })
      .filter((d) => d.isDirectory())

    for (const dir of dirs) {
      const content = readIfExists(join(skillsDir, dir.name, "SKILL.md"))
      if (!content) continue
      const fm = parseFrontmatter(content)
      const taskTypes = fm["task-types"]
      if (!Array.isArray(taskTypes)) continue
      skillContent.set(dir.name, content)
      for (const tt of taskTypes) {
        typeToSkill.set(tt as string, dir.name)
      }
    }
  } catch {
    // skills dir doesn't exist yet
  }

  let policy = ""
  try {
    const policyDir = getPolicyDir()
    policy = readdirSync(policyDir)
      .filter((f) => f.endsWith(".md"))
      .sort()
      .map((f) => readIfExists(join(policyDir, f)))
      .filter(Boolean)
      .join("\n\n---\n\n")
  } catch {
    // policy dir doesn't exist yet
  }

  return { typeToSkill, skillContent, policy }
}

let cache: { home: string; data: ConfigCache } | null = null

const getCache = (): ConfigCache => {
  const home = getClaudeHome()
  if (!cache || cache.home !== home) cache = { home, data: scanConfig() }
  return cache.data
}

export const getValidTaskTypes = (): string[] => [...getCache().typeToSkill.keys()]

export const isValidTaskType = (value: string): boolean => getCache().typeToSkill.has(value)

export const getSkillContent = (taskType: TaskType): Result<string, string> => {
  const { typeToSkill, skillContent } = getCache()
  const skillName = typeToSkill.get(taskType)
  if (!skillName) return err(`No skill found for task type: ${taskType}`)
  return ok(skillContent.get(skillName) ?? "")
}

export const getPolicyContents = (): string => getCache().policy
