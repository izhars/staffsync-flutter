import 'dart:io';
import 'package:flutter/material.dart';
import '../services/avatar_api.dart';
import '../widgets/route_observer.dart';

class TopBar extends StatefulWidget implements PreferredSizeWidget {
  final String address;
  final bool isLoadingAddress;
  final VoidCallback? onAvatarTap;
  final String? avatarUrl;

  const TopBar({
    super.key,
    required this.address,
    this.isLoadingAddress = false,
    this.onAvatarTap,
    this.avatarUrl,
  });

  @override
  _TopBarState createState() => _TopBarState();

  @override
  Size get preferredSize => const Size.fromHeight(80);
}

class _TopBarState extends State<TopBar> with RouteAware {
  File? _avatar;
  bool _isLoadingAvatar = false;
  bool _hasLocalAvatar = false;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to route events so we know when a pushed screen
    // (e.g. ProfileScreen) is popped back to us.
    if (!_isSubscribed) {
      final route = ModalRoute.of(context);
      if (route is ModalRoute<void>) {
        routeObserver.subscribe(this, route);
        _isSubscribed = true;
      }
    }
  }

  @override
  void dispose() {
    if (_isSubscribed) {
      routeObserver.unsubscribe(this);
      _isSubscribed = false;
    }
    super.dispose();
  }

  /// Called when the route *above* this one was popped and we're
  /// now the topmost route again. This is our trigger to reload
  /// the avatar (profile update flow hits exactly this).
  @override
  void didPopNext() {
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      if (mounted) setState(() => _isLoadingAvatar = true);

      final hasLocal = await AvatarService.hasLocalAvatar();

      if (hasLocal) {
        final localAvatar = await AvatarService.getAvatar();
        if (!mounted) return;
        setState(() {
          _avatar = localAvatar;
          _hasLocalAvatar = localAvatar != null;
          _isLoadingAvatar = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _avatar = null;
          _hasLocalAvatar = false;
          _isLoadingAvatar = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading avatar in TopBar: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingAvatar = false;
        _hasLocalAvatar = false;
      });
    }
  }

  // Helper method to get the profile image
  ImageProvider? _getProfileImage() {
    // Priority 1: local image if available
    if (_hasLocalAvatar && _avatar != null) {
      try {
        return FileImage(_avatar!);
      } catch (e) {
        debugPrint('Error loading local avatar in TopBar: $e');
      }
    }

    // Priority 2: network image
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      return NetworkImage(widget.avatarUrl!);
    }

    // Priority 3: default asset
    return const AssetImage('assets/profile.png');
  }

  List<String> _splitAddress(String address) {
    final parts = address.split(',');
    if (parts.isEmpty) return ['', ''];
    final firstPart = parts[0].trim();
    final restParts =
    parts.length > 1 ? parts.sublist(1).join(',').trim() : '';
    return [firstPart, restParts];
  }

  Widget _buildSkeleton({
    required double width,
    required double height,
    double borderRadius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 1000),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.grey[300]!,
                Colors.grey[200]!,
                Colors.grey[300]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF1E2640) : Colors.white;
    final textPrimary = isDark ? const Color(0xFFF8FAFC) : Colors.black87;
    final textSecondary = isDark ? const Color(0xFF94A3B8) : Colors.grey[600];

    final addressParts = _splitAddress(widget.address);
    final firstPart = addressParts[0];
    final restPart = addressParts[1];

    return Container(
      decoration: BoxDecoration(
        color: surface,
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              // ---- AVATAR with local image priority ----
              GestureDetector(
                onTap: widget.onAvatarTap ??
                        () => Scaffold.of(context).openDrawer(),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blue[100]!, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _isLoadingAvatar
                      ? CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey[200],
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.blue,
                      ),
                    ),
                  )
                      : CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.grey[100],
                    child: CircleAvatar(
                      radius: 20,
                      backgroundImage: _getProfileImage(),
                      // Fallback to initials
                      child: _hasLocalAvatar == false &&
                          (widget.avatarUrl == null ||
                              widget.avatarUrl!.isEmpty)
                          ? Text(
                        'U',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      )
                          : null,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // ---- ADDRESS + LOCATION ICON ----
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: widget.isLoadingAddress
                          ? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildSkeleton(
                              width: 120, height: 18, borderRadius: 4),
                          const SizedBox(height: 6),
                          _buildSkeleton(
                              width: 180, height: 14, borderRadius: 4),
                        ],
                      )
                          : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (firstPart.isNotEmpty)
                            Text(
                              firstPart,
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: -0.5,
                                height: 1.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.right,
                            ),
                          if (restPart.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              restPart,
                              style: TextStyle(
                                color: textSecondary,
                                fontWeight: FontWeight.w400,
                                fontSize: 13,
                                height: 1.3,
                                letterSpacing: -0.2,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/location.png',
                        width: 22,
                        height: 22,
                        color: Colors.white,
                      ),
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
}