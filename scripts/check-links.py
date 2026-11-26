#!/usr/bin/env python3
"""Check local links and anchors in Markdown and HTML files.

The repository is self-contained: every relative link must point to a file
that exists, and every `#anchor` must match a heading or an explicit id.
External URLs are not fetched; CI stays fast and works without network access.

Usage:
    python3 scripts/check-links.py [--root PATH]
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

SKIP_DIRS = {".git", "build", "out", "artifacts", "node_modules", "__pycache__"}
LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+[\"'][^\"']*[\"'])?\)")
HTML_LINK_RE = re.compile(r"(?:href|src)=[\"']([^\"']+)[\"']")
HEADING_RE = re.compile(r"^(#{1,6})\s+(.+?)\s*$")
ID_RE = re.compile(r"\bid=[\"']([^\"']+)[\"']")
SCHEMES = ("http://", "https://", "mailto:", "tel:", "data:", "ftp://")


def slugify(text: str) -> str:
    text = re.sub(r"`([^`]*)`", r"\1", text)
    text = re.sub(r"<[^>]+>", "", text)
    text = text.strip().lower()
    text = re.sub(r"[^\w\s-]", "", text, flags=re.UNICODE).strip()
    text = re.sub(r"\s", "-", text)
    return text


def anchors(path: Path) -> set[str]:
    text = path.read_text(encoding="utf-8", errors="replace")
    found: set[str] = set(ID_RE.findall(text))
    if path.suffix.lower() in {".md", ".markdown"}:
        for line in text.splitlines():
            match = HEADING_RE.match(line)
            if not match:
                continue
            slug = slugify(match.group(2))
            found.add(slug)
            # GitHub's slugger can leave double hyphens around punctuation.
            found.add(re.sub(r"-+", "-", slug))
    for anchor in list(found):
        found.add(anchor.removeprefix("user-content-"))
        found.add("user-content-" + anchor)
    return found


def iter_files(root: Path):
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if any(part in SKIP_DIRS for part in path.parts):
            continue
        if path.suffix.lower() in {".md", ".markdown", ".html", ".htm"}:
            yield path


def targets(path: Path):
    text = path.read_text(encoding="utf-8", errors="replace")
    if path.suffix.lower() in {".md", ".markdown"}:
        for match in LINK_RE.finditer(text):
            yield match.group(1)
    for match in HTML_LINK_RE.finditer(text):
        yield match.group(1)


def check(root: Path) -> list[str]:
    errors: list[str] = []
    anchor_cache: dict[Path, set[str]] = {}

    def get_anchors(target: Path) -> set[str]:
        if target not in anchor_cache:
            anchor_cache[target] = anchors(target)
        return anchor_cache[target]

    for source in iter_files(root):
        for raw in targets(source):
            target = raw.strip()
            if not target or target.startswith(SCHEMES):
                continue
            if target.startswith("//"):
                continue

            if target.startswith("#"):
                anchor = target[1:]
                if anchor not in get_anchors(source):
                    errors.append(f"{source.relative_to(root)}: нет якоря #{anchor}")
                continue

            file_part, sep, anchor = target.partition("#")
            if not file_part:
                continue
            if file_part.startswith("/"):
                target_path = (root / file_part.lstrip("/")).resolve()
            else:
                target_path = (source.parent / file_part).resolve()
            try:
                target_path.relative_to(root)
            except ValueError:
                errors.append(
                    f"{source.relative_to(root)}: ссылка вне репозитория: {target}"
                )
                continue
            if not target_path.exists():
                errors.append(
                    f"{source.relative_to(root)}: нет файла {target_path.relative_to(root)}"
                )
                continue
            if sep and anchor and target_path.suffix.lower() in {
                ".md",
                ".markdown",
                ".html",
                ".htm",
            }:
                if anchor not in get_anchors(target_path):
                    errors.append(
                        f"{source.relative_to(root)}: нет якоря #{anchor} в "
                        f"{target_path.relative_to(root)}"
                    )
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="repository root (default: parent of scripts/)",
    )
    args = parser.parse_args()
    root = args.root.resolve()
    errors = check(root)
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print(f"Найдено ошибок: {len(errors)}", file=sys.stderr)
        return 1
    print("Локальные ссылки и якоря в порядке.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
