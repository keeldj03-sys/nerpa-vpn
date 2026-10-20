import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nerpa_vpn/core/router/go_router/helper/active_breakpoint_notifier.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class FixBtn extends ConsumerWidget {
  const FixBtn({super.key, required this.height, required this.title, required this.icon, required this.onTap});

  final double height;
  final String title;
  final IconData icon;
  final GestureTapCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isMobile = Breakpoint(context).isMobile();
    final borderRadius = BorderRadius.circular(isMobile ? 14 : 12);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius,
        child: Container(
          alignment: Alignment.center,
          height: height,
          constraints: const BoxConstraints(minHeight: 44),
          padding: EdgeInsets.symmetric(vertical: isMobile ? 8 : 6, horizontal: 4),
          decoration: BoxDecoration(
            color: AppTheme.nerpaSurface.withOpacity(0.92),
            borderRadius: borderRadius,
            border: Border.all(color: AppTheme.nerpaBorder.withOpacity(0.7)),
            boxShadow: [BoxShadow(color: AppTheme.nerpaAccent.withOpacity(0.04), blurRadius: 14)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 6),
                decoration: BoxDecoration(
                  color: AppTheme.nerpaAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(isMobile ? 12 : 8),
                ),
                child: Icon(icon, size: isMobile ? 25 : 24, color: AppTheme.nerpaAccent),
              ),
              Gap(isMobile ? 4 : 6),
              Text(
                title,
                style: isMobile
                    ? theme.textTheme.titleSmall!.copyWith(
                        color: AppTheme.nerpaTextPrimary,
                        fontWeight: FontWeight.w600,
                      )
                    : theme.textTheme.labelLarge!.copyWith(
                        color: AppTheme.nerpaTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
