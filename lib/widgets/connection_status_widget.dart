// lib/ui/widgets/connection_status_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/chat_service.dart';

class ConnectionStatusWidget extends StatefulWidget {
  const ConnectionStatusWidget({Key? key}) : super(key: key);

  @override
  _ConnectionStatusWidgetState createState() => _ConnectionStatusWidgetState();
}

class _ConnectionStatusWidgetState extends State<ConnectionStatusWidget> {
  final ChatService _chatService = ChatService();
  bool _isConnected = false;
  bool _isConnecting = false;
  String _lastError = '';

  StreamSubscription<bool>? _connectionSubscription;
  StreamSubscription<String>? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _listenToConnection();
  }

  void _listenToConnection() {
    _connectionSubscription = _chatService.connectionStream.listen((connected) {
      setState(() {
        _isConnected = connected;
        _isConnecting = false;
      });
    });

    _errorSubscription = _chatService.errorStream.listen((error) {
      setState(() {
        _lastError = error;
      });
    });
  }

  Future<void> _reconnect() async {
    setState(() => _isConnecting = true);
    await _chatService.reconnect();
    await Future.delayed(Duration(seconds: 2));
    setState(() => _isConnecting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: _isConnected ? Colors.green.shade200 : Colors.red.shade200,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _isConnected ? 'Connected' : 'Disconnected',
            style: TextStyle(
              color: _isConnected ? Colors.green.shade800 : Colors.red.shade800,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_isConnecting)
            Container(
              margin: const EdgeInsets.only(left: 6),
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
              ),
            ),
          if (!_isConnected && !_isConnecting)
            IconButton(
              icon: Icon(Icons.refresh, size: 16, color: Colors.blue.shade800),
              onPressed: _reconnect,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _connectionSubscription?.cancel();
    _errorSubscription?.cancel();
    super.dispose();
  }
}