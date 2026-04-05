#!/usr/bin/env python3
"""Educational scaffold, not production hardened.

Example wrapper that adapts an existing task CLI/API shape to the playbook task contract
instead of replacing the underlying system.

This file is intentionally tiny and obvious. Treat it as a mapping example, not a product.

Demo mode:
    EXISTING_TASK_BIN=/path/to/legacy-task-cli reference/adapters/task-wrapper.example.py start "Title" "Why" ops

If EXISTING_TASK_BIN is unset, the script prints the legacy command it would run.
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from typing import Any

EXIT_USAGE = 1

LEGACY_BIN = os.environ.get("EXISTING_TASK_BIN")
STATUS_MAP = {
    "planned": "todo",
    "in-progress": "doing",
    "done": "complete",
}


def usage() -> None:
    print(
        "usage: task-wrapper.example.py <start|plan|update|show|list> ...",
        file=sys.stderr,
    )
    raise SystemExit(EXIT_USAGE)


def run_legacy(argv: list[str]) -> int:
    if not LEGACY_BIN:
        print(json.dumps({"demo": True, "legacy_command": argv}, indent=2))
        return 0
    proc = subprocess.run([LEGACY_BIN, *argv])
    return proc.returncode


def command_start(args: list[str], status: str) -> int:
    if len(args) < 1:
        usage()
    title = args[0]
    input_text = args[1] if len(args) > 1 else ""
    category = args[2] if len(args) > 2 else "other"
    priority = args[3] if len(args) > 3 else "medium"

    legacy_payload: dict[str, Any] = {
        "summary": title,
        "request": input_text,
        "bucket": category,
        "urgency": priority,
        "state": STATUS_MAP[status],
        "source": "openclaw-playbook-wrapper-example",
    }
    return run_legacy(["tasks", "create", json.dumps(legacy_payload)])


def command_update(args: list[str]) -> int:
    if len(args) < 2:
        usage()
    task_id = args[0]
    status = args[1]
    note = args[2] if len(args) > 2 else ""
    if status not in STATUS_MAP:
        raise SystemExit(f"unsupported playbook status: {status}")

    legacy_payload = {
        "state": STATUS_MAP[status],
        "result": note,
    }
    return run_legacy(["tasks", "patch", task_id, json.dumps(legacy_payload)])


def command_show(args: list[str]) -> int:
    if len(args) != 1:
        usage()
    return run_legacy(["tasks", "get", args[0]])


def command_list(args: list[str]) -> int:
    status = args[0] if args else None
    legacy_state = STATUS_MAP[status] if status else "*"
    return run_legacy(["tasks", "list", "--state", legacy_state])


def main() -> int:
    if len(sys.argv) < 2:
        usage()

    command = sys.argv[1]
    args = sys.argv[2:]

    if command == "start":
        return command_start(args, "in-progress")
    if command == "plan":
        return command_start(args, "planned")
    if command == "update":
        return command_update(args)
    if command == "show":
        return command_show(args)
    if command == "list":
        return command_list(args)
    usage()
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
