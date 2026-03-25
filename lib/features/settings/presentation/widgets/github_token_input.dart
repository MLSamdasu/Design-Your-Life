// F6-GH: GitHub 토큰 입력 섹션 (연결/미연결 상태 UI)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/color_tokens.dart';
import '../../../../core/theme/layout_tokens.dart';
import '../../../../core/theme/radius_tokens.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../core/theme/typography_tokens.dart';

/// GitHub 토큰 입력 및 연결 상태 표시 위젯
class GitHubTokenInput extends StatefulWidget {
  final bool isConnected;
  final String? username;
  final bool isValidating;
  final ValueChanged<String> onConnect;
  final VoidCallback onDisconnect;

  const GitHubTokenInput({
    super.key,
    required this.isConnected,
    this.username,
    required this.isValidating,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  State<GitHubTokenInput> createState() => _GitHubTokenInputState();
}

class _GitHubTokenInputState extends State<GitHubTokenInput> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isConnected) return _connectedRow(context);
    return _disconnectedColumn(context);
  }

  // ─── 연결 상태: @username 연결됨 + 연결 해제 ──────────────────────────
  Widget _connectedRow(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.check_circle_rounded,
            size: AppLayout.iconLg, color: ColorTokens.success),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            '@${widget.username ?? ''} 연결됨',
            style: AppTypography.bodyLg.copyWith(
              color: context.themeColors.textPrimary,
              fontWeight: AppTypography.weightSemiBold,
            ),
          ),
        ),
        GestureDetector(
          onTap: widget.onDisconnect,
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                  color: ColorTokens.error.withValues(alpha: 0.5)),
            ),
            child: Text('연결 해제',
                style: AppTypography.captionLg.copyWith(
                  color: ColorTokens.error,
                  fontWeight: AppTypography.weightSemiBold,
                )),
          ),
        ),
      ],
    );
  }

  // ─── 미연결 상태: 토큰 입력 + 연결 버튼 ──────────────────────────────
  Widget _disconnectedColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.link_off_rounded,
              size: AppLayout.iconLg,
              color: context.themeColors.textPrimaryWithAlpha(0.5)),
          const SizedBox(width: AppSpacing.md),
          Text('연결되지 않음',
              style: AppTypography.bodyLg.copyWith(
                color: context.themeColors.textPrimaryWithAlpha(0.6),
              )),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Row(children: [
          Expanded(child: _tokenField(context)),
          const SizedBox(width: AppSpacing.md),
          _connectButton(context),
        ]),
      ],
    );
  }

  // ─── 토큰 입력 필드 ─────────────────────────────────────────────────
  Widget _tokenField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeColors.overlayLight,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
            color: context.themeColors.textPrimaryWithAlpha(0.20)),
      ),
      child: TextField(
        controller: _controller,
        obscureText: _obscure,
        style: AppTypography.bodyMd
            .copyWith(color: context.themeColors.textPrimary),
        cursorColor: context.themeColors.textPrimary,
        decoration: InputDecoration(
          hintText: '토큰 입력',
          hintStyle: AppTypography.bodyMd.copyWith(
              color: context.themeColors.textPrimaryWithAlpha(0.4)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.mdLg),
          suffixIcon: Row(mainAxisSize: MainAxisSize.min, children: [
            // 표시/숨김 토글
            GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                size: AppLayout.iconMd,
                color: context.themeColors.textPrimaryWithAlpha(0.5),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            // 클립보드 붙여넣기
            GestureDetector(
              onTap: _paste,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Icon(Icons.content_paste_rounded,
                    size: AppLayout.iconMd,
                    color: context.themeColors.textPrimaryWithAlpha(0.5)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── 연결 버튼 ──────────────────────────────────────────────────────
  Widget _connectButton(BuildContext context) {
    return GestureDetector(
      onTap: widget.isValidating ? null : () {
        final token = _controller.text.trim();
        if (token.isNotEmpty) widget.onConnect(token);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.mdLg),
        decoration: BoxDecoration(
          color: widget.isValidating
              ? context.themeColors.accentWithAlpha(0.4)
              : context.themeColors.accent,
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        child: widget.isValidating
            ? SizedBox(
                width: AppLayout.iconMd, height: AppLayout.iconMd,
                child: CircularProgressIndicator(
                  strokeWidth: GoalLayout.spinnerStrokeWidth,
                  color: ColorTokens.white,
                ))
            : Text('연결',
                style: AppTypography.bodySm.copyWith(
                  color: ColorTokens.white,
                  fontWeight: AppTypography.weightSemiBold,
                )),
      ),
    );
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) return;
    _controller.text = data.text!;
    _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length));
  }
}
