import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'notebook/notebook_bottom_sheet.dart';

/// Result of an address search selection.
class AddressResult {
  final String? postalCode;
  final String? address;
  final String? addressDetail;

  const AddressResult({this.postalCode, this.address, this.addressDetail});

  AddressResult copyWith({
    String? postalCode,
    String? address,
    String? addressDetail,
  }) {
    return AddressResult(
      postalCode: postalCode ?? this.postalCode,
      address: address ?? this.address,
      addressDetail: addressDetail ?? this.addressDetail,
    );
  }
}

/// Mock address entry used in the search bottom sheet.
class _MockAddress {
  final String postalCode;
  final String address;

  const _MockAddress({required this.postalCode, required this.address});
}

// Hardcoded mock results — replace with Kakao Address API later.
const _kMockAddresses = [
  _MockAddress(postalCode: '06235', address: '서울시 강남구 역삼동 123-45'),
  _MockAddress(postalCode: '04524', address: '서울시 중구 명동길 14'),
  _MockAddress(postalCode: '03187', address: '서울시 종로구 세종대로 175'),
  _MockAddress(postalCode: '48058', address: '부산시 해운대구 센텀동로 99'),
];

/// 공통 주소 검색 필드 — 심플한 단일 입력 UI.
///
/// 내부적으로 [postalCode], [address], [addressDetail] 3필드로 분리 저장.
/// "검색" 버튼 탭 시 바텀시트를 열어 mock 결과에서 주소를 선택한다.
/// 향후 카카오 주소 API 연결 예정.
///
/// Notebook × Score design: paper background, ink text, inkQuaternary border.
// ignore: widget-smoke-test
class AddressSearchField extends StatefulWidget {
  final String? initialPostalCode;
  final String? initialAddress;
  final String? initialAddressDetail;
  final ValueChanged<AddressResult> onChanged;
  final String? hintText;

  const AddressSearchField({
    super.key,
    this.initialPostalCode,
    this.initialAddress,
    this.initialAddressDetail,
    required this.onChanged,
    this.hintText,
  });

  @override
  State<AddressSearchField> createState() => _AddressSearchFieldState();
}

class _AddressSearchFieldState extends State<AddressSearchField> {
  late String? _postalCode;
  late String? _address;
  late final TextEditingController _detailController;
  late final TextEditingController _manualAddressController;
  late final TextEditingController _manualPostalController;

  @override
  void initState() {
    super.initState();
    _postalCode = widget.initialPostalCode;
    _address = widget.initialAddress;
    _detailController = TextEditingController(
      text: widget.initialAddressDetail,
    );
    _manualAddressController = TextEditingController(text: _address);
    _manualPostalController = TextEditingController(text: _postalCode);
    _detailController.addListener(_onDetailChanged);
    _manualAddressController.addListener(_onManualChanged);
    _manualPostalController.addListener(_onManualChanged);
  }

  @override
  void dispose() {
    _detailController.removeListener(_onDetailChanged);
    _manualAddressController.removeListener(_onManualChanged);
    _manualPostalController.removeListener(_onManualChanged);
    _detailController.dispose();
    _manualAddressController.dispose();
    _manualPostalController.dispose();
    super.dispose();
  }

  void _onDetailChanged() => _notifyParent();
  void _onManualChanged() {
    _postalCode =
        _manualPostalController.text.isEmpty
            ? null
            : _manualPostalController.text;
    _address =
        _manualAddressController.text.isEmpty
            ? null
            : _manualAddressController.text;
    _notifyParent();
  }

  void _notifyParent() {
    widget.onChanged(
      AddressResult(
        postalCode: _postalCode,
        address: _address,
        addressDetail:
            _detailController.text.isEmpty ? null : _detailController.text,
      ),
    );
  }


  Future<void> _openSearchSheet() async {
    final result = await showNotebookModalBottomSheet<_MockAddress>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => const _AddressSearchSheet(),
    );

