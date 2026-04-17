class SubjectModel {
  String? id;
  String name;
  String hours;
  String? date;
  String priority;

  // ── New fields ───────────────────────────────────────────────────
  /// Ordered list of topics for this subject (e.g. ['Algebra', 'Calculus'])
  List<String> topics;

  /// Subset of [topics] the user has already completed
  List<String> completedTopics;

  /// Difficulty rating affects priority score: Easy → 1.0, Medium → 1.25, Hard → 1.5
  String difficulty;

  /// How many hours per day the user can dedicate to this subject
  double dailyHours;

  /// Exam time range shown on exam day card, e.g. '10:00 AM – 1:00 PM'
  String examTime;

  SubjectModel({
    this.id,
    required this.name,
    required this.hours,
    this.date,
    this.priority = 'Medium',
    List<String>? topics,
    List<String>? completedTopics,
    this.difficulty = 'Medium',
    this.dailyHours = 2.0,
    this.examTime = '',
  })  : topics = topics ?? [],
        completedTopics = completedTopics ?? [];

  /// Remaining topics not yet completed
  List<String> get remainingTopics =>
      topics.where((t) => !completedTopics.contains(t)).toList();

  /// Progress ratio 0.0–1.0 based on completed topics
  double get topicProgress =>
      topics.isEmpty ? 0.0 : completedTopics.length / topics.length;

  /// Serialize for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'hours': hours,
      'date': date,
      'priority': priority,
      'topics': topics,
      'completedTopics': completedTopics,
      'difficulty': difficulty,
      'dailyHours': dailyHours,
      'examTime': examTime,
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
      topics: List<String>.from(data['topics'] ?? []),
      completedTopics: List<String>.from(data['completedTopics'] ?? []),
      difficulty: data['difficulty'] ?? 'Medium',
      dailyHours: (data['dailyHours'] as num?)?.toDouble() ?? 2.0,
      examTime: data['examTime'] ?? '',
    );
  }
}
