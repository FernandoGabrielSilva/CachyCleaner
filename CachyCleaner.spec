# -*- mode: python ; coding: utf-8 -*-
"""PyInstaller spec: bundles QML, translations, icon and send2trash."""

from PyInstaller.utils.hooks import collect_data_files

datas = []
datas += collect_data_files("PySide6", includes=["qt/plugins/platforms/*", "qt/qml/QtQuick/**", "qt/qml/QtQml/**", "qt/qml/QtCore/**"])

# Explicit project assets (also works when hooks miss something).
datas += [
    ("app/ui/qml", "app/ui/qml"),
    ("app/ui/i18n", "app/ui/i18n"),
    ("app/assets", "app/assets"),
]

block_cipher = None

a = Analysis(
    ["run.py"],
    pathex=[],
    binaries=[],
    datas=datas,
    hiddenimports=[
        "PySide6.QtCore",
        "PySide6.QtGui",
        "PySide6.QtQml",
        "PySide6.QtQuick",
        "PySide6.QtQuickControls2",
        "PySide6.QtSvg",
        "send2trash",
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=["tkinter", "matplotlib", "numpy", "pandas"],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name="CachyCleaner",
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,
    icon="app/assets/icon.ico" if __import__("os").path.exists("app/assets/icon.ico") else None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name="CachyCleaner",
)

import sys

if sys.platform == "darwin":
    app = BUNDLE(
        coll,
        name="CachyCleaner.app",
        icon="app/assets/icon.icns" if __import__("os").path.exists("app/assets/icon.icns") else None,
        bundle_identifier="com.fernandogabriel.cachycleaner",
        info_plist={
            "CFBundleDisplayName": "CachyCleaner",
            "CFBundleShortVersionString": "1.0.0",
            "CFBundleVersion": "1.0.0",
            "NSHighResolutionCapable": True,
        },
    )
