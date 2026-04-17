

/// Smart AI scheduling algorithm.
///
/// Key intelligence:
/// 1. Distributes each subject's TOTAL study hours across available days
/// 2. Urgency scaling — automatically increases daily hours when exams are near
/// 3. Difficulty scaling — Hard subjects get more time, Easy subjects less
/// 4. Topic-aware — covers topics first, then fills with revision/practice
/// 5. Even distribution — spreads study evenly so no day is overloaded
///
/// Produces a deterministically-ordered plan with a `sortIndex` on every
/// entry so the UI can always re-sort correctly regardless of how Firestore
/// returns the documents.
class PlannerAlgorithm {
  // ── Session / break durations (hours) ───────────────────────────
  static const double _sessionDur = 2.0; // 120 min
  static const double _shortBreak = 0.1667; // 10 min
  static const double _longBreak = 0.4167; // 25 min
  static const int _sessionsBeforeLongBreak = 3;

  // ── Day boundaries ───────────────────────────────────────────────
  static const double _dayStart = 9.0; // 9:00 AM
  static const double _dayEnd = 23.0; // 11:00 PM

  // ─────────────────────────────────────────────────────────────────
  /// Main entry point.
  /// [globalDailyHours] is the user's requested daily study budget.
  /// The AI may push ABOVE this if exam urgency demands it.
  static List<Map<String, dynamic>> generatePlan(
    List<Map<String, dynamic>> subjects,
    List<Map<String, dynamic>> tasks, {
    double globalDailyHours = 6.0,
    Set<String> skipDays = const {},
  }) {
    final List<Map<String, dynamic>> plan = [];
    int sortIdx = 0;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // ── Build Blocked Ranges (Exams) ────────────────────────────────
    final Map<String, List<List<double>>> blockedRanges = {};
    for (final s in subjects) {
      final DateTime examDate =
          _parseDate(s['date'] ?? '') ?? today.add(const Duration(days: 7));
      final DateTime examDay =
          DateTime(examDate.year, examDate.month, examDate.day);
      final String dateStr = _dayLabel(examDay);

      final String examTime = (s['examTime'] ?? '').toString().trim().isNotEmpty
          ? s['examTime']
          : '9:00 AM – 12:00 PM';

      final parts = examTime.split('–');
      if (parts.isNotEmpty) {
        double startHr = _parseTimeToHours(parts.first);
        double endHr = parts.length > 1
            ? _parseTimeToHours(parts.last)
            : (startHr + 2.0);
        if (endHr < startHr) endHr = startHr + 2.0;

        blockedRanges.putIfAbsent(dateStr, () => []);
        blockedRanges[dateStr]!.add([startHr, endHr]);
      }
    }

    // dayHourCursor[dateStr] → next free hour for that day
    final Map<String, double> dayHourCursor = {};
    // daySessionCount[dateStr] → sessions done today (for long-break cadence)
    final Map<String, int> daySessionCount = {};
    // dayStudyHours[dateStr] → actual study hours scheduled (excludes breaks)
    final Map<String, double> dayStudyHours = {};

    // ── Priority sort: high score = study sooner ─────────────────
    final sorted = List<Map<String, dynamic>>.from(subjects)
      ..sort((a, b) =>
          _priorityScore(b, today).compareTo(_priorityScore(a, today)));

    // ══════════════════════════════════════════════════════════════
    // ── PHASE 1: Schedule exam events + revision day ─────────────
    // ══════════════════════════════════════════════════════════════

    for (final s in sorted) {
      final DateTime examDate =
          _parseDate(s['date'] ?? '') ?? today.add(const Duration(days: 7));
      final DateTime examDay =
          DateTime(examDate.year, examDate.month, examDate.day);

      final String examTime = (s['examTime'] ?? '').toString().trim().isNotEmpty
          ? s['examTime']
          : '9:00 AM – 12:00 PM';

      final double examStartHr =
          _parseTimeToHours(examTime.split('–').first.split('-').first.trim());
      final double revStartHr = (examStartHr - 0.5).clamp(0.0, 24.0);

      // 30-min quick revision before exam
      plan.add({
        'subjectId': s['id'] ?? '',
        'subject': '${s['name']} — Final Revision',
        'topic': 'Pre-exam quick review',
        'date': _dayLabel(examDay),
        'time': '${_fmt(revStartHr)} – ${_fmt(examStartHr)}',
        'type': 'study',
        'isDone': false,
        'daysLeft': 0,
        'tip': 'Quick 30 min refresher right before the exam!',
        'sortIndex': sortIdx++,
      });

      // Exam event
      plan.add({
        'subjectId': s['id'] ?? '',
        'subject': '🎓 ${s['name']} — EXAM',
        'topic': '',
        'date': _dayLabel(examDay),
        'time': examTime,
        'type': 'exam',
        'isDone': false,
        'daysLeft': 0,
        'tip': '',
        'sortIndex': sortIdx++,
      });
    }

    // ══════════════════════════════════════════════════════════════
    // ── PHASE 2: AI-powered distribution of study hours ──────────
    // For each subject, calculate:
    //   - totalHoursNeeded = subject.totalHours × difficultyMultiplier
    //   - urgencyBoost based on days until exam
    //   - distribute across available days (more hours closer to exam)
    // ══════════════════════════════════════════════════════════════

    // Build per-day allocation map: date → list of { subject, hours }
    // We'll collect all allocations first, then schedule sessions.
    final Map<String, List<_DayAlloc>> dayAllocations = {};

    for (final s in sorted) {
      final DateTime examDate =
          _parseDate(s['date'] ?? '') ?? today.add(const Duration(days: 7));
      final DateTime examDay =
          DateTime(examDate.year, examDate.month, examDate.day);

      // Study days: today … examDay-2 (examDay-1 = dedicated revision)
      List<DateTime> studyDays = _availableDays(
        today,
        examDay.subtract(const Duration(days: 2)),
        skipDays,
      );
      if (studyDays.isEmpty) {
        studyDays = _availableDays(
            today, examDay.subtract(const Duration(days: 1)), skipDays);
      }
      if (studyDays.isEmpty) continue;

      // ── AI: Calculate total hours needed ──────────────────────
      double baseTotalHours =
          double.tryParse(s['hours']?.toString() ?? '') ?? 6.0;
      double diffMult = _diffMult(s['difficulty']);
      double totalNeeded = baseTotalHours * diffMult;

      // ── AI: Urgency boost ────────────────────────────────────
      // Fewer days → more intense daily study
      int totalDaysAvail = studyDays.length;
      double urgencyMult = _urgencyMultiplier(totalDaysAvail);
      totalNeeded *= urgencyMult;

      // ── AI: Distribute with progressive ramp-up ──────────────
      // Days closer to exam get MORE hours (ramping schedule)
      List<double> dailyAllocs =
          _smartDistribute(totalNeeded, studyDays.length, globalDailyHours);

      // Get topics for this subject
      final List<String> allTopics = List<String>.from(s['topics'] ?? []);
      final List<String> completedTopics =
          List<String>.from(s['completedTopics'] ?? []);
      final List<String> remaining =
          allTopics.where((t) => !completedTopics.contains(t)).toList();

      // Store allocations per day
      for (int i = 0; i < studyDays.length; i++) {
        final dateStr = _dayLabel(studyDays[i]);
        dayAllocations.putIfAbsent(dateStr, () => []);
        dayAllocations[dateStr]!.add(_DayAlloc(
          subject: s,
          allocHours: dailyAllocs[i],
          examDay: examDay,
          studyDay: studyDays[i],
          remainingTopics: remaining,
          daysLeft: examDay.difference(studyDays[i]).inDays,
        ));
      }

      // ── Revision day (day before exam) ───────────────────────
      final DateTime revisionDay = examDay.subtract(const Duration(days: 1));
      final String revDateStr = _dayLabel(revisionDay);
      if (!skipDays.contains(revDateStr) && !revisionDay.isBefore(today)) {
        // Revision gets 50-70% of daily hours depending on urgency
        double revHours =
            (globalDailyHours * (0.5 + urgencyMult * 0.1)).clamp(2.0, globalDailyHours);
        dayAllocations.putIfAbsent(revDateStr, () => []);
        dayAllocations[revDateStr]!.add(_DayAlloc(
          subject: s,
          allocHours: revHours,
          examDay: examDay,
          studyDay: revisionDay,
          remainingTopics: [],
          daysLeft: 1,
          isRevisionDay: true,
        ));
      }
    }

    // ══════════════════════════════════════════════════════════════
    // ── PHASE 3: Create actual sessions from allocations ─────────
    // ══════════════════════════════════════════════════════════════

    // Sort dates chronologically
    final allDates = dayAllocations.keys.toList()
      ..sort((a, b) => _parseDayStr(a).compareTo(_parseDayStr(b)));

    // Track which topic index we're at per subject
    final Map<String, int> subjectTopicIdx = {};

    for (final dateStr in allDates) {
      dayHourCursor.putIfAbsent(dateStr, () => _dayStart);
      daySessionCount.putIfAbsent(dateStr, () => 0);
      dayStudyHours.putIfAbsent(dateStr, () => 0.0);

      final allocs = dayAllocations[dateStr]!;

      for (final alloc in allocs) {
        final s = alloc.subject;
        final String subId = s['id'] ?? s['name'] ?? '';
        final double targetHours = alloc.allocHours;
        final int daysLeft = alloc.daysLeft;

        subjectTopicIdx.putIfAbsent(subId, () => 0);

        double hoursScheduled = 0;
        int sessionNum = 0;

        while (hoursScheduled < targetHours) {
          if ((dayHourCursor[dateStr] ?? _dayStart) >= _dayEnd) break;

          double remaining = targetHours - hoursScheduled;
          double block = remaining.clamp(0.5, _sessionDur);
          double start = dayHourCursor[dateStr]!;
          start = _getNextSafeStart(start, block, dateStr, blockedRanges);

          if (start + block > _dayEnd) {
            block = _dayEnd - start;
            if (block < 0.25) break;
          }

          // Decide what this session should be about
          String topic;
          String sessionLabel;
          String tip;

          if (alloc.isRevisionDay) {
            // Revision day sessions
            final revTypes = [
              'Comprehensive Revision',
              'Practice Problems',
              'Formula & Key Concepts Review',
              'Mock Test / Self-Quiz',
              'Weak Areas Focus',
              'Quick Recap',
            ];
            final revType = revTypes[sessionNum % revTypes.length];
            sessionLabel = '${s['name']} — $revType';
            topic = revType;
            tip = _revisionTip(revType, daysLeft);
          } else {
            // Regular study day
            final topicList = alloc.remainingTopics;
            int tIdx = subjectTopicIdx[subId]!;

            if (tIdx < topicList.length) {
              // Cover a real topic
              topic = topicList[tIdx];
              sessionLabel = s['name'] ?? '';
              tip = _tip(daysLeft, topicList.length - tIdx);
              subjectTopicIdx[subId] = tIdx + 1;
            } else {
              // All topics covered → add smart revision/practice sessions
              final extraTypes = [
                'Revision & Practice',
                'Practice Problems',
                'Active Recall Session',
                'Deep Dive Study',
                'Weak Areas Focus',
                'Concept Review',
                'Key Formulas Review',
                'Quick Recap & Notes',
              ];
              final extraType = extraTypes[sessionNum % extraTypes.length];
              sessionLabel = '${s['name']} — $extraType';
              topic = extraType;
              tip = _fillTip(extraType, daysLeft);
            }
          }

          plan.add({
            'subjectId': subId,
            'subject': sessionLabel,
            'topic': topic,
            'date': dateStr,
            'time': '${_fmt(start)} – ${_fmt(start + block)}',
            'type': 'study',
            'isDone': false,
            'daysLeft': daysLeft,
            'tip': tip,
            'sortIndex': sortIdx++,
          });

          dayHourCursor[dateStr] = start + block;
          dayStudyHours[dateStr] = (dayStudyHours[dateStr] ?? 0) + block;
          daySessionCount[dateStr] = (daySessionCount[dateStr] ?? 0) + 1;
          hoursScheduled += block;
          sessionNum++;

          sortIdx = _insertBreak(
            plan: plan,
            dateStr: dateStr,
            dayHourCursor: dayHourCursor,
            daySessionCount: daySessionCount,
            blockedRanges: blockedRanges,
            sortIdx: sortIdx,
          );
        }
      }
    }

    // ══════════════════════════════════════════════════════════════
    // ── PHASE 4: Schedule tasks ──────────────────────────────────
    // ══════════════════════════════════════════════════════════════

    final taskDays = _availableDays(
      today,
      today.add(const Duration(days: 6)),
      skipDays,
    ).take(3).toList();

    for (final t in tasks) {
      if (t['isDone'] == true) continue;
      final double hrs = double.tryParse(t['hours'].toString()) ?? 1.0;
      final double perDay = taskDays.isEmpty ? hrs : hrs / taskDays.length;
      final String label = '📝 ${t['task']}';
      final String subjectName = t['subject'] ?? '';

      for (final day in taskDays) {
        final String dateStr = _dayLabel(day);
        dayHourCursor.putIfAbsent(dateStr, () => _dayStart);
        daySessionCount.putIfAbsent(dateStr, () => 0);
        dayStudyHours.putIfAbsent(dateStr, () => 0.0);

        double rem = perDay;
        while (rem > 0.05 && (dayHourCursor[dateStr] ?? _dayStart) < _dayEnd) {
          final double block = rem.clamp(0.0, _sessionDur);
          double start = dayHourCursor[dateStr]!;
          start = _getNextSafeStart(start, block, dateStr, blockedRanges);

          if (start + block > _dayEnd) break;

          plan.add({
            'subjectId': t['id'] ?? '',
            'subject': label,
            'topic': subjectName,
            'date': dateStr,
            'time': '${_fmt(start)} – ${_fmt(start + block)}',
            'type': 'task',
            'isDone': false,
            'daysLeft': 0,
            'tip': '',
            'sortIndex': sortIdx++,
          });

          dayHourCursor[dateStr] = start + block;
          dayStudyHours[dateStr] = (dayStudyHours[dateStr] ?? 0) + block;
          daySessionCount[dateStr] = (daySessionCount[dateStr] ?? 0) + 1;
          sortIdx = _insertBreak(
            plan: plan,
            dateStr: dateStr,
            dayHourCursor: dayHourCursor,
            daySessionCount: daySessionCount,
            blockedRanges: blockedRanges,
            sortIdx: sortIdx,
          );
          rem -= block;
        }
      }
    }

    // ── Final sort ───────────────────────────────────────────────
    plan.sort((a, b) {
      final dateComp = _parseDayStr(a['date'] ?? '')
          .compareTo(_parseDayStr(b['date'] ?? ''));
      if (dateComp != 0) return dateComp;
      return (a['sortIndex'] as int).compareTo(b['sortIndex'] as int);
    });

    return plan;
  }

