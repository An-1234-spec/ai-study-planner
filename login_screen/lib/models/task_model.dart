class TaskModel {
  String task;
  String subject;
  String hours;

  TaskModel({required this.task, required this.subject, required this.hours});

  // 🔥 Convert to Map (for Hive)
  Map<String, dynamic> toMap() {
    return {"task": task, "subject": subject, "hours": hours};
  }

  // 🔥 Convert from Map
  factory TaskModel.fromMap(Map<dynamic, dynamic> data) {
    return TaskModel(
      task: data["task"],
      subject: data["subject"],
      hours: data["hours"],
    );
  }
}
