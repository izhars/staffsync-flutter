import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/employee.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/call_service.dart';
import '../services/chat_service.dart';
import '../services/employee_service.dart';
import '../services/notification_service.dart';
import 'call/call_screen.dart';
import 'call/call_socket_service.dart';
import 'call/employee_profile_screen.dart';
import 'chat_connection_screen.dart';
import 'group/groups_screen.dart';

// ===================== CHAT & CALL DESIGN TOKENS =====================

class ChatDesign {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radiusSm = 10;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  // Core palette
  static const Color primary = Color(0xFF0F766E);       // teal-700
  static const Color primaryDark = Color(0xFF115E59);   // teal-800
  static const Color primarySoft = Color(0xFFF0FDFA);   // teal-50
  static const Color primaryLight = Color(0xFFCCFBF1);  // teal-100

  static const Color surface = Colors.white;
  static const Color surfaceMuted = Color(0xFFF8FAFC);  // slate-50
  static const Color bg = Color(0xFFF6F7FB);
  static const Color border = Color(0xFFEAECEF);

  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Accents
  static const Color online = Color(0xFF10B981);        // emerald-500
  static const Color onlineSoft = Color(0xFFECFDF5);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerSoft = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);
  static const Color warning = Color(0xFFD97706);
  static const Color warningSoft = Color(0xFFFFFBEB);
  static const Color info = Color(0xFF3B82F6);          // blue-500
  static const Color infoSoft = Color(0xFFEFF6FF);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleSoft = Color(0xFFF5F3FF);

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
      spreadRadius: -2,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];
}

class ChatHomeScreen extends StatefulWidget {
  final int initialTabIndex;

