import 'dart:math';
import '../models/material_price.dart';

/// Source of truth for material prices. Ships with a deterministic-ish mock
/// feed today; a real deployment swaps [fetchLatestPrices] for a call to a
/// live BOQ/market-price API (e.g. scraped Abuja building-materials market
/// data) without touching any UI code, since callers only depend on this
/// abstract contract.
abstract class MaterialPriceService {
  Future<List<MaterialPrice>> fetchLatestPrices();
}

/// Mock implementation used until a live price feed is wired up.
///
/// Base prices reflect approximate Abuja market rates as of 2025 and jitter
/// slightly on every call to simulate a live feed for demo/testing purposes.
class MockMaterialPriceService implements MaterialPriceService {
  final Random _random;

  MockMaterialPriceService({Random? random}) : _random = random ?? Random();

  static const Map<MaterialType, double> _basePrices = {
    MaterialType.cementBag50kg: 9500,
    MaterialType.ironRod12mm: 12500,
    MaterialType.ironRod16mm: 21000,
    MaterialType.sandTipper: 65000,
    MaterialType.blocks9inch: 650,
  };

  @override
  Future<List<MaterialPrice>> fetchLatestPrices() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final now = DateTime.now();
    return _basePrices.entries.map((entry) {
      final jitterPercent = (_random.nextDouble() * 6) - 3; // -3%..+3%
      final price = entry.value * (1 + jitterPercent / 100);
      return MaterialPrice(
        type: entry.key,
        nairaPrice: double.parse(price.toStringAsFixed(0)),
        asOf: now,
        changePercent: double.parse(jitterPercent.toStringAsFixed(2)),
      );
    }).toList();
  }
}
