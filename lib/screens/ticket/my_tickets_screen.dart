// lib/screens/ticket/my_tickets_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/ticket_model.dart';
import '../../services/ticket_service.dart';
import 'create_ticket_screen.dart';
import 'ticket_detail_screen.dart';

class MyTicketsScreen extends StatefulWidget {
  const MyTicketsScreen({super.key});

  @override
  State<MyTicketsScreen> createState() => _MyTicketsScreenState();
}

class _MyTicketsScreenState extends State<MyTicketsScreen> {
  final TicketService _ticketService = TicketService();
  final TextEditingController _searchController = TextEditingController();

  List<TicketModel> _tickets = [];
  bool _isLoading = true;
  String? _error;
  String _selectedStatus = 'all';

  final List<String> _statusFilters = [
    'all',
    'Open',
    'In Progress',
    'Waiting',
    'Resolved',
    'Closed',
    'Reopened',
  ];

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTickets({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final list = await _ticketService.getMyTickets(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
        search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      );

      if (mounted) {
        setState(() {
          _tickets = list;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Open':
        return Colors.blue;
      case 'In Progress':
        return Colors.amber.shade800;
      case 'Waiting':
        return Colors.purple;
      case 'Resolved':
        return Colors.green.shade700;
      case 'Closed':
        return Colors.grey.shade700;
      case 'Reopened':
        return Colors.red.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red.shade700;
      case 'High':
        return Colors.orange.shade800;
      case 'Medium':
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'attendance':
        return Icons.access_time;
      case 'payroll':
        return Icons.payments_outlined;
      case 'leave':
        return Icons.event_note;
      case 'technical':
        return Icons.computer;
      case 'hr':
        return Icons.people_outline;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'My Support Tickets',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
          );
          if (res == true || mounted) {
            _fetchTickets(isRefresh: true);
          }
        },
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Raise Ticket', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            color: Colors.white,
            child: Column(
              children: [
                // Search Input
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tickets...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _fetchTickets();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _fetchTickets(),
                ),
                const SizedBox(height: 10),

                // Status Chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusFilters.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, idx) {
                      final status = _statusFilters[idx];
                      final isSelected = _selectedStatus == status;
                      final label = status == 'all' ? 'All' : status;

                      return ChoiceChip(
                        label: Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Colors.indigo,
                        backgroundColor: const Color(0xFFF1F5F9),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _selectedStatus = status);
                            _fetchTickets();
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Tickets List / Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchTickets(isRefresh: true),
              color: Colors.indigo,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                const SizedBox(height: 12),
                                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () => _fetchTickets(),
                                  child: const Text('Try Again'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : _tickets.isEmpty
                          ? Center(
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.shade50,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.confirmation_number_outlined, size: 48, color: Colors.indigo),
                                      ),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'No Support Tickets',
                                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _selectedStatus != 'all' || _searchController.text.isNotEmpty
                                            ? 'No tickets match the selected filters.'
                                            : 'You haven\'t submitted any support tickets yet.',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(height: 20),
                                      ElevatedButton.icon(
                                        onPressed: () async {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
                                          );
                                          _fetchTickets(isRefresh: true);
                                        },
                                        icon: const Icon(Icons.add),
                                        label: const Text('Raise a Ticket'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.indigo,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _tickets.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final ticket = _tickets[idx];
                                return _buildTicketCard(ticket);
                              },
                            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(TicketModel ticket) {
    final statusColor = _getStatusColor(ticket.status);
    final priorityColor = _getPriorityColor(ticket.priority);
    final categoryIcon = _getCategoryIcon(ticket.category);

    return InkWell(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TicketDetailScreen(ticketId: ticket.id, initialTicket: ticket),
          ),
        );
        _fetchTickets(isRefresh: true);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Ticket ID, Priority, Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      ticket.displayTicketId,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.indigo,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ticket.priority,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Subject
            Text(
              ticket.subject,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Description preview
            Text(
              ticket.description,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 8),

            // Bottom metadata row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(categoryIcon, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      ticket.category,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                    ),
                    if (ticket.attachments.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.attach_file, size: 13, color: Colors.grey.shade500),
                      Text(
                        '${ticket.attachments.length}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                    if (ticket.replies.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Icon(Icons.chat_bubble_outline, size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 2),
                      Text(
                        '${ticket.replies.length}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ],
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(ticket.createdAt),
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
