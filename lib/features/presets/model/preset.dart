import 'package:nerpa_vpn/hiddifycore/generated/v2/config/route_rule.pb.dart';

/// A routing preset: a named bundle of [Rule]s that can be applied
/// in one tap, similar to v2RayTun's preset system.
class Preset {
  const Preset({
    required this.id,
    required this.name,
    required this.description,
    required this.rules,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String description;
  final List<PresetRule> rules;
  final bool isCustom;

  factory Preset.fromJson(Map<String, dynamic> json) {
    return Preset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isCustom: json['isCustom'] as bool? ?? false,
      rules: (json['rules'] as List<dynamic>? ?? const [])
          .map((e) => PresetRule.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'isCustom': isCustom,
        'rules': rules.map((e) => e.toJson()).toList(),
      };
}

/// JSON representation of a routing [Rule]. Mirrors the protobuf fields
/// used by [Rule] (sing-box rule format) so presets stay interoperable
/// with the rules notifier import/export format.
class PresetRule {
  const PresetRule({
    required this.name,
    this.outbound = 'proxy',
    this.enabled = true,
    this.ruleSets = const [],
    this.domains = const [],
    this.domainSuffix = const [],
    this.domainKeyword = const [],
    this.ipCidrs = const [],
    this.portRanges = const [],
    this.network,
    this.protocols = const [],
    this.processNames = const [],
  });

  final String name;
  final String outbound;
  final bool enabled;
  final List<String> ruleSets;
  final List<String> domains;
  final List<String> domainSuffix;
  final List<String> domainKeyword;
  final List<String> ipCidrs;
  final List<String> portRanges;
  final String? network;
  final List<String> protocols;
  final List<String> processNames;

  factory PresetRule.fromJson(Map<String, dynamic> json) {
    List<String> asList(String key) =>
        ((json[key] as List<dynamic>?) ?? const []).cast<String>().where((e) => e.isNotEmpty).toList();
    return PresetRule(
      name: json['name'] as String? ?? '',
      outbound: json['outbound'] as String? ?? 'proxy',
      enabled: json['enabled'] as bool? ?? true,
      ruleSets: asList('ruleSets'),
      domains: asList('domains'),
      domainSuffix: asList('domainSuffix'),
      domainKeyword: asList('domainKeyword'),
      ipCidrs: asList('ipCidrs'),
      portRanges: asList('portRanges'),
      network: json['network'] as String?,
      protocols: asList('protocols'),
      processNames: asList('processNames'),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'outbound': outbound,
        'enabled': enabled,
        'ruleSets': ruleSets,
        'domains': domains,
        'domainSuffix': domainSuffix,
        'domainKeyword': domainKeyword,
        'ipCidrs': ipCidrs,
        'portRanges': portRanges,
        'network': network,
        'protocols': protocols,
        'processNames': processNames,
      };

  Rule toRule() {
    final rule = Rule.new(
      enabled: enabled,
      name: name,
      outbound: _parseOutbound(outbound),
      ruleSets: ruleSets,
      domains: domains,
      domainSuffixes: domainSuffix,
      domainKeywords: domainKeyword,
      ipCidrs: ipCidrs,
      portRanges: portRanges,
      processNames: processNames,
    );
    if (network != null) rule.network = _parseNetwork(network!);
    return rule;
  }

  static Outbound _parseOutbound(String value) {
    switch (value) {
      case 'direct':
        return Outbound.direct;
      case 'direct_with_fragment':
        return Outbound.direct_with_fragment;
      case 'block':
        return Outbound.block;
      case 'proxy':
      default:
        return Outbound.proxy;
    }
  }

  static Network _parseNetwork(String value) {
    switch (value) {
      case 'tcp':
        return Network.tcp;
      case 'udp':
        return Network.udp;
      default:
        return Network.tcp;
    }
  }
}
