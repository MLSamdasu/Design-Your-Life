// 캘린더 유틸리티: 이벤트 편집 다이얼로그 호출 패턴
// 월간/주간/일간 뷰에서 공통으로 사용하는 이벤트 편집 다이얼로그 호출 로직을 통합한다.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../shared/models/event.dart';
import '../widgets/event_create_dialog.dart';

/// 이벤트 편집 다이얼로그를 표시하고, 저장 시 이벤트 목록을 갱신한다
/// 이벤트 CRUD가 eventDataVersionProvider를 증가시키므로 별도 invalidate가 불필요하다
/// [context] 현재 빌드 컨텍스트
/// [ref] Riverpod WidgetRef (Provider 갱신용)
/// [event] 편집할 이벤트 (Event 모델)
void showEventEditDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Event event,
}) {
  showDialog<bool>(
    context: context,
    barrierColor: ColorTokens.barrierBase.withValues(alpha: 0.50),
    builder: (context) => EventCreateDialog(
      editEventId: event.id,
      editEvent: event,
      initialDate: event.startDate,
    ),
  );
}
