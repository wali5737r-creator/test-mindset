import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Shared pieces for the two Learning Mode maps (Pakistan + World).
///
/// Both maps are REAL slippy maps since v1.4: OpenTopoMap tiles via
/// flutter_map — pinch zoom, pan, and relief shading that makes
/// mountains and valleys look raised, Mapcarta-style. Tiles are
/// cached on disk by flutter_map's built-in caching provider, so an
/// area viewed once keeps opening offline afterwards.

/// The OpenTopoMap tile layer (relief / contour style).
TileLayer topoTileLayer({required VoidCallback onTileError}) {
  return TileLayer(
    urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
    subdomains: const <String>['a', 'b', 'c'],
    maxNativeZoom: 15,
    userAgentPackageName: 'com.muhammad.mindset',
    errorTileCallback: (_, __, ___) => onTileError(),
  );
}

/// Required attribution for the map data, shown on the map itself:
/// OpenStreetMap contributors, OpenTopoMap (CC-BY-SA), SRTM data.
Widget mapAttribution() {
  return const RichAttributionWidget(
    alignment: AttributionAlignment.bottomLeft,
    showFlutterMapAttribution: false,
    attributions: <SourceAttribution>[
      TextSourceAttribution('OpenStreetMap contributors'),
      TextSourceAttribution(
        'OpenTopoMap (CC-BY-SA)',
        prependCopyright: false,
      ),
      TextSourceAttribution('SRTM', prependCopyright: false),
    ],
  );
}

/// One map pin: a category-coloured teardrop with the place's first
/// letter in a white circle, so pins stay readable when they spread
/// out on zoom. [big] is the quiz's revealed-answer pin.
class MapPin extends StatelessWidget {
  final Color color;
  final String label;
  final VoidCallback? onTap;
  final bool big;

  const MapPin({
    super.key,
    required this.color,
    required this.label,
    this.onTap,
    this.big = false,
  });

  /// Edge length of the square box the pin is drawn in.
  double get boxSize => (big ? 46.0 : 32.0) + 10;

  @override
  Widget build(BuildContext context) {
    final glyph = big ? 46.0 : 32.0;
    final pin = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Icon(
          Icons.location_on,
          size: glyph + 10,
          color: Colors.white.withValues(alpha: 0.95),
        ),
        Icon(
          Icons.location_on,
          size: glyph,
          color: color,
        ),
        Positioned(
          top: glyph * 0.14,
          child: Container(
            width: glyph * 0.44,
            height: glyph * 0.44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Text(
              label.isEmpty ? '' : label.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: glyph * 0.30,
                height: 1.0,
              ),
            ),
          ),
        ),
      ],
    );
    if (onTap == null) return pin;
    return GestureDetector(onTap: onTap, child: pin);
  }
}

/// Banner shown when map tiles could not be loaded — no internet
/// and this area was never viewed before, so nothing is cached yet.
/// Areas already viewed keep working from the tile cache.
class MapOfflineNote extends StatelessWidget {
  const MapOfflineNote({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: Colors.amber.shade100,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: <Widget>[
          Icon(Icons.wifi_off, size: 18, color: Colors.brown.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Naqsha load karne ke liye internet chahiye — aik dafa '
              'khul jaye to save ho jata hai.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.brown.shade900),
            ),
          ),
        ],
      ),
    );
  }
}

/// Great-circle distance in kilometres between two coordinates
/// (haversine). Used by the Map Quiz to judge a tap generously.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const earthRadiusKm = 6371.0;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) *
          math.cos(_toRad(lat2)) *
          math.sin(dLon / 2) *
          math.sin(dLon / 2);
  return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _toRad(double deg) => deg * math.pi / 180.0;
