import 'package:flutter/material.dart';

import '../data/entry.dart';
import '../theme.dart';
import '../util/dates.dart';
import 'mood_picker.dart';
import 'surface_card.dart';

/// One entry as a card. With [showDate] the left badge is the day; without it,
/// where the day is already obvious (under a calendar date), it is the time.
class EntryCard extends StatelessWidget {
  const EntryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.showDate = true,
  });

  final Entry entry;
  final VoidCallback onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final body = entry.body.replaceAll('\n', ' ').trim();
    final hasText = entry.title.isNotEmpty || body.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: showDate
                  ? Column(
                      children: [
                        Text(
                          dayNumber(entry.entryDate),
                          style: serif(context, 24),
                        ),
                        Text(
                          shortWeekday(entry.entryDate),
                          style: TextStyle(color: colors.muted, fontSize: 12),
                        ),
                      ],
                    )
                  : Text(
                      clockTime(entry.createdAt),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.muted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showDate)
                    Text(
                      clockTime(entry.createdAt),
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                  if (entry.title.isNotEmpty)
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  if (body.isNotEmpty)
                    Text(
                      body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.muted),
                    ),
                  if (!hasText)
                    Text('No text', style: TextStyle(color: colors.muted)),
                ],
              ),
            ),
            if (entry.mood != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(moodIcon(entry.mood!), color: colors.accent),
              ),
          ],
        ),
      ),
    );
  }
}
