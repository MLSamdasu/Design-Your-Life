// F-Book: 수동 분배 유효성 검사 — 날짜별 한 칸 입력값의 정합성을 검증한다
import '../../../core/utils/date_utils.dart';

/// 수동 분배 행 하나의 유효성 검사 결과
class RowValidationError {
  final int rowIndex;
  final String message;
  const RowValidationError({required this.rowIndex, required this.message});
}

/// 수동 분배 폼 전체 유효성 검사 결과
class ManualPlanValidation {
  final List<RowValidationError> rowErrors;
  final List<String> summaryErrors;
  const ManualPlanValidation({
    this.rowErrors = const [], this.summaryErrors = const [],
  });
  bool get isValid => rowErrors.isEmpty && summaryErrors.isEmpty;
  List<String> errorsForRow(int index) =>
      rowErrors.where((e) => e.rowIndex == index).map((e) => e.message).toList();
}

/// 수동 분배 유효성 검사기
class ManualPlanValidator {
  /// 한 칸 범위 텍스트를 (startPage, endPage)로 파싱한다
  /// ","와 "/"를 구분자로 사용
  static (int?, int?)? parseRangeField(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    final parts = t.replaceAll('/', ',').split(',');
    if (parts.length == 1) {
      return (int.tryParse(parts[0].trim()), null);
    }
    if (parts.length >= 2) {
      final s = int.tryParse(parts[0].trim());
      final eText = parts[1].trim();
      return (s, eText.isEmpty ? null : int.tryParse(eText));
    }
    return null;
  }

  /// 페이지 모드 유효성 검사 (한 칸 입력 형식)
  static ManualPlanValidation validatePageModeSingleField({
    required List<String> rangeTexts,
    required List<bool> restDays,
    required int totalPages,
    required List<DateTime> dates,
  }) {
    final rowErr = <RowValidationError>[];
    final sumErr = <String>[];
    // 활성 행 필터링
    final active = <int>[
      for (var i = 0; i < dates.length; i++) if (!restDays[i]) i
    ];
    if (active.isEmpty) {
      sumErr.add('최소 하루는 읽기 일정이 있어야 합니다');
      return ManualPlanValidation(rowErrors: rowErr, summaryErrors: sumErr);
    }
    // 파싱 + 개별 행 검증
    final sMap = <int, int?>{};
    final eMap = <int, int?>{};
    for (final i in active) {
      final parsed = parseRangeField(rangeTexts[i]);
      if (parsed == null) {
        rowErr.add(RowValidationError(
            rowIndex: i, message: '형식: 시작,끝 (예: 1,20)'));
        continue;
      }
      final s = parsed.$1; final e = parsed.$2;
      sMap[i] = s; eMap[i] = e;
      if (s == null || s <= 0) {
        rowErr.add(RowValidationError(
            rowIndex: i, message: '시작 페이지를 입력해주세요'));
      }
      if (e == null || e <= 0) {
        rowErr.add(RowValidationError(
            rowIndex: i, message: '끝 페이지를 입력해주세요'));
      }
      if (s != null && e != null && s > 0 && e > 0 && e < s) {
        rowErr.add(RowValidationError(
            rowIndex: i,
            message: '끝 페이지($e)가 시작 페이지($s)보다 작습니다'));
      }
    }
    // 전체 검증은 모든 행이 채워진 경우만
    final allFilled = active.every((i) =>
        sMap[i] != null && eMap[i] != null &&
        sMap[i]! > 0 && eMap[i]! > 0);
    if (!allFilled) {
      return ManualPlanValidation(rowErrors: rowErr, summaryErrors: sumErr);
    }
    // 첫 페이지 == 1
    if (sMap[active.first] != 1) {
      rowErr.add(RowValidationError(
          rowIndex: active.first,
          message: '첫째 날 시작 페이지는 1이어야 합니다'));
      sumErr.add('첫째 날 시작 페이지가 1이 아닙니다');
    }
    // 마지막 페이지 == totalPages
    if (eMap[active.last] != totalPages) {
      rowErr.add(RowValidationError(rowIndex: active.last,
          message: '마지막 날 끝 페이지는 $totalPages이어야 합니다'));
      sumErr.add('마지막 날 끝 페이지(${eMap[active.last]})가 '
          '총 페이지($totalPages)와 다릅니다');
    }
    // 순서 + 중복 체크
    for (var idx = 1; idx < active.length; idx++) {
      final pI = active[idx - 1]; final cI = active[idx];
      final pEnd = eMap[pI]!; final cStart = sMap[cI]!;
      final pDate = AppDateUtils.toShortDate(dates[pI]);
      if (cStart < pEnd + 1) {
        rowErr.add(RowValidationError(rowIndex: cI,
            message: '$pDate 끝($pEnd)과 겹칩니다. '
                '시작은 ${pEnd + 1} 이상이어야 합니다'));
      } else if (cStart > pEnd + 1) {
        rowErr.add(RowValidationError(rowIndex: cI,
            message: '$pDate 끝($pEnd)과 이어지지 않습니다. '
                '시작이 ${pEnd + 1}이어야 합니다'));
      }
    }
    return ManualPlanValidation(rowErrors: rowErr, summaryErrors: sumErr);
  }

  /// 챕터 모드 유효성 검사
  static ManualPlanValidation validateChapterMode({
    required List<int?> chapters,
    required List<bool> restDays,
    required int totalChapters,
    required List<DateTime> dates,
  }) {
    final rowErr = <RowValidationError>[];
    final sumErr = <String>[];
    final active = <int>[
      for (var i = 0; i < dates.length; i++) if (!restDays[i]) i
    ];
    if (active.isEmpty) {
      sumErr.add('최소 하루는 읽기 일정이 있어야 합니다');
      return ManualPlanValidation(rowErrors: rowErr, summaryErrors: sumErr);
    }
    for (final i in active) {
      final ch = chapters[i];
      if (ch == null || ch <= 0) {
        rowErr.add(RowValidationError(
            rowIndex: i, message: '챕터 번호를 입력해주세요'));
      } else if (ch > totalChapters) {
        rowErr.add(RowValidationError(rowIndex: i,
            message: '챕터 번호($ch)가 총 챕터 수($totalChapters)를 초과합니다'));
      }
    }
    return ManualPlanValidation(rowErrors: rowErr, summaryErrors: sumErr);
  }
}
