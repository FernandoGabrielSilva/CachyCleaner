"""Built-in cleanup rules plus persistence of user-defined folders."""

from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any

from .models import Rule, RuleSource, TargetKind
from .settings import Settings
from .system import SYSTEM, home, temp_dir, xdg

CATEGORIES = ("system", "browser", "development", "media", "package", "custom")


def _path(*parts: str) -> str:
    return str(Path(*parts))


def builtin_rules() -> list[Rule]:
    """Return platform-aware default rules.

    Patterns are intentionally conservative: they target caches and temporary
    data only, never documents or user-created content. Each rule can be
    toggled from the UI.
    """
    cache = xdg("cache", ".cache")
    data = xdg("data", ".local/share")
    config = xdg("config", ".config")
    tmp = temp_dir()
    h = home()
    rules: list[Rule] = []

    def add(
        rid: str,
        name: str,
        desc: str,
        paths: list[str],
        *,
        kind: TargetKind = TargetKind.GLOB,
        category: str = "system",
        icon: str = "broom",
        min_age: int = 0,
        recursive: bool = True,
    ) -> None:
        rules.append(
            Rule(
                id=rid,
                name_key=name,
                description_key=desc,
                paths=paths,
                kind=kind,
                category=category,
                icon=icon,
                min_age_days=min_age,
                recursive=recursive,
            )
        )

    # ---------------------------------------------------------------- Linux
    if SYSTEM == "linux":
        add(
            "linux-thumbnails",
            "rule.thumbnails",
            "rule.thumbnails.desc",
            [_path(str(cache), "thumbnails", "*")],
            category="media",
            icon="image",
        )
        add(
            "linux-trash-expired",
            "rule.trash",
            "rule.trash.desc",
            [_path(str(data), "Trash", "*")],
            category="system",
            icon="trash",
            min_age=30,
        )
        add(
            "linux-tmp",
            "rule.temp",
            "rule.temp.desc",
            [_path(str(tmp), "*.tmp"), _path(str(tmp), "*.log"), _path(str(tmp), ".org.chromium.*")],
            category="system",
            icon="timer",
        )
        add(
            "linux-pip-cache",
            "rule.pip",
            "rule.pip.desc",
            [_path(str(cache), "pip", "**", "*.whl")],
            category="development",
            icon="code",
        )
        add(
            "linux-npm-cache",
            "rule.npm",
            "rule.npm.desc",
            [_path(str(cache), "npm", "_cacache"), _path(str(cache), "yarn")],
            kind=TargetKind.DIRECTORY,
            category="development",
            icon="code",
        )
        add(
            "linux-meson-cache",
            "rule.build_cache",
            "rule.build_cache.desc",
            [_path(str(cache), "meson"), _path(str(cache), "ccache")],
            kind=TargetKind.DIRECTORY,
            category="development",
            icon="code",
        )
        add(
            "linux-pacman-cache",
            "rule.pacman",
            "rule.pacman.desc",
            ["/var/cache/pacman/pkg/*.pkg.tar.*"],
            category="package",
            icon="package",
            min_age=7,
        )
        add(
            "linux-apt-cache",
            "rule.apt",
            "rule.apt.desc",
            ["/var/cache/apt/archives/*.deb", "/var/cache/apt/archives/partial/*"],
            category="package",
            icon="package",
            min_age=7,
        )
        add(
            "linux-flatpak",
            "rule.flatpak",
            "rule.flatpak.desc",
            [_path(str(config), "flatpak", "cache", "*")],
            category="package",
            icon="package",
        )
        add(
            "linux-crash-reports",
            "rule.crash",
            "rule.crash.desc",
            [_path(str(config), "systemd", "coredump", "*")],
            category="system",
            icon="alert",
        )

    # --------------------------------------------------------------- macOS
    elif SYSTEM == "darwin":
        add(
            "mac-user-cache",
            "rule.user_cache",
            "rule.user_cache.desc",
            [_path(str(cache), "*")],
            category="system",
            icon="broom",
        )
        add(
            "mac-dev-caches",
            "rule.dev_caches",
            "rule.dev_caches.desc",
            [_path(str(cache), "npm"), _path(str(cache), "pip"), _path(str(cache), "Homebrew")],
            kind=TargetKind.DIRECTORY,
            category="development",
            icon="code",
        )
        add(
            "mac-logs",
            "rule.logs",
            "rule.logs.desc",
            [_path("Library", "Logs", "*.log")],
            category="system",
            icon="list",
        )

    # ------------------------------------------------------------- Windows
    elif SYSTEM == "windows":
        local = Path(os.environ.get("LOCALAPPDATA", home() / "AppData" / "Local"))
        add(
            "win-temp",
            "rule.temp",
            "rule.temp.desc",
            [_path(str(local), "Temp", "*.tmp"), _path(str(tmp), "*.tmp")],
            category="system",
            icon="timer",
        )
        add(
            "win-thumbnails",
            "rule.thumbnails",
            "rule.thumbnails.desc",
            [_path(str(local), "Microsoft", "Windows", "Explorer", "thumbcache_*.db")],
            category="media",
            icon="image",
        )
        add(
            "win-npm-cache",
            "rule.npm",
            "rule.npm.desc",
            [_path(str(local), "npm-cache")],
            kind=TargetKind.DIRECTORY,
            category="development",
            icon="code",
        )

    # --------------------------------------------------------- Cross-platform
    add(
        "browser-chromium-cache",
        "rule.browser_cache",
        "rule.browser_cache.desc",
        [
            _path(str(cache), "chromium", "Default", "Cache", "*"),
            _path(str(cache), "google-chrome", "Default", "Cache", "*"),
            _path(str(cache), "brave", "Default", "Cache", "*"),
        ],
        category="browser",
        icon="globe",
    )
    add(
        "browser-firefox-cache",
        "rule.browser_cache",
        "rule.browser_cache.desc",
        [_path(str(cache), "mozilla", "firefox", "profiles", "*.default-release", "cache2", "entries", "*")],
        category="browser",
        icon="globe",
    )
    add(
        "editor-caches",
        "rule.editor_cache",
        "rule.editor_cache.desc",
        [
            _path(str(config), "Code", "Caches", "*"),
            _path(str(config), "Code - OSS", "Caches", "*"),
            _path(str(config), "JetBrains", "*caches*"),
        ],
        category="development",
        icon="code",
    )
    add(
        "old-log-files",
        "rule.old_logs",
        "rule.old_logs.desc",
        [_path(str(cache), "**", "*.log")],
        category="system",
        icon="list",
        min_age=7,
    )

    return rules


