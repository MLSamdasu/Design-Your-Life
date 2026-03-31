// F-Book: 책 생성 폼 필드 — BookCreateDialog에서 사용하는 입력 위젯 모음
// 제목, 설명, 페이지수/챕터수 토글, 시작일, 목표월, 시험일 등
import 'package:flutter/material.dart';
import '../../../../core/theme/spacing_tokens.dart';
import '../../../../shared/widgets/glass_input_field.dart';
import 'book_form_widgets.dart';

/// 페이지/챕터 추적 모드
enum TrackingMode { pages, chapters }

/// 분배 모드 (자동/수동)
enum DistributionMode { auto, manual }

/// 책 생성 폼 필드 위젯
/// 상위 위젯에서 컨트롤러와 상태를 전달받아 폼을 구성한다
class BookCreateFormFields extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController totalController;
  final TextEditingController daysPerChapterController;
  final TrackingMode trackingMode;
  final ValueChanged<TrackingMode> onTrackingModeChanged;
  final DateTime startDate;
  final VoidCallback onStartDateTap;
  final DateTime? targetMonth;
  final VoidCallback onTargetMonthTap;
  final bool hasExam;
  final ValueChanged<bool> onHasExamChanged;
  final DateTime? examDate;
  final VoidCallback onExamDateTap;

  const BookCreateFormFields({
    super.key,
    required this.titleController,
    required this.descController,
    required this.totalController,
    required this.daysPerChapterController,
    required this.trackingMode,
    required this.onTrackingModeChanged,
    required this.startDate,
    required this.onStartDateTap,
    required this.targetMonth,
    required this.onTargetMonthTap,
    required this.hasExam,
    required this.onHasExamChanged,
    required this.examDate,
    required this.onExamDateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 제목 입력
        GlassInputField(
          controller: titleController,
          label: '책 제목',
          hint: '읽을 책의 제목을 입력하세요',
          autofocus: true,
        ),
        const SizedBox(height: AppSpacing.xl),
        // 설명 입력 (선택)
        GlassInputField(
          controller: descController,
          label: '설명 (선택)',
          hint: '메모나 한줄평을 남겨보세요',
          maxLines: 2,
        ),
        const SizedBox(height: AppSpacing.xl),
        // 추적 모드 토글 (페이지/챕터)
        TrackingModeToggle(
          mode: trackingMode,
          onChanged: onTrackingModeChanged,
        ),
        const SizedBox(height: AppSpacing.xl),
        // 총 페이지수 또는 챕터수 입력
        GlassInputField(
          controller: totalController,
          label: trackingMode == TrackingMode.pages
              ? '총 페이지 수'
              : '총 챕터 수',
          hint: trackingMode == TrackingMode.pages ? '예: 350' : '예: 15',
          keyboardType: TextInputType.number,
        ),
        // 챕터 모드일 때 챕터당 소요 일수 입력
        if (trackingMode == TrackingMode.chapters) ...[
          const SizedBox(height: AppSpacing.xl),
          GlassInputField(
            controller: daysPerChapterController,
            label: '챕터당 소요 일수',
            hint: '예: 2',
            keyboardType: TextInputType.number,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        // 시작일 선택
        DatePickerRow(
          label: '시작일',
          value: _formatDate(startDate),
          onTap: onStartDateTap,
        ),
        const SizedBox(height: AppSpacing.xl),
        // 목표 달 선택
        DatePickerRow(
          label: '목표 달',
          value: targetMonth != null
              ? '${targetMonth!.year}년 ${targetMonth!.month}월'
              : '선택하세요',
          onTap: onTargetMonthTap,
        ),
        const SizedBox(height: AppSpacing.xl),
        // 시험 있음 토글
        ExamToggle(hasExam: hasExam, onChanged: onHasExamChanged),
        // 시험일 선택 (시험 있음인 경우)
        if (hasExam) ...[
          const SizedBox(height: AppSpacing.xl),
          DatePickerRow(
            label: '시험일',
            value: examDate != null ? _formatDate(examDate!) : '선택하세요',
            onTap: onExamDateTap,
          ),
        ],
      ],
    );
  }

  /// 날짜 포맷 (YYYY.MM.DD)
  String _formatDate(DateTime date) =>
      '${date.year}.${date.month.toString().padLeft(2, '0')}'
      '.${date.day.toString().padLeft(2, '0')}';
}
