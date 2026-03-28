/**
 * Static configuration: type → skill/guideline mappings and paths.
 */

import { join } from "node:path"
import { homedir } from "node:os"
import { readFileSync, existsSync } from "node:fs"
import type { TaskType } from "./types.ts"

const CLAUDE_HOME = join(homedir(), ".claude")

const TYPE_SKILL_MAP = {
  "exec-dev": "dev-impl",
  "exec-research": "research-gather",
  "exec-research-write": "research-write",
  "plan-dev": "plan",
  "plan-research": "plan",
} as const satisfies Record<TaskType, string>

const TYPE_GUIDELINE_MAP = {
  "exec-dev": "dev-exec-guideline.md",
  "exec-research": "research-exec-guideline.md",
  "exec-research-write": undefined,
  "plan-dev": "dev-plan-guideline.md",
  "plan-research": "research-plan-guideline.md",
} as const satisfies Record<TaskType, string | undefined>

export const getSkillContent = (taskType: TaskType): string => {
  const skillName = TYPE_SKILL_MAP[taskType]
  return readIfExists(join(CLAUDE_HOME, "skills", skillName, "SKILL.md"))
}

export const getGuidelineContent = (taskType: TaskType): string => {
  const fileName = TYPE_GUIDELINE_MAP[taskType]
  if (!fileName) return ""
  return readIfExists(join(CLAUDE_HOME, "references", fileName))
}

const readIfExists = (path: string): string =>
  existsSync(path) ? readFileSync(path, "utf-8") : ""
