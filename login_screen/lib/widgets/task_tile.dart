import 'package:flutter/material.dart';
import '../utils/colors.dart';

class TaskTile extends StatelessWidget {
  final String task;
  final String subject;
  final String hours;

  const TaskTile({
    super.key,
    required this.task,
    required this.subject,
    required this.hours,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.lightGrey, // ✅ FIXED
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: AppColors.textDark, // ✅ FIXED
            ),
          ),

          const SizedBox(height: 5),

          Text(
            "Subject: $subject",
            style: const TextStyle(color: AppColors.grey), // ✅ FIXED
          ),

          const SizedBox(height: 5),

          Text("$hours hrs"),
        ],
      ),
    );
  }
}
