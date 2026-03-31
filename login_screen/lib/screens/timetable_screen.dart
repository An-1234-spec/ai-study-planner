import 'package:flutter/material.dart';
import '../services/planner_algorithm.dart';
import '../utils/colors.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> timetable = PlannerAlgorithm.generatePlan();

    // 🧠 GROUP INTO DAYS
    Map<String, List<Map<String, dynamic>>> dailyPlan = {};

    for (var item in timetable) {
      String dayKey = item["date"] ?? "Unknown";
      dailyPlan.putIfAbsent(dayKey, () => []);
      dailyPlan[dayKey]!.add(item);
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: AppColors.white),
                ),

                const Text(
                  "Smart Study Plan 🧠",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),

                const SizedBox(height: 10),

                // 🔑 Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendDot(AppColors.primary, "Subject"),
                    const SizedBox(width: 12),
                    _legendDot(Colors.orange, "Task"),
                    const SizedBox(width: 12),
                    _legendDot(Colors.redAccent, "Exam"),
                    const SizedBox(width: 12),
                    _legendDot(Colors.grey, "Break"),
                  ],
                ),

                const SizedBox(height: 16),

                timetable.isEmpty
                    ? const Expanded(
                        child: Center(
                          child: Text(
                            "No subjects or tasks added yet.\nAdd some from the Dashboard!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView(
                          children: dailyPlan.entries.map((entry) {
                            return _dayCard(entry.key, entry.value);
                          }).toList(),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: AppColors.white, fontSize: 13),
        ),
      ],
    );
  }

  Widget _dayCard(String date, List<Map<String, dynamic>> sessions) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...sessions.map((session) => _sessionTile(session)),
        ],
      ),
    );
  }

  Widget _sessionTile(Map<String, dynamic> session) {
    final String type = session["type"] ?? "study";
    final String subject = session["subject"] ?? "";
    final String time = session["time"] ?? "";

    Color accentColor;
    IconData icon;

    if (type == "break") {
      accentColor = Colors.grey;
      icon = Icons.coffee;
    } else if (type == "task") {
      accentColor = Colors.orange;
      icon = Icons.task_alt;
    } else if (type == "exam") {
      accentColor = Colors.redAccent;
      icon = Icons.warning_amber_rounded;
    } else {
      accentColor = AppColors.primary;
      icon = Icons.menu_book;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          // Colour strip
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          const SizedBox(width: 12),

          Icon(icon, size: 18, color: accentColor),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: type == "break"
                        ? Colors.grey.shade700
                        : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time,
                        size: 13, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}