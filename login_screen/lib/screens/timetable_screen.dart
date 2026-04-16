import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../utils/colors.dart';

class TimetableScreen extends StatelessWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyProvider>(
      builder: (context, study, _) {
        // Group entries by date
        final Map<String, List<Map<String, dynamic>>> dailyPlan = {};
        for (final item in study.timetable) {
          final key = item['date'] ?? 'Unknown';
          dailyPlan.putIfAbsent(key, () => []);
          dailyPlan[key]!.add(item);
        }

        // Sort days chronologically
        final sortedDays = dailyPlan.keys.toList()
          ..sort((a, b) {
            final da = _parseDay(a);
            final db = _parseDay(b);
            return da.compareTo(db);
          });

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── AppBar ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white),
                        ),
                        const Expanded(
                          child: Text(
                            'Smart Study Plan 🧠',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Generate button ────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: study.isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                  color: Colors.white),
                            ),
                          )
                        : study.planGenerated
                            ? Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade500,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      '✅ AI Plan Generated & Saved!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                height: 46,
                                child: ElevatedButton.icon(
                                  onPressed: study.subjects.isEmpty
                                      ? null
                                      : () => study.generateAndSavePlan(),
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text(
                                    'Generate AI Plan',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    disabledBackgroundColor:
                                        Colors.white38,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                  ),

                  // ── Legend ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        _legendDot(AppColors.primary, 'Study'),
                        const SizedBox(width: 14),
                        _legendDot(Colors.orange, 'Task'),
                        const SizedBox(width: 14),
                        _legendDot(Colors.redAccent, 'Exam'),
                        const SizedBox(width: 14),
                        _legendDot(Colors.grey, 'Break'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Content ─────────────────────────────────────
                  Expanded(
                    child: study.timetable.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today_outlined,
                                    color: Colors.white54, size: 60),
                                SizedBox(height: 16),
                                Text(
                                  'No plan yet.',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Add subjects & tap "Generate AI Plan"',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: sortedDays.length,
                            itemBuilder: (ctx, i) {
                              final day = sortedDays[i];
                              return _dayCard(day, dailyPlan[day]!);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Day card ──────────────────────────────────────────────────────
  Widget _dayCard(String date, List<Map<String, dynamic>> sessions) {
    final hasExam = sessions.any((s) => s['type'] == 'exam');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: hasExam
                  ? Colors.red.shade50
                  : AppColors.primary.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  hasExam ? Icons.warning_amber_rounded : Icons.calendar_today,
                  size: 16,
                  color: hasExam ? Colors.red.shade400 : AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: hasExam ? Colors.red.shade600 : AppColors.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${sessions.length} session${sessions.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          // Sessions
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: sessions.map(_sessionTile).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sessionTile(Map<String, dynamic> session) {
    final String type = session['type'] ?? 'study';
    final String subject = session['subject'] ?? '';
    final String time = session['time'] ?? '';

    late Color color;
    late IconData icon;

    switch (type) {
      case 'break':
        color = Colors.grey;
        icon = Icons.coffee_rounded;
        break;
      case 'task':
        color = Colors.orange;
        icon = Icons.task_alt;
        break;
      case 'exam':
        color = Colors.redAccent;
        icon = Icons.warning_amber_rounded;
        break;
      default:
        color = AppColors.primary;
        icon = Icons.menu_book_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color:
                        type == 'break' ? Colors.grey.shade600 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade500),
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

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  DateTime _parseDay(String d) {
    try {
      final parts = d.split('/');
      return DateTime(
        int.parse(parts[2]),
        int.parse(parts[1]),
        int.parse(parts[0]),
      );
    } catch (_) {
      return DateTime.now();
    }
  }
}