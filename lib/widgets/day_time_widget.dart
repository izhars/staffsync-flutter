import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../models/air_quality_data.dart';
import '../models/quote.dart';
import '../screens/quotes_list_screen.dart';
import '../services/aqi_service.dart';
import '../services/quote_service.dart';

// ===================== DESIGN TOKENS =====================

class AppDesign {
  // ===================== SPACING =====================

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 18;
  static const double xl = 20;

  // ===================== RADIUS =====================

  static const double radiusSm = 12;
  static const double radiusMd = 18;
  static const double radiusLg = 20;
  static const double radiusXl = 28;

  // ===================== AESTHETIC COLORS =====================

  // Backgrounds
  static const Color background = Color(0xFFF7F7F8);
  static const Color surface = Color(0xFFFFFFFF);

  // Text
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Brand / accent
  static const Color primary = Color(0xFF6366F1);
  static const Color primarySoft = Color(0xFFEEF2FF);

  // Supporting accents
  static const Color lavender = Color(0xFF8B7CF6);
  static const Color teal = Color(0xFF5FB3A2);
  static const Color peach = Color(0xFFE9A27F);
  static const Color rose = Color(0xFFD98FA3);
  static const Color slate = Color(0xFF64748B);

  // ===================== TYPOGRAPHY =====================

  static const TextStyle displayLg = TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    height: 1.0,
    letterSpacing: -2.0,
  );

  static const TextStyle headline = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.4,
  );

  static const TextStyle titleLg = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle titleSm = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 13.5,
    fontWeight: FontWeight.w500,
    height: 1.35,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11.5,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.6,
  );

  // ===================== AQI =====================

  static Color aqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF5FB3A2);
    if (aqi <= 100) return const Color(0xFFD6A84F);
    if (aqi <= 150) return const Color(0xFFE09A72);
    if (aqi <= 200) return const Color(0xFFD47F88);
    if (aqi <= 300) return const Color(0xFF9B8CC4);
    return const Color(0xFFB85C6A);
  }

  static String aqiLabel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }
}
// ===================== RESPONSIVE BREAKPOINT HELPERS =====================

// ✅ FIX: A single place to decide if a screen is "narrow".
// 380dp is a good cutoff: iPhone SE (320/375), small Androids (360),
// all hit "narrow" and get the stacked layout.
class _BP {
  static const double narrow = 380;
  static bool isNarrow(BuildContext c) =>
      MediaQuery.sizeOf(c).width < narrow;
}

// ===================== MAIN WIDGET =====================

class DayTimeWidget extends StatefulWidget {
  const DayTimeWidget({Key? key}) : super(key: key);

  @override
  State<DayTimeWidget> createState() => _DayTimeWidgetState();
}

