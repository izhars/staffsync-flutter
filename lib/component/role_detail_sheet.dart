// widgets/role_detail_sheet.dart
import 'package:flutter/material.dart';
import '../models/role_model.dart';

class RoleDetailSheet extends StatelessWidget {
  final ProjectRole role;

  const RoleDetailSheet({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.deepPurple,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      role.code.substring(0, 2).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        role.code,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  _buildSection(
                    title: 'Description',
                    child: Text(
                      role.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Level, Reports To, and Status
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          title: 'Level',
                          value: 'Level ${role.level}',
                          icon: Icons.star_rounded,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInfoCard(
                          title: 'Reports To',
                          value: role.reportsTo,
                          icon: Icons.supervisor_account_rounded,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildInfoCard(
                          title: 'Status',
                          value: role.isActive ? 'Active' : 'Inactive',
                          icon: role.isActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: role.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Permissions
                  _buildSection(
                    title: 'Permissions & Report Access',
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 3,
                      ),
                      itemCount: role.permissions.length,
                      itemBuilder: (context, index) {
                        final key = role.permissions.keys.elementAt(index);
                        final value = role.permissions[key] ?? false;
                        return _buildPermissionItem(key, value);
                      },
                    ),
                  ),
                  if (role.responsibilities.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildSection(
                      title: 'Responsibilities',
                      child: Column(
                        children: role.responsibilities.map((responsibility) {
                          return _buildResponsibilityItem(responsibility);
                        }).toList(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Created Info
                  _buildSection(
                    title: 'Created By',
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.deepPurple[100],
                          child: Text(
                            role.createdBy.fullName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(color: Colors.deepPurple),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role.createdBy.fullName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Created on ${_formatDate(role.createdAt)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(String permission, bool hasPermission) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: hasPermission ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            hasPermission ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: hasPermission ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _formatPermissionText(permission),
              style: TextStyle(
                fontSize: 12,
                color: hasPermission ? Colors.green[800] : Colors.red[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsibilityItem(Responsibility responsibility) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.deepPurple[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.checklist,
              size: 16,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  responsibility.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  responsibility.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    responsibility.category,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPermissionText(String permission) {
    // Convert camelCase to Title Case
    return permission
        .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
        .replaceAll('can ', '')
        .replaceAllMapped(RegExp(r'^.| .'), (match) => match.group(0)!.toUpperCase());
  }

  String _formatDate(DateTime date) {

    return '${date.day}/${date.month}/${date.year}';
  }
}