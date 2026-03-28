"""Task runner: executes tasks via claude -p or in-process."""

import os
import subprocess
import json
from concurrent.futures import ThreadPoolExecutor
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

# Type → guideline mapping
TYPE_GUIDELINE_MAP = {
    "plan-dev": "dev-plan-guideline.md",
    "plan-research": "research-plan-guideline.md",
    "exec-dev": "dev-exec-guideline.md",
    "exec-research": "research-exec-guideline.md",
}

# Environment variable names
ENV_TASK_ID = "DISPATCH_TASK_ID"
ENV_WS_ID = "DISPATCH_WS_ID"

_CLAUDE_HOME = Path.home() / ".claude"


def get_current_task_id() -> str | None:
    return os.environ.get(ENV_TASK_ID)


def get_current_ws_id() -> str | None:
    return os.environ.get(ENV_WS_ID)


def _read_if_exists(path: Path) -> str:
    return path.read_text() if path.exists() else ""


def _build_prompt(task: dict) -> str:
    """Build prompt for a task, including workspace context and skill."""
    ctx = db.get_task_with_context(task["id"])
    ws = ctx["workspace"]

    skill_name = TYPE_SKILL_MAP.get(task["type"], "")
    skill_content = _read_if_exists(_CLAUDE_HOME / "skills" / skill_name / "SKILL.md") if skill_name else ""

    guideline_name = TYPE_GUIDELINE_MAP.get(task["type"], "")
    guideline_content = _read_if_exists(_CLAUDE_HOME / "references" / guideline_name) if guideline_name else ""

    dep_context = "".join(
        f"- {dep['title']}: {dep['result']}\n"
        for dep in ctx["dependencies"] if dep["result"]
    )

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
        prompt += f"## 先行タスクの成果物\n{dep_context}\n"
    if guideline_content:
        prompt += f"## ガイドライン\n{guideline_content}\n\n"
    if skill_content:
        prompt += f"## スキル\n{skill_content}\n"

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
        env=env,
    )
    return result.stdout.strip() if result.returncode == 0 else None


def run_task_inline(task: dict) -> str:
    """Return the prompt for manual/in-process execution."""
    return _build_prompt(task)


def run_next(workspace_id: str, use_subprocess: bool = False) -> dict:
    """Get next runnable task(s), start, and optionally execute."""
    if use_subprocess:
        return _run_auto(workspace_id)

    task = db.get_next_task(workspace_id)
    if not task:
        if db.is_workspace_complete(workspace_id):
            return {"status": "complete", "message": "All tasks done."}
        return {"status": "blocked", "message": "No runnable tasks. Dependencies not met."}

    db.start_task(task["id"])
    return {"status": "ready", "task": task, "prompt": run_task_inline(task)}


def _run_auto(workspace_id: str) -> dict:
    """Auto-run all tasks until workspace is complete. Parallelizes independent tasks."""
    while True:
        tasks = db.get_all_runnable_tasks(workspace_id)
        if not tasks:
            if db.is_workspace_complete(workspace_id):
                return {"status": "complete", "message": "All tasks done."}
            return {"status": "blocked", "message": "No runnable tasks. Dependencies not met."}

        for t in tasks:
            db.start_task(t["id"])

        if len(tasks) == 1:
            result = run_task_subprocess(tasks[0])
            db.complete_task(tasks[0]["id"], result)
        else:
            with ThreadPoolExecutor() as pool:
                futures = {pool.submit(run_task_subprocess, t): t for t in tasks}
                for future in futures:
                    result = future.result()
                    db.complete_task(futures[future]["id"], result)


def complete_and_continue(task_id: str, result: str | None = None,
                          use_subprocess: bool = False) -> dict:
    """Complete a task and dispatch the next one."""
    task = db.complete_task(task_id, result)
    if not task:
        return {"status": "error", "message": f"Task {task_id} not found."}

    return run_next(task["workspace_id"], use_subprocess=use_subprocess)