  // ══════════════════════════════════════════════════════════════════
  // ── AI: Smart Distribution Logic ──────────────────────────────────
  // ══════════════════════════════════════════════════════════════════

  /// Urgency multiplier — fewer days = harder you need to push.
  /// 1 day left → 1.5x, 2 days → 1.3x, 3 days → 1.2x, 7+ days → 1.0x
  static double _urgencyMultiplier(int availableDays) {
    if (availableDays <= 1) return 1.5;
    if (availableDays <= 2) return 1.3;
    if (availableDays <= 3) return 1.2;
    if (availableDays <= 5) return 1.1;
    return 1.0;
  }

  /// Distributes [totalHours] across [numDays] with progressive ramp-up
  /// (days closer to exam get more hours). Each day is capped at [maxPerDay].
  ///
  /// Example: 9 hours over 3 days → [2.0, 3.0, 4.0] (ramps up toward exam)
  static List<double> _smartDistribute(
      double totalHours, int numDays, double maxPerDay) {
    if (numDays <= 0) return [];
    if (numDays == 1) return [totalHours.clamp(0.5, maxPerDay)];

    // Create progressive weights: later days (closer to exam) get more
    // Weight pattern: 1.0, 1.2, 1.4, 1.6 ...
    List<double> weights = [];
    for (int i = 0; i < numDays; i++) {
      weights.add(1.0 + 0.3 * i);
    }
    double totalWeight = weights.fold(0.0, (a, b) => a + b);

    // Distribute proportionally
    List<double> allocs = [];
    double allocated = 0;
    for (int i = 0; i < numDays; i++) {
      double share = totalHours * (weights[i] / totalWeight);
      // Round to nearest 0.5 for cleaner blocks
      share = (share * 2).round() / 2.0;
      share = share.clamp(0.5, maxPerDay);
      allocs.add(share);
      allocated += share;
    }

    // Adjust last day to match total (absorb rounding errors)
    double diff = totalHours - allocated;
    if (diff.abs() > 0.1) {
      allocs[numDays - 1] =
          (allocs[numDays - 1] + diff).clamp(0.5, maxPerDay);
    }

    return allocs;
  }

