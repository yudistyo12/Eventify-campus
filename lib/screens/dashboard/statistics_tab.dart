import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/event_model.dart';
import '../../providers/app_state.dart';
import '../../theme/app_theme.dart';

typedef _MonthPoint = ({String label, int value});

class StatisticsTab extends StatelessWidget {
  const StatisticsTab({super.key});

  static const _categories = [
    (name: 'Organisasi', icon: Icons.groups_rounded),
    (name: 'Akademik', icon: Icons.school_rounded),
    (name: 'Lomba', icon: Icons.emoji_events_rounded),
    (name: 'Seminar', icon: Icons.co_present_rounded),
  ];

  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Consumer<AppState>(
      builder: (context, appState, _) {
        final events = appState.events;
        final total = events.length;
        final active = events.where((event) => event.status == 'Aktif').length;
        final completed = events
            .where((event) => event.status == 'Selesai')
            .length;
        final months = _buildMonthlyActivity(events);

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Statistik Event',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Pantau aktivitas dan komposisi kegiatan kampus.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: scheme.onSurface.withValues(alpha: 0.62),
                              ),
                            ),
                            const SizedBox(height: 22),
                            _buildHeroCard(
                              context,
                              total: total,
                              active: active,
                              completed: completed,
                            ),
                            const SizedBox(height: 24),
                            _buildMonthlyCard(context, months),
                            const SizedBox(height: 24),
                            _buildCategoryCard(context, events),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeroCard(
    BuildContext context, {
    required int total,
    required int active,
    required int completed,
  }) {
    final theme = Theme.of(context);
    final activeRatio = active + completed == 0
        ? 0.0
        : active / (active + completed);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryNavy, Color(0xFF3730A3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryIndigo.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final chartSize = constraints.maxWidth < 350 ? 112.0 : 132.0;
              final chart = _TotalEventsDonut(
                size: chartSize,
                total: total,
                active: active,
                completed: completed,
              );
              final legend = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeroMetric(
                    context,
                    label: 'Total Event',
                    value: total,
                    color: const Color(0xFF818CF8),
                  ),
                  const SizedBox(height: 12),
                  _buildHeroMetric(
                    context,
                    label: 'Event Aktif',
                    value: active,
                    color: AppTheme.successGreen,
                  ),
                  const SizedBox(height: 12),
                  _buildHeroMetric(
                    context,
                    label: 'Selesai',
                    value: completed,
                    color: const Color(0xFF94A3B8),
                  ),
                ],
              );

              if (constraints.maxWidth < 255) {
                return Column(
                  children: [chart, const SizedBox(height: 18), legend],
                );
              }

