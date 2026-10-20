import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/model/failures.dart';
import 'package:nerpa_vpn/core/router/dialog/dialog_notifier.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/profile/notifier/profiles_update_notifier.dart';
import 'package:nerpa_vpn/features/profile/overview/profiles_notifier.dart';
import 'package:nerpa_vpn/features/profile/widget/profile_tile.dart';
import 'package:nerpa_vpn/utils/utils.dart';

class ProfilesModal extends HookConsumerWidget {
  const ProfilesModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final asyncProfiles = ref.watch(profilesNotifierProvider);

    ref.listen(profilesNotifierProvider, (_, next) {
      if (next.hasValue && next.value!.isEmpty) {
        Navigator.of(context).maybePop();
      }
    });

    final initialSize = PlatformUtils.isDesktop ? .60 : .35;
    return SafeArea(
      child: asyncProfiles.when(
        data: (data) => DraggableScrollableSheet(
          initialChildSize: initialSize,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: const Color(0xFF101417),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: Column(
                children: [
                  const Gap(12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.pages.profiles.title,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppTheme.nerpaTextPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          '${data.length}',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.nerpaTextSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      separatorBuilder: (context, index) => const Gap(10),
                      controller: scrollController,
                      itemBuilder: (context, index) => ProfileTile(key: ValueKey(data[index].id), profile: data[index]),
                      itemCount: data.length,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.nerpaTextSecondary,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => ref.read(dialogNotifierProvider.notifier).showSortProfiles(),
                            child: Text(t.common.sort),
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF142228),
                              foregroundColor: AppTheme.nerpaTextPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: () => ref.read(foregroundProfilesUpdateNotifierProvider.notifier).trigger(),
                            child: Text(t.pages.profiles.updateSubscriptions),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.nerpaAccent)),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              t.presentShortError(error),
              style: const TextStyle(color: AppTheme.nerpaTextPrimary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
