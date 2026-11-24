import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import 'call_screen.dart';
import 'call_socket_service.dart';

class RoomJoinScreen extends StatefulWidget {
  const RoomJoinScreen({Key? key}) : super(key: key);

  @override
  State<RoomJoinScreen> createState() => _RoomJoinScreenState();
}

class _RoomJoinScreenState extends State<RoomJoinScreen> {
  final TextEditingController _roomIdController = TextEditingController();
  final CallSocketService _socketService = CallSocketService();
  final AuthService _authService = AuthService();

  String _status = 'Connecting...';
  bool _isConnected = false;
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  Future<void> _connectSocket() async {
    if (_isConnecting) return;

    setState(() {
      _isConnecting = true;
      _status = 'Connecting...';
    });

    try {
      final token = await _getAuthToken();
      await _socketService.connect(token);

      // Setup socket callbacks
      _socketService.onCallSocketConnected = (_) {
        if (!mounted) return;
        setState(() {
          _status = 'Connected ✅';
          _isConnected = true;
          _isConnecting = false;
        });
        debugPrint('✅ Call socket connected');
      };

      _socketService.onError = (error) {
        if (!mounted) return;
        setState(() {
          _status = 'Error: $error';
          _isConnected = false;
          _isConnecting = false;
        });
        _showSnackBar('Connection error: $error');
      };

      _socketService.onRoomCreated = (data) {
        if (!mounted) return;
        debugPrint('🏠 Room created: $data');
        _goToCallScreen(
          roomId: data['roomId'],
          isCaller: true,
        );
      };

      _socketService.onJoinedRoom = (data) {
        if (!mounted) return;
        debugPrint('🚪 Joined room: $data');
        _goToCallScreen(
          roomId: data['roomId'],
          isCaller: false,
        );
      };

      _socketService.onRoomError = (data) {
        if (!mounted) return;
        debugPrint('💥 Room error: $data');
        _showSnackBar('Room error: ${data['message']}');
      };

    } catch (e) {
      debugPrint('❌ Socket init failed: $e');
      if (!mounted) return;
      setState(() {
        _status = 'Connection failed ❌';
        _isConnected = false;
        _isConnecting = false;
      });
      _showSnackBar('Failed to connect: ${e.toString()}');
    }
  }

  Future<String> _getAuthToken() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('JWT token missing');
    }
    return token;
  }

  void _createRoom() {
    if (!_isConnected) {
      _showSnackBar('Not connected to server');
      return;
    }

    final roomId = _roomIdController.text.trim().isNotEmpty
        ? _roomIdController.text.trim()
        : 'room_${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('🏠 Creating room: $roomId');
    _socketService.createRoom(roomId);

    setState(() {
      _status = 'Creating room...';
    });
  }

  void _joinRoom() {
    if (!_isConnected) {
      _showSnackBar('Not connected to server');
      return;
    }

    final roomId = _roomIdController.text.trim();
    if (roomId.isEmpty) {
      _showSnackBar('Please enter a room ID');
      return;
    }

    debugPrint('🚪 Joining room: $roomId');
    _socketService.joinRoom(roomId);

    setState(() {
      _status = 'Joining room...';
    });
  }

  void _goToCallScreen({
    required String roomId,
    required bool isCaller,
  }) async {
    try {
      final token = await _getAuthToken();

      if (!mounted) return;

      // Navigate to SimpleCallScreen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SimpleCallScreen(
            token: token,
            roomId: roomId,
            isCaller: isCaller,
            callType: 'video',
            targetUserName: '',
            targetUserId: '',
            callId: '',
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error going to call screen: $e');
      _showSnackBar('Failed to start call: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _reconnect() {
    _connectSocket();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Video Call Room'),
        centerTitle: true,
        actions: [
          if (_isConnected)
            IconButton(
              icon: Icon(Icons.refresh, color: Colors.white),
              onPressed: _reconnect,
              tooltip: 'Reconnect',
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status indicator
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _isConnected ? Colors.green : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isConnected ? Icons.check_circle : Icons.error,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isConnected ? 'Connected' : 'Disconnected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _isConnected ? Colors.green : Colors.red,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          _status,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  if (_isConnecting)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Room ID input
            TextField(
              controller: _roomIdController,
              decoration: InputDecoration(
                labelText: 'Room ID',
                hintText: 'Enter room ID or leave empty to create new',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.meeting_room),
                suffixIcon: _roomIdController.text.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear),
                  onPressed: () {
                    _roomIdController.clear();
                    setState(() {});
                  },
                )
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),

            SizedBox(height: 8),
            Text(
              _roomIdController.text.isEmpty
                  ? 'Leave empty to generate a random room ID'
                  : 'Room ID: ${_roomIdController.text}',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),

            SizedBox(height: 32),

            // Create Room button
            ElevatedButton.icon(
              onPressed: _isConnected ? _createRoom : null,
              icon: Icon(Icons.add_circle_outline),
              label: Text('CREATE NEW ROOM'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 16),

            // Join Room button
            ElevatedButton.icon(
              onPressed: _isConnected && _roomIdController.text.isNotEmpty
                  ? _joinRoom
                  : null,
              icon: Icon(Icons.login),
              label: Text('JOIN EXISTING ROOM'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: 24),

            // Info section
            Expanded(
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to use:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    _buildInstruction(
                      icon: Icons.add_circle,
                      text: 'Click "CREATE NEW ROOM" to start a new video call',
                    ),
                    _buildInstruction(
                      icon: Icons.share,
                      text: 'Share the Room ID with others to invite them',
                    ),
                    _buildInstruction(
                      icon: Icons.login,
                      text: 'Others can enter the Room ID and click "JOIN EXISTING ROOM"',
                    ),
                    _buildInstruction(
                      icon: Icons.videocam,
                      text: 'Supports both video and audio calls',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstruction({required IconData icon, required String text}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }
}