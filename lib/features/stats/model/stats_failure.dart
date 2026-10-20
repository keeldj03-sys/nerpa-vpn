import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:nerpa_vpn/core/localization/translations.dart';
import 'package:nerpa_vpn/core/model/failures.dart';

part 'stats_failure.freezed.dart';

@freezed
sealed class StatsFailure with _$StatsFailure, Failure {
  const StatsFailure._();

  @With<UnexpectedFailure>()
  const factory StatsFailure.unexpected([Object? error, StackTrace? stackTrace]) = StatsUnexpectedFailure;

  @override
  ({String type, String? message}) present(TranslationsEn t) {
    return switch (this) {
      StatsUnexpectedFailure() => (type: t.errors.unexpected, message: null),
    };
  }
}
