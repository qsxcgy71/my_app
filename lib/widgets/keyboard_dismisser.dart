import 'package:flutter/material.dart';

/// 智能键盘隐藏包装器 - 只在点击非输入框区域时隐藏键盘
class KeyboardDismisser extends StatelessWidget {
  final Widget child;
  final bool enabled;

  const KeyboardDismisser({
    Key? key,
    required this.child,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? () => _hideKeyboard(context) : null,
      behavior: HitTestBehavior.translucent, // 确保能接收到点击事件
      child: child,
    );
  }

  static void _hideKeyboard(BuildContext context) {
    final currentFocus = FocusScope.of(context);
    
    // 只有当有输入框获得焦点时才隐藏键盘
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.unfocus();
    }
  }

  /// 手动隐藏键盘的静态方法
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

/// 专为搜索框设计的智能键盘隐藏包装器
class SmartKeyboardDismisser extends StatelessWidget {
  final Widget child;
  final bool enabled;
  final List<GlobalKey>? excludeWidgets; // 排除的组件，点击这些组件不会隐藏键盘

  const SmartKeyboardDismisser({
    Key? key,
    required this.child,
    this.enabled = true,
    this.excludeWidgets,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: enabled ? (event) => _handlePointerDown(context, event) : null,
      child: child,
    );
  }

  void _handlePointerDown(BuildContext context, PointerDownEvent event) {
    final currentFocus = FocusScope.of(context);
    
    // 检查是否点击了排除的组件
    if (excludeWidgets != null) {
      for (final key in excludeWidgets!) {
        final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          final rect = Rect.fromLTWH(position.dx, position.dy, size.width, size.height);
          
          if (rect.contains(event.position)) {
            return; // 点击了排除的组件，不隐藏键盘
          }
        }
      }
    }
    
    // 如果有输入框获得了焦点，则隐藏键盘
    if (currentFocus.focusedChild != null) {
      currentFocus.unfocus();
    }
  }
}

/// 带有智能键盘隐藏功能的Scaffold包装器
class KeyboardDismissibleScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Widget? endDrawer;
  final Widget? bottomNavigationBar;
  final Widget? bottomSheet;
  final Color? backgroundColor;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  const KeyboardDismissibleScaffold({
    Key? key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.drawer,
    this.endDrawer,
    this.bottomNavigationBar,
    this.bottomSheet,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return KeyboardDismisser(
      child: Scaffold(
        appBar: appBar,
        body: body,
        floatingActionButton: floatingActionButton,
        drawer: drawer,
        endDrawer: endDrawer,
        bottomNavigationBar: bottomNavigationBar,
        bottomSheet: bottomSheet,
        backgroundColor: backgroundColor,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
      ),
    );
  }
} 