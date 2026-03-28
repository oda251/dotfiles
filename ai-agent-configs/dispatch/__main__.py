#!/usr/bin/env python3
"""dispatch - Task orchestration CLI for AI agent workflows."""

import argparse
import json
import sys

from . import db
from . import runner


def _resolve_task_id(args) -> str:
    """Resolve task ID from --id flag or DISPATCH_TASK_ID env."""
    task_id = getattr(args, "id", None) or runner.get_current_task_id()
    if not task_id:
        print("Error: --id required (or set DISPATCH_TASK_ID env)", file=sys.stderr)
        sys.exit(1)
    return task_id


def _resolve_ws_id(args) -> str:
    """Resolve workspace ID from --ws flag or DISPATCH_WS_ID env."""
    ws_id = getattr(args, "ws", None) or runner.get_current_ws_id()
    if not ws_id:
        print("Error: --ws required (or set DISPATCH_WS_ID env)", file=sys.stderr)
        sys.exit(1)
    return ws_id


def cmd_ws_create(args):
    db.init_db()
    ws = db.create_workspace(
        title=args.title,
        background=args.background or "",
        goals=args.goal or [],
        constraints=args.constraint or [],
    )
    print(json.dumps(ws, ensure_ascii=False, indent=2))


def cmd_ws_show(args):
    ws_id = _resolve_ws_id(args)
    ws = db.get_workspace(ws_id)
    if not ws:
        print(f"Workspace {ws_id} not found.", file=sys.stderr)
        sys.exit(1)
    tasks = db.list_tasks(ws_id)
    ws["tasks"] = tasks
    print(json.dumps(ws, ensure_ascii=False, indent=2))


def cmd_ws_list(args):
    workspaces = db.list_workspaces()
    print(json.dumps(workspaces, ensure_ascii=False, indent=2))


def cmd_ws_edit(args):
    ws_id = _resolve_ws_id(args)
    kwargs = {}
    if args.title:
        kwargs["title"] = args.title
    if args.background:
        kwargs["background"] = args.background
    if args.add_goal:
        kwargs["add_goal"] = args.add_goal
    if args.remove_goal:
        kwargs["remove_goal"] = args.remove_goal
    if args.add_constraint:
        kwargs["add_constraint"] = args.add_constraint
    if args.remove_constraint:
        kwargs["remove_constraint"] = args.remove_constraint
    ws = db.edit_workspace(ws_id, **kwargs)
    if not ws:
        print(f"Workspace {ws_id} not found.", file=sys.stderr)
        sys.exit(1)
    print(json.dumps(ws, ensure_ascii=False, indent=2))


def cmd_task_add(args):
    ws_id = _resolve_ws_id(args)
    depends = args.depends_on.split(",") if args.depends_on else []
    task = db.add_task(
        workspace_id=ws_id,
        title=args.title,
        task_type=args.type,
        depends_on=depends,
    )
    print(json.dumps(task, ensure_ascii=False, indent=2))


def cmd_task_edit(args):
    task_id = _resolve_task_id(args)
    kwargs = {}
    if args.title:
        kwargs["title"] = args.title
    if args.type:
        kwargs["type"] = args.type
    if args.add_dep:
        kwargs["add_dep"] = args.add_dep
    if args.remove_dep:
        kwargs["remove_dep"] = args.remove_dep
    task = db.edit_task(task_id, **kwargs)
    if not task:
        print(f"Task {task_id} not found.", file=sys.stderr)
        sys.exit(1)
    print(json.dumps(task, ensure_ascii=False, indent=2))


def cmd_task_current(args):
    task_id = runner.get_current_task_id()
    if not task_id:
        print("No current task (DISPATCH_TASK_ID not set).", file=sys.stderr)
        sys.exit(1)
    ctx = db.get_task_with_context(task_id)
    if not ctx:
        print(f"Task {task_id} not found.", file=sys.stderr)
        sys.exit(1)
    print(json.dumps(ctx, ensure_ascii=False, indent=2))


def cmd_task_done(args):
    task_id = _resolve_task_id(args)
    result = runner.complete_and_continue(
        task_id,
        result=args.result,
        use_subprocess=args.auto,
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))


def cmd_run(args):
    ws_id = _resolve_ws_id(args)
    result = runner.run_next(ws_id, use_subprocess=args.auto)
    print(json.dumps(result, ensure_ascii=False, indent=2))


def main():
    parser = argparse.ArgumentParser(prog="dispatch", description="Task orchestration CLI")
    sub = parser.add_subparsers(dest="command")

    # --- ws ---
    ws_parser = sub.add_parser("ws")
    ws_sub = ws_parser.add_subparsers(dest="ws_command")

    ws_create = ws_sub.add_parser("create")
    ws_create.add_argument("--title", required=True)
    ws_create.add_argument("--background")
    ws_create.add_argument("--goal", action="append")
    ws_create.add_argument("--constraint", action="append")
    ws_create.set_defaults(func=cmd_ws_create)

    ws_show = ws_sub.add_parser("show")
    ws_show.add_argument("--ws")
    ws_show.set_defaults(func=cmd_ws_show)

    ws_list = ws_sub.add_parser("list")
    ws_list.set_defaults(func=cmd_ws_list)

    ws_edit = ws_sub.add_parser("edit")
    ws_edit.add_argument("--ws")
    ws_edit.add_argument("--title")
    ws_edit.add_argument("--background")
    ws_edit.add_argument("--add-goal")
    ws_edit.add_argument("--remove-goal")
    ws_edit.add_argument("--add-constraint")
    ws_edit.add_argument("--remove-constraint")
    ws_edit.set_defaults(func=cmd_ws_edit)

    # --- task ---
    task_parser = sub.add_parser("task")
    task_sub = task_parser.add_subparsers(dest="task_command")

    task_add = task_sub.add_parser("add")
    task_add.add_argument("--ws")
    task_add.add_argument("--title", required=True)
    task_add.add_argument("--type", required=True)
    task_add.add_argument("--depends-on")
    task_add.set_defaults(func=cmd_task_add)

    task_edit = task_sub.add_parser("edit")
    task_edit.add_argument("--id")
    task_edit.add_argument("--title")
    task_edit.add_argument("--type")
    task_edit.add_argument("--add-dep")
    task_edit.add_argument("--remove-dep")
    task_edit.set_defaults(func=cmd_task_edit)

    task_current = task_sub.add_parser("current")
    task_current.set_defaults(func=cmd_task_current)

    task_done = task_sub.add_parser("done")
    task_done.add_argument("--id")
    task_done.add_argument("--result")
    task_done.add_argument("--auto", action="store_true",
                           help="Auto-dispatch next task via claude -p")
    task_done.set_defaults(func=cmd_task_done)

    # --- run ---
    run_parser = sub.add_parser("run")
    run_parser.add_argument("--ws")
    run_parser.add_argument("--auto", action="store_true",
                            help="Auto-execute via claude -p")
    run_parser.set_defaults(func=cmd_run)

    args = parser.parse_args()
    if not hasattr(args, "func"):
        parser.print_help()
        sys.exit(1)
    args.func(args)


if __name__ == "__main__":
    main()
