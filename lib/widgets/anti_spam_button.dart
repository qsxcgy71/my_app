import 'package:flutter/material.dart';

/// 防止快速多次点击的按钮组件
class AntiSpamButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Duration debounceTime;
  final ButtonStyle? style;

  const AntiSpamButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.debounceTime = const Duration(milliseconds: 500),
    this.style,
  }) : super(key: key);

  @override
  State<AntiSpamButton> createState() => _AntiSpamButtonState();
}

class _AntiSpamButtonState extends State<AntiSpamButton> {
  bool _isProcessing = false;

  Future<void> _handlePress() async {
    if (_isProcessing || widget.onPressed == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      widget.onPressed!();
    } finally {
      // 使用延时防止快速点击
      await Future.delayed(widget.debounceTime);
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: widget.style,
      onPressed: _isProcessing ? null : _handlePress,
      child: _isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : widget.child,
    );
  }
}

/// 防止快速多次点击的通用包装器
class AntiSpamWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration debounceTime;

  const AntiSpamWrapper({
    Key? key,
    required this.child,
    this.onTap,
    this.debounceTime = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<AntiSpamWrapper> createState() => _AntiSpamWrapperState();
}

class _AntiSpamWrapperState extends State<AntiSpamWrapper> {
  bool _isProcessing = false;

  Future<void> _handleTap() async {
    if (_isProcessing || widget.onTap == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      widget.onTap!();
    } finally {
      await Future.delayed(widget.debounceTime);
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      absorbing: _isProcessing,
      child: GestureDetector(
        onTap: _handleTap,
        child: widget.child,
      ),
    );
  }
} 