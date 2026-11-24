import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../models/geo_fence_location.dart';
import '../services/geo_fence_service.dart';

// ─── Shared design tokens (mirrors ShiftDesign) ──────────────────
class MapDesign {
  static const Color bg = Color(0xFFF6F7FB);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A1D26);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color border = Color(0xFFEAECEF);
  static const Color primary = Color(0xFF0F766E);
  static const Color primarySoft = Color(0xFFF0FDFA);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFD97706);

  static const double radiusMd = 18;
  static const double radiusLg = 24;

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 16,
      offset: const Offset(0, 6),
      spreadRadius: -4,
    ),
  ];
}

class GeoFenceMapScreen extends StatefulWidget {
  final GeoFenceLocation? initialFocus;

  const GeoFenceMapScreen({super.key, this.initialFocus});

  @override
  State<GeoFenceMapScreen> createState() => _GeoFenceMapScreenState();
}

class _GeoFenceMapScreenState extends State<GeoFenceMapScreen> {
  final GeoFenceService _service = GeoFenceService();
  final MapController _mapController = MapController();

  bool _loading = true;
  String? _error;
  List<GeoFenceLocation> _locations = [];
  GeoFenceLocation? _selected;
  LatLng? _myPosition;
  bool _locating = false;

  // Default center = Gurugram (from your API sample)
  static const LatLng _defaultCenter = LatLng(28.4094, 77.0486);

  @override
  void initState() {
    super.initState();
    _selected = widget.initialFocus;
    _load();
    _getCurrentLocation(silent: true);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchLocations(forceRefresh: true);
      if (!mounted) return;
      setState(() {
        _locations = list;
        _selected ??= list.isNotEmpty ? list.first : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _getCurrentLocation({bool silent = false}) async {
    if (!silent) setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!silent) _showSnack('Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;
      setState(() => _myPosition = LatLng(pos.latitude, pos.longitude));
    } catch (e) {
      if (!silent) _showSnack('Could not get location');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  void _focusOn(GeoFenceLocation loc) {
    setState(() => _selected = loc);
    final target = _centerOf(loc);
    _mapController.move(target, _zoomFor(loc));
  }

  LatLng _centerOf(GeoFenceLocation loc) {
    if (loc.isCircle && loc.latitude != null && loc.longitude != null) {
      return LatLng(loc.latitude!, loc.longitude!);
    }
    if (loc.polylinePoints.isNotEmpty) {
      double lat = 0, lng = 0;
      for (final p in loc.polylinePoints) {
        lat += p.latitude;
        lng += p.longitude;
      }
      return LatLng(lat / loc.polylinePoints.length, lng / loc.polylinePoints.length);
    }
    return _defaultCenter;
  }

  double _zoomFor(GeoFenceLocation loc) {
    if (loc.isCircle) {
      // Simple heuristic: bigger radius → zoom out
      if (loc.radiusMeters > 1000) return 13;
      if (loc.radiusMeters > 500) return 14;
      if (loc.radiusMeters > 200) return 15;
      return 16;
    }
    return 14;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MapDesign.bg,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: MapDesign.primary))
          : _error != null
          ? _errorView()
          : Stack(
        children: [
          _buildMap(),
          _buildTopBadge(),
          _buildControls(),
          _buildLocationSheet(),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: MapDesign.bg,
      surfaceTintColor: MapDesign.bg,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            backgroundColor: MapDesign.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: MapDesign.textPrimary),
        ),
      ),
      title: const Text(
        'Geo-Fence Map',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: MapDesign.textPrimary,
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
    );
  }

  // ── Map ─────────────────────────────────────────────────────
  Widget _buildMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _selected != null ? _centerOf(_selected!) : _defaultCenter,
        initialZoom: _selected != null ? _zoomFor(_selected!) : 15,
        minZoom: 3,
        maxZoom: 19,
        onTap: (_, __) => setState(() => _selected = null),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.staffsync.app',
        ),
        // ── Geofence layers ──
        CircleLayer(circles: _buildCircles()),
        PolylineLayer(polylines: _buildPolylines()),
        MarkerLayer(markers: _buildMarkers()),
        // ── My location ──
        if (_myPosition != null)
          MarkerLayer(
            markers: [
              Marker(
                point: _myPosition!,
                width: 24,
                height: 24,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2563EB),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        const RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }

  List<CircleMarker> _buildCircles() {
    final circles = <CircleMarker>[];
    for (final loc in _locations.where((l) => l.isCircle)) {
      if (loc.latitude == null || loc.longitude == null) continue;
      final selected = _selected?.id == loc.id;
      circles.add(
        CircleMarker(
          point: LatLng(loc.latitude!, loc.longitude!),
          radius: loc.radiusMeters,
          useRadiusInMeter: true,
          color: MapDesign.primary.withOpacity(selected ? 0.20 : 0.10),
          borderColor: selected
              ? MapDesign.primary
              : MapDesign.primary.withOpacity(0.6),
          borderStrokeWidth: selected ? 3 : 1.5,
        ),
      );
    }
    return circles;
  }

  List<Polyline> _buildPolylines() {
    final lines = <Polyline>[];
    for (final loc in _locations.where((l) => l.isPolyline)) {
      if (loc.polylinePoints.length < 2) continue;
      final selected = _selected?.id == loc.id;
      lines.add(
        Polyline(
          points: loc.polylinePoints
              .map((p) => LatLng(p.latitude, p.longitude))
              .toList(),
          strokeWidth: selected ? 6 : 4,
          color: selected
              ? MapDesign.primary
              : MapDesign.primary.withOpacity(0.55),
          borderStrokeWidth: 2,
          borderColor: Colors.white.withOpacity(0.9),
          strokeCap: StrokeCap.round,
          strokeJoin: StrokeJoin.round,
        ),
      );
    }
    return lines;
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    for (final loc in _locations) {
      final point = _centerOf(loc);
      final selected = _selected?.id == loc.id;
      final isCircle = loc.isCircle;

      // For polyline we still put a label at the midpoint
      markers.add(
        Marker(
          point: point,
          width: 160,
          height: 60,
          alignment: Alignment.center,
          child: GestureDetector(
            onTap: () => _focusOn(loc),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isCircle)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? MapDesign.primary : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? MapDesign.primary
                            : MapDesign.border,
                      ),
                      boxShadow: MapDesign.softShadow,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alt_route_rounded,
                          size: 12,
                          color: selected ? Colors.white : MapDesign.primary,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            loc.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: selected
                                  ? Colors.white
                                  : MapDesign.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selected ? MapDesign.primary : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: MapDesign.primary, width: 2),
                      boxShadow: MapDesign.softShadow,
                    ),
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: selected ? Colors.white : MapDesign.primary,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }
    return markers;
  }

