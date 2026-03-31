import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/task_model.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController taskController = TextEditingController();
  final TextEditingController hoursController = TextEditingController();

  String? selectedSubject;

  final subjectBox = Hive.box(AppConstants.subjectBox);
  final taskBox = Hive.box(AppConstants.taskBox);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),

        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔙 Back
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: AppColors.white),
                ),

                const Text(
                  "Add Task 📝",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),

                const SizedBox(height: 30),
                if (subjectBox.length == 0)
                  const Expanded(
                    child: Center(
                      child: Text(
                        "⚠️ Please add a subject first",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                else
                  // 💎 Card
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            // 📝 Task Name
                            TextField(
                              controller: taskController,
                              decoration: InputDecoration(
                                labelText: "Task Name",
                                filled: true,
                                fillColor: AppColors.lightGrey,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 📚 SUBJECT DROPDOWN (FIXED)
                            DropdownButtonFormField<String>(
                              initialValue: selectedSubject,
                              hint: const Text("Select Subject"),
                              items: List.generate(subjectBox.length, (index) {
                                var subject = subjectBox.getAt(index);

                                return DropdownMenuItem<String>(
                                  value: subject["name"].toString(),
                                  child: Text(subject["name"].toString()),
                                );
                              }),
                              onChanged: (value) {
                                setState(() {
                                  selectedSubject = value;
                                });
                              },
                            ),

                            const SizedBox(height: 20),

                            // ⏱ Hours
                            TextField(
                              controller: hoursController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: "Hours",
                                filled: true,
                                fillColor: AppColors.lightGrey,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),

                            const SizedBox(height: 25),

                            // 🚀 SAVE BUTTON
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (taskController.text.isEmpty ||
                                      selectedSubject == null ||
                                      hoursController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Fill all fields"),
                                      ),
                                    );
                                    return;
                                  }

                                  // ✅ SAVE
                                  taskBox.add(
                                    TaskModel(
                                      task: taskController.text,
                                      subject: selectedSubject!,
                                      hours: hoursController.text,
                                    ).toMap(),
                                  );

                                  debugPrint("✅ Task Saved"); // debug

                                  Navigator.pop(context);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("Save"),
                              ),
                            ),
                          ],
                        ),
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
}
