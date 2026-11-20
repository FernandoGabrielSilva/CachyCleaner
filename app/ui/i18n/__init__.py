"""Translation catalogues and language detection."""

from .translator import Translator, LANGUAGES, detect_system_language

__all__ = ["Translator", "LANGUAGES", "detect_system_language"]
