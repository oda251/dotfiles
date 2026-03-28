"""Task runner: executes tasks via claude -p or in-process."""

import os
import subprocess
import json
from pathlib import Path

from . import db


# Type → skill mapping
TYPE_SKILL_MAP = {
    "exec-dev": "dev-impl",
    "exec-research": "research-gather",
    "exec-research-write": "research-write",
    "plan-dev": "plan",
    "plan-research": "plan",
}

# Type → guideline mapping (for plan types)
TYPE_GUIDELINE_MAP = {
    "plan-dev": "dev-plan-guideline.md",
    "plan-research": "research-plan-guideline.md",
    "exec-dev": "dev-exec-guideline.md",
    "exec-research": "research-exec-guideline.md",
}

# Environment variable names
ENV_TASK_ID = "DISPATCH_TASK_ID"
ENV_WS_ID = "DISPATCH_WS_ID"


def get_current_task_id() -> str | None:
    """Get current task ID from environment."""
    return os.environ.get(ENV_TASK_ID)


def get_current_ws_id() -> str | None:
    """Get current workspace ID from environment."""
    return os.environ.get(ENV_WS_ID)


def _build_prompt(task: dict) -> str:
    """Build prompt for a task, including workspace context and skill."""
    ctx = db.get_task_with_context(task["id"])
    ws = ctx["workspace"]

    skill_name = TYPE_SKILL_MAP.get(task["type"], "")
    skill_path = Path.home() / ".claude" / "skills" / skill_name / "SKILL.md"
    skill_content = ""
    if skill_path.exists():
        skill_content = skill_path.read_text()

    guideline_name = TYPE_GUIDELINE_MAP.get(task["type"], "")
    guideline_path = Path.home() / ".claude" / "references" / guideline_name
    guideline_content = ""
    if guideline_path.exists():
        guideline_content = guideline_path.read_text()

    # Build dependency context
    dep_context = ""
    for dep in ctx["dependencies"]:
        if dep["result"]:
            dep_context += f"- {dep['title']}: {dep['result']}\n"

    prompt = f"""## ワークスペース
タイトル: {ws['title']}
背景: {ws['background']}
ゴール: {json.dumps(ws['goals'], ensure_ascii=False)}
制約: {json.dumps(ws['constraints'], ensure_ascii=False)}

## タスク
ID: {task['id']}
タイトル: {task['title']}
タイプ: {task['type']}

"""

    if dep_context:
        prompt += f"""## 先行タスクの成果物
{dep_context}
"""

    if guideline_content:
        prompt += f"""## ガイドライン
{guideline_content}

"""

    if skill_content:
        prompt += f"""## スキル
{skill_content}
"""

    return prompt


def run_task_subprocess(task: dict) -> str | None:
    """Run a task via claude -p in a subprocess."""
    prompt = _build_prompt(task)
    env = {
        **os.environ,
        ENV_TASK_ID: task["id"],
        ENV_WS_ID: task["workspace_id"],
    }
    result = subprocess.run(
        ["claude", "-p", prompt],
        capture_output=True,
        text=True,
        cwd=str(Path.cwd()),
        env=env,
    )
    return result.stdout.strip() if result.returncode == 0 else None


def run_task_inline(task: dict) -> str:
    """Return the prompt for manual/in-process execution."""
    return _build_prompt(task)


def run_next(workspace_id: str, use_subprocess: bool = False) -> dict | None:
    """Get next runnable task, start it, and optionally execute."""
    task = db.get_next_task(workspace_id)
    if not task:
        if db.is_workspace_complete(workspace_id):
            return {"status": "complete", "message": "All tasks done."}
        return {"status": "blocked", "message": "No runnable tasks. Dependencies not met."}

    db.start_task(task["id"])

    if use_subprocess:
        result = run_task_subprocess(task)
        db.complete_task(task["id"], result)
        # Chain: try next task
        return run_next(workspace_id, use_subprocess=True)
    else:
        prompt = run_task_inline(task)
        return {
            "status": "ready",
            "task": task,
            "prompt": prompt,
        }


def complete_and_continue(task_id: str, result: str | None = None,
                          use_subprocess: bool = False) -> dict:
    """Complete a task and dispatch the next one."""
    task = db.complete_task(task_id, result)
    if not task:
        return {"status": "error", "message": f"Task {task_id} not found."}

    workspace_id = task["workspace_id"]

    if db.is_workspace_complete(workspace_id):
        return {"status": "complete", "message": "All tasks done."}

    return run_next(workspace_id, use_subprocess=use_subprocess)
