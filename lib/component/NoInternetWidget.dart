import 'package:flutter/material.dart';

class NoInternetWidget extends StatefulWidget {
  final VoidCallback? onRetry;
  final String? message;
  final String? subMessage;
  final String? imageAsset;
  final Color? primaryColor;
  final Color? backgroundColor;
  final bool showAnimation;

  const NoInternetWidget({
    super.key,
    this.onRetry,
    this.message = "No Internet Connection",
    this.subMessage = "Our boy just cut the wire again 💀",
    this.imageAsset = "assets/no_internet.png",
    this.primaryColor,
    this.backgroundColor,
    this.showAnimation = true,
  });

  @override
  State<NoInternetWidget> createState() => _NoInternetWidgetState();
}

class _NoInternetWidgetState extends State<NoInternetWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );

    if (widget.showAnimation) {
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color get _primaryColor => widget.primaryColor ?? Theme.of(context).primaryColor;
  Color get _backgroundColor => widget.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated Illustration
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: widget.showAnimation ? _pulseAnimation.value : 1.0,
                      child: Opacity(
                        opacity: widget.showAnimation ? _fadeAnimation.value : 1.0,
                        child: child,
                      ),
                    );
                  },
                  child: _buildIllustration(isDark),
                ),

                const SizedBox(height: 40),

                // Main Message with animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        widget.showAnimation ? _slideAnimation.value : 0,
                      ),
                      child: Opacity(
                        opacity: widget.showAnimation ? _fadeAnimation.value : 1.0,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Text(
                        widget.message!,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 16),

                      // Submessage with better typography
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          widget.subMessage!,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.6,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),

                // Retry Button with animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        widget.showAnimation ? _slideAnimation.value * 1.5 : 0,
                      ),
                      child: Opacity(
                        opacity: widget.showAnimation ? _fadeAnimation.value : 1.0,
                        child: child,
                      ),
                    );
                  },
                  child: _buildRetryButton(isDark),
                ),

                // Optional: Add WiFi indicator animation
                if (widget.showAnimation) ...[
                  const SizedBox(height: 32),
                  _buildWifiIndicator(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(bool isDark) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primaryColor.withOpacity(0.1),
            _primaryColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle pattern
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.black12 : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),

          // Image with fallback
          Padding(
            padding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(40),
              child: Image.asset(
                widget.imageAsset!,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primaryColor.withOpacity(0.1),
                    ),
                    child: Icon(
                      Icons.wifi_off_rounded,
                      size: 64,
                      color: _primaryColor,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton(bool isDark) {
    return ElevatedButton.icon(
      onPressed: widget.onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text(
        "Retry Connection",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: _primaryColor.withOpacity(0.3),
        surfaceTintColor: Colors.transparent,
      ).copyWith(
        overlayColor: MaterialStateProperty.all(
          Colors.white.withOpacity(0.1),
        ),
      ),
    );
  }

  Widget _buildWifiIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              width: 6,
              height: 24 * (index + 1),
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.3 + (0.2 * index)),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          "Checking connection...",
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }
}