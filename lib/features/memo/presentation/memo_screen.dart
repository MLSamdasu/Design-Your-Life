// F-Memo: 메모 메인 화면 (반응형 분할 뷰)
// 모바일: MemoListPanel만 표시 → 탭 시 MemoEditorPage push
// 데스크탑: 좌측 리스트(280px) + 우측 에디터 분할
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ads/ad_provider.dart';
import '../../../core/theme/color_tokens.dart';
import '../../../core/theme/layout_tokens.dart';
import '../../../core/theme/spacing_tokens.dart';
import '../../../core/theme/theme_colors.dart';
import '../models/memo.dart';
import '../models/stroke_data.dart';
import '../providers/memo_provider.dart';
import 'memo_editor_page.dart';
import 'widgets/memo_drawing_body.dart';
import 'widgets/memo_drawing_canvas.dart';
import 'widgets/memo_editor_empty_state.dart';
import 'widgets/memo_editor_toolbar.dart';
import 'widgets/memo_list_panel.dart';
import 'widgets/memo_save_button.dart';
import 'widgets/memo_text_editor.dart';

const _kBreakpointWidth = 600.0; // 반응형 분할 뷰 전환 임계 너비
const _kListPanelWidth = 280.0; // 좌측 리스트 패널 고정 너비

/// 메모 메인 화면
class MemoScreen extends ConsumerStatefulWidget {
  const MemoScreen({super.key});

  @override
  ConsumerState<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends ConsumerState<MemoScreen> {
  String? _selectedMemoId;
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
    return Scaffold(
      backgroundColor: ColorTokens.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _kBreakpointWidth;
            return isWide
                ? _buildSplitLayout(constraints)
                : _buildMobileLayout();
          },
        ),
      ),
    );
  }

  /// 모바일 레이아웃: 리스트만 표시, 탭 시 MemoEditorPage push
  Widget _buildMobileLayout() {
    return MemoListPanel(
      selectedMemoId: _selectedMemoId,
      onMemoSelected: (id) {
        setState(() => _selectedMemoId = id);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => MemoEditorPage(memoId: id)),
        );
      },
    );
  }

  /// 데스크탑/태블릿 분할 레이아웃: 좌측 리스트 + 우측 에디터
  Widget _buildSplitLayout(BoxConstraints constraints) {
    final tc = context.themeColors;
    return Row(children: [
      SizedBox(
        width: _kListPanelWidth,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              right: BorderSide(
                color: tc.dividerColor, width: AppLayout.borderThin),
            ),
          ),
          child: MemoListPanel(
            selectedMemoId: _selectedMemoId,
            onMemoSelected: (id) => setState(() => _selectedMemoId = id),
          ),
        ),
      ),
      Expanded(child: _buildDesktopEditor(tc)),
    ]);
  }

  /// 데스크탑 인라인 에디터 영역
  Widget _buildDesktopEditor(ResolvedThemeColors tc) {
    if (_selectedMemoId == null) return const MemoEditorEmptyState();

    final memos = ref.watch(memosProvider);
    final memo = memos.where((m) => m.id == _selectedMemoId).firstOrNull;
    if (memo == null) return const MemoEditorEmptyState();

    return Column(
      children: [
        // 저장 버튼 (우측 정렬)
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: MemoSaveButton(
              onSave: () => _saveNow(memo),
              // 데스크톱에서는 AdConstants.isAdSupported가 false이므로 자동 무시된다
              onPostSave: () =>
                  ref.read(adServiceProvider).showInterstitialAd(),
            ),
          ),
        ),
        // 모드 전환 + 드로잉 도구 툴바
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
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: _buildEditorContent(memo),
          ),
        ),
      ],
    );
  }

  /// 에디터 콘텐츠 (텍스트 또는 드로잉)
  Widget _buildEditorContent(Memo memo) {
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
}
