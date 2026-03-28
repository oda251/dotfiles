"""SQLite database operations for dispatch."""

import sqlite3
import json
import uuid
from pathlib import Path
from datetime import datetime, timezone


DB_NAME = ".dispatch.db"


def _get_db_path() -> Path:
    """Get DB path relative to current working directory."""
    return Path.cwd() / DB_NAME


def _connect(db_path: Path | None = None) -> sqlite3.Connection:
    conn = sqlite3.connect(str(db_path or _get_db_path()))
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    return conn


def init_db(db_path: Path | None = None) -> None:
    conn = _connect(db_path)
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
    conn.commit()
    conn.close()


# --- Workspace operations ---

def create_workspace(title: str, background: str = "",
                     goals: list[str] | None = None,
                     constraints: list[str] | None = None) -> dict:
    conn = _connect()
    ws_id = str(uuid.uuid4())[:8]
    now = datetime.now(timezone.utc).isoformat()
    conn.execute(
        "INSERT INTO workspaces (id, title, background, goals, constraints, created_at) "
        "VALUES (?, ?, ?, ?, ?, ?)",
        (ws_id, title, background,
         json.dumps(goals or [], ensure_ascii=False),
         json.dumps(constraints or [], ensure_ascii=False),
         now)
    )
    conn.commit()
    ws = dict(conn.execute("SELECT * FROM workspaces WHERE id = ?", (ws_id,)).fetchone())
    conn.close()
    ws["goals"] = json.loads(ws["goals"])
    ws["constraints"] = json.loads(ws["constraints"])
    return ws


def get_workspace(ws_id: str) -> dict | None:
    conn = _connect()
    row = conn.execute("SELECT * FROM workspaces WHERE id = ?", (ws_id,)).fetchone()
    conn.close()
    if not row:
        return None
    ws = dict(row)
    ws["goals"] = json.loads(ws["goals"])
    ws["constraints"] = json.loads(ws["constraints"])
    return ws


def list_workspaces() -> list[dict]:
    conn = _connect()
    rows = conn.execute("SELECT * FROM workspaces ORDER BY created_at DESC").fetchall()
    conn.close()
    result = []
    for row in rows:
        ws = dict(row)
        ws["goals"] = json.loads(ws["goals"])
        ws["constraints"] = json.loads(ws["constraints"])
        result.append(ws)
    return result


def edit_workspace(ws_id: str, **kwargs) -> dict | None:
    conn = _connect()
    ws = conn.execute("SELECT * FROM workspaces WHERE id = ?", (ws_id,)).fetchone()
    if not ws:
        conn.close()
        return None

    current = dict(ws)
    current["goals"] = json.loads(current["goals"])
    current["constraints"] = json.loads(current["constraints"])

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
    conn.commit()
    conn.close()
    return current


# --- Task operations ---

def add_task(workspace_id: str, title: str, task_type: str,
             depends_on: list[str] | None = None) -> dict:
    conn = _connect()
    task_id = str(uuid.uuid4())[:8]
    now = datetime.now(timezone.utc).isoformat()
    conn.execute(
        "INSERT INTO tasks (id, workspace_id, title, type, status, created_at) "
        "VALUES (?, ?, ?, ?, 'pending', ?)",
        (task_id, workspace_id, title, task_type, now)
    )
    for dep in (depends_on or []):
        conn.execute(
            "INSERT INTO dependencies (task_id, depends_on) VALUES (?, ?)",
            (task_id, dep)
        )
    conn.commit()
    task = dict(conn.execute("SELECT * FROM tasks WHERE id = ?", (task_id,)).fetchone())
    conn.close()
    return task


def edit_task(task_id: str, **kwargs) -> dict | None:
    conn = _connect()
    task = conn.execute("SELECT * FROM tasks WHERE id = ?", (task_id,)).fetchone()
    if not task:
        conn.close()
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

    conn.commit()
    conn.close()
    return current


def list_tasks(workspace_id: str, status: str | None = None) -> list[dict]:
    conn = _connect()
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
    conn.close()
    return [dict(r) for r in rows]


def get_task_with_context(task_id: str) -> dict | None:
    """Get task with full context: workspace info, dependencies, dependents."""
    conn = _connect()
    task = conn.execute("SELECT * FROM tasks WHERE id = ?", (task_id,)).fetchone()
    if not task:
        conn.close()
        return None

    task = dict(task)

    # Workspace context
    ws = conn.execute(
        "SELECT * FROM workspaces WHERE id = ?", (task["workspace_id"],)
    ).fetchone()
    ws = dict(ws)
    ws["goals"] = json.loads(ws["goals"])
    ws["constraints"] = json.loads(ws["constraints"])

    # Completed dependencies
    deps = conn.execute("""
        SELECT t.* FROM tasks t
        JOIN dependencies d ON t.id = d.depends_on
        WHERE d.task_id = ?
    """, (task_id,)).fetchall()

    # Tasks that depend on this one
    dependents = conn.execute("""
        SELECT t.* FROM tasks t
        JOIN dependencies d ON t.id = d.task_id
        WHERE d.depends_on = ?
    """, (task_id,)).fetchall()

    conn.close()

    return {
        **task,
        "workspace": ws,
        "dependencies": [dict(d) for d in deps],
        "depended_by": [dict(d) for d in dependents],
    }


def get_next_task(workspace_id: str) -> dict | None:
    """Get next runnable task: pending + all dependencies done."""
    conn = _connect()
    rows = conn.execute("""
        SELECT t.* FROM tasks t
        WHERE t.workspace_id = ?
          AND t.status = 'pending'
          AND NOT EXISTS (
              SELECT 1 FROM dependencies d
              JOIN tasks dep ON dep.id = d.depends_on
              WHERE d.task_id = t.id AND dep.status != 'done'
          )
        ORDER BY t.created_at
        LIMIT 1
    """, (workspace_id,)).fetchone()
    conn.close()
    return dict(rows) if rows else None


def get_all_runnable_tasks(workspace_id: str) -> list[dict]:
    """Get all runnable tasks (for parallel execution)."""
    conn = _connect()
    rows = conn.execute("""
        SELECT t.* FROM tasks t
        WHERE t.workspace_id = ?
          AND t.status = 'pending'
          AND NOT EXISTS (
              SELECT 1 FROM dependencies d
              JOIN tasks dep ON dep.id = d.depends_on
              WHERE d.task_id = t.id AND dep.status != 'done'
          )
        ORDER BY t.created_at
    """, (workspace_id,)).fetchall()
    conn.close()
    return [dict(r) for r in rows]


def start_task(task_id: str) -> dict | None:
    conn = _connect()
    conn.execute("UPDATE tasks SET status='running' WHERE id=?", (task_id,))
    conn.commit()
    task = conn.execute("SELECT * FROM tasks WHERE id=?", (task_id,)).fetchone()
    conn.close()
    return dict(task) if task else None


def complete_task(task_id: str, result: str | None = None) -> dict | None:
    conn = _connect()
    conn.execute(
        "UPDATE tasks SET status='done', result=? WHERE id=?",
        (result, task_id)
    )
    conn.commit()
    task = conn.execute("SELECT * FROM tasks WHERE id=?", (task_id,)).fetchone()
    conn.close()
    return dict(task) if task else None


def is_workspace_complete(workspace_id: str) -> bool:
    conn = _connect()
    pending = conn.execute(
        "SELECT COUNT(*) as c FROM tasks WHERE workspace_id=? AND status != 'done'",
        (workspace_id,)
    ).fetchone()
    conn.close()
    return pending["c"] == 0
