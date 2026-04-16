class TaskModel {
  String? id;
  String task;
  String subject;
  String hours;
  bool isDone;
  String? deadline;

  TaskModel({
    this.id,
    required this.task,
    required this.subject,
    required this.hours,
    this.isDone = false,
    this.deadline,
  });

  /// Serialize for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'task': task,
      'subject': subject,
      'hours': hours,
      'isDone': isDone,
      'deadline': deadline,
    };
  }

  /// Legacy alias used by algorithm
  Map<String, dynamic> toMap() => toFirestore();

  /// Deserialize from Firestore doc
  factory TaskModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return TaskModel(
      id: docId,
      task: data['task'] ?? '',
      subject: data['subject'] ?? '',
      hours: data['hours'] ?? '1',
      isDone: data['isDone'] ?? false,
      deadline: data['deadline'],
    );
  }
}
