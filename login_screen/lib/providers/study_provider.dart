import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';
import '../services/planner_algorithm.dart';

/// Manages all study data (subjects, tasks, timetable) via Firestore streams.
/// Initialised by [ChangeNotifierProxyProvider] whenever the logged-in user changes.
class StudyProvider extends ChangeNotifier {
  final FirestoreService _db = FirestoreService();

  String? _uid;
  StreamSubscription<QuerySnapshot>? _subsSub;
  StreamSubscription<QuerySnapshot>? _tasksSub;
  StreamSubscription<QuerySnapshot>? _ttSub;
  StreamSubscription<DocumentSnapshot>? _settingsSub;

  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _timetable = [];
  bool _isLoading = false;
  bool _planGenerated = false;

  // ── User settings ────────────────────────────────────────────────
  double _globalDailyHours = 6.0;
  bool _skippedDay = false;

  // ── Getters ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> get subjects => _subjects;
  List<Map<String, dynamic>> get tasks => _tasks;
  List<Map<String, dynamic>> get timetable => _timetable;
  bool get isLoading => _isLoading;
  bool get planGenerated => _planGenerated;
  double get globalDailyHours => _globalDailyHours;
  bool get skippedDay => _skippedDay;

  /// Total study hours required across all subjects
  double get totalHours {
    double total = 0;
    for (var s in _subjects) {
      total += double.tryParse(s['hours']?.toString() ?? '0') ?? 0;
    }
    return total;
  }

  /// Total study hours completed (from timetable sessions marked done)
  double get completedHours {
    double done = 0;
    for (final entry in _timetable) {
      if (entry['isDone'] == true && entry['type'] == 'study') {
        done += _parseSessionDuration(entry['time'] ?? '');
      }
    }
    return done;
  }

  /// Overall progress based on hours completed / total hours
  double get progress {
    if (totalHours <= 0) return 0;
    return (completedHours / totalHours).clamp(0.0, 1.0);
  }

  /// For backward compatibility — returns hours as formatted strings
  String get completedHoursFormatted => completedHours.toStringAsFixed(1);
  String get totalHoursFormatted => totalHours.toStringAsFixed(1);

  List<Map<String, dynamic>> get upcomingSubjects {
    final now = DateTime.now();
    final list = _subjects.where((s) {
      final d = DateTime.tryParse(s['date'] ?? '');
      return d != null && d.isAfter(now);
    }).toList();
    list.sort((a, b) {
      final da = DateTime.parse(a['date']!);
      final db = DateTime.parse(b['date']!);
      return da.compareTo(db);
    });
    return list;
  }

  /// Per-subject progress based on HOURS completed vs total hours
  /// Maps subjectId → { 'progress': 0.0-1.0, 'done': hours, 'total': hours }
  Map<String, Map<String, double>> get perSubjectHoursProgress {
    final Map<String, Map<String, double>> map = {};
    for (final s in _subjects) {
      final String sid = s['id'] ?? s['name'] ?? '';
      final double subTotal = double.tryParse(s['hours']?.toString() ?? '0') ?? 0;

      // Sum hours of completed timetable sessions for this subject
      double subDone = 0;
      for (final entry in _timetable) {
        if (entry['isDone'] == true &&
            entry['type'] == 'study' &&
            entry['subjectId'] == sid) {
          subDone += _parseSessionDuration(entry['time'] ?? '');
        }
      }

      map[sid] = {
        'progress': subTotal <= 0 ? 0.0 : (subDone / subTotal).clamp(0.0, 1.0),
        'done': subDone,
        'total': subTotal,
      };
    }
    return map;
  }

  /// Parse session duration from time string like "9:00 AM – 11:00 AM"
  static double _parseSessionDuration(String timeStr) {
    final parts = timeStr.split('–');
    if (parts.length < 2) return 0;
    final start = _parseTimeToHours(parts[0].trim());
    final end = _parseTimeToHours(parts[1].trim());
    if (end <= start) return 0;
    return end - start;
  }

  static double _parseTimeToHours(String timeStr) {
    timeStr = timeStr.trim().toUpperCase();
    if (timeStr.isEmpty) return 0;
    bool isPM = timeStr.contains('PM');
    String timePart = timeStr.replaceAll('AM', '').replaceAll('PM', '').trim();
    List<String> parts = timePart.split(':');
    if (parts.isEmpty) return 0;
    double h = double.tryParse(parts[0]) ?? 0;
    double m = parts.length > 1 ? (double.tryParse(parts[1]) ?? 0) : 0;
    if (h == 12 && !isPM) h = 0;
    if (h != 12 && isPM) h += 12;
    return h + (m / 60.0);
  }

  /// Motivational tip for today — pulled from any today-plan entry
  String get todaysTip {
    final today = _dayLabel(DateTime.now());
    for (final entry in _timetable) {
      if (entry['date'] == today &&
          (entry['tip'] ?? '').toString().isNotEmpty) {
        return entry['tip'];
      }
    }
    return '🌟 Keep going — every session counts!';
  }

  // ── Lifecycle ────────────────────────────────────────────────────

  void init(String uid) {
    if (_uid == uid) return;
    _uid = uid;
    _cancelAll();
    _listenSubjects();
    _listenTasks();
    _listenTimetable();
    _listenSettings();
    _checkSkipDay(uid);
  }

  void resetUser() {
    _cancelAll();
    _uid = null;
    _subjects = [];
    _tasks = [];
    _timetable = [];
    _planGenerated = false;
    _skippedDay = false;
    notifyListeners();
  }

  // ── Firestore streams ─────────────────────────────────────────────

