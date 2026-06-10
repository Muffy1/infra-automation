#!/usr/bin/env python3
"""
notte_browser.py — shared Notte browser automation utility for infra-automation scripts.

Usage as a script:
    python scripts/notte_browser.py --task "Check uptime at https://myservice.com"

Usage as a module:
    from scripts.notte_browser import run_browser_task
    result = run_browser_task("Navigate to dashboard and verify widget count")
"""

from __future__ import annotations

import argparse
import os
import sys
from typing import Any


def run_browser_task(
    task: str,
    url: str | None = None,
    max_steps: int = 20,
    reasoning_model: str = "gemini/gemini-2.5-flash",
) -> Any:
    """Run a Notte browser agent task and return the answer."""
    try:
        from notte_sdk import NotteClient  # type: ignore
    except ImportError as exc:
        raise RuntimeError("pip install notte-sdk") from exc

    api_key = os.getenv("NOTTE_API_KEY")
    if not api_key:
        raise RuntimeError("NOTTE_API_KEY not set. Get a key at https://console.notte.cc")

    client = NotteClient(api_key=api_key)
    with client.Session() as session:
        agent = client.Agent(
            session=session,
            reasoning_model=reasoning_model,
            max_steps=max_steps,
        )
        kwargs: dict[str, Any] = {"task": task}
        if url:
            kwargs["url"] = url
        return agent.run(**kwargs).answer


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Notte AI browser automation")
    parser.add_argument("--task", required=True, help="Natural-language browser task")
    parser.add_argument("--url", help="Starting URL")
    parser.add_argument("--max-steps", type=int, default=20)
    parser.add_argument("--model", default="gemini/gemini-2.5-flash")
    args = parser.parse_args()
    print(run_browser_task(args.task, args.url, args.max_steps, args.model))
