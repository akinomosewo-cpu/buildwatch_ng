import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import '../../core/theme/app_theme.dart';
import '../../core/demo/demo_data.dart';
import '../blocs/app_bloc.dart';
import 'milestone_payment_page.dart';
import 'price_tracker_page.dart';
import 'paywall_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    context.read<AppBloc>().add(const AppStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<AppBloc, AppState>(
          builder: (context, state) {
            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true, snap: true,
                  backgroundColor: AppColors.background,
                  title: Row(children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.construction_rounded, color: Colors.white, size: 17),
                    ),
                    const Gap(10),
                    Text('BuildWatch NG', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.textPrimary)),
                  ]),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.warning),
                      tooltip: 'Upgrade',
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaywallPage())),
                    ),
                    IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () => _showAddSheet(context)),
                    const Gap(4),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(delegate: SliverChildListDelegate([
                    const Gap(8),
                    Row(children: [
                      Expanded(child: _StatCard(label: 'Projects', value: state is AppLoaded ? state.items.length.toString() : '0', color: AppColors.primary).animate(delay: 50.ms).fadeIn().slideY(begin: 0.1)),
                      const Gap(12),
                      Expanded(child: _StatCard(label: 'Milestones', value: state is AppLoaded ? state.items.where((i) => i['status'] == 'active').length.toString() : '0', color: AppColors.success).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1)),
                      const Gap(12),
                      Expanded(child: _StatCard(label: 'Alerts', value: state is AppLoaded ? state.items.where((i) => i['status'] == 'pending').length.toString() : '0', color: AppColors.warning).animate(delay: 150.ms).fadeIn().slideY(begin: 0.1)),
                    ]),
                    const Gap(24),
                    Text('What you can do', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary)),
                    const Gap(12),
                    _FeatureCard(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Track build remotely',
                      color: AppColors.primary,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => MilestonePaymentPage(project: buildDemoProject()))),
                    ).animate(delay: 200.ms).fadeIn().slideX(begin: -0.1),
                    const Gap(8),
                    _FeatureCard(
                      icon: Icons.bar_chart_rounded,
                      label: 'Geotagged check-ins',
                      color: AppColors.success,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => MilestonePaymentPage(project: buildDemoProject()))),
                    ).animate(delay: 250.ms).fadeIn().slideX(begin: -0.1),
                    const Gap(8),
                    _FeatureCard(
                      icon: Icons.send_rounded,
                      label: 'Live BOQ pricing',
                      color: AppColors.warning,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PriceTrackerPage())),
                    ).animate(delay: 300.ms).fadeIn().slideX(begin: -0.1),
                    const Gap(24),
                    Text('Recent Activity', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary)),
                    const Gap(12),
                    if (state is AppLoaded && state.items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
                        child: Column(children: [
                          Icon(Icons.construction_rounded, color: AppColors.textTertiary, size: 40),
                          const Gap(12),
                          Text('Nothing here yet', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                          const Gap(4),
                          Text('Tap + to get started', style: AppTextStyles.labelMedium.copyWith(color: AppColors.textTertiary)),
                        ]),
                      ).animate().fadeIn(delay: 350.ms),
                    if (state is AppLoaded)
                      ...state.items.asMap().entries.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ItemTile(
                          title: e.value['title'] ?? 'Item',
                          subtitle: e.value['subtitle'] ?? '',
                          status: e.value['status'] ?? 'active',
                          onDelete: () => context.read<AppBloc>().add(ItemDeleted(e.value['id'] ?? '')),
                        ).animate(delay: Duration(milliseconds: 50 * e.key)).fadeIn(),
                      )),
                    const Gap(32),
                  ])),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => BlocProvider.value(value: context.read<AppBloc>(), child: const _AddSheet()),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
    child: Column(children: [
      Text(value, style: AppTextStyles.displaySmall.copyWith(color: color, fontWeight: FontWeight.w800)),
      const Gap(2),
      Text(label, style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary), textAlign: TextAlign.center),
    ]),
  );
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const _FeatureCard({required this.icon, required this.label, required this.color, this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16)),
        const Gap(14),
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary))),
        const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 18),
      ]),
    ),
  );
}

class _ItemTile extends StatelessWidget {
  final String title, subtitle, status;
  final VoidCallback onDelete;
  const _ItemTile({required this.title, required this.subtitle, required this.status, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final statusColor = status == 'active' ? AppColors.success : status == 'pending' ? AppColors.warning : AppColors.textSecondary;
    return Dismissible(
      key: Key(title + DateTime.now().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary)),
            if (subtitle.isNotEmpty) Text(subtitle, style: AppTextStyles.labelMedium.copyWith(color: AppColors.textSecondary)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
            child: Text(status, style: AppTextStyles.labelSmall.copyWith(color: statusColor, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

class _AddSheet extends StatefulWidget {
  const _AddSheet();
  @override State<_AddSheet> createState() => _AddSheetState();
}

class _AddSheetState extends State<_AddSheet> {
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Add New', style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary)),
        const Gap(20),
        TextField(controller: _titleCtrl, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'Title / Name')),
        const Gap(12),
        TextField(controller: _subtitleCtrl, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary), decoration: const InputDecoration(hintText: 'Details')),
        const Gap(20),
        ElevatedButton(
          onPressed: () {
            if (_titleCtrl.text.isEmpty) return;
            context.read<AppBloc>().add(ItemAdded({
              'id': DateTime.now().millisecondsSinceEpoch.toString(),
              'title': _titleCtrl.text,
              'subtitle': _subtitleCtrl.text,
              'status': 'active',
            }));
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ]),
    );
  }
}