class RuleEngine:
    """Merges built-in rules with user customizations and custom folders."""

    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self._rules: dict[str, Rule] = {}
        self.reload()

    def reload(self) -> None:
        merged: dict[str, Rule] = {rule.id: rule for rule in builtin_rules()}

        for rid, payload in self.settings.get("rule_overrides", {}).items():
            if rid in merged and isinstance(payload, dict):
                current = merged[rid]
                merged[rid] = Rule(
                    id=current.id,
                    name_key=current.name_key,
                    description_key=current.description_key,
                    paths=current.paths,
                    kind=current.kind,
                    enabled=bool(payload.get("enabled", current.enabled)),
                    source=current.source,
                    min_age_days=int(payload.get("min_age_days", current.min_age_days)),
                    category=current.category,
                    icon=current.icon,
                    recursive=current.recursive,
                )

        custom: list[dict[str, Any]] = self.settings.get("custom_folders", [])
        for entry in custom:
            try:
                rule = Rule.from_dict(entry)
            except (KeyError, ValueError, TypeError):
                continue
            rule.source = RuleSource.CUSTOM
            if not rule.id.startswith("custom:"):
                rule.id = f"custom:{rule.id}"
            merged[rule.id] = rule

        self._rules = merged

    @property
    def rules(self) -> list[Rule]:
        return sorted(self._rules.values(), key=lambda r: (r.source != "builtin", r.id))

    def active_rules(self) -> list[Rule]:
        return [rule for rule in self.rules if rule.enabled]

    def get(self, rule_id: str) -> Rule | None:
        return self._rules.get(rule_id)

    def set_enabled(self, rule_id: str, enabled: bool) -> None:
        rule = self._rules.get(rule_id)
        if rule is None:
            return
        rule.enabled = enabled
        if rule.source is RuleSource.BUILTIN:
            overrides = dict(self.settings.get("rule_overrides", {}))
            overrides[rule_id] = {"enabled": enabled, "min_age_days": rule.min_age_days}
            self.settings.set("rule_overrides", overrides)
        else:
            self._update_custom(rule_id, rule)

    def set_min_age(self, rule_id: str, days: int) -> None:
        rule = self._rules.get(rule_id)
        if rule is None:
            return
        rule.min_age_days = max(0, days)
        if rule.source is RuleSource.BUILTIN:
            overrides = dict(self.settings.get("rule_overrides", {}))
            overrides[rule_id] = {"enabled": rule.enabled, "min_age_days": rule.min_age_days}
            self.settings.set("rule_overrides", overrides)
        else:
            self._update_custom(rule_id, rule)

    def add_custom_folder(
        self,
        path: str,
        *,
        pattern: str = "*",
        category: str = "custom",
        min_age: int = 0,
        name: str = "",
    ) -> Rule:
        """Add a user folder. ``path`` may contain glob patterns."""
        from .system import sanitize_component

        rid = f"custom:{sanitize_component(name or Path(path).name or path)}"
        counter = 1
        while rid in self._rules:
            counter += 1
            rid = f"custom:{sanitize_component(name or Path(path).name or path)}-{counter}"

        full_pattern = path if any(ch in path for ch in "*?[") else str(Path(path) / pattern)
        rule = Rule(
            id=rid,
            name_key=name or f"custom:{Path(path).name or path}",
            description_key="custom.description",
            paths=[full_pattern],
            kind=TargetKind.GLOB,
            enabled=True,
            source=RuleSource.CUSTOM,
            min_age_days=max(0, min_age),
            category=category,
            icon="folder",
        )
        self._rules[rid] = rule
        self._persist_custom()
        return rule

    def remove_custom(self, rule_id: str) -> bool:
        rule = self._rules.get(rule_id)
        if rule is None or rule.source is not RuleSource.CUSTOM:
            return False
        del self._rules[rule_id]
        self._persist_custom()
        return True

    def _update_custom(self, rule_id: str, rule: Rule) -> None:
        self._rules[rule_id] = rule
        self._persist_custom()

    def _persist_custom(self) -> None:
        custom = [r.to_dict() for r in self._rules.values() if r.source is RuleSource.CUSTOM]
        self.settings.set("custom_folders", custom)

    def to_variant_list(self) -> list[dict[str, Any]]:
        """Serialize for QML."""
        return [
            {
                "id": r.id,
                "name": r.name_key,
                "description": r.description_key,
                "paths": r.paths,
                "kind": r.kind.value,
                "enabled": r.enabled,
                "source": r.source.value,
                "minAgeDays": r.min_age_days,
                "category": r.category,
                "icon": r.icon,
            }
            for r in self.rules
        ]
