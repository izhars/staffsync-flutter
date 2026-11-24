import 'package:flutter/material.dart';

class BouncyFeatureCard extends StatefulWidget {
  final String title;
  final String gifAssetPath;
  final List<Color> gradientColors;
  final Color iconColor;
  final VoidCallback onTap;

  const BouncyFeatureCard({
    Key? key,
    required this.title,
    required this.gifAssetPath,
    required this.gradientColors,
    required this.iconColor,
    required this.onTap,
  }) : super(key: key);

  @override
  State<BouncyFeatureCard> createState() => _BouncyFeatureCardState();
}

class _BouncyFeatureCardState extends State<BouncyFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  double _cardScale = 1.0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
      lowerBound: 0.0,  // Explicitly set bounds
      upperBound: 1.0,  // Explicitly set bounds
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.18).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    setState(() => _cardScale = 0.93);
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    setState(() => _cardScale = 1.0);
    Future.delayed(const Duration(milliseconds: 150), widget.onTap);
  }

  void _onTapCancel() {
    setState(() => _cardScale = 1.0);
  }

  void _onHover(bool hovering) {
    if (mounted) {
      setState(() {
        _isHovered = hovering;
      });
      if (hovering) {
        // Use repeat() with explicit min and max values
        _animationController.repeat(min: 0.0, max: 1.0, reverse: true);
      } else {
        _animationController.stop();
        _animationController.animateTo(0.0, duration: const Duration(milliseconds: 200));
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildGifIcon() {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.white.withOpacity(0.1),
          ],
          stops: [0.1, 0.8],
        ),
        boxShadow: [
          BoxShadow(
            color: widget.iconColor.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: ClipOval(
            child: Image.asset(
              widget.gifAssetPath,
              width: 34,
              height: 34,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.iconColor.withOpacity(0.3),
                  ),
                  child: const Icon(
                    Icons.error,
                    color: Colors.white,
                    size: 18,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: AnimatedScale(
          scale: _cardScale,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: Container(
            constraints: BoxConstraints(
              minHeight: 120,
              maxHeight: 140,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  widget.gradientColors.first.withOpacity(_isHovered ? 0.9 : 0.85),
                  widget.gradientColors.last.withOpacity(_isHovered ? 0.8 : 0.75),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(
                color: Colors.white.withOpacity(_isHovered ? 0.35 : 0.25),
                width: _isHovered ? 2.0 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.gradientColors.last
                      .withOpacity(_isHovered ? 0.45 : 0.35),
                  blurRadius: _isHovered ? 18 : 12,
                  offset: Offset(0, _isHovered ? 8 : 6),
                ),
                if (_isHovered)
                  BoxShadow(
                    color: widget.iconColor.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(_isHovered ? 0.08 : 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated GIF Icon Container
                    AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Transform.scale(
                            scale: _scaleAnimation.value,
                            child: _buildGifIcon(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    // Title with glow effect
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white.withOpacity(0.05),
                        ),
                        child: Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            letterSpacing: 0.3,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.4),
                                offset: const Offset(1, 1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}