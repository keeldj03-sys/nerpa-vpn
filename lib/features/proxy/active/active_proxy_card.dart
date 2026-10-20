import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/features/proxy/active/ip_widget.dart';
import 'package:nerpa_vpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';

/// Строка активного сервера: флаг, название, IP, протокол.
///
/// Живёт в карточке на главной и работает даже без подключения: тогда показываются
/// название и протокол узла, выбранного в приложении (IP неизвестен, пока нет туннеля).
class ActiveServerInfoRow extends ConsumerWidget {
  const ActiveServerInfoRow({
    super.key,
    required this.name,
    required this.type,
    this.ip = '',
    this.countryCode = '',
    this.organization,
    this.onTap,
    this.onFlagTap,
    this.onIpLongPress,
  });

  /// Название узла.
  final String name;

  /// Протокол узла (vless, vmess, ...).
  final String type;

  /// IP выбранного сервера, если подключение активно.
  final String ip;

  /// Код страны для флага.
  final String countryCode;

  /// Провайдер для значка на флаге.
  final String? organization;

  final VoidCallback? onTap;
  final VoidCallback? onFlagTap;
  final VoidCallback? onIpLongPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(translationsProvider).requireValue;
    final hasName = name.trim().isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          // ── Country flag ──
          GestureDetector(
            onTap: onFlagTap,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF18181B).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3F3F46).withValues(alpha: 0.5)),
              ),
              child: Center(
                child: countryCode.isEmpty
                    ? const Icon(Icons.public_rounded, size: 20, color: AppTheme.nerpaTextMuted)
                    : IPCountryFlag(
                        countryCode: countryCode,
                        organization: organization,
                        size: 28,
                      ),
              ),
            ),
          ),

          const Gap(12),

          // ── Server name + IP ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasName ? name : 'Узел не выбран',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasName ? AppTheme.nerpaTextPrimary : AppTheme.nerpaTextMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Gap(3),
                if (ip.isNotEmpty)
                  IPText(ip: ip, onLongPress: onIpLongPress ?? () {}, constrained: true)
                else
                  UnknownIPText(text: t.pages.proxies.unknownIp, onTap: onIpLongPress ?? () {}, constrained: true),
              ],
            ),
          ),

          const Gap(8),

          // ── Protocol badge ──
          if (type.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.nerpaAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.nerpaAccent.withValues(alpha: 0.2)),
              ),
              child: Text(
                type,
                style: const TextStyle(
                  color: AppTheme.nerpaAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
            ),

          const Gap(8),

          // ── Change node ──
          // The chevron alone reads as "expand the list", but the tap opens
          // the node picker. The label says what the tap does.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.nerpaAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.nerpaAccent.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  t.pages.proxies.changeNode,
                  style: const TextStyle(
                    color: AppTheme.nerpaAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right_rounded, color: AppTheme.nerpaAccent, size: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String getRealOutboundTag(OutboundInfo group) {
  var tag = group.tagDisplay;
  if (group.groupSelectedTagDisplay != '' && group.groupSelectedTagDisplay != tag) {
    tag = '$tag → ${group.groupSelectedTagDisplay}';
  }
  return tag;
}