  const ChatHomeScreen({
    Key? key,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<ChatHomeScreen> createState() => _ChatHomeScreenState();
}

class _ChatHomeScreenState extends State<ChatHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ChatService _chatService;
  final EmployeeService _employeeService = EmployeeService();
  final CallService _callService = CallService();
  final CallSocketService _callSocketService = CallSocketService();
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  List<Employee> employees = [];
  List<Employee> filteredEmployees = [];
  bool isLoading = true;
  bool _isSocketConnected = false;
  String _searchQuery = '';
  String _selectedDepartmentFilter = 'All';

  final Map<String, DateTime> _recentInteractions = {};
  final Map<String, Timer> _interactionTimers = {};
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _chatService = ChatService();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _notificationService.init();
      _notificationSubscription =
          _notificationService.notificationStream.listen(_handleNotification);
      await _loadEmployees();
      await _initializeCallSocket();
    } catch (e) {
      debugPrint('❌ Initialization error in ChatHomeScreen: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _initializeCallSocket() async {
    try {
      final token = await _getAuthToken();
      await _callSocketService.connect(token);

      _callSocketService.onCallSocketConnected = (_) {
        if (!mounted) return;
        setState(() => _isSocketConnected = true);
      };

      _callSocketService.onError = (error) {
        if (!mounted) return;
        setState(() => _isSocketConnected = false);
      };

      _callSocketService.onCallIncoming = _handleIncomingCall;

      _callSocketService.onCallEnded = (data) {
        debugPrint('Call ended notification received: $data');
      };

      _callSocketService.onCallAccepted = (data) {
        debugPrint('Call accepted: $data');
      };
    } catch (e) {
      debugPrint('❌ Call socket initialization failed: $e');
    }
  }

  Future<String> _getAuthToken() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Auth token is null or empty');
    }
    return token;
  }

  Future<void> _loadEmployees() async {
    try {
      setState(() => isLoading = true);
      final data = await _employeeService.getAllEmployees();
      final currentUserId = await _authService.getUserId();
      final employeeList = data
          .map((e) => Employee.fromJson(e))
          .where((emp) => emp.id != currentUserId)
          .toList();

      if (!mounted) return;
      setState(() {
        employees = employeeList;
        _applyFilters();
        isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading employees: $e');
      if (mounted) {
        setState(() => isLoading = false);
        _showSnackBar('Failed to load team members');
      }
    }
  }

  void _handleNotification(Map<String, dynamic> data) {
    final type = data['type'];
    if (type == 'employee_interaction') {
      final senderName = data['senderName'];
      final interactionType = data['interactionType'];
      _showSnackBar(
        '$senderName ${_getInteractionMessage(interactionType)}',
        color: ChatDesign.info,
      );
    }
  }

  String _getInteractionMessage(String type) {
    switch (type) {
      case 'viewed_profile':
        return 'viewed your profile';
      case 'viewed_contact':
        return 'viewed your contact info';
      case 'messaged':
        return 'sent you a message';
      case 'shared_profile':
        return 'shared your profile';
      case 'saved_contact':
        return 'saved your contact';
      case 'started_call':
        return 'started a call with you';
      default:
        return 'interacted with your profile';
    }
  }

  void _showSnackBar(String message, {Color color = ChatDesign.danger}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
        ),
        margin: const EdgeInsets.all(ChatDesign.md),
      ),
    );
  }

  Future<void> _trackProfileView(String employeeId, String employeeName) async {
    try {
      final now = DateTime.now();
      final lastInteraction = _recentInteractions[employeeId];
      if (lastInteraction != null &&
          now.difference(lastInteraction).inSeconds < 60) return;

      _recentInteractions[employeeId] = now;
      _interactionTimers[employeeId]?.cancel();
      _interactionTimers[employeeId] = Timer(const Duration(seconds: 60), () {
        _recentInteractions.remove(employeeId);
      });

      await _employeeService.trackProfileView(employeeId);
    } catch (e) {
      debugPrint('❌ Error tracking profile view: $e');
    }
  }

  // ===================== CALL ACTIONS =====================

  Future<void> _startAudioCall(String targetUserId, String targetUserName) async {
    if (!_isSocketConnected) {
      _showSnackBar('Not connected to call server');
      return;
    }
    try {
      final token = await _getAuthToken();
      final callerId = await _authService.getUserId();
      if (callerId == null || callerId.isEmpty) {
        _showSnackBar('Unable to identify user');
        return;
      }

      final response = await _callService.startCall(targetUserId, 'audio');
      if (response == null || !response['success']) {
        _showSnackBar('Failed to start audio call');
        return;
      }

      final roomId = response['roomId'] as String;
      final callId = response['callId'] as String;
      await _callService.trackCallStart(targetUserId, callType: 'audio');

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleCallScreen(
            token: token,
            roomId: roomId,
            callId: callId,
            isCaller: true,
            callType: 'audio',
            targetUserName: targetUserName,
            targetUserId: targetUserId,
            onCallEnd: (duration) async {
              await _callService.trackCallEnd(targetUserId, callDuration: duration);
            },
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error starting audio call: $e\n$stackTrace');
      _showSnackBar('Failed to start audio call');
    }
  }

  Future<void> _startVideoCall(String targetUserId, String targetUserName) async {
    if (!_isSocketConnected) {
      _showSnackBar('Not connected to call server');
      return;
    }
    try {
      final token = await _getAuthToken();
      final callerId = await _authService.getUserId();
      if (callerId == null || callerId.isEmpty) {
        _showSnackBar('Unable to identify user');
        return;
      }

      final response = await _callService.startCall(targetUserId, 'video');
      if (response == null || !response['success']) {
        _showSnackBar('Failed to start video call');
        return;
      }

      final roomId = response['roomId'] as String;
      final callId = response['callId'] as String;
      await _callService.trackCallStart(targetUserId, callType: 'video');

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleCallScreen(
            token: token,
            roomId: roomId,
            callId: callId,
            isCaller: true,
            callType: 'video',
            targetUserName: targetUserName,
            targetUserId: targetUserId,
            onCallEnd: (duration) async {
              await _callService.trackCallEnd(targetUserId, callDuration: duration);
            },
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error starting video call: $e\n$stackTrace');
      _showSnackBar('Failed to start video call');
    }
  }

  void _handleIncomingCall(Map<String, dynamic> data) {
    if (!mounted) return;
    final callId = data['callId'];
    final roomId = data['roomId'];
    final callerId = data['callerId'];
    final callerName = data['callerName'] ?? 'Unknown';
    final callType = data['callType'] ?? 'video';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: ChatDesign.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(ChatDesign.sm),
              decoration: const BoxDecoration(
                color: ChatDesign.onlineSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.phone_in_talk_rounded,
                color: ChatDesign.online,
                size: 20,
              ),
            ),
            const SizedBox(width: ChatDesign.sm + 4),
            const Text(
              'Incoming Call',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ChatDesign.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              callerName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: ChatDesign.textPrimary,
              ),
            ),
            const SizedBox(height: ChatDesign.sm),
            Text(
              callType == 'video' ? 'Video Call' : 'Audio Call',
              style: const TextStyle(
                fontSize: 13,
                color: ChatDesign.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _declineIncomingCall(callId);
            },
            child: const Text(
              'Decline',
              style: TextStyle(
                color: ChatDesign.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _acceptIncomingCall(
                callId,
                roomId,
                callerId,
                callerName,
                callType,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ChatDesign.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
              ),
            ),
            child: const Text(
              'Accept',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptIncomingCall(
    String callId,
    String roomId,
    String callerId,
    String callerName,
    String callType,
  ) async {
    try {
      final token = await _getAuthToken();
      await _callService.trackCallAccepted(callerId, callType: callType);
      final accepted = await _callService.acceptCall(callId);
      if (!accepted) {
        _showSnackBar('Failed to accept call');
        return;
      }
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SimpleCallScreen(
            token: token,
            roomId: roomId,
            callId: callId,
            isCaller: false,
            callType: callType,
            targetUserName: callerName,
            targetUserId: callerId,
            onCallEnd: (duration) async {
              await _callService.trackCallEnd(callerId, callDuration: duration);
            },
          ),
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error accepting incoming call: $e\n$stackTrace');
      _showSnackBar('Failed to accept call');
    }
  }

  void _declineIncomingCall(String callId) async {
    try {
      await _callService.declineCall(callId);
    } catch (e) {
      debugPrint('❌ Error declining call: $e');
    }
  }

  // ===================== DIRECT CHAT ACTION =====================

  Future<void> _startChatWithEmployee(Employee emp) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(ChatDesign.lg),
          decoration: BoxDecoration(
            color: ChatDesign.surface,
            borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
          ),
          child: const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(ChatDesign.primary),
            ),
          ),
        ),
      ),
    );

    try {
      final otherUser = User(
        id: emp.id,
        employeeId: emp.employeeId,
        firstName: emp.firstName,
        lastName: emp.lastName,
        fullName: emp.fullName,
        email: emp.email,
        phone: emp.phone,
        role: emp.role,
        designation: emp.designation,
        profilePicture: emp.profilePicture ?? '',
        status: emp.isActive ? 'active' : 'inactive',
        isActive: emp.isActive,
        isVerified: true,
        documents: const [],
        createdAt: emp.hireDate,
        updatedAt: DateTime.now(),
      );

      final conversation = await _chatService.getOrCreateConversation(emp.id);
      if (!mounted) return;
      Navigator.pop(context); // Pop loading dialog

      if (conversation != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              otherUser: otherUser,
              conversationId: conversation.id,
              chatService: _chatService,
            ),
          ),
        );
      } else {
        _showSnackBar('Failed to open chat conversation');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      debugPrint('❌ Error starting chat: $e');
      _showSnackBar('Failed to start chat with ${emp.fullName}');
    }
  }

  // ===================== SEARCH & FILTER =====================

  void _applyFilters() {
    List<Employee> list = employees;

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      list = list.where((emp) {
        final fullName = emp.fullName.toLowerCase();
        final designation = emp.designation.toLowerCase();
        final department = emp.department.toLowerCase();
        final email = emp.email.toLowerCase();
        return fullName.contains(query) ||
            designation.contains(query) ||
            department.contains(query) ||
            email.contains(query);
      }).toList();
    }

    if (_selectedDepartmentFilter != 'All') {
      list = list.where((emp) {
        final dept = emp.department.trim().toLowerCase();
        return dept == _selectedDepartmentFilter.toLowerCase();
      }).toList();
    }

    filteredEmployees = list;
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFilters();
    });
  }

  List<String> _getDepartmentsList() {
    final depts = <String>{'All'};
    for (final emp in employees) {
      if (emp.department.trim().isNotEmpty) {
        depts.add(emp.department.trim());
      }
    }
    return depts.toList();
  }

  // ===================== OPTIONS & PROFILE =====================

  void _showEmployeeOptions(Employee emp) {
    final fullName = emp.fullName;
    _trackProfileView(emp.id, fullName);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final surface = isDark ? const Color(0xFF1E2640) : ChatDesign.surface;
        final border = isDark ? const Color(0xFF2D3748) : ChatDesign.border;
        final textPrimary = isDark ? const Color(0xFFF8FAFC) : ChatDesign.textPrimary;

        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(ChatDesign.radiusXl),
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(ChatDesign.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: ChatDesign.md),
                      decoration: BoxDecoration(
                        color: border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Row(
                      children: [
                        _buildAvatar(emp, radius: 26, fontSize: 20),
                        const SizedBox(width: ChatDesign.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textPrimary,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                emp.designation.isNotEmpty
                                    ? emp.designation
                                    : 'Team Member',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: ChatDesign.primaryDark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ChatDesign.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _isSocketConnected
                              ? ChatDesign.onlineSoft
                              : ChatDesign.dangerSoft,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isSocketConnected
                                    ? ChatDesign.online
                                    : ChatDesign.danger,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isSocketConnected ? 'Ready' : 'Offline',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _isSocketConnected
                                    ? ChatDesign.online
                                    : ChatDesign.danger,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: ChatDesign.md),
                  const Divider(color: ChatDesign.border, height: 1),
                  const SizedBox(height: ChatDesign.md),

                  // Communication
                  _buildSheetSectionLabel('COMMUNICATION'),
                  const SizedBox(height: ChatDesign.sm),
                  _buildActionTile(
                    icon: Icons.chat_bubble_outline_rounded,
                    iconColor: ChatDesign.primary,
                    title: 'Direct Chat',
                    subtitle: 'Open conversation with $fullName',
                    onTap: () {
                      Navigator.pop(context);
                      _startChatWithEmployee(emp);
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.call_rounded,
                    iconColor: ChatDesign.online,
                    title: 'Audio Call',
                    subtitle: 'Start voice call',
                    onTap: () {
                      Navigator.pop(context);
                      _startAudioCall(emp.id, fullName);
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.videocam_rounded,
                    iconColor: ChatDesign.info,
                    title: 'Video Call',
                    subtitle: 'Start HD video call',
                    onTap: () {
                      Navigator.pop(context);
                      _startVideoCall(emp.id, fullName);
                    },
                  ),

                  const SizedBox(height: ChatDesign.sm),
                  _buildSheetSectionLabel('MORE OPTIONS'),
                  const SizedBox(height: ChatDesign.sm),
                  _buildActionTile(
                    icon: Icons.person_outline_rounded,
                    iconColor: ChatDesign.purple,
                    title: 'View Profile',
                    subtitle: 'See detailed employee profile',
                    onTap: () {
                      Navigator.pop(context);
                      _viewFullProfile(emp);
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.email_outlined,
                    iconColor: ChatDesign.warning,
                    title: 'Send Email',
                    subtitle: emp.email.isNotEmpty ? emp.email : 'No email provided',
                    onTap: () {
                      Navigator.pop(context);
                      _sendEmail(emp);
                    },
                  ),
                  _buildActionTile(
                    icon: Icons.share_outlined,
                    iconColor: ChatDesign.info,
                    title: 'Share Contact',
                    subtitle: 'Share ${emp.firstName}\'s contact details',
                    onTap: () {
                      Navigator.pop(context);
                      _shareEmployeeProfile(emp);
                    },
                  ),

                  const SizedBox(height: ChatDesign.md),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
                        ),
                        side: const BorderSide(color: ChatDesign.border),
                      ),
                      child: const Text(
                        'Close',
                        style: TextStyle(
                          color: ChatDesign.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

  void _showQuickActions(Employee emp) {
    final fullName = emp.fullName;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: ChatDesign.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(ChatDesign.radiusXl),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(ChatDesign.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: ChatDesign.md),
                  decoration: BoxDecoration(
                    color: ChatDesign.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: ChatDesign.textPrimary,
                  ),
                ),
                const SizedBox(height: ChatDesign.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildQuickActionCircle(
                      icon: Icons.call_rounded,
                      label: 'Audio',
                      color: ChatDesign.online,
                      onTap: () {
                        Navigator.pop(context);
                        _startAudioCall(emp.id, fullName);
                      },
                    ),
                    _buildQuickActionCircle(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Message',
                      color: ChatDesign.primary,
                      onTap: () {
                        Navigator.pop(context);
                        _startChatWithEmployee(emp);
                      },
                    ),
                    _buildQuickActionCircle(
                      icon: Icons.videocam_rounded,
                      label: 'Video',
                      color: ChatDesign.info,
                      onTap: () {
                        Navigator.pop(context);
                        _startVideoCall(emp.id, fullName);
                      },
                    ),
                    _buildQuickActionCircle(
                      icon: Icons.person_rounded,
                      label: 'Profile',
                      color: ChatDesign.purple,
                      onTap: () {
                        Navigator.pop(context);
                        _viewFullProfile(emp);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: ChatDesign.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCircle({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetSectionLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: ChatDesign.textMuted,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E2640) : ChatDesign.surface;
    final border = isDark ? const Color(0xFF2D3748) : ChatDesign.border;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : ChatDesign.textPrimary;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : ChatDesign.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: ChatDesign.sm),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
        border: Border.all(color: border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ChatDesign.sm + 4,
              vertical: ChatDesign.sm + 3,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
                  ),
                  child: Icon(icon, color: iconColor, size: 19),
                ),
                const SizedBox(width: ChatDesign.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF64748B) : ChatDesign.textMuted,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _viewFullProfile(Employee emp) async {
    await _trackProfileView(emp.id, emp.fullName);
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeProfileScreen(employeeId: emp.id),
      ),
    );
  }

  Future<void> _shareEmployeeProfile(Employee emp) async {
    try {
      await _employeeService.trackProfileShare(emp.id, 'flutter_app');
      _showSnackBar('Profile shared', color: ChatDesign.online);
    } catch (e) {
      debugPrint('❌ Error sharing profile: $e');
    }
  }

  void _sendEmail(Employee emp) {
    if (emp.email.isEmpty) {
      _showSnackBar('No email address available');
      return;
    }
    _showSnackBar('Opening email for ${emp.email}...', color: ChatDesign.info);
  }

  // ===================== AVATAR =====================

  Widget _buildAvatar(
    Employee emp, {
    double radius = 22,
    double fontSize = 16,
  }) {
    final imageUrl = emp.profilePicture?.trim() ?? '';

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: ChatDesign.primarySoft,
        shape: BoxShape.circle,
        border: Border.all(color: ChatDesign.primaryLight, width: 1.5),
      ),
      child: ClipOval(
        child: imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildAvatarFallback(emp, fontSize),
              )
            : _buildAvatarFallback(emp, fontSize),
      ),
    );
  }

  Widget _buildAvatarFallback(Employee emp, double fontSize) {
    final initials = emp.firstName.isNotEmpty
        ? emp.firstName[0].toUpperCase()
        : (emp.name.isNotEmpty ? emp.name[0].toUpperCase() : 'E');

    return Container(
      alignment: Alignment.center,
      color: ChatDesign.primarySoft,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: ChatDesign.primaryDark,
        ),
      ),
    );
  }

  // ===================== MAIN BUILD =====================

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0B0F19) : ChatDesign.bg;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: bg,
        body: Column(
          children: [
            // Custom Header with Tabs
            _buildHeader(),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Direct Messages & Calls (Employees)
                  _buildEmployeesTab(),

                  // Tab 2: Group Messages
                  GroupsScreen(chatService: _chatService),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===================== HEADER =====================

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: ChatDesign.primary,
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(ChatDesign.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: ChatDesign.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -6,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            ChatDesign.md,
            ChatDesign.sm,
            ChatDesign.md,
            ChatDesign.md,
          ),
          child: Column(
            children: [
              // Title row
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ChatDesign.sm,
                  vertical: ChatDesign.sm,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(ChatDesign.sm + 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
                      ),
                      child: const Icon(
                        Icons.forum_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: ChatDesign.sm + 4),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chat & Calls',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Connect with your team',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Connection status badge
                    _buildConnectionBadge(),
                    const SizedBox(width: 8),

                    // Refresh button
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                      onPressed: _loadEmployees,
                      tooltip: 'Refresh',
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: ChatDesign.md),

              // Tab bar
              Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
                ),
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: EdgeInsets.zero,
                  labelColor: ChatDesign.primary,
                  unselectedLabelColor: Colors.white.withOpacity(0.9),
                  labelPadding: EdgeInsets.zero,
                  splashFactory: NoSplash.splashFactory,
                  overlayColor: MaterialStateProperty.all(Colors.transparent),
                  tabs: [
                    _buildTab(
                      icon: Icons.person_rounded,
                      label: 'Direct Messages',
                      isSelected: _tabController.index == 0,
                    ),
                    _buildTab(
                      icon: Icons.groups_2_rounded,
                      label: 'Group Messages',
                      isSelected: _tabController.index == 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Tab(
      height: 38,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: _isSocketConnected
            ? ChatDesign.online.withOpacity(0.2)
            : ChatDesign.danger.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSocketConnected
              ? ChatDesign.online.withOpacity(0.4)
              : ChatDesign.danger.withOpacity(0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isSocketConnected ? ChatDesign.online : ChatDesign.danger,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            _isSocketConnected ? 'Online' : 'Offline',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== TAB 1: EMPLOYEES TAB =====================

  Widget _buildEmployeesTab() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(ChatDesign.primary),
              ),
            ),
            SizedBox(height: ChatDesign.md),
            Text(
              'Loading team members...',
              style: TextStyle(
                color: ChatDesign.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEmployees,
      color: ChatDesign.primary,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ChatDesign.md,
          ChatDesign.md,
          ChatDesign.md,
          0,
        ),
        child: Column(
          children: [
            // Search Bar
            _buildSearchBar(),
            const SizedBox(height: ChatDesign.sm + 2),

            // Department filter chips
            _buildDepartmentChips(),
            const SizedBox(height: ChatDesign.sm + 4),

            // Section count label
            Row(
              children: [
                Text(
                  'TEAM MEMBERS (${filteredEmployees.length})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: ChatDesign.textMuted,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Tap for options',
                  style: TextStyle(
                    fontSize: 11,
                    color: ChatDesign.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: ChatDesign.sm),

            // Employee List
            Expanded(
              child: filteredEmployees.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: ChatDesign.lg),
                      itemCount: filteredEmployees.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final emp = filteredEmployees[index];
                        return _buildEmployeeCard(emp);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E2640) : ChatDesign.surface;
    final border = isDark ? const Color(0xFF2D3748) : ChatDesign.border;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : ChatDesign.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(ChatDesign.radiusMd),
        border: Border.all(color: border),
        boxShadow: isDark ? null : ChatDesign.softShadow,
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search members by name, role, dept...',
          hintStyle: const TextStyle(
            color: ChatDesign.textMuted,
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: ChatDesign.textMuted,
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: ChatDesign.textMuted),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: ChatDesign.md,
            vertical: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildDepartmentChips() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E2640) : ChatDesign.surface;
    final border = isDark ? const Color(0xFF2D3748) : ChatDesign.border;

    final depts = _getDepartmentsList();
    if (depts.length <= 1) return const SizedBox.shrink();

    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: depts.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final dept = depts[index];
          final isSelected = _selectedDepartmentFilter == dept;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDepartmentFilter = dept;
                _applyFilters();
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? ChatDesign.primary : surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? ChatDesign.primary : border,
                ),
              ),
              child: Text(
                dept,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : ChatDesign.textSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ===================== EMPLOYEE CARD WITH 3 ACTION ICONS =====================

  Widget _buildEmployeeCard(Employee emp) {
    final fullName = emp.fullName;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E2640) : ChatDesign.surface;
    final border = isDark ? const Color(0xFF2D3748) : ChatDesign.border;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : ChatDesign.textPrimary;

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(ChatDesign.radiusLg),
        border: Border.all(color: border),
        boxShadow: isDark ? null : ChatDesign.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ChatDesign.radiusLg),
          onTap: () => _showEmployeeOptions(emp),
          onLongPress: () => _showQuickActions(emp),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ChatDesign.md,
              vertical: 12,
            ),
            child: Row(
              children: [
                // Avatar
                _buildAvatar(emp, radius: 22, fontSize: 16),
                const SizedBox(width: 12),

                // Name & Designation & Department
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: textPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (emp.designation.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: ChatDesign.primarySoft,
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: ChatDesign.primaryLight,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                emp.designation,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: ChatDesign.primaryDark,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          if (emp.designation.isNotEmpty &&
                              emp.department.isNotEmpty)
                            const SizedBox(width: 6),
                          if (emp.department.isNotEmpty)
                            Flexible(
                              child: Text(
                                emp.department,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: ChatDesign.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Action 1: Call (Audio)
                _buildActionIconButton(
                  icon: Icons.call_rounded,
                  color: ChatDesign.online,
                  tooltip: 'Audio Call',
                  onTap: () => _startAudioCall(emp.id, fullName),
                ),
                const SizedBox(width: 6),

                // Action 2: Messages (Chat)
                _buildActionIconButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: ChatDesign.primary,
                  tooltip: 'Message',
                  onTap: () => _startChatWithEmployee(emp),
                ),
                const SizedBox(width: 6),

                // Action 3: Video Call
                _buildActionIconButton(
                  icon: Icons.videocam_rounded,
                  color: ChatDesign.info,
                  tooltip: 'Video Call',
                  onTap: () => _startVideoCall(emp.id, fullName),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
          onTap: onTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(ChatDesign.radiusSm),
              border: Border.all(
                color: color.withOpacity(0.22),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(ChatDesign.lg),
            decoration: const BoxDecoration(
              color: ChatDesign.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 42,
              color: ChatDesign.primary,
            ),
          ),
          const SizedBox(height: ChatDesign.md),
          Text(
            _searchQuery.isEmpty
                ? 'No team members found'
                : 'No members matching "$_searchQuery"',
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: ChatDesign.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatService.dispose();
    _notificationSubscription?.cancel();
    _callSocketService.disconnect();
    _searchController.dispose();
    _messageController.dispose();
    for (final timer in _interactionTimers.values) {
      timer.cancel();
    }
    _interactionTimers.clear();
    super.dispose();
  }
}
