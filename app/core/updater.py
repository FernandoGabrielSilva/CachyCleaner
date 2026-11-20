"""GitHub release update checking without blocking the UI."""

from __future__ import annotations

import json
import re
import time
import urllib.request
from dataclasses import dataclass

from PySide6.QtCore import QThread, Signal

GITHUB_REPO = "FernandoGabrielSilva/CachyCleaner"
RELEASES_API = f"https://api.github.com/repos/{GITHUB_REPO}/releases/latest"
RELEASES_PAGE = f"https://github.com/{GITHUB_REPO}/releases/latest"


@dataclass(slots=True)
class UpdateInfo:
    available: bool
    current: str
    latest: str
    url: str
    notes: str = ""
    published: str = ""
    error: str = ""

    def to_dict(self) -> dict[str, object]:
        return {
            "available": self.available,
            "current": self.current,
            "latest": self.latest,
            "url": self.url,
            "notes": self.notes,
            "published": self.published,
            "error": self.error,
        }


def _version_tuple(value: str) -> tuple[int, ...]:
    parts = re.findall(r"\d+", value)
    return tuple(int(p) for p in parts[:4]) or (0,)


class UpdateChecker(QThread):
    finished_check = Signal(object)

    def __init__(self, current_version: str, parent=None) -> None:
        super().__init__(parent)
        self.current_version = current_version

    def run(self) -> None:  # noqa: D102 - Qt override
        info = UpdateInfo(
            available=False,
            current=self.current_version,
            latest=self.current_version,
            url=RELEASES_PAGE,
        )
        try:
            request = urllib.request.Request(
                RELEASES_API,
                headers={
                    "Accept": "application/vnd.github+json",
                    "User-Agent": "CachyCleaner-UpdateChecker",
                },
            )
            with urllib.request.urlopen(request, timeout=10) as response:
                payload = json.loads(response.read().decode("utf-8"))
            latest = str(payload.get("tag_name", "")).lstrip("vV") or self.current_version
            info.latest = latest
            info.available = _version_tuple(latest) > _version_tuple(self.current_version)
            info.notes = str(payload.get("body", ""))
            info.published = str(payload.get("published_at", ""))
            info.url = str(payload.get("html_url", RELEASES_PAGE))
        except Exception as exc:  # noqa: BLE001 - offline is not an error for the user
            info.error = str(exc)
        self.finished_check.emit(info)
