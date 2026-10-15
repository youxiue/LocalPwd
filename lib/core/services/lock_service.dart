import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../constants/app_constants.dart';
import 'auth_service.dart';
import 'clipboard_service.dart';

/// 自动锁定服务：监控 App 生命周期，超时自动锁定 + 遮罩
class LockService with WidgetsBindingObserver {
  LockService._();
  static final LockService instance = LockService._();

  static const _channel = MethodChannel('com.localpwd.local_pwd/secure');

  final _auth = AuthService.instance;
  Timer? _lockTimer;
  Timer? _maskTimer;
  DateTime? _pausedTime;

  /// 定时器代次：回到前台或锁定时递增，
  /// 用于丢弃仍在异步读取配置过程中的过期定时任务（防止回前台后误锁定）
  int _timerEpoch = 0;

  /// 遮罩可见性（退后台时显示，回前台时隐藏）
  final isMasked = false.obs;

  void init() {
    WidgetsBinding.instance.addObserver(this);
    // 监听原生锁屏广播，锁屏后立即要求重新解锁
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  Future<dynamic> _handleNativeCall(MethodCall call) async {
    if (call.method == 'onScreenLocked') {
      lockNow();
    }
    return null;
  }

  /// 手机锁屏或超时时立即锁定：清空密钥/剪贴板并跳转到解锁页
  void lockNow() {
    _lockAndRoute();
  }

  /// 锁定应用的唯一入口：清密钥、清剪贴板、跳转解锁页
  void _lockAndRoute() {
    _timerEpoch++; // 使挂起的定时任务全部失效
    _lockTimer?.cancel();
    _lockTimer = null;
    _maskTimer?.cancel();
    _pausedTime = null;
    _auth.lock();
    ClipboardService.instance.clear();
    isMasked.value = false;
    try {
      if (Get.currentRoute != AppConstants.routeUnlock) {
        Get.offAllNamed(AppConstants.routeUnlock);
      }
    } catch (_) {
      // 导航上下文不可用时忽略
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _channel.setMethodCallHandler(null);
    _lockTimer?.cancel();
    _maskTimer?.cancel();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        // 延迟 200ms 显示遮罩，避免对话框/键盘导致的闪烁
        _maskTimer?.cancel();
        _maskTimer = Timer(const Duration(milliseconds: 200), () {
          isMasked.value = true;
        });
        break;
      case AppLifecycleState.paused:
        _maskTimer?.cancel();
        isMasked.value = true;
        _pausedTime = DateTime.now();
        _startLockTimer();
        break;
      case AppLifecycleState.resumed:
        // 递增代次：使后台期间尚未完成配置读取的定时任务失效，
        // 否则回到前台后会突然弹出一个迟到的锁定，表现为"用着用着要求重新验证"
        _timerEpoch++;
        _maskTimer?.cancel();
        _lockTimer?.cancel();
        _lockTimer = null;
        if (_pausedTime != null) {
          _checkLockTime();
        } else {
          // 仅对话框/键盘触发的 inactive → resumed，无需解锁
          isMasked.value = false;
        }
        break;
      default:
        break;
    }
  }

  void _startLockTimer() {
    final epoch = _timerEpoch;
    _auth.getAutoLockMinutes().then((minutes) {
      _scheduleLockTimer(epoch, Duration(minutes: minutes));
    }).catchError((_) {
      // 读取配置失败时使用默认值
      _scheduleLockTimer(
          epoch, Duration(minutes: AppConstants.defaultAutoLockMinutes));
    });
  }

  /// 仅当代次未变化（期间没有回前台/锁定）时才真正挂上定时器，
  /// 且回调触发时应用必须仍处于后台，避免在前台使用中误锁定
  void _scheduleLockTimer(int epoch, Duration duration) {
    if (epoch != _timerEpoch) return;
    _lockTimer = Timer(duration, () {
      if (epoch != _timerEpoch) return;
      final state = WidgetsBinding.instance.lifecycleState;
      if (state != AppLifecycleState.paused) return;
      _lockAndRoute();
    });
  }

  void _checkLockTime() async {
    if (_pausedTime == null) return;
    try {
      final minutes = await _auth.getAutoLockMinutes();
      final elapsed = DateTime.now().difference(_pausedTime!);
      if (elapsed.inMinutes >= minutes) {
        _lockAndRoute();
        await Future.delayed(const Duration(milliseconds: 100));
      }
      _pausedTime = null;
      isMasked.value = false;
    } catch (_) {
      _pausedTime = null;
      isMasked.value = false;
    }
  }
}