  // ── Floating UI ─────────────────────────────────────────────
  Widget _buildTopBadge() {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: MapDesign.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: MapDesign.border),
          boxShadow: MapDesign.softShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF059669),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${_locations.length} zone${_locations.length == 1 ? '' : 's'} configured',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MapDesign.textPrimary,
              ),
            ),
            const Spacer(),
            if (_selected != null)
              Flexible(
                child: Text(
                  _selected!.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: MapDesign.textSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      right: 16,
      bottom: 190,
      child: Column(
        children: [
          _controlButton(
            icon: Icons.my_location_rounded,
            loading: _locating,
            onTap: () async {
              await _getCurrentLocation();
              if (_myPosition != null) {
                _mapController.move(_myPosition!, 16);
              }
            },
          ),
          const SizedBox(height: 10),
          _controlButton(
            icon: Icons.refresh_rounded,
            onTap: _load,
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required VoidCallback onTap,
    bool loading = false,
  }) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: MapDesign.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: MapDesign.softShadow,
          border: Border.all(color: MapDesign.border),
        ),
        child: loading
            ? const Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: MapDesign.primary,
          ),
        )
            : Icon(icon, color: MapDesign.textPrimary, size: 22),
      ),
    );
  }

  // ── Bottom sheet list ───────────────────────────────────────
  Widget _buildLocationSheet() {
    if (_locations.isEmpty) return const SizedBox.shrink();
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: MapDesign.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: MapDesign.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              ConstrainedBox(
                // ✅ hard cap — never overflows, scrolls horizontally
                constraints: const BoxConstraints(maxHeight: 132),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  shrinkWrap: true,
                  itemCount: _locations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _locationChip(_locations[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _locationChip(GeoFenceLocation loc) {
    final selected = _selected?.id == loc.id;
    final isCircle = loc.isCircle;
    return GestureDetector(
      onTap: () => _focusOn(loc),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 200,
        // ✅ no fixed height — let it hug content
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? MapDesign.primarySoft : MapDesign.surface,
          borderRadius: BorderRadius.circular(MapDesign.radiusMd),
          border: Border.all(
            color: selected ? MapDesign.primary : MapDesign.border,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected ? MapDesign.softShadow : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ✅ was the missing piece
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: selected ? MapDesign.primary : MapDesign.primarySoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    isCircle
                        ? Icons.radio_button_unchecked_rounded
                        : Icons.alt_route_rounded,
                    size: 16,
                    color: selected ? Colors.white : MapDesign.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: selected ? MapDesign.primary : MapDesign.textPrimary,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              loc.address,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                height: 1.3,
                color: MapDesign.textSecondary,
              ),
            ),
            const SizedBox(height: 8), // ✅ was Spacer() — now deterministic
            Row(
              children: [
                Flexible(
                  child: _pill(
                    isCircle ? 'Radius' : 'Corridor',
                    isCircle
                        ? '${loc.radiusMeters.toStringAsFixed(0)}m'
                        : '${loc.corridorWidthMeters.toStringAsFixed(0)}m',
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(child: _pill(loc.type, null)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, String? value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: MapDesign.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MapDesign.border),
      ),
      child: Text(
        value != null ? '$label · $value' : label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: MapDesign.textSecondary,
        ),
      ),
    );
  }

  // ── Error ───────────────────────────────────────────────────
  Widget _errorView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: MapDesign.surface,
            borderRadius: BorderRadius.circular(MapDesign.radiusLg),
            border: Border.all(color: const Color(0xFFFECACA)),
            boxShadow: MapDesign.softShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.map_outlined,
                    color: MapDesign.danger, size: 28),
              ),
              const SizedBox(height: 14),
              const Text(
                'Could not load geofences',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: MapDesign.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: MapDesign.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: MapDesign.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}