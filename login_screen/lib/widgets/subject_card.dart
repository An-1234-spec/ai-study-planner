import 'package:flutter/material.dart';
import '../utils/colors.dart';

class SubjectCard extends StatelessWidget {
  final String title;
  final String hours;
  final String? date;

  const SubjectCard({
    super.key,
    required this.title,
    required this.hours,
    this.date,
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
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textDark, // ✅ FIXED
            ),
          ),

          const SizedBox(height: 5),

          Text("$hours hrs"),

          if (date != null) ...[
            const SizedBox(height: 5),
            Text(
              "Exam: $date",
              style: const TextStyle(color: AppColors.grey), // ✅ FIXED
            ),
          ],
        ],
      ),
    );
  }
}
