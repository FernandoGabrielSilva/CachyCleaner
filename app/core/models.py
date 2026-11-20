"""Dataclasses shared across the core and the UI bridge."""

from __future__ import annotations

from dataclasses import dataclass, field
from enum import Enum
from pathlib import Path
from typing import Any


class TargetKind(str, Enum):
    """What kind of filesystem entry a rule points at."""

    FILE = "file"
    DIRECTORY = "directory"
    GLOB = "glob"


class RuleSource(str, Enum):
    """Whether a rule ships with the app or was added by the user."""

    BUILTIN = "builtin"
    CUSTOM = "custom"


@dataclass(slots=True)
class Rule:
    """A declarative description of something that can be cleaned."""

    id: str
    name_key: str
    description_key: str
    paths: list[str]
    kind: TargetKind = TargetKind.GLOB
    enabled: bool = True
    source: RuleSource = RuleSource.BUILTIN
    min_age_days: int = 0
    category: str = "system"
    icon: str = "folder"
    recursive: bool = True

    def to_dict(self) -> dict[str, Any]:
        return {
            "id": self.id,
            "name_key": self.name_key,
            "description_key": self.description_key,
            "paths": list(self.paths),
            "kind": self.kind.value,
            "enabled": self.enabled,
            "source": self.source.value,
            "min_age_days": self.min_age_days,
            "category": self.category,
            "icon": self.icon,
            "recursive": self.recursive,
        }

    @classmethod
    def from_dict(cls, data: dict[str, Any]) -> "Rule":
        return cls(
            id=str(data["id"]),
            name_key=str(data.get("name_key", "custom.name")),
            description_key=str(data.get("description_key", "custom.description")),
            paths=[str(p) for p in data.get("paths", [])],
            kind=TargetKind(str(data.get("kind", "glob"))),
            enabled=bool(data.get("enabled", True)),
            source=RuleSource(str(data.get("source", "custom"))),
            min_age_days=int(data.get("min_age_days", 0)),
            category=str(data.get("category", "custom")),
            icon=str(data.get("icon", "folder")),
            recursive=bool(data.get("recursive", True)),
        )


@dataclass(slots=True)
class ScanItem:
    """One concrete file/folder found by the scanner."""

    path: str
    size: int
    rule_id: str
    rule_name: str
    category: str
    icon: str
    modified: float = 0.0
    selected: bool = True
    is_dir: bool = False

    def to_dict(self) -> dict[str, Any]:
        return {
            "path": self.path,
            "name": Path(self.path).name or self.path,
            "size": self.size,
            "ruleId": self.rule_id,
            "ruleName": self.rule_name,
            "category": self.category,
            "icon": self.icon,
            "modified": self.modified,
            "selected": self.selected,
            "isDir": self.is_dir,
        }


@dataclass(slots=True)
class CleanTarget:
    """A single item passed to the cleaner."""

    path: str
    is_dir: bool = False
    permanent: bool = False


@dataclass(slots=True)
class TrashResult:
    """Result of trying to move one item to the trash."""

    path: str
    success: bool
    method: str = ""
    error: str = ""


@dataclass(slots=True)
class ScanSummary:
    """Aggregated statistics for a finished scan."""

    total_bytes: int = 0
    total_items: int = 0
    per_category: dict[str, int] = field(default_factory=dict)
    per_category_count: dict[str, int] = field(default_factory=dict)

    def to_dict(self) -> dict[str, Any]:
        return {
            "totalBytes": self.total_bytes,
            "totalItems": self.total_items,
            "perCategory": dict(self.per_category),
            "perCategoryCount": dict(self.per_category_count),
        }
