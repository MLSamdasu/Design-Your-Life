// F6: 백업/복원 결과 SnackBar 헬퍼
// BackupResult 상태에 따라 적절한 성공/오류 SnackBar를 표시한다
import 'package:flutter/material.dart';

import '../../../../core/backup/backup_service.dart';
import '../../../../shared/widgets/app_snack_bar.dart';

/// 백업/복원 결과에 따라 SnackBar를 표시한다
/// [isRestore]가 true이면 복원 성공 메시지를 표시한다
void showBackupResultSnackBar(
  BuildContext context,
  BackupResult result, {
  bool isRestore = false,
}) {
  switch (result.status) {
    case BackupResultStatus.success:
      final message = isRestore ? '복원이 완료되었습니다' : '백업이 완료되었습니다';
      AppSnackBar.showSuccess(context, message);
      break;
    case BackupResultStatus.unauthenticated:
      AppSnackBar.showError(context, '로그인이 필요합니다');
      break;
    case BackupResultStatus.error:
      AppSnackBar.showError(
        context,
        result.errorMessage ?? '오류가 발생했습니다',
      );
      break;
  }
}
