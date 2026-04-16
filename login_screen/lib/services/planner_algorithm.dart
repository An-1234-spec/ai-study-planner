/// AI scheduling algorithm — pure Dart, no Hive dependency.
/// Accepts subjects and tasks as plain List<Map> from StudyProvider.
class PlannerAlgorithm {
  /// Generate a full study plan from [subjects] and [tasks].
  /// Returns a list of schedule entries ready to be saved in Firestore.
  static List<Map<String, dynamic>> generatePlan(
    List<Map<String, dynamic>> subjects,
    List<Map<String, dynamic>> tasks,
  ) {
    List<Map<String, dynamic>> plan = [];

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    // Tracks the next available time per day key ("d/m/yyyy")
    Map<String, double> dailyCurrentHour = {};

    // ── Sort subjects by deadline (soonest first) & priority ──────
    final sortedSubjects = List<Map<String, dynamic>>.from(subjects);
    sortedSubjects.sort((a, b) {
      DateTime da = DateTime.tryParse(a['date'] ?? '') ?? today.add(const Duration(days: 30));
      DateTime db = DateTime.tryParse(b['date'] ?? '') ?? today.add(const Duration(days: 30));
      return da.compareTo(db);
    });

    // ── Priority multiplier (High = 1.5×, Low = 0.75×) ───────────
    double priorityMultiplier(String? p) {
      switch (p) {
        case 'High':
          return 1.5;
        case 'Low':
          return 0.75;
        default:
          return 1.0;
      }
    }

    // ── SUBJECTS: spread sessions up to one day before exam ───────
    for (final s in sortedSubjects) {
      DateTime examDate =
          DateTime.tryParse(s['date'] ?? '') ?? today;
      examDate = DateTime(examDate.year, examDate.month, examDate.day);

      // Add exam event
      final examStr = _dayLabel(examDate);
      plan.add({
        'subject': '🎓 ${s['name']} EXAM',
        'date': examStr,
        'time': '9:00 AM - 12:00 PM',
        'type': 'exam',
        'isDone': false,
      });

      // Study only up to the day before the exam
      final lastStudyDay = examDate.subtract(const Duration(days: 1));
      final daysLeft = lastStudyDay.difference(today).inDays + 1;
      if (daysLeft <= 0) continue;

      double totalHours = double.tryParse(s['hours'].toString()) ?? 1;
      totalHours *= priorityMultiplier(s['priority']);

      final double perDay = totalHours / daysLeft;

      for (int d = 0; d < daysLeft; d++) {
        final day = today.add(Duration(days: d));
        final sessions = _buildDaySessions(
          label: s['name'],
          hours: perDay,
          date: day,
          currentTime: d == 0 ? now : null,
          type: 'study',
          dailyCurrentHour: dailyCurrentHour,
          isLastDayBeforeExam: d == daysLeft - 1,
        );
        plan.addAll(sessions);
      }
    }

    // ── TASKS: spread over next 3 days ────────────────────────────
    const int taskDays = 3;

    for (final t in tasks) {
      double totalHours = double.tryParse(t['hours'].toString()) ?? 1;
      final double perDay = totalHours / taskDays;
      final String label = '📝 ${t['task']} (${t['subject']})';

      for (int d = 0; d < taskDays; d++) {
        final day = today.add(Duration(days: d));
        final sessions = _buildDaySessions(
          label: label,
          hours: perDay,
          date: day,
          currentTime: d == 0 ? now : null,
          type: 'task',
          dailyCurrentHour: dailyCurrentHour,
          isLastDayBeforeExam: false,
        );
        plan.addAll(sessions);
      }
    }

    return plan;
  }

  // ── INTERNAL: build study blocks for a single day ────────────────
  static List<Map<String, dynamic>> _buildDaySessions({
    required String label,
    required double hours,
    required DateTime date,
    required DateTime? currentTime,
    required String type,
    required Map<String, double> dailyCurrentHour,
    required bool isLastDayBeforeExam,
  }) {
    List<Map<String, dynamic>> dayPlan = [];
    double remaining = hours;
    String dateStr = _dayLabel(date);
    double currentHour;

    if (dailyCurrentHour.containsKey(dateStr)) {
      currentHour = dailyCurrentHour[dateStr]!;
    } else {
      if (currentTime != null) {
        // Round up to nearest 30 mins
        double nearestHalf = (currentTime.minute / 30).ceil() * 0.5;
        currentHour = currentTime.hour.toDouble() + nearestHalf;

        if (currentHour >= 20 && !isLastDayBeforeExam) {
          // Too late tonight — push to next morning
          date = date.add(const Duration(days: 1));
          dateStr = _dayLabel(date);
          currentHour = dailyCurrentHour[dateStr] ?? 9.0;
        } else if (currentHour < 9) {
          currentHour = 9.0;
        }
      } else {
        currentHour = 9.0;
      }
    }

    final double closingHour = isLastDayBeforeExam ? 26.0 : 22.0;

    while (remaining > 0) {
      if (currentHour >= closingHour) break;

      double block = remaining >= 2.0 ? 2.0 : remaining;
      if (currentHour + block > closingHour) {
        block = closingHour - currentHour;
      }

      final double start = currentHour;
      final double end = currentHour + block;

      dayPlan.add({
        'subject': label,
        'date': dateStr,
        'time': '${_fmt(start)} - ${_fmt(end)}',
        'type': type,
        'isDone': false,
      });

      currentHour = end;
      remaining -= block;

      // Add a 0.5-hour break between sessions
      if (remaining > 0 && currentHour < closingHour) {
        dayPlan.add({
          'subject': 'Break ☕',
          'date': dateStr,
          'time': '${_fmt(currentHour)} - ${_fmt(currentHour + 0.5)}',
          'type': 'break',
          'isDone': false,
        });
        currentHour += 0.5;
      }
    }

    dailyCurrentHour[dateStr] = currentHour;
    return dayPlan;
  }

  static String _dayLabel(DateTime d) => '${d.day}/${d.month}/${d.year}';

  /// Converts a 24-hr double time to a 12-hr AM/PM string.
  static String _fmt(double time) {
    int hour = time.floor();
    int min = ((time - hour) * 60).round();
    final bool isNext = hour >= 24;
    final int h = isNext ? hour - 24 : hour;
    final String period = h >= 12 ? 'PM' : 'AM';
    final int display = h % 12 == 0 ? 12 : h % 12;
    final String m = min.toString().padLeft(2, '0');
    final String s = '$display:$m $period';
    return isNext ? '$s (Next Day)' : s;
  }
}