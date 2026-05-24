# -*- mode: python ; coding: utf-8 -*-

from PyInstaller.utils.hooks import collect_data_files

mediapipe_datas = collect_data_files('mediapipe')

a = Analysis(
    ['app.py'],
    pathex=[],
    binaries=[],
    datas=[('videos', 'videos'), ('audio', 'audio'), ('images', 'images')] + mediapipe_datas,
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    noarchive=False,
    optimize=0,
)
pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    name='MirrorMove PD',
    exclude_binaries=True,
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    upx_exclude=[],
    runtime_tmpdir=None,
    console=False,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
    icon=['mirrormovepd.ico'],
)
coll = COLLECT(
    exe,
    a.binaries,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='MirrorMove PD',
)
app = BUNDLE(
    coll,
    name='MirrorMove PD.app',
    icon='mirrormovepd.ico',
    bundle_identifier='com.mirrormotion.mirrormovepd',
    info_plist={
        'CFBundleDisplayName': 'MirrorMove PD',
        'NSCameraUsageDescription': 'MirrorMove PD uses the camera to mirror your movement during dance sessions.',
        'NSMicrophoneUsageDescription': 'MirrorMove PD may use audio access for session playback.',
    },
)
