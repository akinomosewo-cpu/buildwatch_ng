import 'package:equatable/equatable.dart';

enum MaterialType { cementBag50kg, ironRod12mm, ironRod16mm, sandTipper, blocks9inch }

extension MaterialTypeLabel on MaterialType {
  String get label {
    switch (this) {
      case MaterialType.cementBag50kg:
        return 'Cement (50kg bag)';
      case MaterialType.ironRod12mm:
        return 'Iron Rod (12mm)';
      case MaterialType.ironRod16mm:
        return 'Iron Rod (16mm)';
      case MaterialType.sandTipper:
        return 'Sharp Sand (tipper)';
      case MaterialType.blocks9inch:
        return 'Blocks (9-inch)';
    }
  }

  String get unit {
    switch (this) {
      case MaterialType.cementBag50kg:
        return 'per bag';
      case MaterialType.ironRod12mm:
      case MaterialType.ironRod16mm:
        return 'per rod';
      case MaterialType.sandTipper:
        return 'per trip';
      case MaterialType.blocks9inch:
        return 'per block';
    }
  }
}

/// A single price observation for a building material in the Abuja market.
class MaterialPrice extends Equatable {
  final MaterialType type;
  final double nairaPrice;
  final DateTime asOf;
  final double changePercent;

  const MaterialPrice({
    required this.type,
    required this.nairaPrice,
    required this.asOf,
    this.changePercent = 0,
  });

  @override
  List<Object?> get props => [type, nairaPrice, asOf, changePercent];
}
