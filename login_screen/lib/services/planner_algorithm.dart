import 'package:hive/hive.dart';
import '../utils/constants.dart';

class PlannerAlgorithm {
  static List<Map<String, dynamic>> generatePlan() {
    var subjectBox = Hive.box(AppConstants.subjectBox);
    var taskBox = Hive.box(AppConstants.taskBox);

    // Reset session storage
    var sessionBox = Hive.box('sessions');
    sessionBox.clear();

    List<Map<String, dynamic>> plan = [];

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    
    // Map to keep track of the next available starting hour for each day.
    Map<String, int> dailyCurrentHour = {};

    // ─────────────────────────────────────────────
    // 📚 SUBJECTS  (spread across days until exam)
    // ─────────────────────────────────────────────
    for (int i = 0; i < subjectBox.length; i++) {
      var s = subjectBox.getAt(i);

      DateTime examDate =
          DateTime.tryParse(s["date"] ?? "") ?? today;
      examDate = DateTime(examDate.year, examDate.month, examDate.day);

      // Add the exam event to the plan
      String examStr = "${examDate.day}/${examDate.month}/${examDate.year}";
      plan.add({
        "subject": "🎓 ${s["name"]} EXAM",
        "date": examStr,
        "time": "9:00 AM - 12:00 PM",
        "type": "exam",
        "isDone": false,
      });

      // No study on exam day itself
      DateTime lastStudyDay = examDate.subtract(const Duration(days: 1));
      int daysLeft = lastStudyDay.difference(today).inDays + 1;

      if (daysLeft <= 0) continue;

      double totalHours = double.tryParse(s["hours"].toString()) ?? 1;
      double perDay = totalHours / daysLeft;
      String subjectName = s["name"];

      for (int d = 0; d < daysLeft; d++) {
        DateTime day = today.add(Duration(days: d));
        bool isToday = d == 0;
        bool isLastDay = (d == daysLeft - 1);

        var sessions = _generateSmartDayPlan(
          label: subjectName,
          hours: perDay,
          date: day,
          currentTime: isToday ? now : null,
          type: "study",
          dailyCurrentHour: dailyCurrentHour,
          isLastDayBeforeExam: isLastDay,
        );

        for (var session in sessions) {
          sessionBox.add(session);
        }
        plan.addAll(sessions);
      }
    }

    // ─────────────────────────────────────────────
    // 📝 TASKS  (scheduled over next 3 days)
    // ─────────────────────────────────────────────
    const int taskSpreadDays = 3;

    for (int i = 0; i < taskBox.length; i++) {
      var t = taskBox.getAt(i);

      double totalHours = double.tryParse(t["hours"].toString()) ?? 1;
      double perDay = totalHours / taskSpreadDays;

      // Label shows task name + subject
      String label = "📝 ${t["task"]} (${t["subject"]})";

      for (int d = 0; d < taskSpreadDays; d++) {
        DateTime day = today.add(Duration(days: d));
        bool isToday = d == 0;

        var sessions = _generateSmartDayPlan(
          label: label,
          hours: perDay,
          date: day,
          currentTime: isToday ? now : null,
          type: "task",
          dailyCurrentHour: dailyCurrentHour,
          isLastDayBeforeExam: false,
        );

        for (var session in sessions) {
          sessionBox.add(session);
        }
        plan.addAll(sessions);
      }
    }

    return plan;
  }

  // ─────────────────────────────────────────────
  // 🧠 SMART DAY PLANNER
  // ─────────────────────────────────────────────
  static List<Map<String, dynamic>> _generateSmartDayPlan({
    required String label,
    required double hours,
    required DateTime date,
    required DateTime? currentTime,
    required String type,
    required Map<String, int> dailyCurrentHour,
    required bool isLastDayBeforeExam,
  }) {
    List<Map<String, dynamic>> dayPlan = [];

    int remaining = hours.ceil();
    String dateStr = "${date.day}/${date.month}/${date.year}";
    int currentHour;

    if (dailyCurrentHour.containsKey(dateStr)) {
      currentHour = dailyCurrentHour[dateStr]!;
    } else {
      if (currentTime != null) {
        currentHour = currentTime.hour;

        if (currentHour >= 20 && !isLastDayBeforeExam) {
          // 🌙 Too late tonight & not exam eve → push to next morning 9 AM
          currentHour = 9;
          date = date.add(const Duration(days: 1));
          dateStr = "${date.day}/${date.month}/${date.year}";
          
          if (dailyCurrentHour.containsKey(dateStr)) {
            currentHour = dailyCurrentHour[dateStr]!;
          }
        } else if (currentHour < 9) {
          // 🌅 Early morning → start at 9 AM today
          currentHour = 9;
        }
      } else {
        currentHour = 9;
      }
    }

    // Allow cramming up to 2 AM if it's the night before the exam
    int closingHour = isLastDayBeforeExam ? 26 : 22;

    while (remaining > 0) {
      if (currentHour >= closingHour) break;

      // 🛑 FIX: Study blocks are max 2 hours right away, to avoid splitting
      // 2h sessions into 1h+break+1h.
      int studyBlock = remaining >= 2 ? 2 : 1;
      
      if (currentHour + studyBlock > closingHour) {
        studyBlock = closingHour - currentHour;
      }

      int start = currentHour;
      int end = currentHour + studyBlock;

      dayPlan.add({
        "subject": label,
        "date": dateStr,
        "time": "${_format(start)} - ${_format(end)}",
        "type": type,
        "isDone": false,
      });

      currentHour = end;
      remaining -= studyBlock;

      // Add a 1h break between sessions if time left
      if (remaining > 0 && currentHour < closingHour) {
        dayPlan.add({
          "subject": "Break ☕",
          "date": dateStr,
          "time": "${_format(currentHour)} - ${_format(currentHour + 1)}",
          "type": "break",
          "isDone": false,
        });
        currentHour += 1;
      }
    }

    dailyCurrentHour[dateStr] = currentHour;

    return dayPlan;
  }

  // 🕐 12-hour format helper (handles >24 hours)
  static String _format(int hour) {
    bool isNextDay = hour >= 24;
    int actualHour = isNextDay ? hour - 24 : hour;
    String period = actualHour >= 12 ? "PM" : "AM";
    int h = actualHour % 12;
    if (h == 0) h = 12;
    String timeStr = "$h:00 $period";
    return isNextDay ? "$timeStr (Next Day)" : timeStr;
  }
}