  // ── Insert short or long break ───────────────────────────────────
  static int _insertBreak({
    required List<Map<String, dynamic>> plan,
    required String dateStr,
    required Map<String, double> dayHourCursor,
    required Map<String, int> daySessionCount,
    required Map<String, List<List<double>>> blockedRanges,
    required int sortIdx,
  }) {
    final int count = daySessionCount[dateStr] ?? 0;
    final bool isLong = count % _sessionsBeforeLongBreak == 0;
    final double dur = isLong ? _longBreak : _shortBreak;

    double cursor = dayHourCursor[dateStr] ?? _dayStart;
    cursor = _getNextSafeStart(cursor, dur, dateStr, blockedRanges);

    if (cursor >= _dayEnd) return sortIdx;

    final double end = (cursor + dur).clamp(cursor, _dayEnd + 0.5);

    plan.add({
      'subject': isLong ? '☕ Long Break (25 min)' : '⏸ Short Break (10 min)',
      'topic': '',
      'date': dateStr,
      'time': '${_fmt(cursor)} – ${_fmt(end)}',
      'type': isLong ? 'longBreak' : 'break',
      'isDone': false,
      'daysLeft': 0,
      'tip': '',
      'sortIndex': sortIdx++,
    });

    dayHourCursor[dateStr] = end;
    return sortIdx;
  }

