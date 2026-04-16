import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles all Firestore CRUD operations for the AI Study Planner.
/// Each user's data lives under: users/{userId}/subjects | tasks | timetable
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── HELPERS ─────────────────────────────────────────────────────

  CollectionReference _subjects(String uid) =>
      _db.collection('users').doc(uid).collection('subjects');

  CollectionReference _tasks(String uid) =>
      _db.collection('users').doc(uid).collection('tasks');

  CollectionReference _timetable(String uid) =>
      _db.collection('users').doc(uid).collection('timetable');

  // ── SUBJECTS ────────────────────────────────────────────────────

  Future<void> addSubject(String uid, Map<String, dynamic> data) async {
    await _subjects(uid).add({
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getSubjectsStream(String uid) {
    return _subjects(uid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> deleteSubject(String uid, String docId) async {
    await _subjects(uid).doc(docId).delete();
  }

  Future<void> updateSubject(
      String uid, String docId, Map<String, dynamic> data) async {
    await _subjects(uid).doc(docId).update(data);
  }

  // ── TASKS ────────────────────────────────────────────────────────

  Future<void> addTask(String uid, Map<String, dynamic> data) async {
    await _tasks(uid).add({
      ...data,
      'isDone': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getTasksStream(String uid) {
    return _tasks(uid)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  Future<void> deleteTask(String uid, String docId) async {
    await _tasks(uid).doc(docId).delete();
  }

  Future<void> updateTaskDone(String uid, String docId, bool isDone) async {
    await _tasks(uid).doc(docId).update({'isDone': isDone});
  }

  // ── TIMETABLE ────────────────────────────────────────────────────

  /// Clears old timetable and writes the new plan in a single batch.
  Future<void> saveTimetable(
      String uid, List<Map<String, dynamic>> entries) async {
    // 1. Delete existing entries
    final existing = await _timetable(uid).get();
    final deleteBatch = _db.batch();
    for (final doc in existing.docs) {
      deleteBatch.delete(doc.reference);
    }
    await deleteBatch.commit();

    // 2. Write new entries (Firestore batch max = 500)
    final writeBatch = _db.batch();
    for (final entry in entries) {
      final ref = _timetable(uid).doc();
      writeBatch.set(ref, entry);
    }
    await writeBatch.commit();
  }

  Stream<QuerySnapshot> getTimetableStream(String uid) {
    return _timetable(uid).snapshots();
  }

  Future<void> updateTimetableEntryDone(
      String uid, String docId, bool isDone) async {
    await _timetable(uid).doc(docId).update({'isDone': isDone});
  }
}
