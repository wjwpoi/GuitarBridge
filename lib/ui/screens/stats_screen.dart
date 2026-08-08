import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../models/practice_record.dart';
import '../../services/streak_manager.dart';

class StatsScreen extends StatelessWidget {
  final StreakManager streakManager;
  final List<PracticeRecord> records;

  const StatsScreen({
    super.key,
    required this.streakManager,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: streakManager,
      builder: (context, _) => _buildBody(context, streakManager.records),
    );
  }

  Widget _buildBody(BuildContext context, List<PracticeRecord> records) {
    final totalSessions = records.length;
    final totalCorrect = records.fold<int>(
      0,
      (sum, r) => sum + r.correctAnswers,
    );
    final totalAttempts = records.fold<int>(
      0,
      (sum, r) => sum + r.totalAttempts,
    );
    final overallAccuracy = totalAttempts == 0
        ? 0.0
        : totalCorrect / totalAttempts * 100;
    final totalDuration = records.fold<double>(
      0,
      (sum, record) => sum + record.durationSeconds,
    );
    final globalBestStreak = records.fold<int>(
      0,
      (best, record) => best > record.bestStreak ? best : record.bestStreak,
    );
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final sessionsThisWeek = records
        .where((record) => record.date.isAfter(weekStart))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('练习统计'),
        actions: [
          if (records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: '清除统计',
              onPressed: () => _showClearDialog(context),
            ),
        ],
      ),
      body: records.isEmpty
          ? const _EmptyStats()
          : ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 980),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final columns = constraints.maxWidth >= 720 ? 4 : 2;
                            const gap = 10.0;
                            final width =
                                (constraints.maxWidth - gap * (columns - 1)) /
                                columns;
                            return Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: [
                                _MetricCard(
                                  width: width,
                                  label: '总练习',
                                  value: '$totalSessions',
                                  icon: Icons.layers_rounded,
                                  accent: AppTheme.primaryColor,
                                ),
                                _MetricCard(
                                  width: width,
                                  label: '本周',
                                  value: '$sessionsThisWeek',
                                  icon: Icons.calendar_today_rounded,
                                  accent: AppTheme.secondaryColor,
                                ),
                                _MetricCard(
                                  width: width,
                                  label: '准确率',
                                  value:
                                      '${overallAccuracy.toStringAsFixed(0)}%',
                                  icon: Icons.track_changes_rounded,
                                  accent: AppTheme.accentColor,
                                ),
                                _MetricCard(
                                  width: width,
                                  label: '连续天数',
                                  value: '${streakManager.currentStreak}',
                                  icon: Icons.local_fire_department_rounded,
                                  accent: AppTheme.wrongColor,
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Wrap(
                              spacing: 28,
                              runSpacing: 14,
                              children: [
                                _InlineMetric(
                                  label: '累计答题',
                                  value: '$totalAttempts',
                                ),
                                _InlineMetric(
                                  label: '正确数',
                                  value: '$totalCorrect',
                                ),
                                _InlineMetric(
                                  label: '练习时长',
                                  value: _formatDuration(totalDuration),
                                ),
                                _InlineMetric(
                                  label: '最佳连击',
                                  value: '$globalBestStreak',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '最近记录',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        for (final record in records.reversed.take(20))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: _RecordCard(record: record),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDuration(double seconds) {
    final minutes = seconds ~/ 60;
    final remainder = (seconds % 60).toInt();
    return minutes > 0 ? '${minutes}m ${remainder}s' : '${remainder}s';
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清除所有统计？'),
        content: const Text('练习历史与连续天数将被永久删除，此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              streakManager.clearAll();
              Navigator.pop(dialogContext);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.wrongColor),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _MetricCard({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(height: 16),
              Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineMetric extends StatelessWidget {
  final String label;
  final String value;

  const _InlineMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }
}

class _RecordCard extends StatelessWidget {
  final PracticeRecord record;

  const _RecordCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final accent = record.accuracy >= 80
        ? AppTheme.correctColor
        : record.accuracy >= 60
        ? AppTheme.accentColor
        : AppTheme.wrongColor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accent.withAlpha(16),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accent.withAlpha(70)),
              ),
              child: Center(
                child: Text(
                  '${record.accuracy.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${record.keySignature} ${record.scaleType}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.correctAnswers}/${record.totalAttempts} 正确 · '
                    '${_duration(record.durationSeconds)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Text(
              '${record.date.month}/${record.date.day} '
              '${record.date.hour}:${record.date.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  String _duration(double seconds) {
    final minutes = seconds ~/ 60;
    final remainder = (seconds % 60).toInt();
    return minutes > 0 ? '${minutes}m ${remainder}s' : '${remainder}s';
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.outlineColor),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AppTheme.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text('还没有练习记录', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text(
            '完成第一轮训练后，这里会显示你的趋势。',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
