import 'package:flutter/material.dart';
import '../services/toast_service.dart';

extension ToastContext on BuildContext {
  // Convenience methods to show toasts directly from context
  void showToast(String message, {
    Duration? duration,
    Color? backgroundColor,
    Color? textColor,
    ToastPosition? position,
  }) {
    ToastService().show(
      this,
      message,
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: backgroundColor ?? Colors.black87,
      textColor: textColor ?? Colors.white,
      position: position ?? ToastPosition.bottom,
    );
  }

  void showSuccessToast(String message) {
    ToastService().showSuccess(this, message);
  }

  void showErrorToast(String message) {
    ToastService().showError(this, message);
  }

  void showWarningToast(String message) {
    ToastService().showWarning(this, message);
  }

  void hideToast() {
    ToastService().hide();
  }
}
