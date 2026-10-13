import 'package:flutter/material.dart';

import '../theme.dart';

const _labels = ['Rough', 'Low', 'Okay', 'Good', 'Great'];

const _icons = [
  Icons.sentiment_very_dissatisfied_outlined,
  Icons.sentiment_dissatisfied_outlined,
  Icons.sentiment_neutral_outlined,
  Icons.sentiment_satisfied_outlined,
  Icons.sentiment_very_satisfied_outlined,
];

/// Moods run from 1 (rough) to 5 (great). Out-of-range values are clamped.
int _index(int mood) => mood < 1 ? 0 : (mood > 5 ? 4 : mood - 1);

IconData moodIcon(int mood) => _icons[_index(mood)];

String moodLabel(int mood) => _labels[_index(mood)];

/// Five faces. Tapping the selected one clears it.
class MoodPicker extends StatelessWidget {
  const MoodPicker({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var mood = 1; mood <= 5; mood++)
          IconButton(
            tooltip: moodLabel(mood),
            icon: Icon(moodIcon(mood)),
            style: IconButton.styleFrom(
              backgroundColor: value == mood
                  ? colors.accentSoft
                  : Colors.transparent,
              foregroundColor: value == mood ? colors.accent : colors.muted,
            ),
            onPressed: () => onChanged(value == mood ? null : mood),
          ),
      ],
    );
  }
}
