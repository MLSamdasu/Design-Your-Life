// F-Memo: 메모 텍스트 에디터 위젯
// 제목 TextField + 본문 TextField (멀티라인, 화면 채움).
// 500ms 디바운스로 updateMemoProvider를 통해 Hive에 자동 저장한다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../models/memo.dart';
import '../../providers/memo_provider.dart';

/// 자동 저장 디바운스 시간 (ms)
const _kAutoSaveDebounceMs = 500;

/// 메모 텍스트 에디터 위젯
/// 제목과 본문을 편집하며, 변경 시 디바운스로 자동 저장한다
class MemoTextEditor extends ConsumerStatefulWidget {
  /// 편집할 메모 객체
  final Memo memo;

  const MemoTextEditor({super.key, required this.memo});

  @override
  ConsumerState<MemoTextEditor> createState() => MemoTextEditorState();
}

class MemoTextEditorState extends ConsumerState<MemoTextEditor> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;

  /// 자동 저장용 디바운스 타이머
  Timer? _debounceTimer;

  /// 현재 편집 중인 메모 ID (메모 전환 시 컨트롤러를 교체하기 위함)
  String _currentMemoId = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.memo.title);
    _contentController = TextEditingController(text: widget.memo.content);
    _currentMemoId = widget.memo.id;
  }

  @override
  void didUpdateWidget(covariant MemoTextEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 메모가 변경되면 컨트롤러 텍스트를 교체한다
    if (widget.memo.id != _currentMemoId) {
      _debounceTimer?.cancel();
      _titleController.text = widget.memo.title;
      _contentController.text = widget.memo.content;
      _currentMemoId = widget.memo.id;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    // 타이머가 남아있으면 즉시 저장한다
    _saveNow();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// 디바운스 후 자동 저장 트리거
  void _scheduleAutoSave() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(
      const Duration(milliseconds: _kAutoSaveDebounceMs),
      _saveNow,
    );
  }

  /// 외부에서 호출 가능한 즉시 저장 메서드
  /// 디바운스 타이머를 취소하고 즉시 저장한다
  void cancelDebounceAndSave() {
    _debounceTimer?.cancel();
    _saveNow();
  }

  /// 현재 에디터 내용을 Hive에 즉시 저장한다
  void _saveNow() {
    final update = ref.read(updateMemoProvider);
    final updated = widget.memo.copyWith(
      title: _titleController.text,
      content: _contentController.text,
      updatedAt: DateTime.now(),
    );
    update(widget.memo.id, updated);
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;

    return Container(
      decoration: BoxDecoration(
        color: tc.overlayLight,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: tc.borderLight,
          width: AppLayout.borderThin,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 제목 입력 영역
          _buildTitleField(tc),
          // 구분선
          Divider(
            color: tc.dividerColor,
            height: AppLayout.dividerHeight,
            indent: AppSpacing.xl,
            endIndent: AppSpacing.xl,
          ),
          // 본문 입력 영역 (나머지 공간 채움)
          Expanded(child: _buildContentField(tc)),
        ],
      ),
    );
  }

  /// 제목 입력 필드
  Widget _buildTitleField(ResolvedThemeColors tc) {
    return TextField(
      controller: _titleController,
      onChanged: (_) => _scheduleAutoSave(),
      style: AppTypography.titleLg.copyWith(color: tc.textPrimary),
      cursorColor: tc.textPrimary,
      decoration: InputDecoration(
        hintText: '제목',
        hintStyle: AppTypography.titleLg.copyWith(color: tc.hintColor),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.md,
        ),
      ),
    );
  }

  /// 본문 입력 필드 (멀티라인, 화면 채움)
  Widget _buildContentField(ResolvedThemeColors tc) {
    return TextField(
      controller: _contentController,
      onChanged: (_) => _scheduleAutoSave(),
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: AppTypography.bodyLg.copyWith(
        color: tc.textPrimary,
        height: 1.7,
      ),
      cursorColor: tc.textPrimary,
      decoration: InputDecoration(
        hintText: '내용을 입력하세요...',
        hintStyle: AppTypography.bodyLg.copyWith(color: tc.hintColor),
        border: InputBorder.none,
        contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xxl,
          AppSpacing.lg,
          AppSpacing.xxl,
          AppSpacing.xxl,
        ),
      ),
    );
  }
}
