// 태그 생성/편집 Bottom Sheet
// 태그 이름 입력 + 색상 선택 + 저장 기능을 제공하는 모달 시트이다.
// 생성 모드와 편집 모드를 editTag 파라미터로 구분한다.
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/auth/auth_provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/glassmorphism.dart';
import '../../../../core/theme/typography_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../shared/models/tag.dart';
import '../../../../shared/providers/tag_provider.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import 'tag_color_picker.dart';
import 'tag_name_field.dart';
import 'tag_save_button.dart';

/// 태그 이름 + 색상 입력 Bottom Sheet (생성/편집 공용)
class TagFormSheet extends ConsumerStatefulWidget {
  /// 편집 모드 시 기존 태그, null이면 생성 모드
  final Tag? editTag;

  const TagFormSheet({super.key, this.editTag});

  @override
  ConsumerState<TagFormSheet> createState() => _TagFormSheetState();
}

class _TagFormSheetState extends ConsumerState<TagFormSheet> {
  late final TextEditingController _nameController;
  late int _selectedColorIndex;
  bool _isSaving = false;
  String? _nameError;

  bool get _isEditMode => widget.editTag != null;

  @override
  void initState() {
    super.initState();
    // 편집 모드: 기존 값으로 초기화, 생성 모드: 기본값
    _nameController = TextEditingController(
      text: widget.editTag?.name ?? '',
    );
    _selectedColorIndex = widget.editTag?.colorIndex ?? 0;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  bool _validate() {
    final name = _nameController.text.trim();
    setState(() {
      if (name.isEmpty) {
        _nameError = '태그 이름을 입력해주세요';
      } else if (name.length > 20) {
        _nameError = '20자 이내로 입력해주세요';
      } else {
        _nameError = null;
      }
    });
    return _nameError == null;
  }

  /// 저장 처리 (생성 또는 수정)
  Future<void> _save() async {
    if (!_validate()) return;
    setState(() => _isSaving = true);

    // 로컬 퍼스트: 인증 없이도 태그를 생성/수정할 수 있다
    final userId =
        ref.read(currentUserIdProvider) ?? AppConstants.localUserId;

    final name = _nameController.text.trim();

    try {
      if (_isEditMode) {
        // 수정 모드: 이름과 색상만 변경한다
        final updateTag = ref.read(updateTagProvider);
        await updateTag(widget.editTag!.copyWith(
          name: name,
          colorIndex: _selectedColorIndex,
        ));
      } else {
        // 생성 모드: 새 태그 ID 생성 후 저장한다
        final generateId = ref.read(generateTagIdProvider);
        final createTag = ref.read(createTagProvider);
        final now = DateTime.now();
        await createTag(Tag(
          id: generateId(),
          userId: userId,
          name: name,
          colorIndex: _selectedColorIndex,
          createdAt: now,
        ));
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        AppSnackBar.showError(
          context,
          _isEditMode ? '태그 수정에 실패했습니다' : '태그 생성에 실패했습니다',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return ClipRRect(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppRadius.pill)),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: GlassDecoration.elevatedBlurSigma,
          sigmaY: GlassDecoration.elevatedBlurSigma,
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            decoration: GlassDecoration.modal(),
            padding: EdgeInsets.fromLTRB(
              AppSpacing.dialogPadding,
              AppSpacing.dialogPadding,
              AppSpacing.dialogPadding,
              AppSpacing.dialogPadding + bottomInset,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 핸들 바
                Center(
                  child: Container(
                    width: MiscLayout.handleBarWidth,
                    height: MiscLayout.handleBarHeight,
                    decoration: BoxDecoration(
                      color: context.themeColors.textPrimaryWithAlpha(0.3),
                      borderRadius: BorderRadius.circular(AppRadius.xs),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // 제목
                Text(
                  _isEditMode ? '태그 수정' : '새 태그 추가',
                  style: AppTypography.titleLg.copyWith(
                    color: context.themeColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),

                // 이름 입력 필드
                TagNameField(
                  controller: _nameController,
                  errorText: _nameError,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                // 색상 선택 섹션
                TagColorPicker(
                  selectedIndex: _selectedColorIndex,
                  onColorSelected: (i) =>
                      setState(() => _selectedColorIndex = i),
                ),
                const SizedBox(height: AppSpacing.xxxl),

                // 저장 버튼
                TagSaveButton(
                  isSaving: _isSaving,
                  isEditMode: _isEditMode,
                  onTap: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
