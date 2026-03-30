// F-Memo: 메모 에디터 페이지 (모바일 전용 전체 화면)
// AppBar(뒤로 가기+저장+삭제) + MemoEditorToolbar + MemoTextEditor/DrawingCanvas
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ad_provider.dart';
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
class MemoEditorPage extends ConsumerStatefulWidget {
  final String memoId;

  const MemoEditorPage({super.key, required this.memoId});

  @override
  ConsumerState<MemoEditorPage> createState() => _MemoEditorPageState();
}

class _MemoEditorPageState extends ConsumerState<MemoEditorPage> {
  final _textEditorKey = GlobalKey<MemoTextEditorState>();
  final _canvasKey = GlobalKey<MemoDrawingCanvasState>();

  int _selectedColorIndex = 0;
  int _selectedThicknessIndex = 0;
  bool _isEraser = false;

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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // 뒤로 가기 시 저장 → 전면 광고 → pop
        _saveNow(memo);
        ref.read(adServiceProvider).showInterstitialAd();
        if (context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
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
      ),
    );
  }

  Widget _buildEmptyState(ResolvedThemeColors tc) => Scaffold(
        backgroundColor: ColorTokens.transparent,
        appBar: AppBar(
          backgroundColor: ColorTokens.transparent,
          elevation: 0,
          leading: const BackButton(),
        ),
        body: Center(
          child: Text(
            '메모를 찾을 수 없습니다',
            style: AppTypography.bodyLg
                .copyWith(color: tc.textPrimaryWithAlpha(0.50)),
          ),
        ),
      );

  /// AppBar (뒤로 가기 + 저장 + 삭제)
  AppBar _buildAppBar(ResolvedThemeColors tc, Memo memo) {
    return AppBar(
      backgroundColor: ColorTokens.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: tc.textPrimary),
        // PopScope의 onPopInvokedWithResult를 트리거하여 저장+광고 흐름을 실행한다
        onPressed: () => Navigator.maybePop(context),
      ),
      title: Text(
        memo.title.isEmpty ? '메모' : memo.title,
        style: AppTypography.titleMd.copyWith(color: tc.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        MemoSaveButton(
          onSave: () => _saveNow(memo),
          onPostSave: _showAdAfterSave,
        ),
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

  /// 수동 저장 후 전면 광고 표시 (쿨다운 내이면 자동 무시)
  void _showAdAfterSave() {
    ref.read(adServiceProvider).showInterstitialAd();
  }

  void _saveNow(Memo memo) {
    if (memo.type == 'text') {
      _textEditorKey.currentState?.cancelDebounceAndSave();
    } else {
      _strokeDebounce?.cancel();
    }
  }

  void _onStrokesChanged(Memo memo, List<StrokeData> strokes) {
    _strokeDebounce = scheduleStrokeSave(
      currentTimer: _strokeDebounce,
      memo: memo,
      strokes: strokes,
      ref: ref,
    );
  }

  void _onTypeChanged(Memo memo, String type) {
    final update = ref.read(updateMemoProvider);
    update(memo.id, memo.copyWith(type: type, updatedAt: DateTime.now()));
  }

  Future<void> _deleteMemo(Memo memo) async {
    final confirmed = await showMemoDeleteDialog(context);
    if (confirmed && mounted) {
      ref.read(deleteMemoProvider)(memo.id);
      Navigator.pop(context);
    }
  }
}
