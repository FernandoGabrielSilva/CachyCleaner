"""Cross-platform path helpers and XDG/user-directory resolution."""

from __future__ import annotations

import os
import platform
import re
import sys
from pathlib import Path
from typing import Iterable

HOME = Path.home()
SYSTEM = platform.system().lower()

_ENV_OVERRIDES: dict[str, dict[str, str]] = {
    "cache": {"XDG_CACHE_HOME": ".cache"},
    "config": {"XDG_CONFIG_HOME": ".config"},
    "data": {"XDG_DATA_HOME": ".local/share"},
    "state": {"XDG_STATE_HOME": ".local/state"},
}


def xdg(kind: str, fallback: str) -> Path:
    """Return an XDG directory on Linux, or the platform equivalent."""
    for env_name, default in _ENV_OVERRIDES.get(kind, {}).items():
        value = os.environ.get(env_name)
        if value:
            return Path(value).expanduser()
        if SYSTEM == "linux":
            return HOME / default
    if SYSTEM == "darwin":
        return {
            "cache": HOME / "Library" / "Caches",
            "config": HOME / "Library" / "Application Support",
            "data": HOME / "Library" / "Application Support",
            "state": HOME / "Library" / "Application Support",
        }.get(kind, HOME / fallback)
    if SYSTEM == "windows":
        base = Path(os.environ.get("LOCALAPPDATA", HOME / "AppData" / "Local"))
        return base / fallback
    return HOME / fallback


def home() -> Path:
    return HOME


def expand(path: str | Path) -> Path:
    """Expand ``~``, environment variables and normalize separators."""
    text = os.path.expandvars(str(path))
    return Path(text).expanduser().resolve(strict=False)


def temp_dir() -> Path:
    return Path(os.environ.get("TMPDIR", os.environ.get("TEMP", "/tmp"))).expanduser()


def is_appimage() -> bool:
    """True when running from an AppImage (useful for self-update messages)."""
    return bool(os.environ.get("APPIMAGE") or os.environ.get("APPDIR"))


def is_frozen() -> bool:
    return bool(getattr(sys, "frozen", False))


def safe_relative(path: Path, root: Path) -> str | None:
    try:
        return str(path.relative_to(root))
    except ValueError:
        return None


def is_within(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
        return True
    except ValueError:
        return False


def matches_any(name: str, patterns: Iterable[str]) -> bool:
    """Fast glob matcher for basenames (avoids walking huge trees for patterns)."""
    from fnmatch import fnmatchcase

    return any(fnmatchcase(name, pattern) for pattern in patterns)


def sanitize_component(value: str) -> str:
    """Make a user supplied path component safe for config serialization."""
    cleaned = re.sub(r"[^\w.\- ]+", "_", value, flags=re.UNICODE).strip()
    return cleaned[:120] or "custom"