              return Row(
                children: [
                  chart,
                  SizedBox(width: constraints.maxWidth < 350 ? 14 : 22),
                  Expanded(child: legend),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Event Aktif vs Selesai',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '${(activeRatio * 100).round()}% aktif',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.successGreen,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 7,
              child: total == 0
                  ? ColoredBox(color: Colors.white.withValues(alpha: 0.12))
                  : Row(
                      children: [
                        if (active > 0)
                          Expanded(
                            flex: active,
                            child: const ColoredBox(
                              color: AppTheme.successGreen,
                            ),
                          ),
                        if (completed > 0)
                          Expanded(
                            flex: completed,
                            child: const ColoredBox(color: Color(0xFF94A3B8)),
                          ),
                        if (active == 0 && completed == 0)
                          Expanded(
                            child: ColoredBox(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroMetric(
    BuildContext context, {
    required String label,
    required int value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.45), blurRadius: 7),
            ],
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$value',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyCard(BuildContext context, List<_MonthPoint> months) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final values = months.map((month) => month.value).toList();

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Aktivitas Bulanan',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Jumlah event dibuat dalam enam bulan terakhir.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 148,
            width: double.infinity,
            child: CustomPaint(
              painter: _MonthlyActivityPainter(
                values: values,
                lineColor: AppTheme.primaryIndigo,
                gridColor: scheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final month in months)
                Expanded(
                  child: Text(
                    month.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.55),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, List<EventModel> events) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final total = events.length;

    return _AnalyticsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Distribusi Kategori',
            style: theme.textTheme.titleMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Komposisi seluruh event berdasarkan kategori.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 18),
          for (var index = 0; index < _categories.length; index++) ...[
            if (index > 0) const SizedBox(height: 17),
            _buildCategoryRow(
              context,
              name: _categories[index].name,
              icon: _categories[index].icon,
              count: events
                  .where(
                    (event) =>
                        event.category.toLowerCase() ==
                        _categories[index].name.toLowerCase(),
                  )
                  .length,
              total: total,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context, {
    required String name,
    required IconData icon,
    required int count,
    required int total,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final progress = total == 0 ? 0.0 : (count / total).clamp(0.0, 1.0);

    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryIndigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 18,
                color: theme.brightness == Brightness.dark
                    ? AppTheme.secondaryIndigo
                    : AppTheme.primaryIndigo,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$count Event',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.62),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(left: 47),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: scheme.onSurface.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryIndigo,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<_MonthPoint> _buildMonthlyActivity(List<EventModel> events) {
    final now = DateTime.now();
    final firstMonth = DateTime(now.year, now.month - 5);
    final months = List.generate(
      6,
      (index) => DateTime(firstMonth.year, firstMonth.month + index),
    );
    final counts = <int, int>{for (final month in months) _monthKey(month): 0};

    for (final event in events) {
      final createdAt = event.createdAt;
      final key = _monthKey(createdAt);
      if (counts.containsKey(key)) {
        counts[key] = counts[key]! + 1;
      }
    }

    return [
      for (final month in months)
        (label: _monthNames[month.month - 1], value: counts[_monthKey(month)]!),
    ];
  }

  int _monthKey(DateTime date) => date.year * 12 + date.month;
}

class _AnalyticsCard extends StatelessWidget {
  const _AnalyticsCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.06),
        ),
        boxShadow: AppTheme.softShadow(context),
      ),
      child: child,
    );
  }
}

class _TotalEventsDonut extends StatelessWidget {
  const _TotalEventsDonut({
    required this.size,
    required this.total,
    required this.active,
    required this.completed,
  });

  final double size;
  final int total;
  final int active;
  final int completed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _OverviewDonutPainter(
              total: total,
              active: active,
              completed: completed,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$total',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Total Event',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewDonutPainter extends CustomPainter {
  const _OverviewDonutPainter({
    required this.total,
    required this.active,
    required this.completed,
  });

  final int total;
  final int active;
  final int completed;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 12.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (total == 0) return;

    final segments = [
      (count: active, color: AppTheme.successGreen),
      (count: completed, color: const Color(0xFF94A3B8)),
    ];
    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      if (segment.count <= 0) continue;
      final sweep = 2 * math.pi * segment.count / total;
      final gap = math.min(0.06, sweep * 0.12);
      canvas.drawArc(
        rect,
        startAngle + gap / 2,
        math.max(0, sweep - gap),
        false,
        Paint()
          ..color = segment.color
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidth,
      );
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _OverviewDonutPainter oldDelegate) =>
      oldDelegate.total != total ||
      oldDelegate.active != active ||
      oldDelegate.completed != completed;
}

class _MonthlyActivityPainter extends CustomPainter {
  const _MonthlyActivityPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  final List<int> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || size.isEmpty) return;

    const horizontalInset = 10.0;
    const topInset = 16.0;
    const bottomInset = 10.0;
    final chartWidth = math.max(0.0, size.width - horizontalInset * 2);
    final chartHeight = math.max(0.0, size.height - topInset - bottomInset);
    final chartBottom = topInset + chartHeight;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var line = 0; line < 4; line++) {
      final y = topInset + chartHeight * line / 3;
      canvas.drawLine(
        Offset(horizontalInset, y),
        Offset(size.width - horizontalInset, y),
        gridPaint,
      );
    }

    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final scaleMax = maxValue == 0 ? 1 : maxValue;
    final points = <Offset>[];
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1
          ? horizontalInset + chartWidth / 2
          : horizontalInset + chartWidth * index / (values.length - 1);
      final y = chartBottom - chartHeight * values[index] / scaleMax;
      points.add(Offset(x, y));
    }

    final curve = Path()..moveTo(points.first.dx, points.first.dy);
    for (var index = 0; index < points.length - 1; index++) {
      final previous = index == 0 ? points[index] : points[index - 1];
      final current = points[index];
      final next = points[index + 1];
      final afterNext = index + 2 < points.length ? points[index + 2] : next;
      final firstControl = Offset(
        current.dx + (next.dx - previous.dx) / 6,
        current.dy + (next.dy - previous.dy) / 6,
      );
      final secondControl = Offset(
        next.dx - (afterNext.dx - current.dx) / 6,
        next.dy - (afterNext.dy - current.dy) / 6,
      );
      curve.cubicTo(
        firstControl.dx,
        firstControl.dy,
        secondControl.dx,
        secondControl.dy,
        next.dx,
        next.dy,
      );
    }

    final area = Path.from(curve)
      ..lineTo(points.last.dx, chartBottom)
      ..lineTo(points.first.dx, chartBottom)
      ..close();
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withValues(alpha: 0.22),
          lineColor.withValues(alpha: 0.015),
        ],
      ).createShader(Rect.fromLTWH(0, topInset, size.width, chartHeight));
    canvas.drawPath(area, areaPaint);

    canvas.drawPath(
      curve,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    if (maxValue > 0) {
      final peakIndex = values.indexOf(maxValue);
      final peak = points[peakIndex];
      canvas.drawCircle(
        peak,
        7,
        Paint()..color = lineColor.withValues(alpha: 0.18),
      );
      canvas.drawCircle(peak, 4, Paint()..color = lineColor);
      canvas.drawCircle(peak, 1.7, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyActivityPainter oldDelegate) {
    if (oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.values.length != values.length) {
      return true;
    }
    for (var index = 0; index < values.length; index++) {
      if (oldDelegate.values[index] != values[index]) return true;
    }
    return false;
  }
}
