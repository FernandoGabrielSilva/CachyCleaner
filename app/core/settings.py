"""Thread-safe JSON settings with atomic writes."""

from __future__ import annotations

import json
import os
import tempfile
import threading
from pathlib import Path
from typing import Any

from .system import SYSTEM, home, xdg

DEFAULTS: dict[str, Any] = {
    "language": "auto",
    "theme": "system",
    "use_trash": True,
    "confirm_before_clean": True,
    "min_age_days": 0,
    "auto_check_updates": True,
    "last_update_check": 0,
    "exclusions": [],
    "custom_folders": [],
    "rule_overrides": {},
    "last_scan": 0,
    "first_run": True,
    "window": {"width": 1180, "height": 760, "x": 0, "y": 0, "maximized": False},
}


class Settings:
    """Small persistent key/value store.

    Uses a per-user config directory and writes via a temporary file + rename
    so a crash can never leave a half-written JSON document.
    """

    def __init__(self, path: Path | None = None) -> None:
        if path is None:
            base = xdg("config", ".config")
            path = base / "CachyCleaner" / "settings.json"
        self.path = Path(path)
        self._lock = threading.RLock()
        self._data: dict[str, Any] = {}
        self.load()

    def load(self) -> None:
        with self._lock:
            self._data = dict(DEFAULTS)
            try:
                if self.path.exists():
                    loaded = json.loads(self.path.read_text(encoding="utf-8"))
                    if isinstance(loaded, dict):
                        self._data.update(loaded)
            except (OSError, json.JSONDecodeError):
                # Corrupted settings should never prevent the app from starting.
                pass

    def get(self, key: str, default: Any = None) -> Any:
        with self._lock:
            return self._data.get(key, default)

    def set(self, key: str, value: Any) -> None:
        with self._lock:
            self._data[key] = value
            self._save_locked()

    def update(self, values: dict[str, Any]) -> None:
        with self._lock:
            self._data.update(values)
            self._save_locked()

    def all(self) -> dict[str, Any]:
        with self._lock:
            # Deep-ish copy via JSON keeps nested containers detached.
            return json.loads(json.dumps(self._data))

    def reset(self) -> None:
        with self._lock:
            self._data = dict(DEFAULTS)
            self._save_locked()

    def _save_locked(self) -> None:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        fd, tmp_name = tempfile.mkstemp(dir=str(self.path.parent), prefix=".settings-", suffix=".json")
        try:
            with os.fdopen(fd, "w", encoding="utf-8") as handle:
                json.dump(self._data, handle, indent=2, ensure_ascii=False, sort_keys=True)
                handle.flush()
                os.fsync(handle.fileno())
            os.replace(tmp_name, self.path)
        except OSError:
            try:
                os.unlink(tmp_name)
            except OSError:
                pass
