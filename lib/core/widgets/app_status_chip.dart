import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';
import '../../domain/entities/novel_entity.dart';
import '../../domain/entities/episode_entity.dart';
import '../../domain/entities/report_entity.dart';

class AppStatusChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const AppStatusChip({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory AppStatusChip.novelStatus(NovelStatus status) {
    switch (status) {
      case NovelStatus.ongoing:
        return const AppStatusChip(
          label: 'Ongoing',
          backgroundColor: Color(0xFFE5F0E8),
          textColor: Color(0xFF2C6B43),
          icon: Icons.sync_rounded,
        );
      case NovelStatus.completed:
        return const AppStatusChip(
          label: 'Completed',
          backgroundColor: Color(0xFFE8DFC8),
          textColor: Color(0xFF5D4026),
          icon: Icons.check_circle_outline_rounded,
        );
      case NovelStatus.draft:
        return const AppStatusChip(
          label: 'Draft',
          backgroundColor: Color(0xFFEFE8DE),
          textColor: Color(0xFF7A6A58),
          icon: Icons.edit_note_rounded,
        );
      case NovelStatus.paused:
        return const AppStatusChip(
          label: 'Paused',
          backgroundColor: Color(0xFFFBF2DE),
          textColor: Color(0xFF9E6518),
          icon: Icons.pause_circle_outline_rounded,
        );
      case NovelStatus.archived:
        return const AppStatusChip(
          label: 'Archived',
          backgroundColor: Color(0xFFE0DBD3),
          textColor: Color(0xFF6E6860),
          icon: Icons.archive_outlined,
        );
    }
  }

  factory AppStatusChip.moderationStatus(ModerationStatus status) {
    switch (status) {
      case ModerationStatus.approved:
        return const AppStatusChip(
          label: 'Approved',
          backgroundColor: Color(0xFFE5F0E8),
          textColor: Color(0xFF2C6B43),
          icon: Icons.verified_rounded,
        );
      case ModerationStatus.pending:
        return const AppStatusChip(
          label: 'Pending Review',
          backgroundColor: Color(0xFFFBF2DE),
          textColor: Color(0xFF9E6518),
          icon: Icons.hourglass_top_rounded,
        );
      case ModerationStatus.rejected:
        return const AppStatusChip(
          label: 'Rejected',
          backgroundColor: Color(0xFFFCEAEA),
          textColor: Color(0xFFB33A3A),
          icon: Icons.cancel_outlined,
        );
      case ModerationStatus.hidden:
        return const AppStatusChip(
          label: 'Hidden',
          backgroundColor: Color(0xFFE6E1D8),
          textColor: Color(0xFF5C5248),
          icon: Icons.visibility_off_outlined,
        );
    }
  }

  factory AppStatusChip.episodeStatus(EpisodeStatus status) {
    switch (status) {
      case EpisodeStatus.published:
        return const AppStatusChip(
          label: 'Published',
          backgroundColor: Color(0xFFE5F0E8),
          textColor: Color(0xFF2C6B43),
        );
      case EpisodeStatus.draft:
        return const AppStatusChip(
          label: 'Draft',
          backgroundColor: Color(0xFFEFE8DE),
          textColor: Color(0xFF7A6A58),
        );
      case EpisodeStatus.scheduled:
        return const AppStatusChip(
          label: 'Scheduled',
          backgroundColor: Color(0xFFE5EFF5),
          textColor: Color(0xFF2A6588),
        );
      case EpisodeStatus.archived:
        return const AppStatusChip(
          label: 'Archived',
          backgroundColor: Color(0xFFE0DBD3),
          textColor: Color(0xFF6E6860),
        );
    }
  }

  factory AppStatusChip.reportStatus(ReportStatus status) {
    switch (status) {
      case ReportStatus.pending:
        return const AppStatusChip(
          label: 'Pending Action',
          backgroundColor: Color(0xFFFBF2DE),
          textColor: Color(0xFF9E6518),
        );
      case ReportStatus.resolved:
        return const AppStatusChip(
          label: 'Resolved',
          backgroundColor: Color(0xFFE5F0E8),
          textColor: Color(0xFF2C6B43),
        );
      case ReportStatus.dismissed:
        return const AppStatusChip(
          label: 'Dismissed',
          backgroundColor: Color(0xFFE6E1D8),
          textColor: Color(0xFF5C5248),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
