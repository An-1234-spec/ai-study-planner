import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _taskController = TextEditingController();
  final _hoursController = TextEditingController();
  String? _selectedSubject;
  DateTime? _deadline;
  bool _isSaving = false;

  @override
  void dispose() {
    _taskController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 3)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: Colors.orange),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    final taskName = _taskController.text.trim();
    final hours = _hoursController.text.trim();

    if (taskName.isEmpty || _selectedSubject == null || hours.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    try {
      context.read<StudyProvider>().addTask({
        'task': taskName,
        'subject': _selectedSubject!,
        'hours': hours,
        'deadline': _deadline?.toIso8601String(),
        'isDone': false,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Database Error 🔴'),
            content: Text(
              'Failed to save. Firebase says:\n\n$e\n\n(Did you create the Firestore Database and set the Security Rules?)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(fontSize: 18)),
              )
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = context.watch<StudyProvider>().subjects;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFF8C42), Color(0xFFFF5F6D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── AppBar area ────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                    ),
                    const Text(
                      'Add Task 📝',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 56),
                child: Text(
                  'Auto-saved to your account',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13),
                ),
              ),

              const SizedBox(height: 24),

              // ── Form card ──────────────────────────────────
              Expanded(
                child: subjects.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline,
                                color: Colors.white70, size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              '⚠️ Please add a subject first!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Go back to Dashboard',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Task name
                              _label('Task Name'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _taskController,
                                decoration: _inputDecor(
                                  hint: 'e.g. Complete Chapter 3',
                                  icon: Icons.task_alt,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Subject dropdown (from Firestore stream)
                              _label('Subject *'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSubject,
                                hint: const Text('Select Subject'),
                                items: subjects.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s['name'].toString(),
                                    child: Text(s['name'].toString()),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedSubject = val),
                                decoration: _inputDecor(
                                  hint: 'Select subject',
                                  icon: Icons.menu_book_rounded,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Hours
                              _label('Estimated Hours'),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _hoursController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecor(
                                  hint: 'e.g. 2',
                                  icon: Icons.timer_outlined,
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Deadline (optional)
                              _label('Deadline (Optional)'),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: _pickDeadline,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F5F5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_month_outlined,
                                          color: Colors.orange, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        _deadline == null
                                            ? 'Tap to set a deadline'
                                            : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}',
                                        style: TextStyle(
                                          color: _deadline == null
                                              ? Colors.black38
                                              : Colors.black87,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Save
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _save,
                                  icon: _isSaving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Icon(Icons.cloud_upload_rounded),
                                  label: Text(
                                    _isSaving ? 'Saving...' : 'Save Task',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange.shade500,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.black87,
        ),
      );

  InputDecoration _inputDecor({required String hint, required IconData icon}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        prefixIcon: Icon(icon, color: Colors.orange, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.orange, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}