    if (result != null) {
      setState(() {
        _postalCode = result.postalCode;
        _address = result.address;
      });
      widget.onChanged(
        AddressResult(
          postalCode: result.postalCode,
          address: result.address,
          addressDetail:
              _detailController.text.isEmpty ? null : _detailController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 검색 모드 고정 (우편번호는 검색 시 백그라운드 자동 저장)
        _buildSearchRow(),

        const SizedBox(height: AppSpacing.space2),

        // 상세주소 (모드 무관 공통)
        TextField(
          controller: _detailController,
          decoration: _inputDecoration(hintText: AppStrings.addressDetailHint),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
          textInputAction: TextInputAction.done,
        ),
      ],
    );
  }

  Widget _buildSearchRow() {
    final hasAddress = _address != null && _address!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        border: Border.all(color: AppColors.inkQuaternary),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space2,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_outlined,
            size: AppSpacing.iconSM,
            color: AppColors.inkTertiary,
          ),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child:
                hasAddress
                    ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_postalCode != null)
                          Text(
                            _postalCode!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.inkTertiary,
                            ),
                          ),
                        Text(
                          _address!,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.ink,
                          ),
                        ),
                      ],
                    )
                    : Text(
                      widget.hintText ?? AppStrings.addressSearchHint,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.inkQuaternary,
                      ),
                    ),
          ),
          const SizedBox(width: AppSpacing.space2),
          TextButton(
            onPressed: _openSearchSheet,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.paperAccent,
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space3,
                vertical: AppSpacing.space2,
              ),
              shape: const RoundedRectangleBorder(),
            ),
            child: Text(
              AppStrings.addressSearch,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.paperAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: AppTypography.bodyMedium.copyWith(
        color: AppColors.inkQuaternary,
      ),
      filled: true,
      fillColor: AppColors.paper,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.space3,
        vertical: AppSpacing.space3,
      ),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.inkQuaternary),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.inkQuaternary),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.zero,
        borderSide: BorderSide(color: AppColors.ink),
      ),
    );
  }
}

/// Bottom sheet for address search with mock data.
class _AddressSearchSheet extends StatefulWidget {
  const _AddressSearchSheet();

  @override
  State<_AddressSearchSheet> createState() => _AddressSearchSheetState();
}

class _AddressSearchSheetState extends State<_AddressSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<_MockAddress> _results = _kMockAddresses;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      if (query.isEmpty) {
        _results = _kMockAddresses;
      } else {
        _results =
            _kMockAddresses
                .where(
                  (a) =>
                      a.address.contains(query) || a.postalCode.contains(query),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet handle
            Container(
              color: AppColors.paper,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space3),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.inkQuaternary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),

            // Search input
            Container(
              color: AppColors.paper,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space4,
                vertical: AppSpacing.space2,
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: AppStrings.addressSearchHint,
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.inkQuaternary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: AppSpacing.iconSM,
                    color: AppColors.inkTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.paper,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.space3,
                    vertical: AppSpacing.space3,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.inkQuaternary),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.inkQuaternary),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.ink),
                  ),
                ),
                style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
              ),
            ),

            // Divider
            Container(height: 1, color: AppColors.inkQuaternary),

            // Results list
            Expanded(
              child:
                  _results.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              AppStrings.addressNoResults,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.inkTertiary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.space3),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                AppStrings.addressManualInputGuide,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.paperAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      : ListView.separated(
                        itemCount: _results.length,
                        separatorBuilder:
                            (_, __) => Container(
                              height: 1,
                              color: AppColors.inkQuaternary,
                              margin: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space4,
                              ),
                            ),
                        itemBuilder: (ctx, index) {
                          final item = _results[index];
                          return InkWell(
                            onTap: () => Navigator.of(ctx).pop(item),
                            child: Container(
                              color: AppColors.paper,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space4,
                                vertical: AppSpacing.space3,
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.location_on_outlined,
                                    size: AppSpacing.iconSM,
                                    color: AppColors.inkTertiary,
                                  ),
                                  const SizedBox(width: AppSpacing.space3),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.address,
                                          style: AppTypography.bodyMedium
                                              .copyWith(color: AppColors.ink),
                                        ),
                                        const SizedBox(
                                          height: AppSpacing.space1,
                                        ),
                                        Text(
                                          item.postalCode,
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                color: AppColors.inkTertiary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
