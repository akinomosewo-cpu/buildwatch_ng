import '../models/milestone.dart';
import '../models/project.dart';

/// Result of asking whether a milestone payment can be released.
class ReleaseDecision {
  final bool canRelease;
  final String reason;
  final double amountNaira;

  const ReleaseDecision({
    required this.canRelease,
    required this.reason,
    required this.amountNaira,
  });
}

/// Pure, side-effect-free business logic for milestone verification and
/// milestone payment release. Kept independent of Flutter/UI/state
/// management so it is trivial to unit test and to later move behind an
/// escrow or payment-provider API.
class MilestonePaymentEngine {
  const MilestonePaymentEngine();

  /// Naira amount this milestone represents out of the project's total
  /// budget, based on [Milestone.percentOfBudget].
  double amountForMilestone(Project project, Milestone milestone) {
    return project.totalBudgetNaira * (milestone.percentOfBudget / 100);
  }

  /// Overall project completion, 0-100, weighted by each milestone's share
  /// of the budget (not just a simple count of milestones).
  double projectProgressPercent(Project project) {
    if (project.milestones.isEmpty) return 0;
    final completed = project.milestones.where(
      (m) => m.status == MilestoneStatus.verified || m.status == MilestoneStatus.paid,
    );
    final completedShare = completed.fold<double>(0, (sum, m) => sum + m.percentOfBudget);
    final totalShare = project.milestones.fold<double>(0, (sum, m) => sum + m.percentOfBudget);
    if (totalShare <= 0) return 0;
    return ((completedShare / totalShare) * 100).clamp(0, 100);
  }

  /// Decides whether a milestone's funds may be released to the site
  /// supervisor/contractor.
  ///
  /// Rules (in order):
  /// 1. A milestone that has already been paid can never be paid again.
  /// 2. There must be at least one in-app-captured [ProgressEntry] as proof.
  /// 3. The milestone must be in [MilestoneStatus.verified] — i.e. a human
  ///    reviewer (the diaspora sponsor, or their delegate) has approved the
  ///    submitted geotagged proof. Submitting proof alone is not enough.
  /// 4. The milestone's percentage of budget must be a sane value (0, 100].
  ReleaseDecision evaluateRelease(Project project, Milestone milestone) {
    final amount = amountForMilestone(project, milestone);

    if (milestone.status == MilestoneStatus.paid) {
      return ReleaseDecision(
        canRelease: false,
        reason: 'This milestone has already been paid out.',
        amountNaira: amount,
      );
    }
    if (milestone.percentOfBudget <= 0 || milestone.percentOfBudget > 100) {
      return ReleaseDecision(
        canRelease: false,
        reason: 'Milestone budget share is invalid.',
        amountNaira: 0,
      );
    }
    if (!milestone.hasProof) {
      return ReleaseDecision(
        canRelease: false,
        reason: 'No geotagged progress photo/video has been submitted yet.',
        amountNaira: amount,
      );
    }
    if (milestone.status != MilestoneStatus.verified) {
      return ReleaseDecision(
        canRelease: false,
        reason: 'Progress proof is awaiting your verification.',
        amountNaira: amount,
      );
    }
    return ReleaseDecision(
      canRelease: true,
      reason: 'Verified — ready to release funds.',
      amountNaira: amount,
    );
  }

  /// Applies a release, returning the updated milestone with status `paid`.
  /// Throws a [StateError] if [evaluateRelease] would refuse the release —
  /// callers should check [evaluateRelease] first to show the reason in UI.
  Milestone release(Project project, Milestone milestone, {DateTime? at}) {
    final decision = evaluateRelease(project, milestone);
    if (!decision.canRelease) {
      throw StateError('Cannot release payment: ${decision.reason}');
    }
    return milestone.copyWith(status: MilestoneStatus.paid, paidAt: at ?? DateTime.now());
  }

  /// Sum of naira already released (paid) across the whole project.
  double totalReleased(Project project) {
    return project.milestones
        .where((m) => m.status == MilestoneStatus.paid)
        .fold<double>(0, (sum, m) => sum + amountForMilestone(project, m));
  }

  /// Sum of naira still held back, awaiting future milestones.
  double totalRemaining(Project project) {
    return project.totalBudgetNaira - totalReleased(project);
  }

  /// True once a submitted proof is eligible for a human to verify (i.e. it
  /// actually has in-app-captured evidence attached).
  bool isReadyForVerification(Milestone milestone) {
    return milestone.hasProof &&
        (milestone.status == MilestoneStatus.inProgress ||
            milestone.status == MilestoneStatus.pendingVerification);
  }
}
