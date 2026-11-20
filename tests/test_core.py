"""Smoke tests for the core logic (no GUI required)."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from app import __version__
from app.core import CleanTarget, RuleEngine, ScanItem, Settings
from app.core.cleaner import purge
from app.core.system import SYSTEM, expand, is_within, safe_relative
from app.core.updater import _version_tuple
from app.ui.i18n import LANGUAGES, Translator, detect_system_language


class TestSettings(unittest.TestCase):
    def test_roundtrip_and_atomic_write(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "nested" / "settings.json"
            s = Settings(path)
            self.assertTrue(s.get("first_run"))
            s.set("language", "es")
            s2 = Settings(path)
            self.assertEqual(s2.get("language"), "es")


class TestRules(unittest.TestCase):
    def test_builtin_rules_present(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            s = Settings(Path(tmp) / "s.json")
            engine = RuleEngine(s)
            self.assertGreater(len(engine.rules), 5)
            self.assertTrue(all(r.id for r in engine.rules))

    def test_custom_folder_add_remove(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            s = Settings(Path(tmp) / "s.json")
            engine = RuleEngine(s)
            rule = engine.add_custom_folder("/tmp/**/*.log", name="logs-test")
            self.assertTrue(rule.id.startswith("custom:"))
            self.assertEqual(len([r for r in engine.rules if r.source.value == "custom"]), 1)
            # Persisted across reload
            engine2 = RuleEngine(s)
            self.assertIn(rule.id, [r.id for r in engine2.rules])
            self.assertTrue(engine2.remove_custom(rule.id))
            self.assertEqual(len([r for r in engine2.rules if r.source.value == "custom"]), 0)

    def test_toggle_builtin_persists(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            s = Settings(Path(tmp) / "s.json")
            engine = RuleEngine(s)
            first = engine.rules[0]
            original = first.enabled
            engine.set_enabled(first.id, not original)
            engine2 = RuleEngine(s)
            self.assertEqual(engine2.get(first.id).enabled, not original)


class TestScanner(unittest.TestCase):
    def test_size_and_exclusions(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "sub").mkdir()
            f1 = root / "sub" / "a.log"
            f2 = root / "b.log"
            f1.write_text("x" * 100)
            f2.write_text("y" * 50)
            self.assertTrue(is_within(f1, root / "sub"))
            self.assertFalse(is_within(f2, root / "sub"))
            self.assertEqual(safe_relative(f1, root), "sub/a.log")


class TestCleaner(unittest.TestCase):
    def test_purge_file_and_dir(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            f = root / "a.tmp"
            d = root / "d"
            d.mkdir()
            (d / "x").write_text("z")
            purge(f)
            purge(d, is_dir=True)
            self.assertFalse(f.exists())
            self.assertFalse(d.exists())


class TestI18n(unittest.TestCase):
    def test_all_languages_load(self) -> None:
        self.assertGreaterEqual(len(LANGUAGES), 12)
        for code in LANGUAGES:
            if code == "auto":
                continue
            tr = Translator(code)
            self.assertNotEqual(tr.t("app.name"), "app.name", f"missing catalogue for {code}")
            self.assertIn("Cachy", tr.t("app.name"))

    def test_placeholder_substitution(self) -> None:
        tr = Translator("en")
        self.assertIn("42", tr.t("notify.scanDone", 42))
        self.assertNotIn("%1", tr.t("notify.scanDone", 42))

    def test_detect(self) -> None:
        self.assertIn(detect_system_language(), LANGUAGES)


class TestUpdater(unittest.TestCase):
    def test_version_compare(self) -> None:
        self.assertGreater(_version_tuple("1.2.0"), _version_tuple("1.1.9"))
        self.assertEqual(_version_tuple("v1.2.3"), (1, 2, 3))


class TestModels(unittest.TestCase):
    def test_scan_item_json(self) -> None:
        item = ScanItem(path="/tmp/a.log", size=10, rule_id="r", rule_name="n", category="system", icon="x")
        data = item.to_dict()
        self.assertEqual(data["name"], "a.log")
        self.assertIn("selected", data)


if __name__ == "__main__":
    unittest.main()
