#!/usr/bin/env python3
"""Projects (most used first) and machines for the launcher, as one JSON array.

Ranks directories by zoxide's frecency (every `cd` teaches it), keeps the
ones that are projects (git repos and worktrees), and appends repos under the
project roots that zoxide hasn't seen yet. Branches are read straight from
.git, without running git.
"""

import json
import os
from pathlib import Path
import subprocess
import sys

HOME = Path.home()


def git_head(path):
    """Branch (or short commit) of a repo or worktree, or None if not a repo."""
    dotgit = path / ".git"
    try:
        if dotgit.is_file():
            target = dotgit.read_text().strip().removeprefix("gitdir:").strip()
            dotgit = (path / target).resolve()
        head = (dotgit / "HEAD").read_text().strip()
    except OSError:
        return None
    if head.startswith("ref: "):
        return head.removeprefix("ref: refs/heads/")
    return head[:7]


def zoxide():
    try:
        out = subprocess.run(["zoxide", "query", "--list", "--score"], capture_output=True, text=True, timeout=3).stdout
    except (OSError, subprocess.TimeoutExpired):
        return []
    ranked = []
    for line in out.splitlines():
        score, _, path = line.strip().partition(" ")
        if path:
            ranked.append(Path(path.strip()))
    return ranked


def machines():
    """Tailscale peers you can SSH into (no phones), plus ~/.ssh/config hosts."""
    found = {}
    try:
        status = json.loads(subprocess.run(["tailscale", "status", "--json"], capture_output=True,
                                           text=True, timeout=3).stdout or "{}")
    except (OSError, ValueError, subprocess.TimeoutExpired):
        status = {}
    for peer in (status.get("Peer") or {}).values():
        if peer.get("OS") in ("android", "iOS"):
            continue
        name = peer.get("HostName") or ""
        if name:
            found[name] = {"kind": "machine", "name": name, "host": name, "online": bool(peer.get("Online")),
                           "display": (peer.get("DNSName") or name).rstrip("."), "branch": peer.get("OS") or ""}
    try:
        for line in (HOME / ".ssh" / "config").read_text().splitlines():
            parts = line.split()
            if len(parts) >= 2 and parts[0].lower() == "host":
                for host in parts[1:]:
                    if any(c in host for c in "*?!") or host in found:
                        continue
                    found[host] = {"kind": "machine", "name": host, "host": host, "online": None,
                                   "display": "ssh config", "branch": ""}
    except OSError:
        pass
    rank = {True: 0, None: 1, False: 2}
    return sorted(found.values(), key=lambda m: (rank[m["online"]], m["name"]))


def pretty(path):
    text = str(path)
    home = str(HOME)
    return "~" + text[len(home):] if text == home or text.startswith(home + "/") else text


def main(argv):
    roots = [Path(os.path.expanduser(r)) for r in (argv or ["~/Programming"])]
    seen = set()
    projects = []

    def add(path):
        key = str(path)
        if key in seen or not path.is_dir():
            return
        branch = git_head(path)
        if branch is None:
            return
        seen.add(key)
        projects.append({"kind": "project", "path": key, "display": pretty(path), "name": path.name, "branch": branch})

    for path in zoxide():
        add(path)
    for root in roots:
        try:
            children = sorted((p for p in root.iterdir() if p.is_dir() and not p.name.startswith(".")),
                              key=lambda p: p.stat().st_mtime, reverse=True)
        except OSError:
            continue
        for child in children:
            add(child)

    json.dump(projects + machines(), sys.stdout, separators=(",", ":"))
    sys.stdout.write("\n")


if __name__ == "__main__":
    main(sys.argv[1:])
