import 'package:flutter_test/flutter_test.dart';
import 'package:buildwatch_ng/core/logic/milestone_payment_engine.dart';
import 'package:buildwatch_ng/core/models/milestone.dart';
import 'package:buildwatch_ng/core/models/project.dart';

void main() {
  const engine = MilestonePaymentEngine();

  Project projectWith(List<Milestone> milestones, {double budget = 1000000}) {
    return Project(
      id: 'p1',
      name: 'Test Project',
      location: 'Abuja',
      totalBudgetNaira: budget,
      supervisorName: 'Supervisor',
      createdAt: DateTime(2025, 1, 1),
      milestones: milestones,
    );
  }

  ProgressEntry proof(String milestoneId) => ProgressEntry(
        id: 'e1',
        milestoneId: milestoneId,
        mediaPath: '/tmp/photo.jpg',
        capturedAt: DateTime(2025, 1, 2),
        latitude: 9.05,
        longitude: 7.49,
      );

  group('amountForMilestone', () {
    test('computes naira amount as a share of total budget', () {
      final m = const Milestone(
        id: 'm1',
        projectId: 'p1',
        title: 'Foundation',
        description: '',
        percentOfBudget: 25,
      );
      final project = projectWith([m], budget: 2000000);
      expect(engine.amountForMilestone(project, m), 500000);
    });
  });

  group('projectProgressPercent', () {
    test('is 0 for a project with no milestones', () {
      expect(engine.projectProgressPercent(projectWith([])), 0);
    });

    test('weights progress by budget share, not milestone count', () {
      final milestones = [
        const Milestone(
          id: 'm1', projectId: 'p1', title: 'Foundation', description: '',
          percentOfBudget: 70, status: MilestoneStatus.paid,
        ),
        const Milestone(
          id: 'm2', projectId: 'p1', title: 'Finishing', description: '',
          percentOfBudget: 30, status: MilestoneStatus.notStarted,
        ),
      ];
      final project = projectWith(milestones);
      expect(engine.projectProgressPercent(project), 70);
    });

    test('counts both verified and paid milestones as complete', () {
      final milestones = [
        const Milestone(
          id: 'm1', projectId: 'p1', title: 'A', description: '',
          percentOfBudget: 50, status: MilestoneStatus.verified,
        ),
        const Milestone(
          id: 'm2', projectId: 'p1', title: 'B', description: '',
          percentOfBudget: 50, status: MilestoneStatus.paid,
        ),
      ];
      expect(engine.projectProgressPercent(projectWith(milestones)), 100);
    });
  });

  group('evaluateRelease', () {
    test('refuses release with no submitted proof', () {
      final m = const Milestone(
        id: 'm1', projectId: 'p1', title: 'Foundation', description: '',
        percentOfBudget: 25,
      );
      final decision = engine.evaluateRelease(projectWith([m]), m);
      expect(decision.canRelease, isFalse);
      expect(decision.reason, contains('No geotagged'));
    });

    test('refuses release when proof exists but is not yet verified', () {
      final m = Milestone(
        id: 'm1', projectId: 'p1', title: 'Foundation', description: '',
        percentOfBudget: 25, status: MilestoneStatus.pendingVerification,
        progressEntries: [proof('m1')],
      );
      final decision = engine.evaluateRelease(projectWith([m]), m);
      expect(decision.canRelease, isFalse);
      expect(decision.reason, contains('awaiting'));
    });

    test('allows release once proof exists and milestone is verified', () {
      final m = Milestone(
        id: 'm1', projectId: 'p1', title: 'Foundation', description: '',
        percentOfBudget: 25, status: MilestoneStatus.verified,
        progressEntries: [proof('m1')],
      );
      final project = projectWith([m], budget: 4000000);
      final decision = engine.evaluateRelease(project, m);
      expect(decision.canRelease, isTrue);
      expect(decision.amountNaira, 1000000);
    });

    test('refuses to release a milestone that was already paid', () {
      final m = Milestone(
        id: 'm1', projectId: 'p1', title: 'Foundation', description: '',
        percentOfBudget: 25, status: MilestoneStatus.paid,
        progressEntries: [proof('m1')],
      );
      final decision = engine.evaluateRelease(projectWith([m]), m);
      expect(decision.canRelease, isFalse);
      expect(decision.reason, contains('already been paid'));
    });

    test('refuses an invalid (zero) budget share', () {
      final m = Milestone(
        id: 'm1', projectId: 'p1', title: 'Foundation', description: '',
        percentOfBudget: 0, status: MilestoneStatus.verified,
        progressEntries: [proof('m1')],
      );
      final decision = engine.evaluateRelease(projectWith([m]), m);
      expect(decision.canRelease, isFalse);
      expect(decision.amountNaira, 0);
    });
  });

  group('release', () {
    test('marks a verified milestone as paid', () {
      final m = Milestone(
        id: 'm1', projectId: 'p1', title: 'Foundation', description: '',
        percentOfBudget: 25, status: MilestoneStatus.verified,
        progressEntries: [proof('m1')],
      );
      final project = projectWith([m]);
      final paid = engine.release(project, m, at: DateTime(2025, 2, 1));
      expect(paid.status, MilestoneStatus.paid);
      expect(paid.paidAt, DateTime(2025, 2, 1));
    });

    test('throws when release is not allowed', () {
      final m = const Milestone(
        id: 'm1', projectId: 'p1', title: 'Foundation', description: '',
        percentOfBudget: 25,
      );
      final project = projectWith([m]);
      expect(() => engine.release(project, m), throwsStateError);
    });
  });

  group('totals', () {
    test('totalReleased sums only paid milestones and totalRemaining is the complement', () {
      final milestones = [
        const Milestone(
          id: 'm1', projectId: 'p1', title: 'A', description: '',
          percentOfBudget: 40, status: MilestoneStatus.paid,
        ),
        const Milestone(
          id: 'm2', projectId: 'p1', title: 'B', description: '',
          percentOfBudget: 60, status: MilestoneStatus.notStarted,
        ),
      ];
      final project = projectWith(milestones, budget: 1000000);
      expect(engine.totalReleased(project), 400000);
      expect(engine.totalRemaining(project), 600000);
    });
  });

  group('isReadyForVerification', () {
    test('is false without proof', () {
      const m = Milestone(
        id: 'm1', projectId: 'p1', title: 'A', description: '',
        percentOfBudget: 10, status: MilestoneStatus.inProgress,
      );
      expect(engine.isReadyForVerification(m), isFalse);
    });

    test('is true once proof is attached and awaiting review', () {
      final m = Milestone(
        id: 'm1', projectId: 'p1', title: 'A', description: '',
        percentOfBudget: 10, status: MilestoneStatus.pendingVerification,
        progressEntries: [proof('m1')],
      );
      expect(engine.isReadyForVerification(m), isTrue);
    });
  });
}
