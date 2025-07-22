import 'package:background_downloader/background_downloader.dart';
import 'package:flutter/material.dart';

class Downloadstatus extends StatelessWidget {
  final TaskStatus? taskStatus;
  final double progress;

  const Downloadstatus({
    super.key,
    required this.taskStatus,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Download Status: ${taskStatus?.name ?? 'Unknown'}'),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: progress),
        const SizedBox(height: 8),
        Text('Progress: ${(progress * 100).toStringAsFixed(2)}%'),
      ],
    );
  }
}
