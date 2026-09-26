import '../models/milestone.dart';
import '../models/project.dart';

/// Seed data used so reviewers/testers can immediately explore the
/// milestone + payment workflow without first creating a project by hand.
Project buildDemoProject() {
  final now = DateTime.now();
  return Project(
    id: 'demo-project-1',
    name: 'Gwarinpa 3-Bedroom Bungalow',
    location: 'Gwarinpa, Abuja',
    totalBudgetNaira: 18500000,
    supervisorName: 'Engr. Musa Ibrahim',
    createdAt: now.subtract(const Duration(days: 40)),
    milestones: [
      Milestone(
        id: 'm1',
        projectId: 'demo-project-1',
        title: 'Foundation & Substructure',
        description: 'Excavation, foundation laying, and damp-proof course.',
        percentOfBudget: 25,
        status: MilestoneStatus.paid,
        verifiedAt: now.subtract(const Duration(days: 30)),
        paidAt: now.subtract(const Duration(days: 29)),
        progressEntries: [
          ProgressEntry(
            id: 'p1',
            milestoneId: 'm1',
            mediaPath: 'demo/foundation.jpg',
            capturedAt: now.subtract(const Duration(days: 31)),
            latitude: 9.1102,
            longitude: 7.4165,
          ),
        ],
      ),
      Milestone(
        id: 'm2',
        projectId: 'demo-project-1',
        title: 'Walling & Roofing',
        description: 'Block work to lintel level, roofing carcass and covering.',
        percentOfBudget: 35,
        status: MilestoneStatus.verified,
        verifiedAt: now.subtract(const Duration(days: 3)),
        progressEntries: [
          ProgressEntry(
            id: 'p2',
            milestoneId: 'm2',
            mediaPath: 'demo/walling.jpg',
            capturedAt: now.subtract(const Duration(days: 4)),
            latitude: 9.1105,
            longitude: 7.4169,
          ),
        ],
      ),
      const Milestone(
        id: 'm3',
        projectId: 'demo-project-1',
        title: 'Plumbing & Electrical',
        description: 'First-fix plumbing and electrical conduiting.',
        percentOfBudget: 20,
        status: MilestoneStatus.notStarted,
      ),
      const Milestone(
        id: 'm4',
        projectId: 'demo-project-1',
        title: 'Finishing',
        description: 'Plastering, painting, tiling, and fittings.',
        percentOfBudget: 20,
        status: MilestoneStatus.notStarted,
      ),
    ],
  );
}
