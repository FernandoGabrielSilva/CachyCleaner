"""QML bridge: exposes core state and actions as Qt properties/signals."""

from __future__ import annotations

import json
import time
from pathlib import Path
from typing import Any

from PySide6.QtCore import QObject, Property, Signal, Slot
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QmlElement

from .. import __app_name__, __version__
from ..core import (
    CleanTarget,
    CleanWorker,
    RuleEngine,
    ScanWorker,
    Settings,
    UpdateChecker,
)
from ..core.updater import RELEASES_PAGE
from .i18n import LANGUAGES, Translator

QML_IMPORT_NAME = "CachyCleaner"
QML_IMPORT_MAJOR_VERSION = 1


@QmlElement
class AppController(QObject):
    """Single source of truth for the QML frontend."""

    # Global state
    languageChanged = Signal(str)
    themeChanged = Signal(str)
    statusChanged = Signal(str)
    statusDetailChanged = Signal(str)
    busyChanged = Signal(bool)
    scanningChanged = Signal(bool)
    progressChanged = Signal(int)
    toast = Signal(str, str)  # message, type

    # Scan state
    scanResultsChanged = Signal()
    summaryChanged = Signal()
    selectionChanged = Signal()
    searchChanged = Signal(str)

    # Settings state
    rulesChanged = Signal()
    customFoldersChanged = Signal()
    exclusionsChanged = Signal()
    updateInfoChanged = Signal()
    settingsChanged = Signal()

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self.settings = Settings()
        self.translator = Translator(str(self.settings.get("language", "auto")))
        self.engine = RuleEngine(self.settings)

        self._status = "status.ready"
        self._status_detail = ""
        self._busy = False
        self._scanning = False
        self._progress = 0
        self._items: list[Any] = []
        self._selection: set[int] = set()
        self._search = ""
        self._summary: dict[str, Any] = {
            "totalBytes": 0,
            "totalItems": 0,
            "perCategory": {},
            "perCategoryCount": {},
        }
        self._update_info: dict[str, Any] = {}
        self.scan_worker: ScanWorker | None = None
        self.clean_worker: CleanWorker | None = None
        self.update_worker: UpdateChecker | None = None

    # ------------------------------------------------------------------ helpers
    def tr(self, key: str, *args: object) -> str:
        return self.translator.t(key, *args)

    def _human(self, size: float) -> str:
        units = ("common.bytes", "common.kb", "common.mb", "common.gb", "common.tb")
        index = 0
        value = float(size)
        while value >= 1024 and index < len(units) - 1:
            value /= 1024
            index += 1
        formatted = f"{value:.0f}" if index == 0 else f"{value:.1f}"
        return f"{formatted} {self.tr(units[index])}"

    def _set_status(self, key: str, detail: str = "") -> None:
        self._status = key
        self._status_detail = detail
        self.statusChanged.emit()
        self.statusDetailChanged.emit()

    # ------------------------------------------------------------- Qt properties
    def _get_language(self) -> str:
        return self.translator.current

    @Property(str, notify=languageChanged)
    def language(self) -> str:
        return self._get_language()

    @Property(str, notify=themeChanged)
    def theme(self) -> str:
        return str(self.settings.get("theme", "system"))

    @Property(str, constant=True)
    def appName(self) -> str:
        return __app_name__

    @Property(str, constant=True)
    def appVersion(self) -> str:
        return __version__

    @Property(str, constant=True)
    def releasesUrl(self) -> str:
        return RELEASES_PAGE

    @Property(str, notify=statusChanged)
    def status(self) -> str:
        return self.tr(self._status)

    @Property(str, notify=statusDetailChanged)
    def statusDetail(self) -> str:
        return self._status_detail

    @Property(bool, notify=busyChanged)
    def busy(self) -> bool:
        return self._busy

    @Property(bool, notify=scanningChanged)
    def scanning(self) -> bool:
        return self._scanning

    @Property(int, notify=progressChanged)
    def progress(self) -> int:
        return self._progress

    @Property(str, notify=summaryChanged)
    def summaryJson(self) -> str:
        payload = dict(self._summary)
        payload["humanTotal"] = self._human(self._summary.get("totalBytes", 0))
        payload["lastScan"] = self.settings.get("last_scan", 0)
        return json.dumps(payload, ensure_ascii=False)

    @Property(str, notify=scanResultsChanged)
    def resultsJson(self) -> str:
        visible = self._visible_items()
        payload = []
        for item in visible:
            data = item.to_dict()
            data["selected"] = any(
                i < len(self._items) and self._items[i] is item for i in self._selection
            )
            payload.append(data)
        return json.dumps(payload, ensure_ascii=False)

    @Property(str, notify=selectionChanged)
    def selectionJson(self) -> str:
        selected = [self._items[i].to_dict() for i in sorted(self._selection) if i < len(self._items)]
        total = sum(item["size"] for item in selected)
        return json.dumps(
            {"count": len(selected), "bytes": total, "human": self._human(total)},
            ensure_ascii=False,
        )

    @Property(str, notify=rulesChanged)
    def rulesJson(self) -> str:
        rules = self.engine.to_variant_list()
        for rule in rules:
            rule["displayName"] = self.tr(rule["name"])
            rule["displayDescription"] = self.tr(rule["description"])
            rule["displayCategory"] = self.tr(f"category.{rule['category']}")
        return json.dumps(rules, ensure_ascii=False)

    @Property(str, notify=customFoldersChanged)
    def customFoldersJson(self) -> str:
        rules = [r for r in self.engine.rules if r.source.value == "custom"]
        return json.dumps([r.to_dict() for r in rules], ensure_ascii=False)

    @Property(str, notify=exclusionsChanged)
    def exclusionsJson(self) -> str:
        return json.dumps(self.settings.get("exclusions", []), ensure_ascii=False)

    @Property(str, notify=updateInfoChanged)
    def updateInfoJson(self) -> str:
        return json.dumps(self._update_info, ensure_ascii=False)

    @Property(str, notify=languageChanged)
    def languagesJson(self) -> str:
        return json.dumps(self.translator.language_model(), ensure_ascii=False)

    @Property(str, notify=settingsChanged)
    def settingsJson(self) -> str:
        return json.dumps(
            {
                "language": str(self.settings.get("language", "auto")),
                "theme": str(self.settings.get("theme", "system")),
                "useTrash": bool(self.settings.get("use_trash", True)),
                "confirm": bool(self.settings.get("confirm_before_clean", True)),
                "minAge": int(self.settings.get("min_age_days", 0)),
                "autoUpdate": bool(self.settings.get("auto_check_updates", True)),
            },
            ensure_ascii=False,
        )

    # ---------------------------------------------------------------- slots: scan
    @Slot(str, result=str)
    def translate(self, key: str) -> str:
        return self.tr(key)

    @Slot(str, str, result=str)
    def translateArg(self, key: str, arg: str) -> str:
        return self.tr(key, arg)

    @Slot(str, str, str, result=str)
    def translateArgs(self, key: str, arg1: str, arg2: str) -> str:
        return self.tr(key, arg1, arg2)

    @Slot()
    def startScan(self) -> None:
        if self._busy:
            return
        self._items.clear()
        self._selection.clear()
        self.scanResultsChanged.emit()
        self.selectionChanged.emit()
        self._summary = {
            "totalBytes": 0,
            "totalItems": 0,
            "perCategory": {},
            "perCategoryCount": {},
        }
        self.summaryChanged.emit()
        self._busy = True
        self._scanning = True
        self._progress = 0
        self.busyChanged.emit()
        self.scanningChanged.emit()
        self.progressChanged.emit()
        self._set_status("status.scanning")

        self.scan_worker = ScanWorker(
            self.engine,
            exclusions=[str(p) for p in self.settings.get("exclusions", [])],
            min_age_days=int(self.settings.get("min_age_days", 0)),
            parent=self,
        )
        self.scan_worker.item_found.connect(self._on_item_found)
        self.scan_worker.progress.connect(self._on_scan_progress)
        self.scan_worker.finished_scan.connect(self._on_scan_finished)
        self.scan_worker.error.connect(self._on_worker_error)
        self.scan_worker.start()

    @Slot()
    def cancelScan(self) -> None:
        if self.scan_worker and self.scan_worker.isRunning():
            self.scan_worker.cancel()
            self._set_status("status.cancelled")
            self.toast.emit(self.tr("status.cancelled"), "info")

    def _on_item_found(self, item: Any) -> None:
        self._items.append(item)
        self._selection.add(len(self._items) - 1)
        self.scanResultsChanged.emit()
        self.selectionChanged.emit()
        category = item.category
        self._summary["total_bytes"] += item.size
        self._summary["total_items"] += 1
        self._summary["per_category"][category] = self._summary["per_category"].get(category, 0) + item.size
        self._summary["per_category_count"][category] = self._summary["per_category_count"].get(category, 0) + 1
        self.summaryChanged.emit()

    @Slot(int, str)
    def _on_scan_progress(self, value: int, detail: str) -> None:
        self._progress = value
        self.progressChanged.emit()
        self._status_detail = self.tr(detail) if detail.startswith(("rule.", "done")) else detail
        self.statusDetailChanged.emit()

    def _on_scan_finished(self, summary: Any) -> None:
        self._busy = False
        self._scanning = False
        self._progress = 100
        self.busyChanged.emit()
        self.scanningChanged.emit()
        self.progressChanged.emit()
        self.settings.set("last_scan", int(time.time()))
        self._set_status("status.done")
        self.summaryChanged.emit()
        self.toast.emit(self.tr("notify.scanDone", summary.total_items), "success")

    # ---------------------------------------------------------------- slots: clean
    @Slot(str, bool)
    def cleanSelected(self, permanent: str = "false", confirmed: bool = True) -> None:
        """``permanent`` is a string because QML booleans can arrive as strings."""
        if self._busy or not confirmed:
            return
        targets = [
            CleanTarget(
                path=self._items[i].path,
                is_dir=self._items[i].is_dir,
                permanent=str(permanent).lower() in ("true", "1", "yes"),
            )
            for i in sorted(self._selection)
            if i < len(self._items)
        ]
        if not targets:
            return
        use_trash = bool(self.settings.get("use_trash", True))
        self._busy = True
        self._scanning = False
        self._progress = 0
        self.busyChanged.emit()
        self.scanningChanged.emit()
        self.progressChanged.emit()
        self._set_status("status.cleaning")

        self.clean_worker = CleanWorker(targets, use_trash=use_trash, parent=self)
        self.clean_worker.progress.connect(self._on_clean_progress)
        self.clean_worker.item_done.connect(self._on_item_cleaned)
        self.clean_worker.finished_clean.connect(self._on_clean_finished)
        self.clean_worker.error.connect(self._on_worker_error)
        self.clean_worker.start()

    @Slot()
    def cancelClean(self) -> None:
        if self.clean_worker and self.clean_worker.isRunning():
            self.clean_worker.cancel()
            self._set_status("status.cancelled")

    @Slot(int, int, str)
    def _on_clean_progress(self, current: int, total: int, path: str) -> None:
        self._progress = int(current / max(1, total) * 100)
        self.progressChanged.emit()
        self._status_detail = Path(path).name
        self.statusDetailChanged.emit()

    def _on_item_cleaned(self, result: Any) -> None:
        # Remove cleaned items from the visible list and selection.
        remaining: list[Any] = []
        old_to_new: dict[int, int] = {}
        for old_index, item in enumerate(self._items):
            if item.path == result.path and result.success:
                continue
            old_to_new[old_index] = len(remaining)
            remaining.append(item)
        self._items = remaining
        self._selection = {old_to_new[i] for i in self._selection if i in old_to_new}
        self.scanResultsChanged.emit()
        self.selectionChanged.emit()

    def _on_clean_finished(self, succeeded: int, failed: int, skipped: int) -> None:
        self._busy = False
        self._progress = 100
        self.busyChanged.emit()
        self.progressChanged.emit()
        self._set_status("status.done")
        remaining = len(self._items)
        self.toast.emit(self.tr("notify.cleanDone", f"{remaining} {self.tr('dashboard.items').lower()}"), "success")

    @Slot(str)
    def _on_worker_error(self, message: str) -> None:
        self._busy = False
        self._scanning = False
        self.busyChanged.emit()
        self.scanningChanged.emit()
        self._set_status("status.ready", message)
        self.toast.emit(f"{self.tr('common.error')}: {message}", "error")

    # --------------------------------------------------------------- slots: items
    @Slot(int, bool)
    def setItemSelected(self, index: int, selected: bool) -> None:
        visible = self._visible_items()
        if 0 <= index < len(visible):
            target = visible[index]
            for i, item in enumerate(self._items):
                if item is target:
                    if selected:
                        self._selection.add(i)
                    else:
                        self._selection.discard(i)
                    break
            self.selectionChanged.emit()
        self.scanResultsChanged.emit()

    @Slot(str, bool)
    def setItemSelectedByPath(self, path: str, selected: bool) -> None:
        for i, item in enumerate(self._items):
            if item.path == path:
                if selected:
                    self._selection.add(i)
                else:
                    self._selection.discard(i)
                break
        self.selectionChanged.emit()
        self.scanResultsChanged.emit()

    @Slot()
    def selectAll(self) -> None:
        self._selection = {i for i in range(len(self._items))}
        self.selectionChanged.emit()
        self.scanResultsChanged.emit()

    @Slot()
    def clearSelection(self) -> None:
        self._selection.clear()
        self.selectionChanged.emit()
        self.scanResultsChanged.emit()

    @Slot(str)
    def setSearch(self, query: str) -> None:
        self._search = query.strip().lower()
        self.searchChanged.emit()
        self.scanResultsChanged.emit()

    def _visible_items(self) -> list[Any]:
        if not self._search:
            return list(self._items)
        return [
            item
            for item in self._items
            if self._search in item.path.lower()
            or self._search in item.rule_name.lower()
            or self._search in item.category.lower()
        ]

    # ------------------------------------------------------------ slots: settings
    @Slot(str)
    def setLanguage(self, code: str) -> None:
        self.settings.set("language", code)
        self.translator.set_language(code)
        self.settingsChanged.emit()
        self.languageChanged.emit()
        self.rulesChanged.emit()
        self.summaryChanged.emit()
        self._set_status(self._status)

    @Slot(str)
    def setTheme(self, theme: str) -> None:
        self.settings.set("theme", theme)
        self.settingsChanged.emit()
        self._apply_theme()
        self.themeChanged.emit()

    def _apply_theme(self) -> None:
        theme = str(self.settings.get("theme", "system"))
        app = QGuiApplication.instance()
        if app is None:
            return
        # QML handles the palette; this keeps native dialogs consistent.
        from PySide6.QtCore import Qt

        if theme == "light":
            app.styleHints().setColorScheme(Qt.ColorScheme.Light)
        elif theme == "dark":
            app.styleHints().setColorScheme(Qt.ColorScheme.Dark)
        else:
            app.styleHints().setColorScheme(Qt.ColorScheme.Unknown)

    @Property(str, notify=themeChanged)
    def effectiveTheme(self) -> str:
        """Resolved theme: 'dark' or 'light' (defaults to dark)."""
        theme = str(self.settings.get("theme", "dark"))
        if theme in ("dark", "light"):
            return theme
        app = QGuiApplication.instance()
        if app is not None:
            from PySide6.QtCore import Qt

            if app.styleHints().colorScheme() == Qt.ColorScheme.Light:
                return "light"
        return "dark"

    @Slot(bool)
    def setUseTrash(self, value: bool) -> None:
        self.settings.set("use_trash", value)
        self.settingsChanged.emit()

    @Slot(bool)
    def setConfirm(self, value: bool) -> None:
        self.settings.set("confirm_before_clean", value)
        self.settingsChanged.emit()

    @Slot(int)
    def setMinAge(self, days: int) -> None:
        self.settings.set("min_age_days", max(0, days))
        self.settingsChanged.emit()

    @Slot(bool)
    def setAutoUpdate(self, value: bool) -> None:
        self.settings.set("auto_check_updates", value)
        self.settingsChanged.emit()

    @Slot(str, bool)
    def setRuleEnabled(self, rule_id: str, enabled: bool) -> None:
        self.engine.set_enabled(rule_id, enabled)
        self.rulesChanged.emit()

    @Slot(str, int)
    def setRuleMinAge(self, rule_id: str, days: int) -> None:
        self.engine.set_min_age(rule_id, days)
        self.rulesChanged.emit()

    @Slot(str, str, str, int, result=bool)
    def addCustomFolder(self, path: str, pattern: str, category: str, min_age: int) -> bool:
        if not path.strip():
            return False
        full = path if any(ch in path for ch in "*?[") else str(Path(path) / (pattern or "*"))
        self.engine.add_custom_folder(full, category=category or "custom", min_age=min_age)
        self.rulesChanged.emit()
        self.customFoldersChanged.emit()
        return True

    @Slot(str)
    def removeCustomFolder(self, rule_id: str) -> None:
        self.engine.remove_custom(rule_id)
        self.rulesChanged.emit()
        self.customFoldersChanged.emit()

    @Slot(str, result=bool)
    def addExclusion(self, path: str) -> bool:
        if not path.strip():
            return False
        exclusions = list(self.settings.get("exclusions", []))
        if path not in exclusions:
            exclusions.append(path)
            self.settings.set("exclusions", exclusions)
        self.exclusionsChanged.emit()
        return True

    @Slot(str)
    def removeExclusion(self, path: str) -> None:
        exclusions = [p for p in self.settings.get("exclusions", []) if p != path]
        self.settings.set("exclusions", exclusions)
        self.exclusionsChanged.emit()

    @Slot()
    def resetSettings(self) -> None:
        self.settings.reset()
        self.engine.reload()
        self.translator.set_language("auto")
        self._apply_theme()
        for signal in (
            self.languageChanged,
            self.rulesChanged,
            self.customFoldersChanged,
            self.exclusionsChanged,
            self.themeChanged,
        ):
            signal.emit()
        self._set_status("status.ready")
        self.toast.emit(self.tr("common.success"), "success")

    # ------------------------------------------------------------ slots: updates
    @Slot()
    def checkForUpdates(self) -> None:
        if self.update_worker and self.update_worker.isRunning():
            return
        self.update_worker = UpdateChecker(__version__, parent=self)
        self.update_worker.finished_check.connect(self._on_update_info)
        self.update_worker.start()

    def _on_update_info(self, info: Any) -> None:
        self._update_info = info.to_dict()
        self.updateInfoChanged.emit()
        self.settings.set("last_update_check", int(time.time()))
        if info.error:
            self.toast.emit(self.tr("settings.updateFailed", info.error), "error")
        elif info.available:
            self.toast.emit(self.tr("settings.updateAvailable", info.latest), "info")

    @Slot()
    def openReleases(self) -> None:
        from PySide6.QtGui import QDesktopServices
        from PySide6.QtCore import QUrl

        QDesktopServices.openUrl(QUrl(RELEASES_PAGE))

    @Slot()
    def openCustomFolderDialog(self) -> None:
        """Ask QML to open a native folder dialog (signal bridge)."""
        self.toast.emit(self.tr("settings.foldersHint"), "info")
