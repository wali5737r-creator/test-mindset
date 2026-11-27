import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';

/// Shared pieces for the two Learning Mode maps (Pakistan + World).
///
/// Both maps are REAL slippy maps since v1.4 (flutter_map). Since
/// v1.7 the tiles are the standard OpenStreetMap Carto style — the
/// clean, light Mapcarta look the owner asked for (the old relief
/// tiles made the map look heavy and crowded). Tiles are cached on
/// disk by flutter_map's built-in caching provider, so an area
/// viewed once keeps opening offline afterwards. Browse-mode pins
/// are clustered (see [clusteredPinsLayer]) so even 'All' stays
/// readable instead of 143 pins stacked on each other.

/// The standard OpenStreetMap (Carto) tile layer.
TileLayer topoTileLayer({required VoidCallback onTileError}) {
  return TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    maxNativeZoom: 18,
    userAgentPackageName: 'com.muhammad.mindset',
    errorTileCallback: (_, __, ___) => onTileError(),
  );
}

/// Required attribution for the map data, shown on the map itself:
/// © OpenStreetMap contributors.
Widget mapAttribution() {
  return const RichAttributionWidget(
    alignment: AttributionAlignment.bottomLeft,
    showFlutterMapAttribution: false,
    attributions: <SourceAttribution>[
      TextSourceAttribution('OpenStreetMap contributors'),
    ],
  );
}

/// Cluster bubble shown in place of a group of nearby pins: a navy
/// circle with a thin white ring and the pin count in bold white.
class ClusterBubble extends StatelessWidget {
  final int count;

  const ClusterBubble({super.key, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B2A4A),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 15,
        ),
      ),
    );
  }
}

/// Browse-mode pin layer WITH clustering (flutter_map_marker_cluster
/// 8.2.2, API verified against the published package source): nearby
/// pins collapse into a [ClusterBubble]; tapping a bubble zooms to
/// its pins' bounds. `markerChildBehavior: true` keeps each pin's
/// own tap (open the detail sheet) working exactly as it did under
/// the plain MarkerLayer — the layer adds no tap handling of its own
/// on individual pins.
Widget clusteredPinsLayer({required List<Marker> markers}) {
  return MarkerClusterLayerWidget(
    options: MarkerClusterLayerOptions(
      markers: markers,
      maxClusterRadius: 60,
      size: const Size(42, 42),
      padding: const EdgeInsets.all(40),
      zoomToBoundsOnClick: true,
      markerChildBehavior: true,
      builder: (BuildContext context, List<Marker> clustered) =>
          ClusterBubble(count: clustered.length),
    ),
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
  double get boxSize => (big ? 46.0 : 26.0) + 10;

  @override
  Widget build(BuildContext context) {
    final glyph = big ? 46.0 : 26.0;
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
              'Internet is needed to load the map. Once an area '
              'opens, it is saved on your phone.',
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
