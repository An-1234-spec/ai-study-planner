class SubjectModel {
  String name;
  String hours;
  String? date;

  SubjectModel({required this.name, required this.hours, this.date});

  // Convert to Map (for Hive storage)
  Map<String, dynamic> toMap() {
    return {"name": name, "hours": hours, "date": date};
  }

  // 🔥 Convert from Map (for reading from Hive)
  factory SubjectModel.fromMap(Map<dynamic, dynamic> data) {
    return SubjectModel(
      name: data["name"],
      hours: data["hours"],
      date: data["date"],
    );
  }
}
