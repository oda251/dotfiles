"""Black-box tests for dispatch CLI."""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from unittest.mock import patch

import pytest

# Add parent dir to path
sys.path.insert(0, str(Path(__file__).parent.parent))

from dispatch import db, runner


@pytest.fixture(autouse=True)
def tmp_db(tmp_path, monkeypatch):
    """Use a temp DB for each test."""
    db_path = tmp_path / ".dispatch.db"
    monkeypatch.setattr(db, "_get_db_path", lambda: db_path)
    db.init_db(db_path)
    yield db_path


@pytest.fixture
def ws():
    """Create a test workspace."""
    return db.create_workspace(
        title="Test Project",
        background="Testing dispatch CLI",
        goals=["Goal A", "Goal B"],
        constraints=["Constraint 1"],
    )


@pytest.fixture
def ws_with_tasks(ws):
    """Workspace with a DAG: research → dev."""
    t1 = db.add_task(ws["id"], "Research auth patterns", "exec-research")
    t2 = db.add_task(ws["id"], "Implement auth API", "exec-dev", depends_on=[t1["id"]])
    return ws, t1, t2


# --- Workspace tests ---

class TestWorkspace:
    def test_create(self):
        ws = db.create_workspace("Test", "bg", ["g1"], ["c1"])
        assert ws["title"] == "Test"
        assert ws["goals"] == ["g1"]
        assert ws["constraints"] == ["c1"]
        assert len(ws["id"]) == 8

    def test_show(self, ws):
        result = db.get_workspace(ws["id"])
        assert result["title"] == "Test Project"
        assert result["goals"] == ["Goal A", "Goal B"]

    def test_list(self, ws):
        ws2 = db.create_workspace("Second", "", [], [])
        result = db.list_workspaces()
        assert len(result) == 2

    def test_edit_title(self, ws):
        result = db.edit_workspace(ws["id"], title="New Title")
        assert result["title"] == "New Title"

    def test_edit_add_goal(self, ws):
        result = db.edit_workspace(ws["id"], add_goal="Goal C")
        assert "Goal C" in result["goals"]
        assert len(result["goals"]) == 3

    def test_edit_remove_goal(self, ws):
        result = db.edit_workspace(ws["id"], remove_goal="Goal A")
        assert "Goal A" not in result["goals"]
        assert len(result["goals"]) == 1

    def test_edit_nonexistent(self):
        result = db.edit_workspace("nonexistent", title="x")
        assert result is None


# --- Task tests ---

class TestTask:
    def test_add(self, ws):
        task = db.add_task(ws["id"], "Test task", "exec-dev")
        assert task["title"] == "Test task"
        assert task["status"] == "pending"

    def test_add_with_deps(self, ws):
        t1 = db.add_task(ws["id"], "First", "exec-research")
        t2 = db.add_task(ws["id"], "Second", "exec-dev", depends_on=[t1["id"]])
        ctx = db.get_task_with_context(t2["id"])
        assert len(ctx["dependencies"]) == 1
        assert ctx["dependencies"][0]["id"] == t1["id"]

    def test_edit_title(self, ws):
        task = db.add_task(ws["id"], "Old", "exec-dev")
        result = db.edit_task(task["id"], title="New")
        assert result["title"] == "New"

    def test_edit_add_dep(self, ws):
        t1 = db.add_task(ws["id"], "A", "exec-research")
        t2 = db.add_task(ws["id"], "B", "exec-dev")
        db.edit_task(t2["id"], add_dep=t1["id"])
        ctx = db.get_task_with_context(t2["id"])
        assert len(ctx["dependencies"]) == 1

    def test_edit_remove_dep(self, ws_with_tasks):
        ws, t1, t2 = ws_with_tasks
        db.edit_task(t2["id"], remove_dep=t1["id"])
        ctx = db.get_task_with_context(t2["id"])
        assert len(ctx["dependencies"]) == 0

    def test_list(self, ws_with_tasks):
        ws, _, _ = ws_with_tasks
        tasks = db.list_tasks(ws["id"])
        assert len(tasks) == 2

    def test_list_by_status(self, ws_with_tasks):
        ws, t1, _ = ws_with_tasks
        db.start_task(t1["id"])
        running = db.list_tasks(ws["id"], status="running")
        assert len(running) == 1


# --- DAG dependency resolution ---

class TestDAG:
    def test_next_picks_no_deps(self, ws_with_tasks):
        ws, t1, t2 = ws_with_tasks
        # t1 has no deps, t2 depends on t1
        nxt = db.get_next_task(ws["id"])
        assert nxt["id"] == t1["id"]

    def test_next_blocked_when_dep_pending(self, ws_with_tasks):
        ws, t1, t2 = ws_with_tasks
        db.start_task(t1["id"])
        # t2 still blocked (t1 not done)
        nxt = db.get_next_task(ws["id"])
        assert nxt is None  # t1 is running, t2 blocked

    def test_next_unblocked_after_dep_done(self, ws_with_tasks):
        ws, t1, t2 = ws_with_tasks
        db.start_task(t1["id"])
        db.complete_task(t1["id"], "result.md")
        nxt = db.get_next_task(ws["id"])
        assert nxt["id"] == t2["id"]

    def test_all_runnable_parallel(self, ws):
        t1 = db.add_task(ws["id"], "A", "exec-research")
        t2 = db.add_task(ws["id"], "B", "exec-research")
        t3 = db.add_task(ws["id"], "C", "exec-dev", depends_on=[t1["id"], t2["id"]])
        runnable = db.get_all_runnable_tasks(ws["id"])
        assert len(runnable) == 2
        ids = {t["id"] for t in runnable}
        assert t1["id"] in ids
        assert t2["id"] in ids
        assert t3["id"] not in ids

    def test_diamond_dag(self, ws):
        #   A
        #  / \
        # B   C
        #  \ /
        #   D
        a = db.add_task(ws["id"], "A", "exec-research")
        b = db.add_task(ws["id"], "B", "exec-dev", depends_on=[a["id"]])
        c = db.add_task(ws["id"], "C", "exec-dev", depends_on=[a["id"]])
        d = db.add_task(ws["id"], "D", "exec-dev", depends_on=[b["id"], c["id"]])

        # Only A is runnable
        assert db.get_next_task(ws["id"])["id"] == a["id"]

        # Complete A → B, C runnable
        db.start_task(a["id"])
        db.complete_task(a["id"])
        runnable = db.get_all_runnable_tasks(ws["id"])
        assert len(runnable) == 2

        # Complete B only → D still blocked
        db.start_task(b["id"])
        db.complete_task(b["id"])
        assert db.get_next_task(ws["id"])["id"] == c["id"]

        # Complete C → D runnable
        db.start_task(c["id"])
        db.complete_task(c["id"])
        assert db.get_next_task(ws["id"])["id"] == d["id"]


