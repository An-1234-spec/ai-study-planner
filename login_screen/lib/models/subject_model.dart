class SubjectModel {
  String? id;
  String name;
  String hours;
  String? date;
  String priority;

  SubjectModel({
    this.id,
    required this.name,
    required this.hours,
    this.date,
    this.priority = 'Medium',
  });

  /// Serialize for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'hours': hours,
      'date': date,
      'priority': priority,
    };
  }

  /// Legacy alias used by algorithm
  Map<String, dynamic> toMap() => toFirestore();

  /// Deserialize from Firestore doc
  factory SubjectModel.fromFirestore(Map<String, dynamic> data, String docId) {
    return SubjectModel(
      id: docId,
      name: data['name'] ?? '',
      hours: data['hours'] ?? '1',
      date: data['date'],
      priority: data['priority'] ?? 'Medium',
    );
  }
}
