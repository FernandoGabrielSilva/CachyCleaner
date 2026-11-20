"""Runtime translator with locale detection and graceful fallbacks."""

from __future__ import annotations

import json
import locale
import os
from pathlib import Path

LANGUAGES: dict[str, str] = {
    "auto": "Automático / Auto",
    "pt_BR": "Português (Brasil)",
    "en": "English",
    "es": "Español",
    "fr": "Français",
    "de": "Deutsch",
    "it": "Italiano",
    "ja": "日本語",
    "ko": "한국어",
    "zh_CN": "简体中文",
    "ru": "Русский",
    "hi": "हिन्दी",
    "ar": "العربية",
}

_I18N_DIR = Path(__file__).parent
_FALLBACK = "en"


def detect_system_language() -> str:
    """Best-effort detection from environment and locale."""
    candidates: list[str] = []
    for env in ("LC_ALL", "LC_MESSAGES", "LANG", "LANGUAGE"):
        value = os.environ.get(env)
        if value:
            candidates.append(value)
    try:
        candidates.append(locale.getlocale(locale.LC_MESSAGES)[0] or "")
    except Exception:
        pass

    for raw in candidates:
        code = raw.split(".")[0].replace("-", "_")
        base = code.split("_")[0].lower()
        if base == "pt":
            return "pt_BR"
        if base in LANGUAGES and base != "auto":
            if base == "zh":
                return "zh_CN"
            return base
    return _FALLBACK


class Translator:
    """Loads JSON catalogues and translates keys with ``%1`` placeholders."""

    def __init__(self, language: str = "auto") -> None:
        self._catalogues: dict[str, dict[str, str]] = {}
        self._cache: dict[str, str] = {}
        self.language = "en"
        self.set_language(language)

    def set_language(self, language: str) -> None:
        resolved = detect_system_language() if language == "auto" else language
        if resolved not in LANGUAGES:
            resolved = _FALLBACK
        self.language = resolved
        self._cache.clear()
        for code in dict.fromkeys([resolved, "pt_BR", _FALLBACK]):
            if code in self._catalogues:
                continue
            path = _I18N_DIR / f"{code}.json"
            try:
                self._catalogues[code] = json.loads(path.read_text(encoding="utf-8"))
            except (OSError, json.JSONDecodeError):
                self._catalogues[code] = {}

    @property
    def current(self) -> str:
        return self.language

    def t(self, key: str, *args: object) -> str:
        cached = self._cache.get(key)
        if cached is None:
            for code in dict.fromkeys([self.language, "pt_BR", _FALLBACK]):
                value = self._catalogues.get(code, {}).get(key)
                if value is not None:
                    cached = value
                    break
            if cached is None:
                cached = key
            self._cache[key] = cached
        text = cached
        for index, arg in enumerate(args, start=1):
            text = text.replace(f"%{index}", str(arg))
        return text

    def language_model(self) -> list[dict[str, str]]:
        return [{"code": code, "name": name} for code, name in LANGUAGES.items()]
