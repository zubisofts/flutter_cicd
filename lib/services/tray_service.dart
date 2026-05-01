import 'dart:io';
import 'package:tray_manager/tray_manager.dart';

class TrayService with TrayListener {
  bool _initialized = false;

  Future<void> init() async {
    try {
      await trayManager.setIcon('assets/tray/tray_idle.png');
      await trayManager.setToolTip('FlutterCI');
      trayManager.addListener(this);
      _initialized = true;
      await _updateMenu(null);
    } catch (_) {}
  }

  Future<void> setBuilding(String label) async {
    if (!_initialized) return;
    try {
      await trayManager.setIcon('assets/tray/tray_building.png');
      await trayManager.setToolTip('FlutterCI — Building');
      await _updateMenu('Building: $label');
    } catch (_) {}
  }

  Future<void> setSuccess(String label) async {
    if (!_initialized) return;
    try {
      await trayManager.setIcon('assets/tray/tray_success.png');
      await trayManager.setToolTip('FlutterCI — Build Succeeded');
      await _updateMenu('Succeeded: $label');
    } catch (_) {}
  }

  Future<void> setFailed(String label) async {
    if (!_initialized) return;
    try {
      await trayManager.setIcon('assets/tray/tray_failed.png');
      await trayManager.setToolTip('FlutterCI — Build Failed');
      await _updateMenu('Failed: $label');
    } catch (_) {}
  }

  Future<void> setIdle() async {
    if (!_initialized) return;
    try {
      await trayManager.setIcon('assets/tray/tray_idle.png');
      await trayManager.setToolTip('FlutterCI');
      await _updateMenu(null);
    } catch (_) {}
  }

  Future<void> _updateMenu(String? statusLine) async {
    final items = [
      MenuItem(
        key: 'status',
        label: statusLine ?? 'Ready',
        disabled: true,
      ),
      MenuItem.separator(),
      MenuItem(key: 'quit', label: 'Quit FlutterCI'),
    ];
    await trayManager.setContextMenu(Menu(items: items));
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'quit') exit(0);
  }

  @override
  void onTrayIconMouseDown() {}

  @override
  void onTrayIconMouseUp() {}

  @override
  void onTrayIconRightMouseDown() {}

  @override
  void onTrayIconRightMouseUp() {}
}
