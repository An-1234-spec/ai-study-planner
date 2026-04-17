import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/study_provider.dart';
import '../utils/colors.dart';
import '../widgets/subject_card.dart';
import '../widgets/task_tile.dart';
import 'add_subject.dart';
import 'add_task.dart';
import 'timetable_screen.dart';
import 'progress_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, StudyProvider>(
      builder: (context, auth, study, _) {
        return Scaffold(
          floatingActionButton: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FloatingActionButton(
                heroTag: 'task',
                backgroundColor: Colors.orange,
                tooltip: 'Add Task',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddTaskScreen()),
                ),
                child: const Icon(Icons.task_alt, color: Colors.white),
              ),
              const SizedBox(height: 12),
              FloatingActionButton(
                heroTag: 'subject',
                backgroundColor: AppColors.primary,
                tooltip: 'Add Subject',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddSubjectScreen()),
                ),
                child: const Icon(Icons.add, color: Colors.white),
              ),
            ],
          ),
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
                children: [
                  // ── Header ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor:
                              Colors.white.withValues(alpha: 0.25),
                          child: Text(
                            auth.displayName.isNotEmpty
                                ? auth.displayName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hello, ${auth.displayName} 👋',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Dashboard 📚',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        // Logout
                        IconButton(
                          icon: const Icon(Icons.logout_rounded,
                              color: Colors.white70),
                          tooltip: 'Logout',
                          onPressed: () async {
                            await auth.signOut();
                            if (context.mounted) {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LoginScreen()),
                                (_) => false,
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Stats row ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        _statChip(
                          icon: Icons.menu_book_rounded,
                          label: '${study.subjects.length}',
                          sub: 'Subjects',
                          color: Colors.blue.shade300,
                        ),
                        const SizedBox(width: 10),
                        _statChip(
                          icon: Icons.task_alt,
                          label:
                              '${study.completedHoursFormatted}/${study.totalHoursFormatted}',
                          sub: 'Hours Done',
                          color: Colors.green.shade300,
                        ),
                        const SizedBox(width: 10),
                        _statChip(
                          icon: Icons.trending_up,
                          label: '${(study.progress * 100).toInt()}%',
                          sub: 'Progress',
                          color: Colors.orange.shade300,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ── Main scrollable body ──────────────────────────
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(28),
                          topRight: Radius.circular(28),
                        ),
                      ),
                      child: ListView(
                        children: [
                          // ── Skip-day warning ─────────────────────
                          if (study.skippedDay) ...[
                            _SkipDayBanner(study: study),
                            const SizedBox(height: 16),
                          ],

                          // ── Motivational tip ──────────────────────
                          if (study.timetable.isNotEmpty) ...[
                            _TipCard(tip: study.todaysTip),
                            const SizedBox(height: 16),
                          ],

                          // ── Upcoming exams ────────────────────────
                          if (study.upcomingSubjects.isNotEmpty) ...[
                            _sectionTitle('🔔 Upcoming Exams'),
                            const SizedBox(height: 8),
                            ...study.upcomingSubjects.take(3).map((s) {
                              final date =
                                  DateTime.tryParse(s['date'] ?? '');
                              final daysLeft = date != null
                                  ? date
                                      .difference(DateTime.now())
                                      .inDays
                                  : 0;
                              return _deadlineBanner(
                                  s['name'], daysLeft, s['difficulty']);
                            }),
                            const SizedBox(height: 20),
                          ],

                          // ── Subjects ──────────────────────────────
                          _sectionTitle('📚 Your Subjects'),
                          const SizedBox(height: 10),
                          study.subjects.isEmpty
                              ? _emptyHint(
                                  'No subjects yet.\nTap ➕ to add one.')
                              : Column(
                                  children: study.subjects.map((s) {
                                    return Dismissible(
                                      key: Key('sub_${s['id']}'),
                                      direction:
                                          DismissDirection.endToStart,
                                      background: _deleteBackground(),
                                      onDismissed: (_) => context
                                          .read<StudyProvider>()
                                          .deleteSubject(s['id']),
                                      child: SubjectCard(
                                        title: s['name'] ?? '',
                                        hours: s['hours'] ?? '0',
                                        date: s['date'],
                                        priority: s['priority'] ?? 'Medium',
                                      ),
                                    );
                                  }).toList(),
                                ),

                          const SizedBox(height: 20),

                          // ── Tasks ─────────────────────────────────
                          _sectionTitle('📝 Your Tasks'),
                          const SizedBox(height: 10),
                          study.tasks.isEmpty
                              ? _emptyHint(
                                  'No tasks yet.\nTap the orange ➕ to add one.')
                              : Column(
                                  children: study.tasks.map((t) {
                                    return Dismissible(
                                      key: Key('task_${t['id']}'),
                                      direction:
                                          DismissDirection.endToStart,
                                      background: _deleteBackground(),
                                      onDismissed: (_) => context
                                          .read<StudyProvider>()
                                          .deleteTask(t['id']),
                                      child: TaskTile(
                                        task: t['task'] ?? '',
                                        subject: t['subject'] ?? '',
                                        hours: t['hours'] ?? '0',
                                        isDone: t['isDone'] ?? false,
                                        onToggle: (val) => context
                                            .read<StudyProvider>()
                                            .toggleTaskDone(
                                                t['id'], val ?? false),
                                      ),
                                    );
                                  }).toList(),
                                ),

                          const SizedBox(height: 24),

                          // ── Action buttons ────────────────────────
                          _actionButton(
                            context,
                            icon: Icons.auto_awesome,
                            label: 'Generate Study Plan',
                            color: AppColors.primary,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const TimetableScreen()),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _actionButton(
                            context,
                            icon: Icons.bar_chart_rounded,
                            label: 'View Progress',
                            color: const Color(0xFF764ba2),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProgressScreen()),
                            ),
                          ),

                          const SizedBox(height: 40),
                        ],
                      ),
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

  // ── Helpers ──────────────────────────────────────────────────────

  Widget _statChip({
    required IconData icon,
    required String label,
    required String sub,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            Text(
              sub,
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _deadlineBanner(
      String name, int daysLeft, String? difficulty) {
    final Color c = daysLeft <= 3
        ? Colors.red.shade400
        : daysLeft <= 7
            ? Colors.orange.shade400
            : Colors.green.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.event_busy_rounded, color: c, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                if (difficulty != null)
                  Text(difficulty,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(
            daysLeft <= 0 ? 'Today!' : '$daysLeft day${daysLeft == 1 ? '' : 's'} left',
            style: TextStyle(
                fontSize: 12, color: c, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
        ),
      );

  Widget _emptyHint(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, height: 1.6),
          ),
        ),
      );

  Widget _deleteBackground() => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      );

  Widget _actionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 15)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}

// ── Motivational tip card ────────────────────────────────────────────
class _TipCard extends StatelessWidget {
  final String tip;
  const _TipCard({required this.tip});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.08),
            AppColors.secondary.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Skip-day warning banner ──────────────────────────────────────────
class _SkipDayBanner extends StatelessWidget {
  final StudyProvider study;
  const _SkipDayBanner({required this.study});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              color: Colors.orange.shade600, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'You missed a study day!',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap "Generate Study Plan" to redistribute topics across remaining days.',
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => study.generateAndSavePlan(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('Fix',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
