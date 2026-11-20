"""Non-blocking filesystem scanner running inside a QThread."""

from __future__ import annotations

import os
import time
from glob import iglob
from pathlib import Path
from typing import Callable

from PySide6.QtCore import QThread, Signal

from .models import ScanItem, ScanSummary
from .rules import Rule, RuleEngine
from .system import is_within


def _size_of(path: Path, recursive: bool = True) -> int:
    """Return apparent size in bytes, tolerant of permission errors and races."""
    try:
        if path.is_symlink():
            return 0
        if path.is_file():
            return path.stat().st_size
        if not path.is_dir():
            return 0
        total = 0
        if recursive:
            for root, _dirs, files in os.walk(path, followlinks=False, onerror=lambda _e: None):
                root_path = Path(root)
                for name in files:
                    candidate = root_path / name
                    try:
                        if candidate.is_symlink():
                            continue
                        total += candidate.stat().st_size
                    except OSError:
                        continue
        return total
    except OSError:
        return 0


class ScanWorker(QThread):
    """Emits progress while walking the filesystem."""

    item_found = Signal(object)
    progress = Signal(int, str)
    finished_scan = Signal(object)
    error = Signal(str)

    def __init__(
        self,
        rule_engine: RuleEngine,
        exclusions: list[str] | None = None,
        min_age_days: int = 0,
        parent=None,
    ) -> None:
        super().__init__(parent)
        self.engine = rule_engine
        self.exclusions = [Path(p).expanduser().resolve(strict=False) for p in (exclusions or []) if p]
        self.min_age_days = max(0, min_age_days)
        self._cancelled = False

    def cancel(self) -> None:
        self._cancelled = True
        if not self.isFinished():
            self.requestInterruption()

    def run(self) -> None:  # noqa: D102 - Qt override
        summary = ScanSummary()
        started = time.time()
        rules = self.engine.active_rules()
        try:
            for index, rule in enumerate(rules):
                if self._cancelled or self.isInterruptionRequested():
                    break
                self.progress.emit(
                    int(index / max(1, len(rules)) * 100), rule.name_key
                )
                self._scan_rule(rule, summary)

            elapsed = time.time() - started
            self.progress.emit(100, f"done in {elapsed:.1f}s")
            self.finished_scan.emit(summary)
        except Exception as exc:  # pragma: no cover - defensive Qt boundary
            self.error.emit(str(exc))

    def _excluded(self, path: Path) -> bool:
        return any(is_within(path, root) for root in self.exclusions)

    def _scan_rule(self, rule: Rule, summary: ScanSummary) -> None:
        now = time.time()
        min_age_seconds = max(rule.min_age_days, self.min_age_days) * 86400
        seen: set[str] = set()

        for pattern in rule.paths:
            if self._cancelled or self.isInterruptionRequested():
                return
            expanded = os.path.expandvars(pattern)
            for match in iglob(expanded, recursive=True):
                if self._cancelled or self.isInterruptionRequested():
                    return
                path = Path(match)
                key = str(path)
                if key in seen:
                    continue
                seen.add(key)
                try:
                    if not path.exists() or path.is_symlink() or self._excluded(path):
                        continue
                    is_dir = path.is_dir()
                    if rule.kind.value == "directory" and not is_dir:
                        continue
                    if rule.kind.value == "file" and is_dir:
                        continue
                    if min_age_seconds:
                        try:
                            if now - path.stat().st_mtime < min_age_seconds:
                                continue
                        except OSError:
                            continue

                    size = _size_of(path, recursive=rule.recursive)
                    item = ScanItem(
                        path=str(path),
                        size=size,
                        rule_id=rule.id,
                        rule_name=rule.name_key,
                        category=rule.category,
                        icon=rule.icon,
                        modified=path.stat().st_mtime,
                        selected=True,
                        is_dir=is_dir,
                    )
                    summary.total_bytes += size
                    summary.total_items += 1
                    summary.per_category[rule.category] = summary.per_category.get(rule.category, 0) + size
                    summary.per_category_count[rule.category] = summary.per_category_count.get(rule.category, 0) + 1
                    self.item_found.emit(item)
                except (OSError, ValueError):
                    continue