  // ── Tips ─────────────────────────────────────────────────────────

  static String _revisionTip(String revType, int daysLeft) {
    switch (revType) {
      case 'Comprehensive Revision':
        return '📚 Go through everything — tomorrow is the big day!';
      case 'Practice Problems':
        return '✏️ Solve problems without looking at solutions first.';
      case 'Formula & Key Concepts Review':
        return '📐 Write down all formulas from memory, then verify.';
      case 'Mock Test / Self-Quiz':
        return '🧪 Test yourself under exam conditions!';
      case 'Weak Areas Focus':
        return '🎯 Spend extra time on topics you struggle with.';
      case 'Quick Recap':
        return '⚡ Speed-run your notes — hit the key points.';
      default:
        return '🌟 Final prep — you\'ve got this!';
    }
  }

  static String _fillTip(String label, int daysLeft) {
    if (daysLeft <= 2) {
      return '🔥 Exam is close! This extra practice will boost your confidence.';
    }
    switch (label) {
      case 'Revision & Practice':
        return '📝 Revisit what you learned. Repetition builds mastery!';
      case 'Practice Problems':
        return '✏️ Solve problems to test your understanding.';
      case 'Active Recall Session':
        return '💡 Close the book and test yourself from memory!';
      case 'Deep Dive Study':
        return '🧠 Go beyond basics — explore tricky edge cases.';
      case 'Weak Areas Focus':
        return '🎯 Focus on the topics you find hardest.';
      case 'Concept Review':
        return '🔍 Re-read key concepts for deeper understanding.';
      case 'Key Formulas Review':
        return '📐 Go over important formulas and derivations.';
      case 'Quick Recap & Notes':
        return '⚡ Speed-review your notes — hit the highlights.';
      default:
        return '🌟 Every session counts — keep going!';
    }
  }

