import 'package:flutter/material.dart';
import '../../models/practice_record.dart';
import '../../services/streak_manager.dart';

/// 统计页面（对应原 Swift StatsView.swift）
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
    final totalSessions = records.length;
    final totalCorrect = records.fold<int>(0, (s, r) => s + r.correctAnswers);
    final totalAttempts = records.fold<int>(0, (s, r) => s + r.totalAttempts);
    final overallAccuracy =
        totalAttempts > 0 ? totalCorrect / totalAttempts * 100 : 0.0;
    final totalDuration = records.fold<double>(
        0, (s, r) => s + r.durationSeconds);
    final globalBestStreak = records.fold<int>(
        0, (s, r) => s > r.bestStreak ? s : r.bestStreak);

    // This week
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final sessionsThisWeek = records
        .where((r) => r.date.isAfter(weekStart))
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('练习统计'),
        actions: [
          if (records.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _showClearDialog(context),
            ),
        ],
      ),
      body: records.isEmpty
          ? const Center(
              child: Text('暂无练习记录',
                  style: TextStyle(color: Colors.grey, fontSize: 16)))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildOverviewSection(
                  totalSessions,
                  sessionsThisWeek,
                  overallAccuracy,
                  totalAttempts,
                  totalCorrect,
                  totalDuration,
                  globalBestStreak,
                ),
                const SizedBox(height: 16),
                const Text('最近记录',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 8),
                ...records.reversed.take(20).map((r) => _buildRecordTile(r)),
              ],
            ),
    );
  }

  Widget _buildOverviewSection(
    int totalSessions,
    int sessionsThisWeek,
    double accuracy,
    int totalAttempts,
    int totalCorrect,
    double duration,
    int bestStreak,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow('总练习次数', '$totalSessions', Icons.fitness_center),
            _buildStatRow('本周练习', '$sessionsThisWeek', Icons.calendar_today),
            _buildStatRow('总准确率', '${accuracy.toStringAsFixed(1)}%', Icons.pie_chart),
            _buildStatRow('总答题数', '$totalAttempts', Icons.quiz),
            _buildStatRow('正确数', '$totalCorrect', Icons.check_circle),
            _buildStatRow('总练习时长', _formatDuration(duration), Icons.timer),
            _buildStatRow('最佳连击', '$bestStreak', Icons.local_fire_department),
            _buildStatRow('连续天数', '${streakManager.currentStreak}', Icons.streak),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.cyan),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.cyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildRecordTile(PracticeRecord record) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: record.accuracy >= 80
              ? Colors.green
              : record.accuracy >= 60
                  ? Colors.orange
                  : Colors.red,
          child: Text('${record.accuracy.toStringAsFixed(0)}%',
              style: const TextStyle(fontSize: 11, color: Colors.white)),
        ),
        title: Text(
          '${record.keySignature} ${record.scaleType}',
          style: const TextStyle(fontSize: 14, color: Colors.white),
        ),
        subtitle: Text(
          '${record.correctAnswers}/${record.totalAttempts} | ${_formatDuration(record.durationSeconds)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: Text(
          _dateFormat(record.date),
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ),
    );
  }

  String _formatDuration(double seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toInt();
    return m > 0 ? '${m}m ${s}s' : '${s}s';
  }

  String _dateFormat(DateTime d) {
    return '${d.month}/${d.day} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清除所有统计？'),
        content: const Text('此操作将永久删除你的练习历史，无法撤销。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              streakManager.clearAll();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}
