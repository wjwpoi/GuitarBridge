import 'package:flutter/material.dart';

/// 首次使用引导（对应原 Swift OnboardingView.swift）
class OnboardingScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(Icons.music_note, size: 80, color: Colors.cyan.shade300),
              const SizedBox(height: 24),
              const Text(
                'GuitarBridge',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '相对音准训练工具',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              _buildFeature(Icons.hearing, '调性内音程识别', '在选定调性中，听辨根音与其他音级的音程关系'),
              const SizedBox(height: 16),
              _buildFeature(Icons.piano, '12种音阶覆盖', '自然大小调、五声音阶、蓝调音阶、教会调式'),
              const SizedBox(height: 16),
              _buildFeature(Icons.trending_up, '练习统计追踪', '记录准确率、连续练习天数、答题趋势'),
              const SizedBox(height: 16),
              _buildFeature(
                Icons.devices,
                '全平台支持',
                'iOS / Android / Windows / macOS',
              ),

              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onComplete,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                  child: const Text('开始训练'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String title, String description) {
    return Row(
      children: [
        Icon(icon, color: Colors.cyan, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                description,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
