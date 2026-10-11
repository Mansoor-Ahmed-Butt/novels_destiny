import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../app/theme/app_theme.dart';
import '../../../domain/entities/analytics_entity.dart';
import '../../../core/widgets/app_card.dart';

class AdminAnalyticsChartsView extends StatefulWidget {
  final PlatformAnalyticsEntity stats;

  const AdminAnalyticsChartsView({
    super.key,
    required this.stats,
  });

  @override
  State<AdminAnalyticsChartsView> createState() => _AdminAnalyticsChartsViewState();
}

class _AdminAnalyticsChartsViewState extends State<AdminAnalyticsChartsView> {
  int _selectedMode = 0; // 0: Traffic, 1: Novel Ratings, 2: Episode Engagement, 3: Rating Distribution

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.l),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Mode Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Platform Intelligence & Ratings',
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Real-time traffic growth, user ratings & chapter analytics',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.m),

          // Horizontal selector chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildModeChip(index: 0, label: 'Traffic Trend', icon: Icons.trending_up_rounded),
                const SizedBox(width: AppSpacing.s),
                _buildModeChip(index: 1, label: 'Novel Ratings', icon: Icons.star_rounded),
                const SizedBox(width: AppSpacing.s),
                _buildModeChip(index: 2, label: 'Episode Reads', icon: Icons.menu_book_rounded),
                const SizedBox(width: AppSpacing.s),
                _buildModeChip(index: 3, label: 'Rating Breakdown', icon: Icons.pie_chart_outline_rounded),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.l),

          // Active Chart View
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: switch (_selectedMode) {
              0 => _buildTrafficChart(),
              1 => _buildNovelRatingsChart(),
              2 => _buildEpisodePerformanceChart(),
              _ => _buildRatingDistributionView(),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip({required int index, required String label, required IconData icon}) {
    final isSelected = _selectedMode == index;
    return InkWell(
      onTap: () => setState(() => _selectedMode = index),
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? AppColors.textInverse : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? AppColors.textInverse : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 1. Traffic Growth Chart ---
  Widget _buildTrafficChart() {
    final dataPoints = widget.stats.dailyReadsTrend;
    if (dataPoints.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No traffic data recorded yet')),
      );
    }

    final totalReadsPeriod = dataPoints.fold<double>(0.0, (sum, p) => sum + p.value);
    final avgDaily = (totalReadsPeriod / dataPoints.length).round();

    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Weekly Daily Reads',
              style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                '~ $avgDaily reads/day',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          height: 190,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: AppColors.cardBorder.withValues(alpha: 0.4),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (val, meta) {
                      final str = val >= 1000
                          ? '${(val / 1000).toStringAsFixed(1)}k'
                          : '${val.toInt()}';
                      return Text(str, style: AppTextStyles.labelSmall.copyWith(fontSize: 10));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 24,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < dataPoints.length) {
                        return Text(
                          dataPoints[idx].dateLabel,
                          style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(dataPoints.length, (i) {
                    return FlSpot(i.toDouble(), dataPoints[i].value);
                  }),
                  isCurved: true,
                  color: AppColors.primary,
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                      radius: 4,
                      color: AppColors.primary,
                      strokeWidth: 2,
                      strokeColor: AppColors.surface,
                    ),
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary.withValues(alpha: 0.35),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. Novel Ratings Analysis Chart ---
  Widget _buildNovelRatingsChart() {
    final list = widget.stats.novelRatings;
    if (list.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No novels published yet to analyze ratings')),
      );
    }

    final topNovels = list.take(6).toList();

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Novel User Ratings Comparison (0.0 to 5.0 ★)',
              style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              'Top ${topNovels.length} Stories',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          height: 190,
          child: BarChart(
            BarChartData(
              maxY: 5.0,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: AppColors.cardBorder.withValues(alpha: 0.4),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (val, meta) {
                      return Text('${val.toInt()}★', style: AppTextStyles.labelSmall.copyWith(fontSize: 10));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < topNovels.length) {
                        final title = topNovels[idx].title;
                        final shortTitle = title.length > 7 ? '${title.substring(0, 6)}..' : title;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            shortTitle,
                            style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(topNovels.length, (i) {
                final n = topNovels[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: n.rating > 0 ? n.rating : 0.2,
                      color: const Color(0xFFEAA228),
                      width: 18,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.m),
        // Mini ranking cards
        Wrap(
          spacing: AppSpacing.s,
          runSpacing: AppSpacing.s,
          children: topNovels.map((n) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.s),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFEAA228)),
                  const SizedBox(width: 4),
                  Text(
                    '${n.rating > 0 ? n.rating.toStringAsFixed(1) : "Unrated"} ★',
                    style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    n.title.length > 14 ? '${n.title.substring(0, 14)}...' : n.title,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                  ),
                  if (n.ratingCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '(${n.ratingCount})',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary, fontSize: 10),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- 3. Episode Engagement Chart ---
  Widget _buildEpisodePerformanceChart() {
    final list = widget.stats.episodeMetrics;
    if (list.isEmpty) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('No published chapters recorded yet')),
      );
    }

    final topEpisodes = list.take(6).toList();

    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Chapter Reads Distribution',
              style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            Text(
              '${widget.stats.totalPublishedEpisodes} Total Chapters',
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.m),
        SizedBox(
          height: 190,
          child: BarChart(
            BarChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (val) => FlLine(
                  color: AppColors.cardBorder.withValues(alpha: 0.4),
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (val, meta) {
                      final str = val >= 1000
                          ? '${(val / 1000).toStringAsFixed(1)}k'
                          : '${val.toInt()}';
                      return Text(str, style: AppTextStyles.labelSmall.copyWith(fontSize: 10));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (val, meta) {
                      final idx = val.toInt();
                      if (idx >= 0 && idx < topEpisodes.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            'Ch ${topEpisodes[idx].episodeNumber}',
                            style: AppTextStyles.labelSmall.copyWith(fontSize: 10),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(topEpisodes.length, (i) {
                final ep = topEpisodes[i];
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: ep.views > 0 ? ep.views.toDouble() : 5.0,
                      color: AppColors.accent,
                      width: 18,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  // --- 4. User Rating Distribution ---
  Widget _buildRatingDistributionView() {
    final dist = widget.stats.ratingDistribution;
    final totalRatings = dist.values.fold<int>(0, (sum, count) => sum + count);

    // Compute platform-wide weighted rating
    double weightedSum = 0;
    dist.forEach((star, count) {
      weightedSum += star * count;
    });
    final platformAvgRating = totalRatings > 0 ? (weightedSum / totalRatings) : 0.0;

    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Score circle
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadii.card),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  Text(
                    platformAvgRating > 0 ? platformAvgRating.toStringAsFixed(1) : '—',
                    style: AppTextStyles.headlineLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFFEAA228),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return Icon(
                        star <= platformAvgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 14,
                        color: const Color(0xFFEAA228),
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalRatings Total Votes',
                    style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.l),

            // 5 to 1 star bars
            Expanded(
              child: Column(
                children: [5, 4, 3, 2, 1].map((star) {
                  final count = dist[star] ?? 0;
                  final pct = totalRatings > 0 ? count / totalRatings : 0.0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            '$star ★',
                            style: AppTextStyles.labelSmall.copyWith(fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                            child: LinearProgressIndicator(
                              value: pct,
                              backgroundColor: AppColors.surfaceMuted,
                              color: const Color(0xFFEAA228),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 30,
                          child: Text(
                            '$count',
                            textAlign: TextAlign.end,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
