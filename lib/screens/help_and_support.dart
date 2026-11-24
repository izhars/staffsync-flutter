import 'package:flutter/material.dart';

import 'ticket/create_ticket_screen.dart';
import 'ticket/my_tickets_screen.dart';

class HelpSupportPage extends StatelessWidget {
  const HelpSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Help & Support"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_number_outlined),
            tooltip: "My Tickets",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar for FAQs
            TextField(
              decoration: InputDecoration(
                hintText: "Search help topics...",
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Support Actions: My Tickets & Raise Ticket banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.indigo, Color(0xFF4338CA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.indigo.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
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
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Need Direct Assistance?",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Submit a support ticket for payroll, attendance, leave, or technical queries. Our team will review and reply directly.",
                    style: TextStyle(fontSize: 12.5, color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CreateTicketScreen()),
                            );
                          },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text("Raise Ticket"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.indigo,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MyTicketsScreen()),
                            );
                          },
                          icon: const Icon(Icons.receipt_long, size: 18, color: Colors.white),
                          label: const Text("My Tickets", style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white70),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick help categories
            const Text(
              "Popular Help Topics",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.3,
              ),
              children: [
                _HelpCard(
                  icon: Icons.account_circle,
                  title: "Profile & Settings",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateTicketScreen(initialCategory: "HR"),
                      ),
                    );
                  },
                ),
                _HelpCard(
                  icon: Icons.payment,
                  title: "Salary & Payslips",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateTicketScreen(initialCategory: "Payroll"),
                      ),
                    );
                  },
                ),
                _HelpCard(
                  icon: Icons.schedule,
                  title: "Attendance & Leaves",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateTicketScreen(initialCategory: "Attendance"),
                      ),
                    );
                  },
                ),
                _HelpCard(
                  icon: Icons.computer,
                  title: "Technical Support",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CreateTicketScreen(initialCategory: "Technical"),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // FAQ Section
            const Text(
              "Frequently Asked Questions",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  _FAQTile(
                    question: "How do I update my profile information?",
                    answer: "Go to Profile -> Edit Profile and update your details.",
                  ),
                  Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _FAQTile(
                    question: "How do I apply for leave?",
                    answer: "Navigate to Attendance -> Leave Requests and click 'Apply Leave'.",
                  ),
                  Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _FAQTile(
                    question: "Where can I download my payslip?",
                    answer: "Go to Salary -> Payslips, select the month, and download.",
                  ),
                  Divider(height: 1, color: Color(0xFFF1F5F9)),
                  _FAQTile(
                    question: "How do I raise a support ticket?",
                    answer: "Click the 'Raise Ticket' button above or in the Tickets screen, fill in the subject, category, and issue description, and submit. You can track status and reply in real-time.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _HelpCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _HelpCard({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 28, color: Colors.indigo),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1E293B)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FAQTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FAQTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: Color(0xFF1E293B)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              answer,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
          ),
        )
      ],
    );
  }
}
