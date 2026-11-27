import 'package:flutter/material.dart';

import '../learning_content.dart';
import '../models/learning_models.dart';
import 'feature_sheet.dart';

/// Native solar-system visual for the Space portion: the Sun and the
/// eight planets as coloured circles in correct order, drawn with
/// Flutter widgets only (no images). Sizes are roughly relative
/// (compressed — real ratios would make the small planets invisible).
/// Tapping a body opens its full section from solar-system.md.
class SolarSystemVisual extends StatelessWidget {
  const SolarSystemVisual({super.key});

  static const Map<String, double> _sizes = <String, double>{
    'sun': 92,
    'mercury': 24,
    'venus': 36,
    'earth': 38,
    'mars': 30,
    'jupiter': 72,
    'saturn': 58,
    'uranus': 46,
    'neptune': 46,
  };

  static const Map<String, Color> _colors = <String, Color>{
    'sun': Color(0xFFF6A821),
    'mercury': Color(0xFFB8B2AB),
    'venus': Color(0xFFE8C97A),
    'earth': Color(0xFF3E7CB1),
    'mars': Color(0xFFD1603D),
    'jupiter': Color(0xFFD8B48F),
    'saturn': Color(0xFFE6CF9E),
    'uranus': Color(0xFFAFDBE0),
    'neptune': Color(0xFF3055C8),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B2E),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.rocket_launch, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'The Solar System — the Sun and Eight Planets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Every planet is shown in its real colour and correct '
            'order. Tap any of them — its full details will open.',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                for (final section in allPlanetSections)
                  _bodyItem(context, section),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bodyItem(BuildContext context, PlanetSection section) {
    final size = _sizes[section.id] ?? 36;
    return InkWell(
      onTap: () => showBlocksSheet(
        context,
        title: section.label,
        icon: section.id == 'sun' ? Icons.wb_sunny : Icons.public,
        blocks: section.blocks,
      ),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 100,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _circle(section, size),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              section.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              section.urduName,
              style: const TextStyle(color: Colors.white60, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circle(PlanetSection section, double size) {
    final color = _colors[section.id] ?? Colors.blueGrey;
    Widget circle;
    if (section.id == 'sun') {
      circle = Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: <Color>[Color(0xFFFFE082), Color(0xFFF6A821), Color(0xFFE07B1F)],
            stops: <double>[0.2, 0.65, 1.0],
          ),
        ),
      );
    } else if (section.id == 'jupiter') {
      circle = ClipOval(
        child: SizedBox(
          width: size,
          height: size,
          child: Column(
            children: <Widget>[
              Expanded(child: Container(color: const Color(0xFFD8B48F))),
              Expanded(child: Container(color: const Color(0xFFB08968))),
              Expanded(child: Container(color: const Color(0xFFEAD9B8))),
              Expanded(child: Container(color: const Color(0xFFC08552))),
              Expanded(child: Container(color: const Color(0xFFD8B48F))),
            ],
          ),
        ),
      );
    } else {
      circle = Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          gradient: RadialGradient(
            center: const Alignment(-0.35, -0.35),
            colors: <Color>[Color.lerp(color, Colors.white, 0.35)!, color],
          ),
        ),
      );
    }
    if (section.id == 'saturn') {
      return SizedBox(
        width: size * 1.75,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            Container(
              width: size * 1.7,
              height: size * 0.52,
              decoration: BoxDecoration(
                border: Border.all(
                  color: const Color(0xFFCBB27F),
                  width: 5,
                ),
                borderRadius: BorderRadius.all(
                  Radius.elliptical(size * 0.85, size * 0.26),
                ),
              ),
            ),
            circle,
          ],
        ),
      );
    }
    return circle;
  }
}
