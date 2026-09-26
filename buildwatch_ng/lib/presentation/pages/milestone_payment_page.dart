import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../core/logic/milestone_payment_engine.dart';
import '../../core/models/milestone.dart';
import '../../core/models/project.dart';
import '../../core/theme/app_theme.dart';
import 'capture_page.dart';
import 'timeline_page.dart';

/// Milestone tracking + payment release workflow for a single project.
///
/// Flow: supervisor captures proof in-app -> proof is "pending verification"
/// -> the diaspora sponsor reviews it here and marks it "verified" -> only
/// then does the "Release payment" action become available.
class MilestonePaymentPage extends StatefulWidget {
  final Project project;
  const MilestonePaymentPage({super.key, required this.project});

  @override
  State<MilestonePaymentPage> createState() => _MilestonePaymentPageState();
}

class _MilestonePaymentPageState extends State<MilestonePaymentPage> {
  static const _engine = MilestonePaymentEngine();
  late Project _project;
  final _currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _project = widget.project;
  }

  void _updateMilestone(Milestone updated) {
    setState(() {
      _project = _project.copyWith(
        milestones: _project.milestones.map((m) => m.id == updated.id ? updated : m).toList(),
      );
    });
  }

  Future<void> _capture(Milestone milestone) async {
    final entry = await Navigator.push<ProgressEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => CapturePage(milestoneId: milestone.id, milestoneTitle: milestone.title),
      ),
    );
    if (entry == null) return;
    _updateMilestone(milestone.copyWith(
      progressEntries: [...milestone.progressEntries, entry],
      status: MilestoneStatus.pendingVerification,
    ));
  }

  void _verify(Milestone milestone) {
    _updateMilestone(milestone.copyWith(status: MilestoneStatus.verified, verifiedAt: DateTime.now()));
  }

  void _release(Milestone milestone) {
    final decision = _engine.evaluateRelease(_project, milestone);
    if (!decision.canRelease) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(decision.reason)));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Release payment?'),
        content: Text(
          'Release ${_currency.format(decision.amountNaira)} to the site supervisor for "${milestone.title}"? This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final paid = _engine.release(_project, milestone);
              _updateMilestone(paid);
              Navigator.pop(context);
            },
            child: const Text('Release'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = _engine.projectProgressPercent(_project);
    final released = _engine.totalReleased(_project);
    final remaining = _engine.totalRemaining(_project);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(_project.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProgressCard(
            progress: progress,
            released: _currency.format(released),
            remaining: _currency.format(remaining),
          ),
          const Gap(28),
          Text('Milestones', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary)),
          const Gap(14),
          ..._project.milestones.map((m) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MilestoneCard(
                  milestone: m,
                  amount: _currency.format(_engine.amountForMilestone(_project, m)),
                  onCapture: () => _capture(m),
                  onVerify: () => _verify(m),
                  onRelease: () => _release(m),
                  onViewTimeline: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TimelinePage(title: m.title, entries: m.progressEntries),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final double progress;
  final String released;
  final String remaining;
  const _ProgressCard({required this.progress, required this.released, required this.remaining});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.28), blurRadius: 24, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Build Progress', style: AppTextStyles.labelMedium.copyWith(color: Colors.white70)),
          const Gap(6),
          Text('${progress.toStringAsFixed(0)}%',
              style: AppTextStyles.displayLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
          const Gap(14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const Gap(18),
          Row(
            children: [
              Expanded(
                child: _StatColumn(label: 'Released', value: released),
              ),
              Expanded(
                child: _StatColumn(label: 'Remaining', value: remaining),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;
  const _StatColumn({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: Colors.white70)),
          const Gap(2),
          Text(value, style: AppTextStyles.headlineLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w800)),
        ],
      );
}

class _MilestoneCard extends StatelessWidget {
  final Milestone milestone;
  final String amount;
  final VoidCallback onCapture;
  final VoidCallback onVerify;
  final VoidCallback onRelease;
  final VoidCallback onViewTimeline;

  const _MilestoneCard({
    required this.milestone,
    required this.amount,
    required this.onCapture,
    required this.onVerify,
    required this.onRelease,
    required this.onViewTimeline,
  });

  @override
  Widget build(BuildContext context) {
    final statusMeta = _statusMeta(milestone.status);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(milestone.title,
                    style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusMeta.color.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(statusMeta.label,
                    style: AppTextStyles.labelSmall.copyWith(color: statusMeta.color, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const Gap(4),
          Text(milestone.description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
          const Gap(8),
          Row(
            children: [
              Text('${milestone.percentOfBudget.toStringAsFixed(0)}% of budget',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary)),
              const Spacer(),
              Text(amount, style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary)),
            ],
          ),
          const Gap(12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onCapture,
                icon: const Icon(Icons.camera_alt_rounded, size: 16),
                label: const Text('Submit proof'),
              ),
              if (milestone.progressEntries.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: onViewTimeline,
                  icon: const Icon(Icons.timeline_rounded, size: 16),
                  label: Text('View (${milestone.progressEntries.length})'),
                ),
              if (milestone.status == MilestoneStatus.pendingVerification)
                ElevatedButton.icon(
                  onPressed: onVerify,
                  icon: const Icon(Icons.fact_check_rounded, size: 16),
                  label: const Text('Verify'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, minimumSize: const Size(0, 40)),
                ),
              if (milestone.status == MilestoneStatus.verified)
                ElevatedButton.icon(
                  onPressed: onRelease,
                  icon: const Icon(Icons.payments_rounded, size: 16),
                  label: const Text('Release payment'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                ),
              if (milestone.status == MilestoneStatus.paid)
                const Chip(
                  label: Text('Paid out'),
                  avatar: Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                ),
            ],
          ),
        ],
      ),
    );
  }

  _StatusMeta _statusMeta(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.notStarted:
        return _StatusMeta('Not started', AppColors.textSecondary);
      case MilestoneStatus.inProgress:
        return _StatusMeta('In progress', AppColors.warning);
      case MilestoneStatus.pendingVerification:
        return _StatusMeta('Pending review', AppColors.warning);
      case MilestoneStatus.verified:
        return _StatusMeta('Verified', AppColors.primary);
      case MilestoneStatus.paid:
        return _StatusMeta('Paid', AppColors.success);
      case MilestoneStatus.disputed:
        return _StatusMeta('Disputed', AppColors.danger);
    }
  }
}

class _StatusMeta {
  final String label;
  final Color color;
  const _StatusMeta(this.label, this.color);
}