class _DayTimeWidgetState extends State<DayTimeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  Quote? _currentQuote;
  bool _isLoadingQuote = true;

  AirQualityData? _airQualityData;
  bool _isLoadingAQI = true;
  String _address = 'Fetching location...';
  Position? _currentPosition;
  final AQIService _aqiService = AQIService();

  @override
  void initState() {
    super.initState();
    _fetchQuote();
    _getLocationAndAQI();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
          ),
        );
    _controller.forward();
  }

  Future<void> _getLocationAndAQI() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _address = 'Location permission denied';
            _isLoadingAQI = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _address = 'Location permission permanently denied';
          _isLoadingAQI = false;
        });
        return;
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _address = 'Location services disabled';
          _isLoadingAQI = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentPosition = position;

      try {
        final placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        final p = placemarks.isNotEmpty ? placemarks.first : null;
        final addr = p != null
            ? '${p.locality ?? ''}, ${p.administrativeArea ?? ''}'.trim()
            : 'Unknown location';
        if (mounted) {
          setState(() => _address = addr.isEmpty ? 'Unknown location' : addr);
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _address =
            '${position.latitude.toStringAsFixed(2)}, ${position.longitude.toStringAsFixed(2)}';
          });
        }
      }

      final aqiData =
      await _aqiService.fetchByGeo(position.latitude, position.longitude);
      if (mounted) {
        setState(() {
          _airQualityData = aqiData;
          _isLoadingAQI = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _address = 'Location error';
          _isLoadingAQI = false;
        });
      }
      debugPrint('Error getting location and AQI: $e');
    }
  }

  Future<void> _fetchQuote() async {
    setState(() => _isLoadingQuote = true);
    try {
      final quote = await QuoteService().fetchRandomQuote();
      if (mounted) setState(() => _currentQuote = quote);
    } catch (e, stackTrace) {
      if (mounted) {
        setState(() {
          _currentQuote = Quote(
            text:
            "The best time to plant a tree was 20 years ago. The second best time is now.",
            author: "Chinese Proverb",
            body: '',
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingQuote = false);
    }
  }

  int _getCurrentTimeIndex() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return 0;
    if (hour >= 12 && hour < 17) return 1;
    if (hour >= 17 && hour < 21) return 2;
    return 3;
  }

  _TimeSection _getCurrentSection() {
    final sections = [
      _TimeSection(
        title: "Good Morning",
        subtitle: "Rise and shine",
        emoji: "🌅",
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _TimeSection(
        title: "Good Afternoon",
        subtitle: "Keep the momentum",
        emoji: "☀️",
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9488), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _TimeSection(
        title: "Good Evening",
        subtitle: "Time to unwind",
        emoji: "🌆",
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      _TimeSection(
        title: "Good Night",
        subtitle: "Rest and recharge",
        emoji: "🌙",
        gradient: const LinearGradient(
          colors: [Color(0xFF334155), Color(0xFF1E293B)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    ];
    return sections[_getCurrentTimeIndex()];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final section = _getCurrentSection();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: _DayTimeCard(
                section: section,
                quote: _currentQuote,
                isLoadingQuote: _isLoadingQuote,
                onRefreshQuote: _fetchQuote,
                airQualityData: _airQualityData,
                isLoadingAQI: _isLoadingAQI,
                address: _address,
                onRefreshAQI: _getLocationAndAQI,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimeSection {
  final String title;
  final String subtitle;
  final String emoji;
  final LinearGradient gradient;

  _TimeSection({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.gradient,
  });
}

// ===================== MAIN CARD =====================

class _DayTimeCard extends StatefulWidget {
  final _TimeSection section;
  final Quote? quote;
  final bool isLoadingQuote;
  final VoidCallback onRefreshQuote;
  final AirQualityData? airQualityData;
  final bool isLoadingAQI;
  final String address;
  final VoidCallback onRefreshAQI;

  const _DayTimeCard({
    required this.section,
    required this.quote,
    required this.isLoadingQuote,
    required this.onRefreshQuote,
    required this.airQualityData,
    required this.isLoadingAQI,
    required this.address,
    required this.onRefreshAQI,
  });

  @override
  State<_DayTimeCard> createState() => _DayTimeCardState();
}

class _DayTimeCardState extends State<_DayTimeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: responsive paddings + margins — no more 20px+18px eaten
    // on a 320dp screen.
    final isNarrow = _BP.isNarrow(context);
    final hPad = isNarrow ? 14.0 : AppDesign.xl;
    final vPad = isNarrow ? 14.0 : AppDesign.xl;
    final hMargin = isNarrow ? 10.0 : AppDesign.lg;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        margin: EdgeInsets.symmetric(
          horizontal: hMargin,
          vertical: AppDesign.sm,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDesign.radiusXl),
          border: Border.all(
            color: Colors.white.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 10),
              spreadRadius: 0,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDesign.radiusXl),
          child: Stack(
            children: [
              // Solid wall
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: widget.section.gradient,
                  ),
                ),
              ),

              // Decorative icon
              Positioned(
                right: -25,
                bottom: -25,
                child: Opacity(
                  opacity: 0.05,
                  child: Icon(
                    _getIconForSection(widget.section.title),
                    size: 130,
                    color: Colors.white,
                  ),
                ),
              ),

              // Content
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hPad,
                  vertical: vPad,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ============ TOP SECTION ============
                    // ✅ FIX: swap between wide (side-by-side) and narrow
                    // (stacked) layouts. On narrow screens the two-column
                    // Row with flex 5/5 was the #1 cause of overflow.
                    isNarrow
                        ? _buildNarrowTop(context)
                        : _buildWideTop(context),

                    // ============ DIVIDER BEFORE QUOTE ============
                    const SizedBox(height: AppDesign.md),
                    Container(
                      height: 1,
                      width: double.infinity,
                      color: Colors.white.withOpacity(0.25),
                    ),
                    const SizedBox(height: AppDesign.md),

                    // ============ QUOTE ============
                    if (widget.isLoadingQuote)
                      const SizedBox(height: 24, child: _InlineLoading())
                    else if (widget.quote != null)
                      _CompactQuoteRow(
                        quote: widget.quote!,
                        onRefresh: widget.onRefreshQuote,
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- WIDE LAYOUT (≥ 380dp) ----------
  Widget _buildWideTop(BuildContext context) {
    // ✅ FIX: IntrinsicHeight makes the divider match the tallest column
    // instead of a hard-coded 90. No more mismatch when text wraps.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LEFT: Time + title
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DigitalTimeCompact(),
                const SizedBox(height: 6),
                Text(
                  widget.section.title,
                  style: AppDesign.titleSm.copyWith(color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Divider (stretches to match tallest column)
          Container(
            width: 1,
            color: Colors.white.withOpacity(0.3),
            margin: const EdgeInsets.symmetric(horizontal: AppDesign.md),
          ),

          // RIGHT: Location, date, AQI, temp/humidity
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                _LocationBlock(address: widget.address),
                const SizedBox(height: AppDesign.md),
                if (widget.isLoadingAQI)
                  const SizedBox(height: 28, child: _InlineLoading())
                else if (widget.airQualityData != null)
                  _CompactMetricsRow(
                    data: widget.airQualityData!,
                    onRefresh: widget.onRefreshAQI,
                  )
                else
                  _InlineError(onRetry: widget.onRefreshAQI),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- NARROW LAYOUT (< 380dp) ----------
  Widget _buildNarrowTop(BuildContext context) {
    // ✅ FIX: full-width stacked — clock, title, then location block,
    // then metrics. Nothing shares horizontal space with the clock,
    // so it can never overflow.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Clock + greeting row
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const _DigitalTimeCompact(),
            const SizedBox(width: AppDesign.sm),
            Flexible(
              child: Text(
                widget.section.title,
                style: AppDesign.titleSm.copyWith(color: Colors.white),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDesign.md),

        _LocationBlock(address: widget.address),
        const SizedBox(height: AppDesign.sm),

        if (widget.isLoadingAQI)
          const SizedBox(height: 28, child: _InlineLoading())
        else if (widget.airQualityData != null)
          _CompactMetricsRow(
            data: widget.airQualityData!,
            onRefresh: widget.onRefreshAQI,
          )
        else
          _InlineError(onRetry: widget.onRefreshAQI),
      ],
    );
  }

  IconData _getIconForSection(String title) {
    if (title.contains('Morning')) return Icons.wb_sunny_rounded;
    if (title.contains('Afternoon')) return Icons.wb_sunny_outlined;
    if (title.contains('Evening')) return Icons.wb_twilight_rounded;
    return Icons.nightlight_round;
  }
}

// ===================== LOCATION BLOCK (extracted, reused) =====================

class _LocationBlock extends StatelessWidget {
  final String address;
  const _LocationBlock({required this.address});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const Icon(
              Icons.location_on_rounded,
              size: 15,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                address,
                style: AppDesign.bodySm.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          _formatDate(DateTime.now()),
          style: AppDesign.caption.copyWith(
            color: Colors.white.withOpacity(0.85),
            fontSize: 10.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

// ===================== DIGITAL TIME =====================

class _DigitalTimeCompact extends StatefulWidget {
  const _DigitalTimeCompact();

  @override
  State<_DigitalTimeCompact> createState() => _DigitalTimeCompactState();
}

class _DigitalTimeCompactState extends State<_DigitalTimeCompact> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final period = _now.hour >= 12 ? 'PM' : 'AM';

    // ✅ FIX: clock font scales down on small screens. Previously it was
    // a fixed 40px inside a flex:5 column, which truncated "12:59" on
    // a 320dp screen.
    final w = MediaQuery.sizeOf(context).width;
    final clockSize = w < 340 ? 28.0 : (w < 380 ? 32.0 : 40.0);
    final periodSize = w < 380 ? 10.0 : 11.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            '$hour:$minute',
            style: AppDesign.displayLg.copyWith(
              color: Colors.white,
              fontSize: clockSize,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            period,
            style: AppDesign.caption.copyWith(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w700,
              fontSize: periodSize,
            ),
          ),
        ),
      ],
    );
  }
}

// ===================== METRICS ROW =====================

class _CompactMetricsRow extends StatelessWidget {
  final AirQualityData data;
  final VoidCallback onRefresh;

  const _CompactMetricsRow({required this.data, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final aqiColor = AppDesign.aqiColor(data.aqi);
    final aqiLabel = AppDesign.aqiLabel(data.aqi);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Row 1: AQI pill + refresh
        Row(
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: aqiColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSm),
                  border:
                  Border.all(color: aqiColor.withOpacity(0.7), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: aqiColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${data.aqi}',
                      style: AppDesign.titleSm.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        aqiLabel,
                        style: AppDesign.caption.copyWith(
                          color: Colors.white,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppDesign.sm),
            _RefreshButton(onPressed: onRefresh, size: 15),
          ],
        ),
        const SizedBox(height: 6),

        // ✅ FIX: Was a raw Row of [icon, text, icon, text, icon, text]
        // with no Flexible → guaranteed RenderFlex overflow on small
        // screens. Now a Wrap that drops to a new line when needed.
        Wrap(
          spacing: AppDesign.md,
          runSpacing: 4,
          children: [
            _MetricChip(
              icon: Icons.thermostat_rounded,
              label: '${data.temperature.toStringAsFixed(0)}°',
            ),
            _MetricChip(
              icon: Icons.water_drop_rounded,
              label: '${data.humidity}%',
            ),
            _MetricChip(
              icon: Icons.grain_rounded,
              label: 'PM2.5 ${data.pm25.toStringAsFixed(0)}',
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _MetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppDesign.titleSm.copyWith(
            color: Colors.white,
            fontSize: 12.5,
          ),
        ),
      ],
    );
  }
}

// ===================== QUOTE ROW =====================

class _CompactQuoteRow extends StatelessWidget {
  final Quote quote;
  final VoidCallback onRefresh;

  const _CompactQuoteRow({required this.quote, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QuotesListScreen()),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.format_quote_rounded,
            color: Colors.white.withOpacity(0.7),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${quote.text} — ${quote.author}',
              style: AppDesign.bodySm.copyWith(
                color: Colors.white,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
                fontSize: 13,
                height: 1.4,
              ),
              maxLines: 3, // ✅ FIX: was 2 — 3 reads better on narrow.
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          _RefreshButton(onPressed: onRefresh, size: 16),
        ],
      ),
    );
  }
}

// ===================== INLINE STATES =====================

class _InlineLoading extends StatelessWidget {
  const _InlineLoading();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
        ),
        const SizedBox(width: AppDesign.sm + 2),
        Text(
          'Loading...',
          style: AppDesign.bodySm.copyWith(color: Colors.white),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  final VoidCallback onRetry;
  const _InlineError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: Colors.white,
          size: 16,
        ),
        const SizedBox(width: AppDesign.sm + 2),
        Expanded(
          child: Text(
            'Unavailable',
            style: AppDesign.bodySm.copyWith(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        _RefreshButton(onPressed: onRetry, size: 16),
      ],
    );
  }
}

// ===================== REFRESH BUTTON =====================

class _RefreshButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double size;

  const _RefreshButton({required this.onPressed, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppDesign.radiusSm),
        child: Padding(
          padding: const EdgeInsets.all(6), // ✅ FIX: was 4 — bigger tap target.
          child: Icon(
            Icons.refresh_rounded,
            color: Colors.white,
            size: size,
          ),
        ),
      ),
    );
  }
}

// ===================== UTIL =====================

String _formatDate(DateTime now) {
  const months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'
  ];
  const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  return '${days[now.weekday - 1]} • ${now.day} ${months[now.month - 1]}';
}