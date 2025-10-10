import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

/// 権限状態を管理するサービスクラス
class PermissionService extends ChangeNotifier {
  static PermissionService? _instance;
  bool _hasPermission = false;
  bool _isCheckingPermission = false;

  PermissionService._();

  static PermissionService get instance {
    _instance ??= PermissionService._();
    return _instance!;
  }

  bool get hasPermission => _hasPermission;
  bool get isCheckingPermission => _isCheckingPermission;

  /// 権限を確認し、状態を更新
  Future<bool> checkPermission() async {
    _isCheckingPermission = true;
    notifyListeners();

    try {
      final state = await PhotoManager.requestPermissionExtend();
      _hasPermission = state.isAuth;
      _isCheckingPermission = false;
      notifyListeners();
      return _hasPermission;
    } catch (e) {
      _hasPermission = false;
      _isCheckingPermission = false;
      notifyListeners();
      return false;
    }
  }

  /// 権限状態をリセット
  void resetPermission() {
    _hasPermission = false;
    _isCheckingPermission = false;
    notifyListeners();
  }
}
