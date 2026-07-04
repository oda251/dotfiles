#!/usr/bin/env python3
"""Name each herdr space after its primary pane's git repo / cwd.

Background poller started once per herdr session from the zsh startup
(dot_zsh/plugins.zsh.tmpl). It:
  * self-dedups via an flock on <session-dir>/space-namer.lock,
  * exits when the session socket disappears,
  * for every workspace, looks at its primary pane (lowest tab number, then
    lowest pane number = tab1/pane1) foreground_cwd, and renames the workspace
    to the git repo root basename (or "~" for $HOME, else the cwd basename).

Run with --once for a single tick (no lock, no loop) — handy for testing.
Managed by chezmoi; source: dot_config/herdr/executable_space-namer.py.
"""
import fcntl
import json
import os
import signal
import subprocess
import sys
import time

SOCK = os.environ.get("HERDR_SOCKET_PATH")
INTERVAL = float(os.environ.get("HERDR_SPACE_NAMER_INTERVAL", "10"))
HOME = os.path.realpath(os.path.expanduser("~"))


def herdr(args):
    try:
        out = subprocess.run(["herdr", *args], capture_output=True, text=True, timeout=10)
        return json.loads(out.stdout).get("result")
    except Exception:
        return None


def desired_name(cwd):
    if not cwd or not os.path.isdir(cwd):
        return None
    try:
        r = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=5,
        )
        root = r.stdout.strip()
        if r.returncode == 0 and root:
            return os.path.basename(root)
    except Exception:
        pass
    if os.path.realpath(cwd) == HOME:
        return "~"
    return os.path.basename(cwd.rstrip("/")) or "/"


def _tnum(tid):
    try:
        return int(tid.split(":t")[1])
    except Exception:
        return 1 << 30


def _pnum(pid):
    try:
        return int(pid.split(":p")[1])
    except Exception:
        return 1 << 30


def tick():
    """One reconcile pass. Returns False when the session is gone (stop)."""
    if SOCK and not os.path.exists(SOCK):
        return False
    panes = herdr(["pane", "list"])
    wl = herdr(["workspace", "list"])
    if panes is None or wl is None:
        return True
    labels = {w["workspace_id"]: w.get("label", "") for w in wl.get("workspaces", [])}

    # primary pane per workspace = min(tab number, pane number)
    prim = {}
    for p in panes.get("panes", []):
        wid = p.get("workspace_id")
        if not wid:
            continue
        key = (_tnum(p.get("tab_id", "")), _pnum(p.get("pane_id", "")))
        cwd = p.get("foreground_cwd") or p.get("cwd") or ""
        if wid not in prim or key < prim[wid][0]:
            prim[wid] = (key, cwd)

    for wid, (_key, cwd) in prim.items():
        cur = labels.get(wid, "")
        want = desired_name(cwd)
        if want and want != cur:
            herdr(["workspace", "rename", wid, want])
    return True


def main():
    once = "--once" in sys.argv[1:]
    if once:
        tick()
        return
    if not SOCK:
        return
    # single instance per session
    lock_path = os.path.join(os.path.dirname(SOCK), "space-namer.lock")
    lock_fd = open(lock_path, "w")
    try:
        fcntl.flock(lock_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return  # another poller already holds it
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    while tick():
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