# --- Workspace completion ---

class TestCompletion:
    def test_not_complete(self, ws_with_tasks):
        ws, _, _ = ws_with_tasks
        assert not db.is_workspace_complete(ws["id"])

    def test_complete_after_all_done(self, ws_with_tasks):
        ws, t1, t2 = ws_with_tasks
        db.start_task(t1["id"])
        db.complete_task(t1["id"])
        db.start_task(t2["id"])
        db.complete_task(t2["id"])
        assert db.is_workspace_complete(ws["id"])


# --- Task context ---

class TestContext:
    def test_includes_workspace(self, ws_with_tasks):
        ws, _, t2 = ws_with_tasks
        ctx = db.get_task_with_context(t2["id"])
        assert ctx["workspace"]["title"] == "Test Project"
        assert ctx["workspace"]["goals"] == ["Goal A", "Goal B"]

    def test_includes_deps(self, ws_with_tasks):
        _, t1, t2 = ws_with_tasks
        ctx = db.get_task_with_context(t2["id"])
        assert len(ctx["dependencies"]) == 1
        assert ctx["dependencies"][0]["title"] == "Research auth patterns"

    def test_includes_dependents(self, ws_with_tasks):
        _, t1, t2 = ws_with_tasks
        ctx = db.get_task_with_context(t1["id"])
        assert len(ctx["depended_by"]) == 1
        assert ctx["depended_by"][0]["title"] == "Implement auth API"


# --- Runner (with mocked claude -p) ---

class TestRunner:
    def test_run_next_picks_task(self, ws_with_tasks):
        ws, t1, _ = ws_with_tasks
        result = runner.run_next(ws["id"])
        assert result["status"] == "ready"
        assert result["task"]["id"] == t1["id"]

    def test_run_next_complete(self, ws):
        t = db.add_task(ws["id"], "Only", "exec-dev")
        db.start_task(t["id"])
        db.complete_task(t["id"])
        result = runner.run_next(ws["id"])
        assert result["status"] == "complete"

    def test_run_next_blocked(self, ws_with_tasks):
        ws, t1, _ = ws_with_tasks
        db.start_task(t1["id"])
        result = runner.run_next(ws["id"])
        assert result["status"] == "blocked"

    def test_complete_and_continue(self, ws_with_tasks):
        ws, t1, t2 = ws_with_tasks
        db.start_task(t1["id"])
        result = runner.complete_and_continue(t1["id"], result="res.md")
        assert result["status"] == "ready"
        assert result["task"]["id"] == t2["id"]

    def test_complete_and_continue_all_done(self, ws):
        t = db.add_task(ws["id"], "Only", "exec-dev")
        db.start_task(t["id"])
        result = runner.complete_and_continue(t["id"])
        assert result["status"] == "complete"

    def test_prompt_includes_workspace(self, ws_with_tasks):
        ws, t1, _ = ws_with_tasks
        result = runner.run_next(ws["id"])
        assert "Test Project" in result["prompt"]
        assert "Goal A" in result["prompt"]

    def test_prompt_includes_dep_results(self, ws_with_tasks):
        ws, t1, t2 = ws_with_tasks
        db.start_task(t1["id"])
        db.complete_task(t1["id"], "docs/research.md")
        result = runner.run_next(ws["id"])
        assert "docs/research.md" in result["prompt"]

    @patch("dispatch.runner.run_task_subprocess")
    def test_auto_run_chains(self, mock_subprocess, ws_with_tasks):
        ws, t1, t2 = ws_with_tasks
        mock_subprocess.return_value = "mocked result"
        result = runner.run_next(ws["id"], use_subprocess=True)
        assert result["status"] == "complete"
        assert mock_subprocess.call_count == 2


# --- Environment variable resolution ---

class TestEnvResolution:
    def test_get_current_task_id(self, monkeypatch):
        monkeypatch.setenv("DISPATCH_TASK_ID", "abc123")
        assert runner.get_current_task_id() == "abc123"

    def test_get_current_task_id_unset(self, monkeypatch):
        monkeypatch.delenv("DISPATCH_TASK_ID", raising=False)
        assert runner.get_current_task_id() is None

    def test_get_current_ws_id(self, monkeypatch):
        monkeypatch.setenv("DISPATCH_WS_ID", "ws456")
        assert runner.get_current_ws_id() == "ws456"
