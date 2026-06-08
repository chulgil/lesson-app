import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

/// Notebook × Score 각진 라디오 버튼.
///
/// Material `Radio` 는 항상 원형이라 Notebook × Score 메타 원칙
/// (§1.3.1 각진 / `BorderRadius.zero`) 을 위반한다. 이 위젯은 동일한
/// 선택 의미를 정사각형 잉크 박스로 표현한다.
///
/// 시각 규칙:
/// - 20×20 정사각형, `BorderRadius.zero`
/// - 미선택: paper 배경 + ink quaternary 1.5px 보더
/// - 선택: vermillion(paperAccent) 보더 + paperAccent 채움 + 내부 8×8 paper 사각형
///   (악보 음표 머리의 "검은 사각형" 메타포)
/// - disabled: ink tertiary 톤
/// - hover/focus/pressed: paperAccentSoft overlay
///
/// 인터페이스는 `Radio<T>` 와 호환:
/// `value` · `groupValue` · `onChanged` · 선택적 `activeColor` · `toggleable`.
///
/// 스펙: `docs/specs/design/notebook/README.md` §1.3.1
class NotebookRadio<T> extends StatelessWidget {
  /// 이 라디오가 표현하는 값.
  final T value;

  /// 현재 선택된 그룹 값. `value == groupValue` 면 선택 상태.
  final T? groupValue;

  /// 선택 변경 콜백. null 이면 disabled.
  final ValueChanged<T?>? onChanged;

  /// 선택 색상 override. 기본 `AppColors.paperAccent`.
  final Color? activeColor;

  /// true 면 이미 선택된 값을 다시 탭했을 때 null 로 토글.
  final bool toggleable;

  const NotebookRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.activeColor,
    this.toggleable = false,
  });

  bool get _selected => value == groupValue;
  bool get _enabled => onChanged != null;

  void _handleTap() {
    if (!_enabled) return;
    if (_selected) {
      if (toggleable) onChanged!(null);
      return;
    }
    onChanged!(value);
  }

  @override
  Widget build(BuildContext context) {
    final Color accent = activeColor ?? AppColors.paperAccent;
    final Color borderColor = _enabled
        ? (_selected ? accent : AppColors.inkQuaternary)
        : AppColors.inkTertiary;
    final Color fillColor = _enabled && _selected ? accent : Colors.transparent;

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: _selected,
      enabled: _enabled,
      child: InkResponse(
        onTap: _enabled ? _handleTap : null,
        radius: AppSpacing.space5,
        containedInkWell: false,
        highlightShape: BoxShape.rectangle,
        splashColor: AppColors.paperAccentSoft,
        highlightColor: AppColors.paperAccentSoft,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space2),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: fillColor,
              border: Border.all(color: borderColor, width: 1.5),
              borderRadius: BorderRadius.zero,
            ),
            child: _selected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Notebook × Score 각진 라디오 + ListTile 조합.
///
/// `RadioListTile<T>` 의 Notebook 버전. leading 에 [NotebookRadio]
/// 를 두고 title/subtitle/secondary 슬롯을 제공한다.
///
/// 인터페이스는 `RadioListTile<T>` 와 호환되어 호출부 교체가
/// `s/RadioListTile/NotebookRadioListTile/` 수준으로 단순하다.
class NotebookRadioListTile<T> extends StatelessWidget {
  final T value;
  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget? title;
  final Widget? subtitle;
  final Widget? secondary;
  final EdgeInsetsGeometry? contentPadding;
  final bool dense;
  final Color? activeColor;
  final bool toggleable;

  const NotebookRadioListTile({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChanged,
    this.title,
    this.subtitle,
    this.secondary,
    this.contentPadding,
    this.dense = false,
    this.activeColor,
    this.toggleable = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool enabled = onChanged != null;
    return ListTile(
      contentPadding: contentPadding,
      dense: dense,
      leading: NotebookRadio<T>(
        value: value,
        groupValue: groupValue,
        onChanged: onChanged,
        activeColor: activeColor,
        toggleable: toggleable,
      ),
      title: title,
      subtitle: subtitle,
      trailing: secondary,
      onTap: enabled ? () => onChanged!(value) : null,
    );
  }
}
