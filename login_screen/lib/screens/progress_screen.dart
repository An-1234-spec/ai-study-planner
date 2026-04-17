import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../utils/colors.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StudyProvider>(
      builder: (context, study, _) {
        final double progress = study.progress;
        final int pct = (progress * 100).toInt();
        final double doneHrs = study.completedHours;
        final double totalHrs = study.totalHours;
        final double pendingHrs = totalHrs - doneHrs;
        final Map<String, Map<String, double>> subjectProgress = study.perSubjectHoursProgress;

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
                  // ── AppBar ──────────────────────────────────────
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
                          'Your Progress 📊',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        // ── Overall circular progress ─────────────
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _CircularProgress(percent: pct),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  _statBlock(
                                    icon: Icons.check_circle_rounded,
                                    label: '${doneHrs.toStringAsFixed(1)}h',
                                    sub: 'Done',
                                    color: Colors.green.shade500,
                                  ),
                                  _divider(),
                                  _statBlock(
                                    icon: Icons.radio_button_unchecked,
                                    label: '${pendingHrs.toStringAsFixed(1)}h',
                                    sub: 'Pending',
                                    color: Colors.orange.shade500,
                                  ),
                                  _divider(),
                                  _statBlock(
                                    icon: Icons.list_alt_rounded,
                                    label: '${totalHrs.toStringAsFixed(1)}h',
                                    sub: 'Total Hours',
                                    color: AppColors.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(
                                    pct >= 80
                                        ? Colors.green.shade500
                                        : pct >= 50
                                            ? Colors.orange.shade500
                                            : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '$pct% of study hours completed',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Per-subject topic progress ─────────────
                        if (study.subjects.isNotEmpty) ...[
                          const Text(
                            '📚 Subject-wise Study Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...study.subjects.map((s) {
                            final String sid = s['id'] ?? s['name'];
                            final Map<String, double> hourData =
                                subjectProgress[sid] ?? {'progress': 0.0, 'done': 0.0, 'total': 0.0};
                            final double pctVal = hourData['progress'] ?? 0.0;
                            final double hrsDone = hourData['done'] ?? 0.0;
                            final double hrsTotal = hourData['total'] ?? 0.0;
                            final List topics =
                                s['topics'] ?? [];
                            final List doneTops =
                                s['completedTopics'] ?? [];
                            final DateTime? exam =
                                DateTime.tryParse(s['date'] ?? '');
                            final int daysLeft = exam != null
                                ? exam
                                    .difference(DateTime.now())
                                    .inDays
                                : -1;
                            final String diff =
                                s['difficulty'] ?? 'Medium';

                            return _SubjectProgressCard(
                              subject: s,
                              daysLeft: daysLeft,
                              hoursDone: hrsDone,
                              hoursTotal: hrsTotal,
                              topicsDone: doneTops.length,
                              topicsTotal: topics.length,
                              pct: pctVal,
                              difficulty: diff,
                              study: study,
                            );
                          }),
                          const SizedBox(height: 20),
                        ],

                        // ── Task checklist ────────────────────────
                        const Text(
                          '✅ Task Checklist',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        study.tasks.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Text('No tasks added yet.',
                                      style: TextStyle(
                                          color: Colors.white70)),
                                ),
                              )
                            : Column(
                                children: study.tasks.map((t) {
                                  final bool isDone =
                                      t['isDone'] ?? false;
                                  return _taskRow(
                                    context: context,
                                    task: t['task'] ?? '',
                                    subject: t['subject'] ?? '',
                                    hours: t['hours'] ?? '0',
                                    isDone: isDone,
                                    onTap: () => context
                                        .read<StudyProvider>()
                                        .toggleTaskDone(
                                            t['id'], !isDone),
                                  );
                                }).toList(),
                              ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _taskRow({
    required BuildContext context,
    required String task,
    required String subject,
    required String hours,
    required bool isDone,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDone ? Colors.green.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                isDone ? Colors.green.shade300 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isDone
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                key: ValueKey(isDone),
                color: isDone
                    ? Colors.green.shade500
                    : Colors.grey.shade400,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: isDone
                          ? Colors.grey.shade400
                          : Colors.black87,
                      decoration: isDone
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  Text(
                    '$subject • $hours hrs',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
            if (isDone)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Done ✓',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _statBlock({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87)),
        Text(sub,
            style:
                TextStyle(fontSize: 12, color: Colors.grey.shade500)),
      ],
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 40,
        color: Colors.grey.shade200,
      );
}

// ── Per-subject progress card ───────────────────────────────────────
class _SubjectProgressCard extends StatefulWidget {
  final Map<String, dynamic> subject;
  final int daysLeft;
  final double hoursDone;
  final double hoursTotal;
  final int topicsDone;
  final int topicsTotal;
  final double pct;
  final String difficulty;
  final StudyProvider study;

  const _SubjectProgressCard({
    required this.subject,
    required this.daysLeft,
    required this.hoursDone,
    required this.hoursTotal,
    required this.topicsDone,
    required this.topicsTotal,
    required this.pct,
    required this.difficulty,
    required this.study,
  });

  @override
  State<_SubjectProgressCard> createState() =>
      _SubjectProgressCardState();
}

class _SubjectProgressCardState extends State<_SubjectProgressCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final Color diffColor = widget.difficulty == 'Hard'
        ? Colors.red.shade400
        : widget.difficulty == 'Easy'
            ? Colors.green.shade400
            : Colors.orange.shade400;

    final List<String> topics =
        List<String>.from(widget.subject['topics'] ?? []);
    final List<String> done =
        List<String>.from(widget.subject['completedTopics'] ?? []);
    final String sid = widget.subject['id'] ?? widget.subject['name'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Card header ──────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  // Mini ring
                  _MiniRing(
                      pct: widget.pct,
                      size: 46,
                      color: widget.pct >= 0.8
                          ? Colors.green.shade500
                          : widget.pct >= 0.5
                              ? Colors.orange.shade400
                              : AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.subject['name'] ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.black87),
                              ),
                            ),
                            // Difficulty badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: diffColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color:
                                        diffColor.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                widget.difficulty,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: diffColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: widget.pct,
                            minHeight: 5,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.pct >= 0.8
                                  ? Colors.green.shade500
                                  : widget.pct >= 0.5
                                      ? Colors.orange.shade400
                                      : AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Text(
                              '${widget.hoursDone.toStringAsFixed(1)}/${widget.hoursTotal.toStringAsFixed(1)} hrs',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade600),
                            ),
                            if (topics.isNotEmpty) ...[
                              Text(
                                '  •  ${widget.topicsDone}/${widget.topicsTotal} topics',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                            const Spacer(),
                            if (widget.daysLeft >= 0)
                              Text(
                                widget.daysLeft == 0
                                    ? '🔴 Exam today!'
                                    : '${widget.daysLeft} day${widget.daysLeft == 1 ? '' : 's'} left',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: widget.daysLeft <= 3
                                      ? Colors.red.shade400
                                      : widget.daysLeft <= 7
                                          ? Colors.orange.shade500
                                          : Colors.green.shade600,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable topic list ─────────────────────────────────
          if (_expanded && topics.isNotEmpty) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: topics.asMap().entries.map((entry) {
                  final int idx = entry.key;
                  final String topic = entry.value;
                  final bool isDone = done.contains(topic);

                  return GestureDetector(
                    onTap: () {
                      if (isDone) {
                        widget.study.unmarkTopicDone(sid, topic);
                      } else {
                        widget.study.markTopicDone(sid, topic);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.green.shade50
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDone
                              ? Colors.green.shade300
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${idx + 1}.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              topic,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: isDone
                                    ? Colors.grey.shade400
                                    : Colors.black87,
                                decoration: isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                          ),
                          Icon(
                            isDone
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: isDone
                                ? Colors.green.shade500
                                : Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

          if (_expanded && topics.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'No topics added for this subject.',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade400),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Mini ring chart ─────────────────────────────────────────────────
class _MiniRing extends StatelessWidget {
  final double pct;
  final double size;
  final Color color;

  const _MiniRing({
    required this.pct,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: pct,
              strokeWidth: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            '${(pct * 100).toInt()}%',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated circular progress indicator with percentage text.
class _CircularProgress extends StatefulWidget {
  final int percent;
  const _CircularProgress({required this.percent});

  @override
  State<_CircularProgress> createState() => _CircularProgressState();
}

class _CircularProgressState extends State<_CircularProgress>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = Tween<double>(begin: 0, end: widget.percent / 100)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color color = widget.percent >= 80
        ? Colors.green.shade500
        : widget.percent >= 50
            ? Colors.orange.shade500
            : AppColors.primary;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: _anim.value,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(_anim.value * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Text(
                    'Complete',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}