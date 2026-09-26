import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';

class SubscriptionPlan {
  final String id;
  final String name;
  final double monthlyUsd;
  final List<String> perks;
  final bool highlighted;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.monthlyUsd,
    required this.perks,
    this.highlighted = false,
  });
}

const kSubscriptionPlans = [
  SubscriptionPlan(
    id: 'starter',
    name: 'Starter',
    monthlyUsd: 15,
    perks: ['1 active project', 'Weekly progress digest', 'Material price tracker'],
  ),
  SubscriptionPlan(
    id: 'family',
    name: 'Family Build',
    monthlyUsd: 25,
    perks: ['Up to 3 projects', 'Milestone payment workflow', 'Priority support'],
    highlighted: true,
  ),
  SubscriptionPlan(
    id: 'pro',
    name: 'Diaspora Pro',
    monthlyUsd: 40,
    perks: ['Unlimited projects', 'Multiple supervisors', 'Export reports for family'],
  ),
];

/// Subscription paywall stub. No real payment provider is wired up yet —
/// selecting a plan simulates a purchase so the upgrade flow can be
/// demoed/tested end-to-end before billing integration lands.
class PaywallPage extends StatefulWidget {
  const PaywallPage({super.key});

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  String _selectedId = kSubscriptionPlans[1].id;
  bool _purchasing = false;

  Future<void> _subscribe() async {
    setState(() => _purchasing = true);
    await Future.delayed(const Duration(milliseconds: 900)); // simulated purchase call
    if (!mounted) return;
    setState(() => _purchasing = false);
    final plan = kSubscriptionPlans.firstWhere((p) => p.id == _selectedId);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Subscribed'),
        content: Text('You are now on the ${plan.name} plan (\$${plan.monthlyUsd.toStringAsFixed(0)}/month).'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Upgrade')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Keep every build fully monitored',
              style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary)),
          const Gap(6),
          Text(
            'Choose a plan to unlock milestone payments, verified proof review, and live material prices for your project.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
          const Gap(20),
          ...kSubscriptionPlans.map((plan) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _PlanCard(
                  plan: plan,
                  selected: _selectedId == plan.id,
                  onTap: () => setState(() => _selectedId = plan.id),
                ),
              )),
          const Gap(12),
          ElevatedButton(
            onPressed: _purchasing ? null : _subscribe,
            child: _purchasing
                ? const SizedBox(
                    height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Subscribe'),
          ),
          const Gap(8),
          Center(
            child: Text('Cancel anytime. Billed monthly in USD.',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textTertiary)),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final SubscriptionPlan plan;
  final bool selected;
  final VoidCallback onTap;
  const _PlanCard({required this.plan, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(plan.name, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary)),
                      if (plan.highlighted) ...[
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.16), borderRadius: BorderRadius.circular(6)),
                          child: Text('POPULAR',
                              style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                        ),
                      ],
                    ],
                  ),
                ),
                Text('\$${plan.monthlyUsd.toStringAsFixed(0)}/mo',
                    style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary)),
              ],
            ),
            const Gap(10),
            ...plan.perks.map((perk) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                      const Gap(8),
                      Expanded(child: Text(perk, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
