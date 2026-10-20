import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/model/failures.dart';
import 'package:nerpa_vpn/core/notification/in_app_notification_controller.dart';
import 'package:nerpa_vpn/core/router/bottom_sheets/bottom_sheets_notifier.dart';
import 'package:nerpa_vpn/core/router/dialog/dialog_notifier.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/profile/import/v2raytun_import_service.dart';
import 'package:nerpa_vpn/features/profile/model/profile_entity.dart';
import 'package:nerpa_vpn/features/profile/notifier/active_profile_notifier.dart';
import 'package:nerpa_vpn/features/profile/notifier/profiles_update_notifier.dart';
import 'package:nerpa_vpn/features/profile/overview/profiles_notifier.dart';
import 'package:nerpa_vpn/features/profile/widget/profile_tile.dart';

class ProfilesPage extends HookConsumerWidget {
  const ProfilesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final asyncProfiles = ref.watch(profilesNotifierProvider);

    ref.listen(hasAnyProfileProvider, (_, next) {
      if (next.valueOrNull == false) {
        context.goNamed('home');
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0A0D10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0D10),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          t.pages.profiles.title,
          style: const TextStyle(color: AppTheme.nerpaTextPrimary, fontWeight: FontWeight.w700, letterSpacing: 0.2),
        ),
        actions: [
          _HeaderAction(
            label: t.pages.profiles.updateSubscriptions,
            onPressed: () => ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger(),
          ),
          const Gap(4),
          IconButton(
            tooltip: t.pages.profiles.importV2raytun,
            icon: const Icon(Icons.download_rounded, color: AppTheme.nerpaTextSecondary, size: 20),
            onPressed: () => _importFromV2RayTun(context, ref),
          ),
          const Gap(8),
          _HeaderAction(
            label: t.common.sort,
            onPressed: () => ref.read(dialogNotifierProvider.notifier).showSortProfiles(),
          ),
          const Gap(16),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF12181C),
        foregroundColor: AppTheme.nerpaTextPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppTheme.nerpaAccent.withValues(alpha: 0.18)),
        ),
        onPressed: () async => await ref.read(bottomSheetsNotifierProvider.notifier).showAddProfile(),
        label: Text(t.pages.profiles.add, style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.2)),
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(color: Color(0xFF0A0D10)),
        child: asyncProfiles.when(
          data: (data) => _ProfilesLoadedState(data: data),
          loading: () => const _ProfilesLoadingState(),
          error: (error, stackTrace) => _ProfilesErrorState(message: t.presentShortError(error)),
        ),
      ),
    );
  }

  Future<void> _importFromV2RayTun(BuildContext context, WidgetRef ref) async {
    final t = ref.read(translationsProvider).requireValue;
    final notifications = ref.read(inAppNotificationControllerProvider);
    final service = ref.read(v2raytunImportServiceProvider);

    if (service.preferencesFile() == null) {
      notifications.showErrorToast(t.pages.profiles.msg.importV2raytun.notFound);
      return;
    }

    notifications.showInfoToast(t.pages.profiles.msg.importV2raytun.started);
    final result = await service.import();
    if (!context.mounted) return;
    if (result.imported > 0) {
      notifications.showSuccessToast(
        t.pages.profiles.msg.importV2raytun.success(count: result.imported),
      );
    } else {
      notifications.showErrorToast(t.pages.profiles.msg.importV2raytun.failure);
    }
    ref.invalidate(profilesNotifierProvider);
  }
}

class _ProfilesLoadedState extends ConsumerWidget {
  const _ProfilesLoadedState({required this.data});

  final List<ProfileEntity> data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${data.length} ${data.length == 1 ? 'profile' : 'profiles'}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppTheme.nerpaTextSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (data.isEmpty)
                const SliverFillRemaining(hasScrollBody: false, child: _ProfilesEmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  sliver: SliverList.separated(
                    itemCount: data.length,
                    itemBuilder: (context, index) => ProfileTile(profile: data[index], showActiveOutbounds: true),
                    separatorBuilder: (context, index) => const Gap(10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilesLoadingState extends StatelessWidget {
  const _ProfilesLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(color: AppTheme.nerpaAccent, strokeWidth: 2.4),
      ),
    );
  }
}

class _ProfilesEmptyState extends StatelessWidget {
  const _ProfilesEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF11161A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Профили пока не добавлены',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.nerpaTextPrimary,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                'Импортируйте подписку или локальный конфиг, чтобы собрать рабочий набор профилей.',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppTheme.nerpaTextSecondary, height: 1.45),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilesErrorState extends StatelessWidget {
  const _ProfilesErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 560),
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF151114),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.nerpaError.withValues(alpha: 0.26)),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.nerpaTextPrimary, height: 1.45, fontWeight: FontWeight.w500),
          ),
        ),
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppTheme.nerpaTextSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}
