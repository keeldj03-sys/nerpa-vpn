import 'package:nerpa_vpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';

class ProxyOverviewItem {
  const ProxyOverviewItem({required this.groupTag, required this.outbound, required this.isSelected});

  final String groupTag;
  final OutboundInfo outbound;
  final bool isSelected;
}
