"""CachyCleaner entry point.

Runs the Qt Quick frontend with the Python controller exposed as a QML type.
"""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

# Allow running from source: python -m app.main
if __package__ in (None, ""):
    sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from PySide6.QtCore import Qt, QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine

from app import __app_name__, __version__
from app.ui.controller import AppController  # noqa: F401 - registers QmlElement


def resource_root() -> Path:
    """Return the directory containing the QML files (source or frozen)."""
    frozen = getattr(sys, "_MEIPASS", None)
    if frozen:
        return Path(frozen) / "app" / "ui" / "qml"
    return Path(__file__).resolve().parent / "ui" / "qml"


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(prog="cachycleaner")
    parser.add_argument("--version", action="version", version=f"{__app_name__} {__version__}")
    parser.add_argument("--no-update", action="store_true", help="do not check for updates on startup")
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv if argv is not None else sys.argv[1:])

    # High-DPI support on all platforms.
    os.environ.setdefault("QT_ENABLE_HIGHDPI_SCALING", "1")
    QGuiApplication.setHighDpiScaleFactorRoundingPolicy(
        Qt.HighDpiScaleFactorRoundingPolicy.PassThrough
    )

    app = QGuiApplication(sys.argv)
    app.setApplicationName(__app_name__)
    app.setApplicationVersion(__version__)
    app.setOrganizationName("CachyCleaner")

    icon_path = Path(__file__).resolve().parent / "assets" / "icon.svg"
    if icon_path.exists():
        app.setWindowIcon(QIcon(str(icon_path)))

    controller = AppController()
    if args.no_update:
        controller.settings.set("auto_check_updates", False)
    controller._apply_theme()

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("appController", controller)
    qml_root = resource_root() / "main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_root)))

    if not engine.rootObjects():
        print(f"Failed to load QML: {qml_root}", file=sys.stderr)
        return 1

    return app.exec()


if __name__ == "__main__":
    raise SystemExit(main())
