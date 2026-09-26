import 'package:equatable/equatable.dart';

/// Lifecycle of a single construction milestone.
enum MilestoneStatus {
  notStarted,
  inProgress,
  pendingVerification,
  verified,
  paid,
  disputed,
}

/// A geotagged, timestamped piece of proof submitted by the site supervisor.
///
/// Every [ProgressEntry] MUST originate from the in-app camera capture flow —
/// there is no gallery-import path anywhere in the app — so [capturedAt] and
/// [latitude]/[longitude] can be trusted as evidence of real, on-site work.
class ProgressEntry extends Equatable {
  final String id;
  final String milestoneId;
  final String mediaPath;
  final bool isVideo;
  final DateTime capturedAt;
  final double latitude;
  final double longitude;
  final String? note;

  const ProgressEntry({
    required this.id,
    required this.milestoneId,
    required this.mediaPath,
    required this.capturedAt,
    required this.latitude,
    required this.longitude,
    this.isVideo = false,
    this.note,
  });

  @override
  List<Object?> get props =>
      [id, milestoneId, mediaPath, isVideo, capturedAt, latitude, longitude, note];
}

/// A single funded stage of a project (e.g. "Foundation", "Roofing").
///
/// [percentOfBudget] is this milestone's share (0-100) of the parent
/// project's total budget, and drives how much money is released to the
/// contractor once the milestone is verified.
class Milestone extends Equatable {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final double percentOfBudget;
  final MilestoneStatus status;
  final List<ProgressEntry> progressEntries;
  final DateTime? verifiedAt;
  final DateTime? paidAt;

  const Milestone({
    required this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.percentOfBudget,
    this.status = MilestoneStatus.notStarted,
    this.progressEntries = const [],
    this.verifiedAt,
    this.paidAt,
  });

  Milestone copyWith({
    String? title,
    String? description,
    double? percentOfBudget,
    MilestoneStatus? status,
    List<ProgressEntry>? progressEntries,
    DateTime? verifiedAt,
    DateTime? paidAt,
  }) {
    return Milestone(
      id: id,
      projectId: projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      percentOfBudget: percentOfBudget ?? this.percentOfBudget,
      status: status ?? this.status,
      progressEntries: progressEntries ?? this.progressEntries,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }

  bool get hasProof => progressEntries.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        projectId,
        title,
        description,
        percentOfBudget,
        status,
        progressEntries,
        verifiedAt,
        paidAt,
      ];
}
