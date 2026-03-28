#!/usr/bin/env python3
"""dispatch - Task orchestration CLI for AI agent workflows."""

import argparse
import json
import sys

from . import db
from . import runner


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
    ws = db.get_workspace(args.id)
    if not ws:
        print(f"Workspace {args.id} not found.", file=sys.stderr)
        sys.exit(1)
    tasks = db.list_tasks(args.id)
    ws["tasks"] = tasks
    print(json.dumps(ws, ensure_ascii=False, indent=2))


def cmd_ws_list(args):
    workspaces = db.list_workspaces()
    print(json.dumps(workspaces, ensure_ascii=False, indent=2))


def cmd_ws_edit(args):
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
    ws = db.edit_workspace(args.id, **kwargs)
    if not ws:
        print(f"Workspace {args.id} not found.", file=sys.stderr)
        sys.exit(1)
    print(json.dumps(ws, ensure_ascii=False, indent=2))


def cmd_task_add(args):
    depends = args.depends_on.split(",") if args.depends_on else []
    task = db.add_task(
        workspace_id=args.ws,
        title=args.title,
        task_type=args.type,
        depends_on=depends,
    )
    print(json.dumps(task, ensure_ascii=False, indent=2))


def cmd_task_edit(args):
    kwargs = {}
    if args.title:
        kwargs["title"] = args.title
    if args.type:
        kwargs["type"] = args.type
    if args.add_dep:
        kwargs["add_dep"] = args.add_dep
    if args.remove_dep:
        kwargs["remove_dep"] = args.remove_dep
    task = db.edit_task(args.id, **kwargs)
    if not task:
        print(f"Task {args.id} not found.", file=sys.stderr)
        sys.exit(1)
    print(json.dumps(task, ensure_ascii=False, indent=2))


def cmd_task_done(args):
    result = runner.complete_and_continue(
        args.id,
        result=args.result,
        use_subprocess=args.auto,
    )
    print(json.dumps(result, ensure_ascii=False, indent=2))


def cmd_run(args):
    result = runner.run_next(args.ws, use_subprocess=args.auto)
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
    ws_show.add_argument("--id", required=True)
    ws_show.set_defaults(func=cmd_ws_show)

    ws_list = ws_sub.add_parser("list")
    ws_list.set_defaults(func=cmd_ws_list)

    ws_edit = ws_sub.add_parser("edit")
    ws_edit.add_argument("--id", required=True)
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
    task_add.add_argument("--ws", required=True)
    task_add.add_argument("--title", required=True)
    task_add.add_argument("--type", required=True)
    task_add.add_argument("--depends-on")
    task_add.set_defaults(func=cmd_task_add)

    task_edit = task_sub.add_parser("edit")
    task_edit.add_argument("--id", required=True)
    task_edit.add_argument("--title")
    task_edit.add_argument("--type")
    task_edit.add_argument("--add-dep")
    task_edit.add_argument("--remove-dep")
    task_edit.set_defaults(func=cmd_task_edit)

    task_done = task_sub.add_parser("done")
    task_done.add_argument("--id", required=True)
    task_done.add_argument("--result")
    task_done.add_argument("--auto", action="store_true",
                           help="Auto-dispatch next task via claude -p")
    task_done.set_defaults(func=cmd_task_done)

    # --- run ---
    run_parser = sub.add_parser("run")
    run_parser.add_argument("--ws", required=True)
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
