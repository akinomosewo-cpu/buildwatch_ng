import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../core/models/milestone.dart';
import '../../core/theme/app_theme.dart';

/// Chronological feed of geotagged, timestamped progress proof for a
/// milestone or project. Every entry shown here was captured through the
/// in-app camera flow — never imported from a gallery.
class TimelinePage extends StatelessWidget {
  final String title;
  final List<ProgressEntry> entries;

  const TimelinePage({super.key, required this.title, required this.entries});

  @override
  Widget build(BuildContext context) {
    final sorted = [...entries]..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: sorted.isEmpty
          ? Center(
              child: Text('No progress submitted yet',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: sorted.length,
              separatorBuilder: (_, __) => const Gap(14),
              itemBuilder: (context, index) => _TimelineTile(entry: sorted[index]),
            ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final ProgressEntry entry;
  const _TimelineTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final formatted = DateFormat('EEE d MMM yyyy · HH:mm').format(entry.capturedAt);
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(
                  entry.isVideo ? Icons.videocam_rounded : Icons.image_rounded,
                  color: AppColors.textTertiary,
                  size: 36,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded, size: 14, color: AppColors.textSecondary),
                    const Gap(6),
                    Text(formatted,
                        style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary)),
                  ],
                ),
                const Gap(6),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, size: 14, color: AppColors.textSecondary),
                    const Gap(6),
                    Text(
                      '${entry.latitude.toStringAsFixed(5)}, ${entry.longitude.toStringAsFixed(5)}',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  const Gap(8),
                  Text(entry.note!, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
