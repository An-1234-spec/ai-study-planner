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

  List<Map<String, dynamic>> _subjects = [];
  List<Map<String, dynamic>> _tasks = [];
  List<Map<String, dynamic>> _timetable = [];
  bool _isLoading = false;
  bool _planGenerated = false;

  // ── Getters ──────────────────────────────────────────────────────
  List<Map<String, dynamic>> get subjects => _subjects;
  List<Map<String, dynamic>> get tasks => _tasks;
  List<Map<String, dynamic>> get timetable => _timetable;
  bool get isLoading => _isLoading;
  bool get planGenerated => _planGenerated;
  int get totalTasks => _tasks.length;
  int get completedTasks =>
      _tasks.where((t) => t['isDone'] == true).length;
  double get progress =>
      totalTasks == 0 ? 0 : completedTasks / totalTasks;

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

  // ── Lifecycle ────────────────────────────────────────────────────

  /// Called by ProxyProvider whenever the user changes.
  void init(String uid) {
    if (_uid == uid) return; // already listening for this user
    _uid = uid;
    _cancelAll();
    _listenSubjects();
    _listenTasks();
    _listenTimetable();
  }

  /// Clears all data when user logs out.
  void resetUser() {
    _cancelAll();
    _uid = null;
    _subjects = [];
    _tasks = [];
    _timetable = [];
    _planGenerated = false;
    notifyListeners();
  }

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
      notifyListeners();
    });
  }

  void _cancelAll() {
    _subsSub?.cancel();
    _tasksSub?.cancel();
    _ttSub?.cancel();
  }

  // ── Subjects ─────────────────────────────────────────────────────

  Future<void> addSubject(Map<String, dynamic> data) async {
    if (_uid == null) return;
    await _db.addSubject(_uid!, data);
    // Stream automatically updates _subjects
  }

  Future<void> deleteSubject(String docId) async {
    if (_uid == null) return;
    await _db.deleteSubject(_uid!, docId);
  }

  Future<void> updateSubject(String docId, Map<String, dynamic> data) async {
    if (_uid == null) return;
    await _db.updateSubject(_uid!, docId, data);
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

  Future<void> generateAndSavePlan() async {
    if (_uid == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final plan = PlannerAlgorithm.generatePlan(_subjects, _tasks);
      // Fire-and-forget! Immediately saves to local offline cache without UI freeze
      _db.saveTimetable(_uid!, plan);
      _planGenerated = true;
      notifyListeners();

      // Auto-clear the "generated" banner after 3 s
      Future.delayed(const Duration(seconds: 3), () {
        _planGenerated = false;
        notifyListeners();
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cancelAll();
    super.dispose();
  }
}