  static String _tip(int daysLeft, int remTopics) {
    if (daysLeft <= 1) {
      return '🔥 Final push — you\'ve prepared for this. Trust your work!';
    }
    if (daysLeft <= 3) {
      return remTopics <= 2
          ? '🎯 Almost there! $remTopics topic${remTopics == 1 ? '' : 's'} left — finish strong.'
          : '⚡ Short on time — focus on high-yield topics first.';
    }
    if (daysLeft <= 7) {
      return '📌 $daysLeft days left. Consistency beats cramming.';
    }
    return '🌱 Great momentum! Early prep = confident exam day.';
  }

  // ── Priority score ───────────────────────────────────────────────
  static double _priorityScore(Map<String, dynamic> s, DateTime today) {
    final DateTime? exam = _parseDate(s['date'] ?? '');
    if (exam == null) return 0;
    final int days = exam.difference(today).inDays.clamp(1, 999);
    final List topics = s['topics'] ?? [];
    final List done = s['completedTopics'] ?? [];
    final double rem =
        topics.isEmpty ? 1.0 : (topics.length - done.length) / topics.length;
    return (100.0 / days) * _diffMult(s['difficulty']) * (0.5 + rem);
  }

  static double _diffMult(dynamic d) {
    switch (d) {
      case 'Hard':
        return 1.5;
      case 'Easy':
        return 0.85;
      default:
        return 1.0;
    }
  }

