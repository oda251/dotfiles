"""SQLite database operations for dispatch."""

import sqlite3
import json
import uuid
from contextlib import contextmanager
from pathlib import Path
from datetime import datetime, timezone


DB_NAME = ".dispatch.db"


class TaskStatus:
    PENDING = "pending"
    RUNNING = "running"
    DONE = "done"


def _get_db_path() -> Path:
    """Get DB path relative to current working directory."""
    return Path.cwd() / DB_NAME


@contextmanager
def _connection(db_path: Path | None = None):
    conn = sqlite3.connect(str(db_path or _get_db_path()))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys=ON")
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def _gen_id() -> str:
    return str(uuid.uuid4())[:8]


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _deserialize_workspace(row: sqlite3.Row) -> dict:
    ws = dict(row)
    ws["goals"] = json.loads(ws["goals"])
    ws["constraints"] = json.loads(ws["constraints"])
    return ws


def _print_json(obj) -> None:
    print(json.dumps(obj, ensure_ascii=False, indent=2))


def init_db(db_path: Path | None = None) -> None:
    with _connection(db_path) as conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS workspaces (
                id TEXT PRIMARY KEY,
                title TEXT NOT NULL,
                background TEXT,
                goals TEXT DEFAULT '[]',
                constraints TEXT DEFAULT '[]',
                created_at TEXT NOT NULL
            );

            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                workspace_id TEXT NOT NULL,
                title TEXT NOT NULL,
                type TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'pending',
                result TEXT,
                created_at TEXT NOT NULL,
                FOREIGN KEY (workspace_id) REFERENCES workspaces(id)
            );

            CREATE TABLE IF NOT EXISTS dependencies (
                task_id TEXT NOT NULL,
                depends_on TEXT NOT NULL,
                PRIMARY KEY (task_id, depends_on),
                FOREIGN KEY (task_id) REFERENCES tasks(id),
                FOREIGN KEY (depends_on) REFERENCES tasks(id)
            );
        """)
        conn.execute("PRAGMA journal_mode=WAL")


# --- Workspace operations ---

def create_workspace(title: str, background: str = "",
                     goals: list[str] | None = None,
                     constraints: list[str] | None = None) -> dict:
    ws_id = _gen_id()
    now = _now()
    goals_list = goals or []
    constraints_list = constraints or []
    with _connection() as conn:
        conn.execute(
            "INSERT INTO workspaces (id, title, background, goals, constraints, created_at) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (ws_id, title, background,
             json.dumps(goals_list, ensure_ascii=False),
             json.dumps(constraints_list, ensure_ascii=False),
             now)
        )
    return {
        "id": ws_id, "title": title, "background": background,
        "goals": goals_list, "constraints": constraints_list, "created_at": now,
    }


def get_workspace(ws_id: str) -> dict | None:
    with _connection() as conn:
        row = conn.execute("SELECT * FROM workspaces WHERE id = ?", (ws_id,)).fetchone()
    return _deserialize_workspace(row) if row else None


def list_workspaces() -> list[dict]:
    with _connection() as conn:
        rows = conn.execute("SELECT * FROM workspaces ORDER BY created_at DESC").fetchall()
    return [_deserialize_workspace(r) for r in rows]


def edit_workspace(ws_id: str, **kwargs) -> dict | None:
    with _connection() as conn:
        row = conn.execute("SELECT * FROM workspaces WHERE id = ?", (ws_id,)).fetchone()
        if not row:
            return None
        current = _deserialize_workspace(row)

        if "title" in kwargs:
            current["title"] = kwargs["title"]
        if "background" in kwargs:
            current["background"] = kwargs["background"]
        if "add_goal" in kwargs:
            current["goals"].append(kwargs["add_goal"])
        if "remove_goal" in kwargs:
            current["goals"] = [g for g in current["goals"] if g != kwargs["remove_goal"]]
        if "add_constraint" in kwargs:
            current["constraints"].append(kwargs["add_constraint"])
        if "remove_constraint" in kwargs:
            current["constraints"] = [c for c in current["constraints"] if c != kwargs["remove_constraint"]]

        conn.execute(
            "UPDATE workspaces SET title=?, background=?, goals=?, constraints=? WHERE id=?",
            (current["title"], current["background"],
             json.dumps(current["goals"], ensure_ascii=False),
             json.dumps(current["constraints"], ensure_ascii=False),
             ws_id)
        )
    return current


# --- Task operations ---

def add_task(workspace_id: str, title: str, task_type: str,
             depends_on: list[str] | None = None) -> dict:
    task_id = _gen_id()
    now = _now()
    with _connection() as conn:
        conn.execute(
            "INSERT INTO tasks (id, workspace_id, title, type, status, created_at) "
            "VALUES (?, ?, ?, ?, ?, ?)",
            (task_id, workspace_id, title, task_type, TaskStatus.PENDING, now)
        )
        for dep in (depends_on or []):
            conn.execute(
                "INSERT INTO dependencies (task_id, depends_on) VALUES (?, ?)",
                (task_id, dep)
            )
    return {
        "id": task_id, "workspace_id": workspace_id, "title": title,
        "type": task_type, "status": TaskStatus.PENDING, "result": None,
        "created_at": now,
    }


def edit_task(task_id: str, **kwargs) -> dict | None:
    with _connection() as conn:
        task = conn.execute("SELECT * FROM tasks WHERE id = ?", (task_id,)).fetchone()
        if not task:
            return None
        current = dict(task)

        if "title" in kwargs:
            current["title"] = kwargs["title"]
        if "type" in kwargs:
            current["type"] = kwargs["type"]

        conn.execute(
            "UPDATE tasks SET title=?, type=? WHERE id=?",
            (current["title"], current["type"], task_id)
        )
        if "add_dep" in kwargs:
            conn.execute(
                "INSERT OR IGNORE INTO dependencies (task_id, depends_on) VALUES (?, ?)",
                (task_id, kwargs["add_dep"])
            )
        if "remove_dep" in kwargs:
            conn.execute(
                "DELETE FROM dependencies WHERE task_id=? AND depends_on=?",
                (task_id, kwargs["remove_dep"])
            )
    return current


def list_tasks(workspace_id: str, status: str | None = None) -> list[dict]:
    with _connection() as conn:
        if status:
            rows = conn.execute(
                "SELECT * FROM tasks WHERE workspace_id=? AND status=? ORDER BY created_at",
                (workspace_id, status)
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT * FROM tasks WHERE workspace_id=? ORDER BY created_at",
                (workspace_id,)
            ).fetchall()
    return [dict(r) for r in rows]


def get_task_with_context(task_id: str) -> dict | None:
    """Get task with full context: workspace info, dependencies, dependents."""
    with _connection() as conn:
        task = conn.execute("SELECT * FROM tasks WHERE id = ?", (task_id,)).fetchone()
        if not task:
            return None
        task = dict(task)

        ws = conn.execute(
            "SELECT * FROM workspaces WHERE id = ?", (task["workspace_id"],)
        ).fetchone()

        deps = conn.execute("""
            SELECT t.* FROM tasks t
            JOIN dependencies d ON t.id = d.depends_on
            WHERE d.task_id = ?
        """, (task_id,)).fetchall()

        dependents = conn.execute("""
            SELECT t.* FROM tasks t
            JOIN dependencies d ON t.id = d.task_id
            WHERE d.depends_on = ?
        """, (task_id,)).fetchall()

    return {
        **task,
        "workspace": _deserialize_workspace(ws),
        "dependencies": [dict(d) for d in deps],
        "depended_by": [dict(d) for d in dependents],
    }


def get_all_runnable_tasks(workspace_id: str) -> list[dict]:
    """Get all runnable tasks: pending + all dependencies done."""
    with _connection() as conn:
        rows = conn.execute("""
            SELECT t.* FROM tasks t
            WHERE t.workspace_id = ?
              AND t.status = ?
              AND NOT EXISTS (
                  SELECT 1 FROM dependencies d
                  JOIN tasks dep ON dep.id = d.depends_on
                  WHERE d.task_id = t.id AND dep.status != ?
              )
            ORDER BY t.created_at
        """, (workspace_id, TaskStatus.PENDING, TaskStatus.DONE)).fetchall()
    return [dict(r) for r in rows]


def get_next_task(workspace_id: str) -> dict | None:
    tasks = get_all_runnable_tasks(workspace_id)
    return tasks[0] if tasks else None


def start_task(task_id: str) -> None:
    with _connection() as conn:
        conn.execute("UPDATE tasks SET status=? WHERE id=?", (TaskStatus.RUNNING, task_id))


def complete_task(task_id: str, result: str | None = None) -> dict | None:
    with _connection() as conn:
        conn.execute(
            "UPDATE tasks SET status=?, result=? WHERE id=?",
            (TaskStatus.DONE, result, task_id)
        )
        task = conn.execute("SELECT * FROM tasks WHERE id=?", (task_id,)).fetchone()
    return dict(task) if task else None


def is_workspace_complete(workspace_id: str) -> bool:
    with _connection() as conn:
        pending = conn.execute(
            "SELECT COUNT(*) as c FROM tasks WHERE workspace_id=? AND status != ?",
            (workspace_id, TaskStatus.DONE)
        ).fetchone()
    return pending["c"] == 0