  void _listenSubjects() {
    _subsSub = _db.getSubjectsStream(_uid!).listen((snap) {
      _subjects = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {...data, 'id': d.id};
      }).toList();
      notifyListeners();
    });
  }

  void _listenTasks() {
    _tasksSub = _db.getTasksStream(_uid!).listen((snap) {
      _tasks = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {...data, 'id': d.id};
      }).toList();
      notifyListeners();
    });
  }

  void _listenTimetable() {
    _ttSub = _db.getTimetableStream(_uid!).listen((snap) {
      _timetable = snap.docs.map((d) {
        final data = d.data() as Map<String, dynamic>;
        return {...data, 'id': d.id};
      }).toList();

      // Sort by date then sortIndex so sessions are always chronological,
      // regardless of the order Firestore returns the documents.
      _timetable.sort((a, b) {
        final dateComp = _parseDayStr(a['date'] ?? '').compareTo(
          _parseDayStr(b['date'] ?? ''),
        );
        if (dateComp != 0) return dateComp;
        final ai = (a['sortIndex'] ?? 0) as int;
        final bi = (b['sortIndex'] ?? 0) as int;
        return ai.compareTo(bi);
      });

      notifyListeners();
    });
  }

  static DateTime _parseDayStr(String s) {
    try {
      final p = s.split('/');
      return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
    } catch (_) {
      return DateTime(2000);
    }
  }

  void _listenSettings() {
    _settingsSub = _db.getUserSettingsStream(_uid!).listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return;
      _globalDailyHours =
          (data['globalDailyHours'] as num?)?.toDouble() ?? 6.0;
      notifyListeners();
    });
  }

  /// On each login, compare last-login date to detect skip days.
  Future<void> _checkSkipDay(String uid) async {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);

    try {
      final snap = await _db.getUserSettings(uid);
      final data = snap.data() as Map<String, dynamic>?;
      final String? lastStr = data?['lastLoginDate'];

      if (lastStr != null) {
        final DateTime? last = DateTime.tryParse(lastStr);
        if (last != null) {
          final DateTime lastOnly =
              DateTime(last.year, last.month, last.day);
          if (todayOnly.difference(lastOnly).inDays > 1) {
            _skippedDay = true;
          }
        }
      }
    } catch (_) {}

    // Update last login to today
    await _db.saveUserSettings(uid, {
      'lastLoginDate': todayOnly.toIso8601String(),
      'globalDailyHours': _globalDailyHours,
    });
  }

  void _cancelAll() {
    _subsSub?.cancel();
    _tasksSub?.cancel();
    _ttSub?.cancel();
    _settingsSub?.cancel();
  }

  // ── Subjects ─────────────────────────────────────────────────────

  Future<void> addSubject(Map<String, dynamic> data) async {
    if (_uid == null) return;
    await _db.addSubject(_uid!, data);
  }

  Future<void> deleteSubject(String docId) async {
    if (_uid == null) return;
    await _db.deleteSubject(_uid!, docId);
  }

  Future<void> updateSubject(String docId, Map<String, dynamic> data) async {
    if (_uid == null) return;
    await _db.updateSubject(_uid!, docId, data);
  }

  // ── Topics ───────────────────────────────────────────────────────

  /// Mark a topic as done and regenerate the plan automatically.
  Future<void> markTopicDone(String subjectId, String topic) async {
    if (_uid == null) return;
    await _db.markTopicDone(_uid!, subjectId, topic);
    // Re-generate so completed topics are excluded from future sessions
    await generateAndSavePlan();
  }

  Future<void> unmarkTopicDone(String subjectId, String topic) async {
    if (_uid == null) return;
    await _db.unmarkTopicDone(_uid!, subjectId, topic);
    await generateAndSavePlan();
  }

  // ── Tasks ────────────────────────────────────────────────────────

  Future<void> addTask(Map<String, dynamic> data) async {
    if (_uid == null) return;
    await _db.addTask(_uid!, data);
  }

  Future<void> deleteTask(String docId) async {
    if (_uid == null) return;
    await _db.deleteTask(_uid!, docId);
  }

  Future<void> toggleTaskDone(String docId, bool isDone) async {
    if (_uid == null) return;
    await _db.updateTaskDone(_uid!, docId, isDone);
  }

  // ── Timetable ────────────────────────────────────────────────────

  Future<void> markEntryDone(String entryId, bool isDone) async {
    if (_uid == null) return;
    await _db.updateTimetableEntryDone(_uid!, entryId, isDone);
  }

  Future<void> updateDailyHours(double hours) async {
    if (_uid == null) return;
    _globalDailyHours = hours;
    notifyListeners();
    await _db.saveUserSettings(_uid!, {'globalDailyHours': hours});
  }

  Future<void> generateAndSavePlan() async {
    if (_uid == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final plan = PlannerAlgorithm.generatePlan(
        _subjects,
        _tasks,
        globalDailyHours: _globalDailyHours,
        skipDays: const {},
      );

      // ── Show the plan INSTANTLY in the UI ──────────────────────
      // Give each entry a temporary empty 'id' so the UI can render now,
      // without waiting for the Firestore round-trip.
      _timetable = plan.map((e) => {...e, 'id': ''}).toList();
      _planGenerated = true;
      _skippedDay = false;
      _isLoading = false;
      notifyListeners();

      // ── Persist to Firestore in the background ─────────────────
      // The real Firestore stream will replace the local copy once saved,
      // which provides the proper doc-ids for marking entries done.
      _db.saveTimetable(_uid!, plan);

      Future.delayed(const Duration(seconds: 3), () {
        _planGenerated = false;
        notifyListeners();
      });
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────
  static String _dayLabel(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }
}
