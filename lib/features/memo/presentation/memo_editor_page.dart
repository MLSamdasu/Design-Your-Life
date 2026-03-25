// F-Memo: 메모 에디터 페이지 (모바일 전용)
// Navigator.push로 이동하는 전체 화면 에디터이다.
// AppBar에 뒤로 가기 + 저장 + 삭제 버튼을 포함한다.
// MemoEditorToolbar + MemoTextEditor (또는 MemoDrawingCanvas)를 결합한다.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../core/theme/typography_tokens.dart';
import '../models/memo.dart';
import '../models/stroke_data.dart';
import '../providers/memo_provider.dart';
import 'widgets/memo_delete_dialog.dart';
import 'widgets/memo_drawing_body.dart';
import 'widgets/memo_drawing_canvas.dart';
import 'widgets/memo_editor_toolbar.dart';
import 'widgets/memo_save_button.dart';
import 'widgets/memo_text_editor.dart';

/// 모바일 전체 화면 메모 에디터 페이지
/// MemoScreen에서 모바일 레이아웃일 때 push 네비게이션으로 열린다
class MemoEditorPage extends ConsumerStatefulWidget {
  /// 편집할 메모의 ID
  final String memoId;

  const MemoEditorPage({super.key, required this.memoId});

  @override
  ConsumerState<MemoEditorPage> createState() => _MemoEditorPageState();
}

class _MemoEditorPageState extends ConsumerState<MemoEditorPage> {
  /// 텍스트 에디터 접근 키 (즉시 저장 호출용)
  final _textEditorKey = GlobalKey<MemoTextEditorState>();

  /// 드로잉 캔버스 접근 키 (undo/clear 호출용)
  final _canvasKey = GlobalKey<MemoDrawingCanvasState>();

  /// 드로잉 모드 관련 상태
  int _selectedColorIndex = 0;
  int _selectedThicknessIndex = 0;
  bool _isEraser = false;

  /// 드로잉 스트로크 저장용 디바운스 타이머
  Timer? _strokeDebounce;

  @override
  void dispose() {
    _strokeDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = context.themeColors;
    final memos = ref.watch(memosProvider);
    final memo = memos.where((m) => m.id == widget.memoId).firstOrNull;

    if (memo == null) return _buildEmptyState(tc);

    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      appBar: _buildAppBar(tc, memo),
      body: Column(
        children: [
          // 에디터 툴바 (모드 전환 + 드로잉 도구)
          MemoEditorToolbar(
            currentType: memo.type,
            onTypeChanged: (type) => _onTypeChanged(memo, type),
            selectedColorIndex: _selectedColorIndex,
            onColorChanged: (i) => setState(() => _selectedColorIndex = i),
            selectedThicknessIndex: _selectedThicknessIndex,
            onThicknessChanged: (i) =>
                setState(() => _selectedThicknessIndex = i),
            isEraser: _isEraser,
            onEraserToggle: () => setState(() => _isEraser = !_isEraser),
            onUndo: memo.type == 'drawing'
                ? () => _canvasKey.currentState?.undoLastStroke()
                : null,
            onClear: memo.type == 'drawing'
                ? () => _canvasKey.currentState?.clearAllStrokes()
                : null,
          ),
          // 에디터 본체
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: _buildEditorBody(memo),
            ),
          ),
        ],
      ),
    );
  }

  /// 메모를 찾을 수 없을 때 빈 화면
  Widget _buildEmptyState(ResolvedThemeColors tc) {
    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      appBar: AppBar(
        backgroundColor: ColorTokens.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      body: Center(
        child: Text(
          '메모를 찾을 수 없습니다',
          style: AppTypography.bodyLg.copyWith(
            color: tc.textPrimaryWithAlpha(0.50),
          ),
        ),
      ),
    );
  }

  /// AppBar 구성 (뒤로 가기 + 저장 + 삭제)
  AppBar _buildAppBar(ResolvedThemeColors tc, Memo memo) {
    return AppBar(
      backgroundColor: ColorTokens.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: tc.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        memo.title.isEmpty ? '메모' : memo.title,
        style: AppTypography.titleMd.copyWith(color: tc.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        MemoSaveButton(onSave: () => _saveNow(memo)),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            color: ColorTokens.error,
            size: AppLayout.iconXl,
          ),
          onPressed: () => _deleteMemo(memo),
        ),
      ],
    );
  }

  /// 에디터 본체 (텍스트 또는 드로잉)
  Widget _buildEditorBody(Memo memo) {
    if (memo.type == 'drawing') {
      return buildMemoDrawingCanvas(
        canvasKey: _canvasKey,
        memo: memo,
        colorIndex: _selectedColorIndex,
        thicknessIndex: _selectedThicknessIndex,
        isEraser: _isEraser,
        onStrokesChanged: _onStrokesChanged,
      );
    }
    return MemoTextEditor(key: _textEditorKey, memo: memo);
  }

  /// 즉시 저장 (텍스트: 에디터에서 저장, 드로잉: 디바운스 취소)
  void _saveNow(Memo memo) {
    if (memo.type == 'text') {
      _textEditorKey.currentState?.cancelDebounceAndSave();
    } else {
      _strokeDebounce?.cancel();
    }
  }

  /// 드로잉 스트로크 변경 → 디바운스 후 Hive 저장
  void _onStrokesChanged(Memo memo, List<StrokeData> strokes) {
    _strokeDebounce = scheduleStrokeSave(
      currentTimer: _strokeDebounce,
      memo: memo,
      strokes: strokes,
      ref: ref,
    );
  }

  /// 메모 타입 변경 처리
  void _onTypeChanged(Memo memo, String type) {
    final update = ref.read(updateMemoProvider);
    update(memo.id, memo.copyWith(type: type, updatedAt: DateTime.now()));
  }

  /// 메모 삭제 확인 후 뒤로 이동
  Future<void> _deleteMemo(Memo memo) async {
    final confirmed = await showMemoDeleteDialog(context);
    if (confirmed && mounted) {
      ref.read(deleteMemoProvider)(memo.id);
      Navigator.pop(context);
    }
  }
}
