"""Safe deletion: trash first, permanent delete only when explicitly asked."""

from __future__ import annotations

import os
import shutil
import subprocess
from pathlib import Path

from PySide6.QtCore import QThread, Signal

from .models import CleanTarget, TrashResult
from .system import SYSTEM, home, is_within


def _send2trash(path: Path) -> str:
    """Move ``path`` to the platform trash. Returns the method used."""
    # 1. Prefer the well-maintained send2trash package when bundled.
    try:
        from send2trash import send2trash as _s2t  # type: ignore[import-not-found]

        _s2t(str(path))
        return "send2trash"
    except Exception:
        pass

    # 2. Linux: GIO (GNOME) then KDE's kioclient5/6.
    if SYSTEM == "linux":
        for command in (
            ["gio", "trash", str(path)],
            ["kioclient6", "move", str(path), "trash:/"],
            ["kioclient5", "move", str(path), "trash:/"],
        ):
            try:
                result = subprocess.run(
                    command, check=False, capture_output=True, text=True, timeout=30
                )
                if result.returncode == 0:
                    return command[0]
            except (OSError, subprocess.SubprocessError):
                continue
        return _fallback_trash_dir(path)

    # 3. Windows: Shell COM via ctypes (recycle bin).
    if SYSTEM == "windows":  # pragma: no cover - platform specific
        try:
            import ctypes
            from ctypes import wintypes

            class SHFILEOPSTRUCTW(ctypes.Structure):
                _fields_ = [
                    ("hwnd", wintypes.HWND),
                    ("wFunc", wintypes.UINT),
                    ("pFrom", wintypes.LPCWSTR),
                    ("pTo", wintypes.LPCWSTR),
                    ("fFlags", ctypes.c_uint16),
                    ("fAnyOperationsAborted", wintypes.BOOL),
                    ("hNameMappings", ctypes.c_void_p),
                    ("lpszProgressTitle", wintypes.LPCWSTR),
                ]

            FO_DELETE = 3
            FOF_ALLOWUNDO = 0x0040
            FOF_NOCONFIRMATION = 0x0010
            FOF_SILENT = 0x0004
            op = SHFILEOPSTRUCTW()
            op.wFunc = FO_DELETE
            op.pFrom = str(path) + "\0"
            op.fFlags = FOF_ALLOWUNDO | FOF_NOCONFIRMATION | FOF_SILENT
            result = ctypes.windll.shell32.SHFileOperationW(ctypes.byref(op))
            if result == 0 and not op.fAnyOperationsAborted:
                return "windows-shell"
        except Exception:
            pass
        return _fallback_trash_dir(path)

    # 4. macOS: use `trash` CLI if installed, otherwise ~/.Trash.
    if SYSTEM == "darwin":  # pragma: no cover - platform specific
        try:
            result = subprocess.run(["trash", str(path)], check=False, capture_output=True, timeout=30)
            if result.returncode == 0:
                return "trash-cli"
        except OSError:
            pass
        trash = home() / ".Trash"
        return _move_into(trash, path, "mac-trash-dir")

    return _fallback_trash_dir(path)


def _fallback_trash_dir(path: Path) -> str:
    from .system import xdg

    trash = xdg("data", ".local/share") / "Trash"
    return _move_into(trash, path, "xdg-trash-dir")


def _move_into(trash: Path, path: Path, method: str) -> str:
    trash.mkdir(parents=True, exist_ok=True)
    target = trash / path.name
    counter = 1
    while target.exists():
        target = trash / f"{path.name}.{counter}"
        counter += 1
    shutil.move(str(path), str(target))
    return method


def purge(path: Path, is_dir: bool = False) -> None:
    if is_dir:
        shutil.rmtree(path, ignore_errors=False)
    else:
        path.unlink(missing_ok=True)


class CleanWorker(QThread):
    """Deletes selected targets off the UI thread."""

    progress = Signal(int, int, str)
    item_done = Signal(object)
    finished_clean = Signal(int, int, int)
    error = Signal(str)

    def __init__(self, targets: list[CleanTarget], use_trash: bool = True, parent=None) -> None:
        super().__init__(parent)
        self.targets = targets
        self.use_trash = use_trash
        self._cancelled = False

    def cancel(self) -> None:
        self._cancelled = True
        self.requestInterruption()

    def run(self) -> None:  # noqa: D102 - Qt override
        succeeded = failed = skipped = 0
        total = max(1, len(self.targets))
        for index, target in enumerate(self.targets):
            if self._cancelled or self.isInterruptionRequested():
                break
            path = Path(target.path)
            result = TrashResult(path=str(path), success=False)
            try:
                if not path.exists() and not path.is_symlink():
                    result.error = "missing"
                    skipped += 1
                elif self.use_trash and not target.permanent:
                    result.method = _send2trash(path)
                    result.success = True
                    succeeded += 1
                else:
                    purge(path, target.is_dir)
                    result.method = "permanent"
                    result.success = True
                    succeeded += 1
            except Exception as exc:  # noqa: BLE001 - report to UI
                result.error = str(exc)
                failed += 1
            self.progress.emit(index + 1, total, str(path))
            self.item_done.emit(result)

        self.finished_clean.emit(succeeded, failed, skipped)
