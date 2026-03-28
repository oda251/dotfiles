/**
 * Dynamic configuration: scan skills/ for task-type mappings.
 */

import { join } from "node:path"
import { homedir } from "node:os"
import { readFileSync, readdirSync } from "node:fs"
import type { TaskType } from "./types.ts"

const CLAUDE_HOME = join(homedir(), ".claude")
const SKILLS_DIR = join(CLAUDE_HOME, "skills")

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

const buildSkillMap = (): Map<string, string> => {
  const map = new Map<string, string>()
  try {
    const dirs = readdirSync(SKILLS_DIR, { withFileTypes: true })
      .filter((d) => d.isDirectory())

    for (const dir of dirs) {
      const content = readIfExists(join(SKILLS_DIR, dir.name, "SKILL.md"))
      if (!content) continue
      const fm = parseFrontmatter(content)
      const taskTypes = fm["task-types"]
      if (!Array.isArray(taskTypes)) continue
      for (const tt of taskTypes) {
        map.set(tt as string, dir.name)
      }
    }
  } catch {
    // skills dir doesn't exist yet
  }
  return map
}

let skillMap: Map<string, string> | null = null

const getSkillMap = (): Map<string, string> => {
  if (!skillMap) skillMap = buildSkillMap()
  return skillMap
}

export const getValidTaskTypes = (): string[] => [...getSkillMap().keys()]

export const isValidTaskType = (value: string): boolean => getSkillMap().has(value)

export const getSkillContent = (taskType: TaskType): string => {
  const skillName = getSkillMap().get(taskType)
  if (!skillName) return ""
  return readIfExists(join(SKILLS_DIR, skillName, "SKILL.md"))
}
