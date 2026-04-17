import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../utils/colors.dart';

class TimetableScreen extends StatelessWidget {
  /// Shows a dialog to pick daily study hours, then generates the plan.
  static void _showHoursPickerAndGenerate(BuildContext context, StudyProvider study) {
    double selectedHours = study.globalDailyHours;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: const Row(
                children: [
                  Icon(Icons.schedule, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text('How many hours?'),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'How many hours do you want to study today?',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '${selectedHours.toInt()} hours',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: selectedHours,
                    min: 1.0,
                    max: 24.0,
                    divisions: 23,
                    activeColor: AppColors.primary,
                    label: '${selectedHours.toInt()}h',
                    onChanged: (val) {
                      setState(() => selectedHours = val);
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('1h', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      Text(
                        _hoursHint(selectedHours.toInt()),
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      const Text('24h', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.blueGrey),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Study sessions can be scheduled any time of the day — morning, afternoon, or night.',
                            style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    study.updateDailyHours(selectedHours);
                    study.generateAndSavePlan();
                  },
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Generate Plan'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  static String _hoursHint(int h) {
    if (h <= 3) return 'Light session';
    if (h <= 6) return 'Moderate study';
    if (h <= 10) return 'Intensive day';
    if (h <= 16) return 'Marathon mode 💪';
    return 'Full grind mode 🔥';
  }
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
                        _DailyHoursChip(study: study),
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
                                      ? () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Please add subjects first to generate a plan.')),
                                          );
                                      }
                                      : () => _showHoursPickerAndGenerate(context, study),
                                  icon: const Icon(Icons.auto_awesome),
                                  label: const Text(
                                    'Generate AI Plan',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    disabledBackgroundColor: Colors.white38,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),
                  ),

                  // ── Subject Progress Row ─────────────────────
                  if (study.subjects.isNotEmpty)
                     _SubjectProgressRow(study: study),

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
                        _legendDot(Colors.blueGrey, 'Short Break'),
                        const SizedBox(width: 14),
                        _legendDot(Colors.amber.shade700, 'Long Break'),
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
                              return _dayCard(day, dailyPlan[day]!, study);
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
  Widget _dayCard(String date, List<Map<String, dynamic>> sessions, StudyProvider study) {
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
              children: sessions.map((s) => _SessionTile(session: s, study: study)).toList(),
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

class _DailyHoursChip extends StatelessWidget {
  final StudyProvider study;

  const _DailyHoursChip({required this.study});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => TimetableScreen._showHoursPickerAndGenerate(context, study),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              '${study.globalDailyHours.toInt()}h/day 🔽',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectProgressRow extends StatelessWidget {
  final StudyProvider study;
  const _SubjectProgressRow({required this.study});

  @override
  Widget build(BuildContext context) {
    final subjectHours = study.perSubjectHoursProgress;
    return Container(
      height: 80,
      margin: const EdgeInsets.only(top: 14),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: study.subjects.length,
        itemBuilder: (context, index) {
          final s = study.subjects[index];
          final String name = s['name'] ?? '';
          final String sid = s['id'] ?? s['name'] ?? '';
          
          DateTime? examDate;
          try {
             if(s['date'] != null) {
                examDate = DateTime.tryParse(s['date'].toString());
             }
          } catch (_) {}

          int daysLeft = 0;
          if (examDate != null) {
             daysLeft = examDate.difference(DateTime.now()).inDays.clamp(0, 999);
          }
          
          final hourData = subjectHours[sid] ?? {'progress': 0.0, 'done': 0.0, 'total': 0.0};
          final double progress = hourData['progress'] ?? 0.0;
          final double hrsDone = hourData['done'] ?? 0.0;
          final double hrsTotal = hourData['total'] ?? 0.0;

          return Container(
            width: 140,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${daysLeft}d',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${hrsDone.toStringAsFixed(1)}/${hrsTotal.toStringAsFixed(1)}h',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final Map<String, dynamic> session;
  final StudyProvider study;

  const _SessionTile({required this.session, required this.study});

  @override
  Widget build(BuildContext context) {
    final String type = session['type'] ?? 'study';
    final String subject = session['subject'] ?? '';
    final String time = session['time'] ?? '';
    
    // Default to false, support isDone later if needed
    final bool isDone = session['isDone'] ?? false;
    final String? entryId = session['id'];

    late Color color;
    late IconData icon;

    switch (type) {
      case 'break':
        color = Colors.blueGrey;
        icon = Icons.pause_circle_outline;
        break;
      case 'longBreak':
        color = Colors.amber.shade700;
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
        color: isDone 
             ? Colors.green.withValues(alpha: 0.05) 
             : color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDone ? Colors.green.withValues(alpha: 0.3) : color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: isDone ? Colors.green : color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Icon(isDone ? Icons.check_circle : icon, size: 16, color: isDone ? Colors.green : color),
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
                    color: isDone ? Colors.grey : (type == 'break' || type == 'longBreak') ? Colors.grey.shade600 : Colors.black87,
                    decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
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
          
          if (type != 'break' && type != 'longBreak' && type != 'exam' && entryId != null)
             GestureDetector(
                onTap: () {
                    final newDone = !isDone;
                    study.markEntryDone(entryId, newDone);
                    
                    final String topic = session['topic'] ?? '';
                    final String subId = session['subjectId'] ?? '';
                    if (subId.isNotEmpty) {
                      if (type == 'study' &&
                          topic.isNotEmpty &&
                          topic != 'General Study' &&
                          topic != 'Revision' && topic != 'Final Revision') {
                        if (newDone) {
                          study.markTopicDone(subId, topic);
                        } else {
                          study.unmarkTopicDone(subId, topic);
                        }
                      } else if (type == 'task') {
                        study.toggleTaskDone(subId, newDone);
                      }
                    }
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    border: Border.all(color: isDone ? Colors.green : Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                    color: isDone ? Colors.green.withValues(alpha: 0.1) : Colors.white,
                  ),
                  child: Icon(Icons.check, size: 16, color: isDone ? Colors.green : Colors.transparent),
                ),
             )
        ],
      ),
    );
  }
}