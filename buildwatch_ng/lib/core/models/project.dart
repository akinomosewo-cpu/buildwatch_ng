import 'package:equatable/equatable.dart';
import 'milestone.dart';

/// A house/build being funded remotely, usually by a diaspora sponsor.
class Project extends Equatable {
  final String id;
  final String name;
  final String location;
  final double totalBudgetNaira;
  final String supervisorName;
  final List<Milestone> milestones;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.name,
    required this.location,
    required this.totalBudgetNaira,
    required this.supervisorName,
    required this.createdAt,
    this.milestones = const [],
  });

  Project copyWith({
    String? name,
    String? location,
    double? totalBudgetNaira,
    String? supervisorName,
    List<Milestone>? milestones,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      location: location ?? this.location,
      totalBudgetNaira: totalBudgetNaira ?? this.totalBudgetNaira,
      supervisorName: supervisorName ?? this.supervisorName,
      createdAt: createdAt,
      milestones: milestones ?? this.milestones,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, location, totalBudgetNaira, supervisorName, milestones, createdAt];
}
