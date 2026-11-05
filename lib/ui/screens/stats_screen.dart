import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../engine/adaptive_planner.dart';
import '../../models/practice_record.dart';
import '../../models/training_config.dart';
import '../../services/streak_manager.dart';
import '../widgets/common.dart';
import '../widgets/interval_breakdown.dart';

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
    final c = context.gb;
    final sorted = [...records]..sort((a, b) => b.date.compareTo(a.date));
    final totalCorrect = records.fold<int>(0, (s, r) => s + r.correctAnswers);
    final totalAttempts = records.fold<int>(0, (s, r) => s + r.totalAttempts);
    final accuracy = totalAttempts == 0
        ? 0.0
        : totalCorrect / totalAttempts * 100;
    final totalDuration = records.fold<double>(
      0,
      (s, r) => s + r.durationSeconds,
    );
    final bestStreak = records.fold<int>(
      0,
      (best, r) => best > r.bestStreak ? best : r.bestStreak,
    );
    final now = DateTime.now();
    // Monday 00:00 local time, so sessions earlier on Monday still count.
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    final sessionsThisWeek = records
        .where((r) => !r.date.toLocal().isBefore(weekStart))
        .length;
    final history = AdaptivePlanner.historyFrom(records);

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
          const SizedBox(width: 8),
        ],
      ),
      body: records.isEmpty
          ? const _EmptyStats()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 760),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final columns = constraints.maxWidth >= 480
                                      ? 4
                                      : 2;
                                  final width =
                                      (constraints.maxWidth -
                                          16 * (columns - 1)) /
                                      columns;
                                  return Wrap(
                                    spacing: 16,
                                    runSpacing: 20,
                                    children: [
                                      for (final (value, label) in [
                                        ('${records.length}', '练习轮数'),
                                        ('$sessionsThisWeek', '本周'),
                                        (
                                          '${accuracy.toStringAsFixed(0)}%',
                                          '首答正确率',
                                        ),
                                        (
                                          '${streakManager.currentStreak}',
                                          '连续天数',
                                        ),
                                      ])
                                        SizedBox(
                                          width: width,
                                          child: _BigNumber(
                                            value: value,
                                            label: label,
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              const Divider(),
                              const SizedBox(height: 14),
                              Text(
                                '累计 $totalAttempts 题 · 练习 ${_formatDuration(totalDuration)} · 最佳连击 $bestStreak',
                                style: context.text.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (history.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Panel(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('音程掌握度', style: context.text.titleLarge),
                                const SizedBox(height: 4),
                                Text(
                                  '最近 ${AdaptivePlanner.historyWindow} 轮的首答结果。智能出题会多安排较弱的音程。',
                                  style: context.text.bodySmall,
                                ),
                                const SizedBox(height: 14),
                                IntervalBreakdown(tallies: history),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 28),
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 8),
                          child: Text('最近记录', style: context.text.labelMedium),
                        ),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (final (i, record)
                                  in sorted.take(20).indexed) ...[
                                if (i > 0) const Divider(indent: 20),
                                _RecordRow(record: record),
                              ],
                            ],
                          ),
                        ),
                        if (sorted.length > 20)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              '仅显示最近 20 轮',
                              textAlign: TextAlign.center,
                              style: context.text.bodySmall?.copyWith(
                                color: c.textMuted,
                              ),
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

  static String _formatDuration(double seconds) {
    final minutes = seconds ~/ 60;
    if (minutes >= 60) return '${minutes ~/ 60} 小时 ${minutes % 60} 分';
    if (minutes > 0) return '$minutes 分钟';
    return '${seconds.toInt()} 秒';
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('清除所有统计？'),
        content: const Text('练习记录、音程掌握度与连续天数将被永久删除，无法撤销。'),
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
            style: TextButton.styleFrom(
              foregroundColor: dialogContext.gb.wrong,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}

class _BigNumber extends StatelessWidget {
  final String value;
  final String label;

  const _BigNumber({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: context.text.displaySmall?.copyWith(fontSize: 30)),
        const SizedBox(height: 2),
        Text(label, style: context.text.bodySmall),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  final PracticeRecord record;

  const _RecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final c = context.gb;
    final date = record.date.toLocal();
    final color = record.accuracy >= 80
        ? c.correct
        : record.accuracy >= 50
        ? c.textPrimary
        : c.wrong;
    final difficulty = record.difficulty == null
        ? ''
        : ' · ${TrainingConfig.difficultyLabel(record.difficulty!)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${record.keySignature} ${record.scaleType}$difficulty',
                  style: context.text.bodyLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  '${date.month}月${date.day}日 '
                  '${date.hour}:${date.minute.toString().padLeft(2, '0')} · '
                  '${record.correctAnswers}/${record.totalAttempts} 首答正确',
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${record.accuracy.toStringAsFixed(0)}%',
            style: TextStyle(
              fontFamily: AppTheme.serif,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyStats extends StatelessWidget {
  const _EmptyStats();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('还没有练习记录', style: context.text.titleLarge),
            const SizedBox(height: 8),
            Text(
              '完成一轮训练后，这里会显示正确率、连续天数和各音程的掌握情况。',
              textAlign: TextAlign.center,
              style: context.text.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
