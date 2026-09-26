import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../core/models/material_price.dart';
import '../../core/services/material_price_service.dart';
import '../../core/theme/app_theme.dart';

/// Live(ish) cement/iron-rod/materials price tracker for the Abuja market,
/// used to keep a diaspora sponsor's budget assumptions realistic.
///
/// Backed by [MaterialPriceService] so the mock feed used today can be
/// swapped for a real market-data API later with no UI changes.
class PriceTrackerPage extends StatefulWidget {
  final MaterialPriceService? service;
  const PriceTrackerPage({super.key, this.service});

  @override
  State<PriceTrackerPage> createState() => _PriceTrackerPageState();
}

class _PriceTrackerPageState extends State<PriceTrackerPage> {
  late final MaterialPriceService _service;
  late Future<List<MaterialPrice>> _future;
  final _currency = NumberFormat.currency(locale: 'en_NG', symbol: '₦', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? MockMaterialPriceService();
    _future = _service.fetchLatestPrices();
  }

  void _refresh() {
    setState(() => _future = _service.fetchLatestPrices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Material Prices — Abuja'),
        actions: [IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh_rounded))],
      ),
      body: FutureBuilder<List<MaterialPrice>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Could not load prices: ${snapshot.error}',
                  style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
            );
          }
          final prices = snapshot.data ?? [];
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text('Updated ${prices.isNotEmpty ? DateFormat('HH:mm:ss').format(prices.first.asOf) : '—'}',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary)),
                const Gap(16),
                ...prices.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PriceRow(price: p, currency: _currency),
                    )),
                const Gap(8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.textTertiary, size: 16),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          'Prices are indicative Abuja market rates and may vary by supplier and location. Live pricing feed coming soon.',
                          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final MaterialPrice price;
  final NumberFormat currency;
  const _PriceRow({required this.price, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isUp = price.changePercent >= 0;
    final changeColor = isUp ? AppColors.danger : AppColors.success;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(price.type.label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
                Text(price.type.unit, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(currency.format(price.nairaPrice),
                  style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary)),
              Row(
                children: [
                  Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, size: 12, color: changeColor),
                  Text('${price.changePercent.abs().toStringAsFixed(1)}%',
                      style: AppTextStyles.labelSmall.copyWith(color: changeColor)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
