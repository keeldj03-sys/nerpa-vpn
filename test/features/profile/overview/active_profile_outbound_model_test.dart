import 'package:flutter_test/flutter_test.dart';
import 'package:nerpa_vpn/features/profile/overview/active_profile_outbound_model.dart';
import 'package:nerpa_vpn/hiddifycore/generated/v2/hcore/hcore.pb.dart';

OutboundInfo _node(
  String tag, {
  bool isGroup = false,
  bool isSelected = false,
  String? tagDisplay,
  int delay = 0,
}) {
  return OutboundInfo(
    tag: tag,
    type: 'vless',
    isGroup: isGroup,
    isSelected: isSelected,
    tagDisplay: tagDisplay,
    urlTestDelay: delay,
  );
}

void main() {
  group('flattenActiveProfileOutbounds', () {
    test('берёт группу select, даже если она не первая', () {
      final groups = [
        OutboundGroup(
          tag: 'balance',
          type: 'urltest',
          selectable: false,
          selected: 'node-1',
          items: [_node('node-1')],
        ),
        OutboundGroup(
          tag: 'select',
          type: 'selector',
          selectable: true,
          selected: 'node-2',
          items: [_node('node-1'), _node('node-2')],
        ),
      ];

      final result = flattenActiveProfileOutbounds(groups);

      expect(result.map((item) => item.tag), ['node-1', 'node-2']);
      expect(result.every((item) => item.groupTag == 'select'), isTrue);
    });

    test('пропускает ссылки на группы и дедуплицирует по тегу', () {
      final groups = [
        OutboundGroup(
          tag: 'select',
          type: 'selector',
          selectable: true,
          selected: 'node-1',
          items: [
            _node('group-link', isGroup: true),
            _node('node-1'),
            _node('node-1'),
          ],
        ),
      ];

      final result = flattenActiveProfileOutbounds(groups);

      expect(result.map((item) => item.tag), ['node-1']);
    });

    test('помечает выбранным узел из group.selected', () {
      final groups = [
        OutboundGroup(
          tag: 'select',
          type: 'selector',
          selectable: true,
          selected: 'node-2',
          items: [
            _node('node-1'),
            _node('node-2', isSelected: true),
          ],
        ),
      ];

      final result = flattenActiveProfileOutbounds(groups);

      expect(result.where((item) => item.isSelected).map((item) => item.tag), ['node-2']);
    });

    test('без группы select берёт первую selectable-группу', () {
      final groups = [
        OutboundGroup(
          tag: 'balance',
          type: 'urltest',
          selectable: false,
          items: [_node('node-1')],
        ),
        OutboundGroup(
          tag: 'other',
          type: 'selector',
          selectable: true,
          items: [_node('node-2')],
        ),
      ];

      final result = flattenActiveProfileOutbounds(groups);

      expect(result.map((item) => item.tag), ['node-2']);
      expect(result.first.groupTag, 'other');
    });

    test('без selectable-групп список пуст', () {
      final groups = [
        OutboundGroup(
          tag: 'balance',
          type: 'urltest',
          selectable: false,
          items: [_node('node-1')],
        ),
      ];

      expect(flattenActiveProfileOutbounds(groups), isEmpty);
    });

    test('displayName берётся из tagDisplay, иначе из tag', () {
      final groups = [
        OutboundGroup(
          tag: 'select',
          type: 'selector',
          selectable: true,
          items: [
            _node('node-1', tagDisplay: 'Node One'),
            _node('node-2'),
          ],
        ),
      ];

      final result = flattenActiveProfileOutbounds(groups);

      expect(result[0].displayName, 'Node One');
      expect(result[1].displayName, 'node-2');
    });

    test('задержка и тип прокидываются в модель', () {
      final groups = [
        OutboundGroup(
          tag: 'select',
          type: 'selector',
          selectable: true,
          items: [_node('node-1', delay: 120)],
        ),
      ];

      final result = flattenActiveProfileOutbounds(groups);

      expect(result.single.delayMs, 120);
      expect(result.single.type, 'vless');
    });
  });

  group('parseProfileConfigOutbounds', () {
    const config = '''
{
  "outbounds": [
    {"type": "selector", "tag": "select", "outbounds": ["lowest", "balance", "🇺🇸 USA 01", "🇩🇪 Germany 02"], "default": "🇩🇪 Germany 02"},
    {"type": "urltest", "tag": "lowest", "outbounds": ["🇺🇸 USA 01"]},
    {"type": "urltest", "tag": "balance", "outbounds": ["🇺🇸 USA 01"]},
    {"type": "vless", "tag": "🇺🇸 USA 01"},
    {"type": "vmess", "tag": "🇩🇪 Germany 02"},
    {"type": "direct", "tag": "direct §hide§"},
    {"type": "direct", "tag": "bypass §hide§"}
  ]
}
''';

    test('берёт порядок и выбор из группы select', () {
      final result = parseProfileConfigOutbounds(config);

      expect(result.map((item) => item.tag), ['🇺🇸 USA 01', '🇩🇪 Germany 02']);
      expect(result.map((item) => item.type), ['vless', 'vmess']);
      expect(result.every((item) => item.groupTag == 'select'), isTrue);
      expect(result.where((item) => item.isSelected).map((item) => item.tag), ['🇩🇪 Germany 02']);
    });

    test("пропускает служебные и скрытые outbound'ы", () {
      final result = parseProfileConfigOutbounds(config);

      expect(result.any((item) => item.tag.contains('§hide§')), isFalse);
      expect(result.any((item) => item.type == 'selector' || item.type == 'urltest'), isFalse);
      expect(result.any((item) => item.type == 'direct'), isFalse);
    });

    test('битый json даёт пустой список', () {
      expect(parseProfileConfigOutbounds('not a json'), isEmpty);
      expect(parseProfileConfigOutbounds('{}'), isEmpty);
      expect(parseProfileConfigOutbounds('{"outbounds": 5}'), isEmpty);
    });
  });

  group('trimTagDisplay', () {
    test("отрезает всё после § и trim'ит пробелы", () {
      expect(trimTagDisplay('🇺🇸 USA 01'), '🇺🇸 USA 01');
      expect(trimTagDisplay('direct §hide§'), 'direct');
      expect(trimTagDisplay('Node § 1'), 'Node');
    });
  });
}
