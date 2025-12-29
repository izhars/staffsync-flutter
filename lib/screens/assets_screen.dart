import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../component/connectivity_wrapper.dart';
import '../models/Asset.dart';
import '../services/assets_service.dart';
import '../services/connectivity_service.dart';

class AssetsScreen extends StatefulWidget {
  const AssetsScreen({Key? key}) : super(key: key);

  @override
  _AssetsScreenState createState() => _AssetsScreenState();
}

class _AssetsScreenState extends State<AssetsScreen> {
  final AssetsService _assetsService = AssetsService();
  final ConnectivityService _connectivityService = ConnectivityService();
  List<Asset> _assets = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadAssets();

    // Listen to connectivity changes
    _connectivityService.connectionStream.listen((hasConnection) {
      if (hasConnection && !_isLoading && _errorMessage != null) {
        // Auto-retry when connection comes back
        _loadAssets();
      }
    });
  }

  Future<void> _loadAssets() async {
    try {
      // Check connectivity first
      final hasConnection = await _connectivityService.hasConnection();

      if (!hasConnection) {
        setState(() {
          _errorMessage = 'No internet connection. Please check your connection and try again.';
          _isLoading = false;
        });
        return;
      }

      final assets = await _assetsService.getMyAssets();
      setState(() {
        _assets = assets;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load assets. Please try again.';
        _isLoading = false;
      });
    }
  }

  List<Asset> get _filteredAssets {
    if (_selectedFilter == 'all') return _assets;
    return _assets.where((asset) => asset.category == _selectedFilter).toList();
  }

  Set<String> get _categories {
    return _assets.map((asset) => asset.category).toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'My Assets',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: _loadAssets,
          ),
        ],
      ),
      body: ConnectivityWrapper(
        onRetry: _loadAssets,
        child: _isLoading
            ? _buildLoadingState()
            : _errorMessage != null
            ? _buildErrorState()
            : _buildSuccessState(),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(strokeWidth: 3),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadAssets,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    if (_assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 90, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text(
              'No assets assigned yet',
              style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'Check back later or contact IT',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildFilterChips(),
        _buildAssetStats(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadAssets,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredAssets.length,
              itemBuilder: (context, index) {
                return _buildAssetCard(_filteredAssets[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return Container(
      color: Colors.white,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 40, // important: ListView needs a height
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildFilterChip('all', 'All (${_assets.length})'),
            ..._categories.map((category) {
              final count = _assets.where((a) => a.category == category).length;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildFilterChip(
                  category,
                  '${_capitalizeFirst(category)} ($count)',
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }


  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        onSelected: (selected) {
          setState(() {
            _selectedFilter = value;
          });
        },
        backgroundColor: Colors.grey[200],
        selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildAssetStats() {
    final totalValue = _assets.fold<double>(
      0,
          (sum, asset) => sum + (asset.purchasePrice ?? 0),
    );

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Total Assets',
            '${_assets.length}',
            Icons.inventory_2,
          ),
          Container(
            height: 40,
            width: 1,
            color: Colors.white.withOpacity(0.3),
          ),
          _buildStatItem(
            'Total Value',
            '\$${totalValue.toStringAsFixed(0)}',
            Icons.attach_money,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildAssetCard(Asset asset) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showAssetDetails(asset),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _buildAssetIcon(asset.category),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          asset.brandModelDisplay, // Use the new getter
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(asset.status),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(
                    Icons.category_outlined,
                    _capitalizeFirst(asset.category),
                  ),
                  _buildInfoChip(
                    Icons.verified_outlined,
                    _capitalizeFirst(asset.condition),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Assigned: ${_formatDate(asset.assignedDate)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAssetIcon(String category) {
    IconData icon;
    Color color;

    switch (category.toLowerCase()) {
      case 'laptop':
        icon = Icons.laptop_mac;
        color = Colors.blue;
        break;

      case 'desktop':
        icon = Icons.desktop_windows;
        color = Colors.indigo;
        break;

      case 'mobile':
        icon = Icons.phone_android;
        color = Colors.green;
        break;

      case 'tablet':
        icon = Icons.tablet_mac;
        color = Colors.orange;
        break;

      case 'accessories':
        icon = Icons.headphones;
        color = Colors.pink;
        break;

      case 'furniture':
        icon = Icons.chair_alt;
        color = Colors.brown;
        break;

      case 'other':
        icon = Icons.devices_other;
        color = Colors.grey;
        break;

      default:
        icon = Icons.device_unknown;
        color = Colors.grey;
    }


    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'assigned':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'available':
        color = Colors.blue;
        icon = Icons.circle_outlined;
        break;
      case 'maintenance':
        color = Colors.orange;
        icon = Icons.build_circle;
        break;
      case 'retired':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            _capitalizeFirst(status),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value.isNotEmpty ? value : 'N/A', // Handle empty strings
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showAssetDetails(Asset asset) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent, // For backdrop blur compatibility
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          // Optional: add 'dart:ui' import for ImageFilter
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            color: Colors.white.withOpacity(0.92), // Frosted glass effect
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) => SingleChildScrollView(
                controller: scrollController,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 24,
                    right: 24,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle bar
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      // Header Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _getCategoryColor(asset.category).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getCategoryIcon(asset.category),
                                color: _getCategoryColor(asset.category),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    asset.name,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade900,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${asset.assetId}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            _buildStatusBadge(asset.status),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Asset Details Card
                      _buildSectionCard(
                        title: 'Asset Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailTile('Brand', asset.brand ?? 'N/A'),
                            _buildDetailTile('Model', asset.model ?? 'N/A'),
                            _buildDetailTile('Category', _capitalizeFirst(asset.category)),
                            _buildDetailTile(
                              'Condition',
                              _capitalizeFirst(asset.condition),
                              leading: Icon(
                                _getConditionIcon(asset.condition),
                                color: _getConditionColor(asset.condition),
                                size: 18,
                              ),
                            ),
                            if (asset.location != null && asset.location!.isNotEmpty)
                              _buildDetailTile('Location', asset.location!),
                            if (asset.purchaseDate != null)
                              _buildDetailTile(
                                'Purchase Date',
                                _formatDate(asset.purchaseDate),
                                leading: const Icon(Icons.calendar_today_outlined, size: 18),
                              ),
                            if (asset.assignedDate != null)
                              _buildDetailTile(
                                'Assigned Date',
                                _formatDate(asset.assignedDate),
                                leading: const Icon(Icons.date_range_outlined, size: 18),
                              ),
                          ],
                        ),
                      ),

                      // Assignment History (if any)
                      if (asset.hasAssignmentHistory) ...[
                        const SizedBox(height: 20),
                        _buildSectionCard(
                          title: 'Assignment History',
                          subtitle: 'Total assignments: ${asset.totalAssignments}',
                          child: Column(
                            children: [
                              ...asset.assignmentHistory.map((record) =>
                                  _buildAssignmentHistoryCard(record)
                              ).toList(),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Close Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Close Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.grey.shade800,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

// ——— Helper Widgets ——————————————————————————————————————————————

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.hardEdge,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.grey.shade600),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String value, {Widget? leading}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

// ——— Utility Functions ——————————————————————————————————————————

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'laptop': return Colors.blue;
      case 'phone': return Colors.green;
      case 'tablet': return Colors.orange;
      case 'monitor': return Colors.purple;
      default: return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'laptop': return Icons.laptop;
      case 'phone': return Icons.phone_android;
      case 'tablet': return Icons.tablet_android;
      case 'monitor': return Icons.monitor;
      default: return Icons.devices;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Colors.green;
      case 'inactive': return Colors.grey;
      case 'maintenance': return Colors.orange;
      case 'retired': return Colors.red;
      default: return Colors.blue;
    }
  }

  Color _getConditionColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent': return Colors.green;
      case 'good': return Colors.blue;
      case 'fair': return Colors.orange;
      case 'poor': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getConditionIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'excellent': return Icons.star;
      case 'good': return Icons.star_half;
      case 'fair': return Icons.star_border;
      case 'poor': return Icons.warning;
      default: return Icons.info_outline;
    }
  }


  Widget _buildAssignmentHistoryCard(AssignmentRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Employee: ${record.employee.substring(0, 8)}...', // Show first 8 chars of employee ID
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: record.returnedDate == null
                        ? Colors.green.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.returnedDate == null ? 'Active' : 'Returned',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: record.returnedDate == null ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned: ${_formatDateShort(record.assignedDate)}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      if (record.returnedDate != null)
                        Text(
                          'Returned: ${_formatDateShort(record.returnedDate!)}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConditionColor(record.condition).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.condition,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getConditionColor(record.condition),
                    ),
                  ),
                ),
              ],
            ),
            if (record.remarks.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Remarks: ${record.remarks}',
                style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateShort(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    try {
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}