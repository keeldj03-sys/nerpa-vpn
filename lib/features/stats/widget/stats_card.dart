import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:nerpa_vpn/core/theme/app_theme.dart';
import 'package:nerpa_vpn/core/widget/spaced_list_widget.dart';

typedef PresentableStat = ({Widget label, Widget data, String? semanticLabel});

/// Nerpa VPN — Stats Card
/// Dark themed card with rows of label → value pairs
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    this.title,
    this.titleStyle,
    this.padding = const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
    this.labelStyle,
    this.dataStyle,
    required this.stats,
  });

  final String? title;
  final TextStyle? titleStyle;
  final EdgeInsets padding;
  final TextStyle? labelStyle;
  final TextStyle? dataStyle;
  final List<PresentableStat> stats;

  @override
  Widget build(BuildContext context) {
    const labelColor = AppTheme.nerpaTextMuted;
    const dataColor = AppTheme.nerpaTextSecondary;

    final effectiveTitleStyle = titleStyle ??
        const TextStyle(
          color: AppTheme.nerpaTextMuted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
        );
    final effectiveLabelStyle = labelStyle ??
        const TextStyle(
          color: labelColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        );
    final effectiveDataStyle = dataStyle ??
        const TextStyle(
          color: dataColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF121215),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.nerpaBorder.withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title!.toUpperCase(),
                style: effectiveTitleStyle,
              ),
              const Gap(10),
            ],
            ...stats
                .map((stat) {
                  Widget label = IconTheme.merge(
                    data: IconThemeData(size: 14, color: labelColor),
                    child: DefaultTextStyle(
                      style: effectiveLabelStyle,
                      overflow: TextOverflow.ellipsis,
                      child: stat.label,
                    ),
                  );
                  if (stat.semanticLabel != null) {
                    label = Tooltip(message: stat.semanticLabel, verticalOffset: 8, child: label);
                  }
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      label,
                      const Gap(8),
                      DefaultTextStyle(
                        style: effectiveDataStyle,
                        overflow: TextOverflow.ellipsis,
                        child: stat.data,
                      ),
                    ],
                  );
                })
                .toList()
                .spaceBy(height: 8),
          ],
        ),
      ),
    );
  }
}