  static List<DateTime> _availableDays(
      DateTime start, DateTime end, Set<String> skip) {
    final List<DateTime> days = [];
    DateTime cur = start;
    while (!cur.isAfter(end)) {
      if (!skip.contains(_dayLabel(cur))) days.add(cur);
      cur = cur.add(const Duration(days: 1));
    }
    return days;
  }

  // ── Helpers ──────────────────────────────────────────────────────
  static String _dayLabel(DateTime d) => '${d.day}/${d.month}/${d.year}';

  static DateTime _parseDayStr(String s) {
    try {
      final p = s.split('/');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) {
      return DateTime(2000);
    }
  }

  static DateTime? _parseDate(String s) => DateTime.tryParse(s);

  static String _fmt(double time) {
    final int h = time.floor();
    final int m = ((time - h) * 60).round();
    final String period = h >= 12 ? 'PM' : 'AM';
    final int display = h % 12 == 0 ? 12 : h % 12;
    return '$display:${m.toString().padLeft(2, '0')} $period';
  }

  // ── Collision handling ──────────────────────────────────────────
  static double _parseTimeToHours(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();
    if (timeStr.isEmpty) return 12.0;

    bool isPM = timeStr.contains('PM');
    String timePart = timeStr.replaceAll('AM', '').replaceAll('PM', '').trim();
    List<String> parts = timePart.split(':');
    if (parts.isEmpty) return 12.0;

    double h = double.tryParse(parts[0]) ?? 12.0;
    double m = parts.length > 1 ? (double.tryParse(parts[1]) ?? 0.0) : 0.0;

    if (h == 12 && !isPM) h = 0.0;
    if (h != 12 && isPM) h += 12.0;

    return h + (m / 60.0);
  }

  static double _getNextSafeStart(
    double start,
    double duration,
    String dateStr,
    Map<String, List<List<double>>> blockedRanges,
  ) {
    if (!blockedRanges.containsKey(dateStr)) return start;
    final blocks = blockedRanges[dateStr]!;

    double current = start;
    for (final b in blocks) {
      double bStart = b[0];
      double bEnd = b[1];

      // If session overlaps exam block (with a 30 min prep buffer before exam)
      if (current + duration > bStart - 0.5 && current < bEnd) {
        // Jump to 1 hour after the exam ends for rest
        current = bEnd + 1.0;
      }
    }
    return current;
  }
}

/// Internal helper class for per-day allocation tracking.
class _DayAlloc {
  final Map<String, dynamic> subject;
  final double allocHours;
  final DateTime examDay;
  final DateTime studyDay;
  final List<String> remainingTopics;
  final int daysLeft;
  final bool isRevisionDay;

  _DayAlloc({
    required this.subject,
    required this.allocHours,
    required this.examDay,
    required this.studyDay,
    required this.remainingTopics,
    required this.daysLeft,
    this.isRevisionDay = false,
  });
}