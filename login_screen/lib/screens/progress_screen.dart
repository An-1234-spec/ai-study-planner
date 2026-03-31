import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box(AppConstants.subjectBox);

    int totalSubjects = box.length;

    double progress = totalSubjects == 0
        ? 0
        : (totalSubjects / AppConstants.maxSubjects).clamp(0, 1);

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
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: AppColors.white),
                ),

                const Text(
                  "Your Progress 📊",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),

                const SizedBox(height: 30),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Overall Progress",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 15),

                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        backgroundColor: AppColors.lightGrey,
                        color: AppColors.primary,
                      ),

                      const SizedBox(height: 10),

                      Text("${(progress * 100).toInt()}% completed"),

                      const SizedBox(height: 20),

                      Text("Subjects Added: $totalSubjects"),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 🔥 NEW SIMPLE BAR CHART (NO PACKAGE)
                const Text(
                  "Study Hours Chart",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: box.length,
                    itemBuilder: (context, index) {
                      var subject = box.getAt(index);

                      double hours = double.tryParse(
                              subject["hours"].toString()) ??
                          0;

                      return Container(
                        width: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              height: hours * 10, // 🔥 scale
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              subject["name"],
                              style: const TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "Subjects",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),

                const SizedBox(height: 15),

                Expanded(
                  child: box.length == 0
                      ? const Center(
                          child: Text(
                            "No subjects added",
                            style: TextStyle(color: AppColors.white),
                          ),
                        )
                      : ListView.builder(
                          itemCount: box.length,
                          itemBuilder: (context, index) {
                            var subject = box.getAt(index);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subject["name"],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  Text("${subject["hours"]} hrs"),
                                  if (subject["date"] != null)
                                    Text("Exam: ${subject["date"]}"),
                                ],
                              ),
                            );
                          },
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