import 'package:flutter/material.dart';

import '../theme.dart';
import 'surface_card.dart';

/// One bar per day, oldest first. Taller bars are better days, and a short
/// grey stub means no mood was logged.
class MoodStrip extends StatelessWidget {
  const MoodStrip({super.key, required this.moods});

  final List<int?> moods;

  double _barHeight(int? mood) {
    if (mood == null) return 4;
    final level = mood < 1 ? 1 : (mood > 5 ? 5 : mood);
    return 8.0 + (level - 1) * 9;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final logged = moods.whereType<int>().length;

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Last ${moods.length} days',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '$logged logged',
                style: TextStyle(color: colors.muted, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final mood in moods)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.5),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: _barHeight(mood),
                          decoration: BoxDecoration(
                            color: mood == null ? colors.line : colors.accent,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Taller bars are better days.',
            style: TextStyle(color: colors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
