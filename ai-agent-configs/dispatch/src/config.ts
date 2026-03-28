/**
 * Static configuration: type → skill mappings and paths.
 */

import { join } from "node:path"
import { homedir } from "node:os"
import { readFileSync } from "node:fs"
import type { TaskType } from "./types.ts"

const CLAUDE_HOME = join(homedir(), ".claude")

const TYPE_SKILL_MAP = {
  "exec-dev": "dev-impl",
  "exec-research": "research-gather",
  "exec-research-write": "research-write",
  "plan-dev": "plan",
  "plan-research": "plan",
} as const satisfies Record<TaskType, string>

export const getSkillContent = (taskType: TaskType): string => {
  const skillName = TYPE_SKILL_MAP[taskType]
  return readIfExists(join(CLAUDE_HOME, "skills", skillName, "SKILL.md"))
}

const readIfExists = (path: string): string => {
  try {
    return readFileSync(path, "utf-8")
  } catch {
    return ""
  }
}
