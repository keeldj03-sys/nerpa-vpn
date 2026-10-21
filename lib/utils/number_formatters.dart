import 'package:humanizer/humanizer.dart';

extension ByteFormatter on int {
  String size() => bytes().toString();

  static final _sizeOfFormat = InformationSizeFormat(permissibleValueUnits: {InformationUnit.gibibyte});

  String sizeGB() => _sizeOfFormat.format(bytes());

  String sizeOf(int total) => "${_sizeOfFormat.format(bytes())} / ${_sizeOfFormat.format(total.bytes())}";

  bool isInfinitSize() => bytes().terabytes.toDouble() > 10;

  static final _rateFormat = InformationRateFormat(
    // The rate unit is the period (per second) and the value unit is the
    // size (bytes). Without both, humanizer picks the unit from the value
    // alone and prints "30KiB/min" for 512 bytes per second.
    permissibleValueUnits: {InformationUnit.byte, InformationUnit.kibibyte, InformationUnit.mebibyte, InformationUnit.gibibyte},
    permissibleRateUnits: {RateUnit.second},
  );

  String speed() => _rateFormat.format(bytes().per(const Duration(seconds: 1)));
}
