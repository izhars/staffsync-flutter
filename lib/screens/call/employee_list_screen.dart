import 'package:flutter/material.dart';
import '../chat_home_screen.dart';

/// EmployeeScreen has been merged into ChatHomeScreen.
/// This widget provides seamless backward compatibility.
class EmployeeScreen extends StatelessWidget {
  final int initialTabIndex;

  const EmployeeScreen({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChatHomeScreen(initialTabIndex: initialTabIndex);
  }
}
