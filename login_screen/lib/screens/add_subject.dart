import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../utils/colors.dart';

class AddSubjectScreen extends StatefulWidget {
  const AddSubjectScreen({super.key});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  final _subjectController = TextEditingController();
  final _hoursController = TextEditingController();
  final _dailyHoursController = TextEditingController(text: '2');
  final _topicController = TextEditingController();

  String _difficulty = 'Medium';
  DateTime? _selectedDate;
  TimeOfDay? _examStartTime;
  TimeOfDay? _examEndTime;
  bool _isSaving = false;

  final List<String> _topics = [];

  @override
  void dispose() {
    _subjectController.dispose();
    _hoursController.dispose();
    _dailyHoursController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickExamTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart
          ? const TimeOfDay(hour: 10, minute: 0)
          : const TimeOfDay(hour: 13, minute: 0),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _examStartTime = picked;
        } else {
          _examEndTime = picked;
        }
      });
    }
  }

  String _fmtTime(TimeOfDay t) {
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m $period';
  }

  void _addTopic() {
    final t = _topicController.text.trim();
    if (t.isEmpty) return;
    if (_topics.contains(t)) {
      _topicController.clear();
      return;
    }
    setState(() {
      _topics.add(t);
      _topicController.clear();
    });
  }

  void _removeTopic(String topic) {
    setState(() => _topics.remove(topic));
  }

  Future<void> _save() async {
    final name = _subjectController.text.trim();
    final hours = _hoursController.text.trim();
    final dailyHrs = double.tryParse(_dailyHoursController.text.trim()) ?? 2.0;

    if (name.isEmpty || hours.isEmpty || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Please fill subject name, total hours and exam date.'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      context.read<StudyProvider>().addSubject({
        'name': name,
        'hours': hours,
        'date': _selectedDate!.toIso8601String(),
        'priority': 'Medium',
        'difficulty': _difficulty,
        'topics': _topics,
        'completedTopics': [],
        'dailyHours': dailyHrs,
        'examTime': (_examStartTime != null && _examEndTime != null)
            ? '${_fmtTime(_examStartTime!)} – ${_fmtTime(_examEndTime!)}'
            : '',
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
              'Failed to save. Firebase says:\n\n$e\n\n(Did you create the Firestore Database and set Security Rules?)',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK', style: TextStyle(fontSize: 16)),
              )
            ],
          ),
        );
      }
    }
  }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── AppBar ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add Subject 📚',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Auto-saved to your account',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Form card ────────────────────────────────────────
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
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
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Subject name ─────────────────────────
                        _label('Subject Name'),
                        const SizedBox(height: 8),
                        _textField(
                          controller: _subjectController,
                          hint: 'e.g. Mathematics',
                          icon: Icons.menu_book_rounded,
                          capitalize: TextCapitalization.words,
                        ),

                        const SizedBox(height: 18),

                        // ── Difficulty ───────────────────────────
                        _label('Difficulty Level'),
                        const SizedBox(height: 8),
                        _difficultySelector(),

                        const SizedBox(height: 18),

                        // ── Total hours ──────────────────────────
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Total Study Hours'),
                                  const SizedBox(height: 8),
                                  _textField(
                                    controller: _hoursController,
                                    hint: 'e.g. 12',
                                    icon: Icons.timer_outlined,
                                    keyboard: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _label('Daily Hours (this subject)'),
                                  const SizedBox(height: 8),
                                  _textField(
                                    controller: _dailyHoursController,
                                    hint: 'e.g. 2',
                                    icon: Icons.access_time_rounded,
                                    keyboard: TextInputType.number,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // ── Exam date ────────────────────────────
                        _label('Exam Date'),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_outlined,
                                    color: AppColors.primary, size: 20),
                                const SizedBox(width: 12),
                                Text(
                                  _selectedDate == null
                                      ? 'Tap to pick exam date'
                                      : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                  style: TextStyle(
                                    color: _selectedDate == null
                                        ? Colors.black38
                                        : Colors.black87,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // ── Exam Time ─────────────────────────────
                        _label('Exam Time (optional)'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickExamTime(true),
                                child: _timePicker(
                                  label: _examStartTime == null
                                      ? 'Start time'
                                      : _fmtTime(_examStartTime!),
                                  icon: Icons.schedule,
                                  iconColor: AppColors.primary,
                                  selected: _examStartTime != null,
                                ),
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text('–',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.black45,
                                      fontWeight: FontWeight.bold)),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => _pickExamTime(false),
                                child: _timePicker(
                                  label: _examEndTime == null
                                      ? 'End time'
                                      : _fmtTime(_examEndTime!),
                                  icon: Icons.schedule,
                                  iconColor: Colors.redAccent,
                                  selected: _examEndTime != null,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // ── Topics chip input ─────────────────────
                        _label('Topics  (optional but recommended)'),
                        const SizedBox(height: 4),
                        Text(
                          'Add each topic, then tap ➕ — the plan will schedule them individually.',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade500),
                        ),
                        const SizedBox(height: 10),
                        // Input row
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _topicController,
                                textCapitalization: TextCapitalization.sentences,
                                onSubmitted: (_) => _addTopic(),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Differential Equations',
                                  hintStyle:
                                      const TextStyle(color: Colors.black38),
                                  filled: true,
                                  fillColor: const Color(0xFFF5F5F5),
                                  contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                        color: AppColors.primary, width: 1.5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 46,
                              width: 46,
                              child: ElevatedButton(
                                onPressed: _addTopic,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Icon(Icons.add, size: 22),
                              ),
                            ),
                          ],
                        ),

                        // Topic chips
                        if (_topics.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: _topics
                                .asMap()
                                .entries
                                .map((entry) => _topicChip(
                                    entry.key + 1, entry.value))
                                .toList(),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // ── Save button ──────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _save,
                            icon: _isSaving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Icon(Icons.cloud_upload_rounded),
                            label: Text(
                              _isSaving ? 'Saving...' : 'Save Subject',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── Difficulty segmented selector ─────────────────────────────────
  Widget _difficultySelector() {
    const levels = ['Easy', 'Medium', 'Hard'];
    const colors = [Colors.green, Colors.orange, Colors.red];
    return Row(
      children: List.generate(levels.length, (i) {
        final selected = _difficulty == levels[i];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _difficulty = levels[i]),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? colors[i].withValues(alpha: 0.15)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? colors[i] : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    i == 0
                        ? Icons.sentiment_satisfied_alt
                        : i == 1
                            ? Icons.sentiment_neutral
                            : Icons.local_fire_department,
                    color: selected ? colors[i] : Colors.grey.shade400,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    levels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selected ? colors[i] : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Topic chip ────────────────────────────────────────────────────
  Widget _topicChip(int index, String topic) {
    return Chip(
      backgroundColor: AppColors.primary.withValues(alpha: 0.08),
      side: BorderSide(
          color: AppColors.primary.withValues(alpha: 0.3), width: 1),
      label: Text(
        '$index. $topic',
        style: const TextStyle(
            fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
      ),
      deleteIcon: const Icon(Icons.close, size: 14, color: AppColors.primary),
      onDeleted: () => _removeTopic(topic),
      visualDensity: VisualDensity.compact,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────
  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: Colors.black87,
        ),
      );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    TextCapitalization capitalize = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      textCapitalization: capitalize,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.black38),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _timePicker({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool selected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(12),
        border: selected
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.5))
            : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: selected ? Colors.black87 : Colors.black38,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
