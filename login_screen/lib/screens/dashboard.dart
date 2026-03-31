import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'add_subject.dart';
import 'add_task.dart'; // ✅ NEW
import 'timetable_screen.dart';
import 'progress_screen.dart';
import 'login_screen.dart'; // ✅ ADDED
import '../widgets/subject_card.dart';
import '../widgets/task_tile.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  var box = Hive.box(AppConstants.subjectBox);
  var taskBox = Hive.box(AppConstants.taskBox);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🔥 TWO BUTTONS NOW
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // ➕ ADD TASK
          FloatingActionButton(
            heroTag: "task",
            backgroundColor: Colors.orange,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTaskScreen()),
              );
              setState(() {});
            },
            child: const Icon(Icons.task),
          ),

          const SizedBox(height: 10),

          // ➕ ADD SUBJECT
          FloatingActionButton(
            heroTag: "subject",
            backgroundColor: AppColors.primary,
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddSubjectScreen(),
                ),
              );
              setState(() {});
            },
            child: const Icon(Icons.add),
          ),
        ],
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
          ),
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔥 ONLY CHANGE HERE (LOGOUT ADDED)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Dashboard 📚",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () {
                        var authBox = Hive.box('auth');

                        authBox.put("isLoggedIn", false);

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => LoginScreen()),
                          (route) => false,
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // 💎 MAIN CONTENT
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),

                    child: ListView(
                      children: [
                        // 📊 PROGRESS
                        const Text(
                          "Study Progress",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        LinearProgressIndicator(
                          value: box.isEmpty
                              ? 0
                              : (box.length / AppConstants.maxSubjects).clamp(
                                  0.0, 1.0),
                          color: AppColors.primary,
                        ),

                        const SizedBox(height: 20),

                        // 📚 SUBJECTS
                        const Text(
                          "Your Subjects",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        box.isEmpty
                            ? _empty("No subjects yet")
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: box.length,
                                itemBuilder: (context, index) {
                                  var subject = box.getAt(index);

                                  return Dismissible(
                                    key: Key(box.keyAt(index).toString()),
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onDismissed: (_) {
                                      box.deleteAt(index);
                                      setState(() {});
                                    },
                                    child: GestureDetector(
                                      onLongPress: () {
                                        _editSubject(index, subject);
                                      },
                                      child: SubjectCard(
                                        title: subject["name"],
                                        hours: subject["hours"],
                                        date: subject["date"],
                                      ),
                                    ),
                                  );
                                },
                              ),

                        const SizedBox(height: 20),

                        // 📝 TASKS
                        const Text(
                          "Your Tasks",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 10),

                        taskBox.isEmpty
                            ? _empty("No tasks yet")
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: taskBox.length,
                                itemBuilder: (context, index) {
                                  var task = taskBox.getAt(index);

                                  return Dismissible(
                                    key: Key("task_${taskBox.keyAt(index)}"),
                                    background: Container(
                                      color: Colors.red,
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      child: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                      ),
                                    ),
                                    onDismissed: (_) {
                                      taskBox.deleteAt(index);
                                      setState(() {});
                                    },
                                    child: TaskTile(
                                      task: task["task"],
                                      subject: task["subject"],
                                      hours: task["hours"],
                                    ),
                                  );
                                },
                              ),

                        const SizedBox(height: 20),

                        // 🚀 BUTTONS
                        _button("Generate Study Plan", () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TimetableScreen(),
                            ),
                          );
                        }),

                        const SizedBox(height: 10),

                        _button("View Progress", () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProgressScreen(),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _editSubject(int index, dynamic subject) {
    TextEditingController controller = TextEditingController(
      text: subject["name"],
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Subject"),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () {
              subject["name"] = controller.text;
              box.putAt(index, subject);
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _empty(String text) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _button(String text, VoidCallback onTap) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(text),
      ),
    );
  }
}
