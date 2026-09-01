#!/usr/bin/env python3
"""
notte_browser.py — Notte browser automation helpers for infra-automation scripts.

Three entry points:

  scrape_page(url, instructions)
      One-shot structured data extraction from a URL. No session management needed.

  run_workflow(steps, url, scrape_instructions)
      Execute a known sequence of actions (goto/click/fill/press_key) then
      optionally scrape results. Use this when selectors are known in advance.
      Exported from a live session via: notte sessions workflow-code

  run_browser_task(task, url, max_steps)
      Start an AI agent for open-ended or exploratory tasks where the exact
      steps are not known ahead of time.

CLI usage:
    python scripts/notte_browser.py --task "Check uptime at https://myservice.com"
    python scripts/notte_browser.py --scrape https://news.ycombinator.com \
        --instructions "Extract top 10 story titles as JSON"
"""

from __future__ import annotations

import argparse
import os
import sys
from typing import Any


def _get_client():
    try:
        from notte_sdk import NotteClient  # type: ignore
    except ImportError as exc:
        raise RuntimeError("pip install notte-sdk") from exc
    api_key = os.getenv("NOTTE_API_KEY")
    if not api_key:
        raise RuntimeError("NOTTE_API_KEY not set. Get a key at https://console.notte.cc")
    return NotteClient(api_key=api_key)


def scrape_page(
    url: str,
    instructions: str = "Extract main content as JSON",
) -> Any:
    """
    One-shot structured extraction from a URL.
    Generates workflow code via: notte sessions workflow-code
    """
    client = _get_client()
    return client.scrape(url, instructions=instructions)


def run_workflow(
    steps: list[dict[str, Any]],
    *,
    url: str | None = None,
    scrape_instructions: str | None = None,
    solve_captchas: bool = False,
) -> Any:
    """
    Execute a known sequence of browser actions then optionally scrape.

    steps format mirrors the SDK execute() API:
        [
            {"type": "goto",      "url": "https://example.com"},
            {"type": "fill",      "selector": "input[name='q']", "value": "query"},
            {"type": "press_key", "key": "Enter"},
            {"type": "click",     "selector": "button#submit"},
        ]

    Tip: generate steps from a live session with:
        notte sessions start
        notte page goto <url>
        notte page observe
        notte page click "B3"
        notte sessions workflow-code
    """
    client = _get_client()
    with client.Session(solve_captchas=solve_captchas) as session:
        if url:
            session.execute(type="goto", url=url)
        for step in steps:
            step_type = step.pop("type")
            session.execute(type=step_type, **step)
        if scrape_instructions:
            return session.scrape(instructions=scrape_instructions)
    return None


def run_browser_task(
    task: str,
    url: str | None = None,
    max_steps: int = 20,
    reasoning_model: str = "gemini/gemini-2.5-flash",
) -> Any:
    """Run a Notte AI agent for open-ended tasks where exact steps are unknown."""
    client = _get_client()
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
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--task", help="Open-ended natural-language browser task (AI agent)")
    group.add_argument("--scrape", metavar="URL", help="One-shot URL scrape")
    parser.add_argument("--url", help="Starting URL (for --task mode)")
    parser.add_argument("--instructions", default="Extract main content as JSON",
                        help="Extraction instructions for --scrape mode")
    parser.add_argument("--max-steps", type=int, default=20)
    parser.add_argument("--model", default="gemini/gemini-2.5-flash")
    args = parser.parse_args()

    try:
        if args.scrape:
            print(scrape_page(args.scrape, args.instructions))
        else:
            print(run_browser_task(args.task, args.url, args.max_steps, args.model))
    except RuntimeError as err:
        print(f"ERROR: {err}", file=sys.stderr)
        sys.exit(1)
