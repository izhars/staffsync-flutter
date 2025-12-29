import 'package:flutter/material.dart';
import '../services/employee_service.dart';
import 'chat_connection_screen.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final EmployeeService _employeeService = EmployeeService();
  late Future<List<Map<String, dynamic>>> _futureHRs;
  bool _showAvailableOnly = true;

  @override
  void initState() {
    super.initState();
    _futureHRs = _employeeService.getAllHRs();
  }

  void _refreshHRs() {
    setState(() {
      _futureHRs = _employeeService.getAllHRs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orangeScheme = Colors.orange.shade600;
    final orangeLight = Colors.orange.shade50;
    final orangeLightest = Colors.orange.shade100;
    final orangeDark = Colors.orange.shade800;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: orangeScheme,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'HR Support',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Colors.white,
              size: 24,
            ),
            onPressed: _refreshHRs,
            tooltip: 'Refresh list',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _futureHRs,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState(orangeScheme);
          } else if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString(), orangeScheme);
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(orangeScheme);
          }

          final hrs = snapshot.data!;
          final filteredHRs = _showAvailableOnly
              ? hrs.where((hr) => hr['isAvailable'] == true).toList()
              : hrs;

          filteredHRs.sort((a, b) {
            if (a['isAvailable'] != b['isAvailable']) {
              return a['isAvailable'] ? -1 : 1;
            }
            final nameA = '${a['firstName']} ${a['lastName']}';
            final nameB = '${b['firstName']} ${b['lastName']}';
            return nameA.compareTo(nameB);
          });

          final availableCount = hrs.where((hr) => hr['isAvailable']).length;
          final totalCount = hrs.length;
          final availabilityPercent = totalCount > 0
              ? (availableCount / totalCount * 100).round()
              : 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with stats
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      orangeScheme,
                      orangeDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: orangeScheme.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.support_agent_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Connect with HR Support',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'Get help with your queries',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          availableCount.toString(),
                          'Available',
                          Icons.check_circle_rounded,
                          Colors.white,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildStatItem(
                          totalCount.toString(),
                          'Total HR',
                          Icons.people_rounded,
                          Colors.white,
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white.withOpacity(0.3),
                        ),
                        _buildStatItem(
                          '$availabilityPercent%',
                          'Online Rate',
                          Icons.bar_chart_rounded,
                          Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Filter toggle
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: orangeLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: orangeScheme.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _showAvailableOnly
                                ? Icons.filter_alt_rounded
                                : Icons.filter_alt_off_rounded,
                            color: orangeScheme,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _showAvailableOnly ? 'Available Only' : 'Showing All',
                            style: TextStyle(
                              color: orangeDark,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAvailableOnly = !_showAvailableOnly;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Toggle Filter',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _showAvailableOnly
                                  ? Icons.toggle_on_rounded
                                  : Icons.toggle_off_rounded,
                              color: orangeScheme,
                              size: 30,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Results count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Text(
                      '${filteredHRs.length} HR ${_showAvailableOnly ? 'Available' : 'Found'}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (filteredHRs.isNotEmpty)
                      Text(
                        'Tap to chat with available HR',
                        style: TextStyle(
                          color: orangeScheme,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // HR List
              Expanded(
                child: filteredHRs.isEmpty
                    ? _buildNoResultsState(orangeScheme)
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filteredHRs.length,
                  itemBuilder: (context, index) {
                    final hr = filteredHRs[index];
                    return _buildHRCard(hr, orangeScheme);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.9),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHRCard(Map<String, dynamic> hr, Color primaryColor) {
    final bool isAvailable = hr['isAvailable'] ?? false;
    final String availabilityStatus = hr['availabilityStatus'] ?? '';
    final String firstName = hr['firstName'] ?? '';
    final String lastName = hr['lastName'] ?? '';
    final String fullName = '$firstName $lastName'.trim();
    final String email = hr['email'] ?? '';
    final String designation = hr['designation'] ?? '';
    final String profilePicture = hr['profilePicture'] ?? '';
    final String hrId = hr['_id'] ?? hr['id'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        child: InkWell(
          onTap: isAvailable ? () => _navigateToChat(hr) : null,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAvailable
                    ? primaryColor.withOpacity(0.2)
                    : Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Avatar with Status
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.1),
                        image: profilePicture.isNotEmpty
                            ? DecorationImage(
                          image: NetworkImage(profilePicture),
                          fit: BoxFit.cover,
                        )
                            : null,
                      ),
                      child: profilePicture.isEmpty
                          ? Icon(
                        Icons.person_rounded,
                        color: primaryColor,
                        size: 28,
                      )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isAvailable ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),

                // HR Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fullName,
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey[900],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAvailable)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    color: Colors.green,
                                    size: 8,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Available',
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    color: Colors.orange,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    availabilityStatus.isNotEmpty
                                        ? availabilityStatus
                                        : 'Unavailable',
                                    style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        designation,
                        style: TextStyle(
                          fontSize: 14,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Chat Button
                const SizedBox(width: 12),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: isAvailable
                        ? LinearGradient(
                      colors: [
                        primaryColor,
                        Colors.orange.shade800,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    color: isAvailable ? null : Colors.grey[300],
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: isAvailable
                        ? [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                        : null,
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.chat_bubble_rounded,
                      color: isAvailable ? Colors.white : Colors.grey[500],
                      size: 22,
                    ),
                    onPressed: isAvailable
                        ? () => _navigateToChat(hr)
                        : null,
                    tooltip: isAvailable ? 'Start Chat' : 'Not Available',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor,
                  Colors.orange.shade800,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Loading HR Team...',
            style: TextStyle(
              fontSize: 18,
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fetching available support staff',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.red.shade100,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Unable to Load',
              style: TextStyle(
                fontSize: 20,
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshHRs,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Try Again', style: TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color primaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent_rounded,
                color: primaryColor,
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No HR Staff Found',
              style: TextStyle(
                fontSize: 22,
                color: primaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'There are currently no HR team members registered in the system.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _refreshHRs,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Refresh',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(Color primaryColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.search_off_rounded,
              color: primaryColor,
              size: 56,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _showAvailableOnly
                ? 'No Available HR Staff'
                : 'No HR Staff Found',
            style: TextStyle(
              fontSize: 20,
              color: primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _showAvailableOnly
                ? 'All HR team members are currently busy or offline.\nTry again later.'
                : 'Check your connection and try refreshing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _showAvailableOnly = !_showAvailableOnly;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: primaryColor,
                  width: 1.5,
                ),
              ),
            ),
            child: Text(
              _showAvailableOnly
                  ? 'Show All HR'
                  : 'Show Available Only',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToChat(Map<String, dynamic> hr) {
    print("📦 Full HR object: $hr");
    final userId = hr['_id'] ?? hr['id'];
    final firstName = hr['firstName'] ?? '';
    final lastName = hr['lastName'] ?? '';

    if (userId == null || userId.isEmpty) {
      print('❌ Error: HR ID is null or empty');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Cannot start chat: HR ID is missing'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    print("📨 Navigating to chat with: $userId | $firstName $lastName");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(targetUser: hr),
      ),
    );
  }
}