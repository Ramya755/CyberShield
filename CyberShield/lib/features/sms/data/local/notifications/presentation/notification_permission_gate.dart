import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notification_listener_provider.dart';
import 'notification_permission_screen.dart';

class NotificationPermissionGate extends StatefulWidget {
  final Widget child;

  const NotificationPermissionGate({
    super.key,
    required this.child,
  });

  @override
  State<NotificationPermissionGate> createState() => _NotificationPermissionGateState();
}

class _NotificationPermissionGateState extends State<NotificationPermissionGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final provider = context.read<NotificationListenerProvider>();
    provider.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<NotificationListenerProvider>().refreshPermission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = context.watch<NotificationListenerProvider>().permissionEnabled;
    return enabled ? widget.child : const NotificationPermissionScreen();
  }
}
