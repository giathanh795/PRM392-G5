// ============================================================================
// HỘP THOẠI BIỂU MẪU CẦU THỦ (PLAYER FORM DIALOG)
// ============================================================================
// Mục đích:
// - Cung cấp biểu mẫu hợp nhất dùng chung cho cả 2 thao tác:
//   1. THÊM MỚI CẦU THỦ (Create): Khởi tạo cầu thủ mới kèm bộ 6 chỉ số tự động.
//   2. CHỈNH SỬA CẦU THỦ (Update): Nạp toàn bộ dữ liệu sẵn có và cho phép cập nhật.
// - Tính năng nổi bật:
//   + Chọn ảnh trực tiếp từ thư viện máy (ImagePicker), tự động mã hóa Base64 Data URI
//     để lưu trữ bền vững trong SharedPreferences mà không cần server lưu trữ ngoài.
//   + Bộ chọn ngày tháng (DatePicker) trực quan cho ngày sinh và hạn hợp đồng.
//   + Xác thực form nghiêm ngặt (Form Validation) trước khi gửi.
//   + Tự động cập nhật biểu đồ lịch sử định giá chuyển nhượng (Market Value History).
// ============================================================================

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';
import '../data/mock_data.dart';
import '../models/player.dart';
import '../providers/app_state_provider.dart';
import 'player_avatar.dart';

/// Hàm tiện ích mở Hộp thoại biểu mẫu cầu thủ
/// - Tham số `player`: Nếu truyền vào sẽ mở chế độ CHỈNH SỬA, nếu null là THÊM MỚI.
/// - Trả về `true` nếu lưu thành công, `false` hoặc `null` nếu bấm Hủy.
Future<bool?> showPlayerFormDialog(BuildContext context, {Player? player}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => PlayerFormDialog(player: player),
  );
}

class PlayerFormDialog extends StatefulWidget {
  /// Cầu thủ cần chỉnh sửa (nếu null là tạo mới)
  final Player? player;

  const PlayerFormDialog({super.key, this.player});

  /// Kiểm tra xem biểu mẫu đang ở chế độ Sửa hay Tạo mới
  bool get isEdit => player != null;

  @override
  State<PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends State<PlayerFormDialog> {
  /// Khóa quản lý trạng thái form và kiểm tra hợp lệ
  final _formKey = GlobalKey<FormState>();

  // --------------------------------------------------------------------------
  // CÁC BỘ ĐIỀU KHIỂN DỮ LIỆU NHẬP (TEXT EDITING CONTROLLERS)
  // --------------------------------------------------------------------------
  late TextEditingController _nameController;
  late TextEditingController _numberController;
  late TextEditingController _nationalityController;
  late TextEditingController _dobController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _contractController;
  late TextEditingController _marketValueController;
  late TextEditingController _sponsorController;
  late TextEditingController _avatarUrlController;

  /// Vị trí thi đấu được chọn trong Dropdown
  late PlayerPosition _selectedPosition;

  /// Chân thuận được chọn trong Dropdown (Right, Left, Both)
  late String _selectedFoot;

  /// Trạng thái thi đấu được chọn trong Dropdown (Active, Injured, On Duty, Loaned)
  late String _selectedStatus;

  /// Công cụ chọn tệp/ảnh từ hệ thống máy tính/điện thoại
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final p = widget.player;

    // Khởi tạo giá trị ban đầu cho các Controller:
    // Nếu là chế độ Sửa (p != null) -> Lấy dữ liệu hiện tại của cầu thủ
    // Nếu là chế độ Thêm mới (p == null) -> Đặt giá trị gợi ý chuẩn Liverpool FC
    _nameController = TextEditingController(text: p?.name ?? '');
    _numberController = TextEditingController(text: p != null ? p.number.toString() : '');
    _nationalityController = TextEditingController(text: p?.nationality ?? 'England');
    _dobController = TextEditingController(text: p?.dateOfBirth ?? '2002-05-15');
    _heightController = TextEditingController(text: p?.height ?? '182 cm');
    _weightController = TextEditingController(text: p?.weight ?? '76 kg');
    _contractController = TextEditingController(text: p?.contractUntil ?? '2029-06-30');
    _marketValueController = TextEditingController(
      text: p != null ? p.currentMarketValue.toStringAsFixed(0) : '35',
    );
    _sponsorController = TextEditingController(text: p?.sponsorPartner ?? 'Adidas');
    _avatarUrlController = TextEditingController(text: p?.avatarUrl ?? '');

    _selectedPosition = p?.position ?? PlayerPosition.forward;
    _selectedFoot = p?.preferredFoot ?? 'Right';
    _selectedStatus = p?.status ?? 'Active';
  }

  @override
  void dispose() {
    // Giải phóng toàn bộ Controller khỏi bộ nhớ RAM khi đóng Dialog
    _nameController.dispose();
    _numberController.dispose();
    _nationalityController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _contractController.dispose();
    _marketValueController.dispose();
    _sponsorController.dispose();
    _avatarUrlController.dispose();
    super.dispose();
  }

  /// ==========================================================================
  /// LUỒNG CHỌN ẢNH ĐẠI DIỆN TỪ THIẾT BỊ:
  /// 1. Mở thư viện ảnh (gallery) của máy tính hoặc điện thoại.
  /// 2. Giới hạn độ phân giải (600x600) và chất lượng (85%) để tối ưu kích thước.
  /// 3. Đọc dữ liệu nhị phân (bytes) và mã hóa thành chuỗi Base64 Data URI.
  /// 4. Cập nhật vào _avatarUrlController để PlayerAvatar hiển thị xem trước tức thì.
  /// ==========================================================================
  Future<void> _pickImageFromGallery() async {
    try {
      final picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
        setState(() {
          _avatarUrlController.text = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể chọn ảnh từ thiết bị: $e')),
        );
      }
    }
  }

  /// ==========================================================================
  /// LUỒNG CHỌN NGÀY BẰNG BỘ LỊCH (DATE PICKER):
  /// - Hiển thị hộp thoại lịch chuẩn dark theme Liverpool FC.
  /// - Format ngày được chọn thành chuỗi YYYY-MM-DD và gán vào controller tương ứng.
  /// ==========================================================================
  Future<void> _selectDate(TextEditingController controller) async {
    DateTime initial = DateTime.tryParse(controller.text) ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.lfcRed,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceNavy,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      final year = picked.year.toString();
      final month = picked.month.toString().padLeft(2, '0');
      final day = picked.day.toString().padLeft(2, '0');
      setState(() {
        controller.text = '$year-$month-$day';
      });
    }
  }

  /// ==========================================================================
  /// LUỒNG XỬ LÝ LƯU BIỂU MẪU (SUBMIT FORM FLOW):
  /// 1. Gọi validate() kiểm tra tất cả các trường bắt buộc (Tên, Số áo, Giá trị).
  /// 2. Thu thập và chuẩn hóa dữ liệu từ các Controller và Dropdown.
  /// 3. Phân nhánh xử lý:
  ///    - NẾU LÀ CHỈNH SỬA (widget.isEdit == true):
  ///      + Sao chép dữ liệu cũ kèm thông tin mới qua phương thức copyWith.
  ///      + Nếu giá thị trường thay đổi, bổ sung mốc định giá mới vào marketValueHistory.
  ///      + Gọi AppStateProvider.updatePlayer(updated) để cập nhật danh sách và lưu SharedPreferences.
  ///    - NẾU LÀ THÊM MỚI (widget.isEdit == false):
  ///      + Sinh mã định danh duy nhất (p_timestamp).
  ///      + Tự động sinh bộ chỉ số kỹ năng 82 điểm phù hợp với vị trí thi đấu đã chọn.
  ///      + Khởi tạo đối tượng Player mới và gọi AppStateProvider.addPlayer(newPlayer).
  /// 4. Đóng hộp thoại và hiển thị SnackBar thông báo thành công.
  /// ==========================================================================
  void _submitForm() async {
    // Bước 1: Kiểm tra tính hợp lệ của dữ liệu nhập
    if (!_formKey.currentState!.validate()) return;

    // Bước 2: Thu thập dữ liệu từ các ô nhập liệu
    final name = _nameController.text.trim();
    final number = int.tryParse(_numberController.text.trim()) ?? 0;
    final nationality = _nationalityController.text.trim();
    final dob = _dobController.text.trim();
    final height = _heightController.text.trim();
    final weight = _weightController.text.trim();
    final contract = _contractController.text.trim();
    final marketValue = double.tryParse(_marketValueController.text.trim()) ?? 0.0;
    final sponsor = _sponsorController.text.trim();
    final avatar = _avatarUrlController.text.trim();

    final provider = context.read<AppStateProvider>();

    if (widget.isEdit) {
      // ----------------------------------------------------------------------
      // CHẾ ĐỘ 1: CẬP NHẬT CẦU THỦ HIỆN TẠI (UPDATE)
      // ----------------------------------------------------------------------
      final oldPlayer = widget.player!;
      final double previousValue = (marketValue != oldPlayer.currentMarketValue)
          ? oldPlayer.currentMarketValue
          : oldPlayer.previousMarketValue;

      // Cập nhật lịch sử biến động giá trị thị trường
      List<MarketValuePoint> updatedMarketHistory = List.from(oldPlayer.marketValueHistory);
      if (marketValue != oldPlayer.currentMarketValue) {
        updatedMarketHistory.add(MarketValuePoint(date: 'Now', valueInMillionsEuro: marketValue));
      }

      // Tạo đối tượng Player mới với thông tin cập nhật
      final updated = oldPlayer.copyWith(
        name: name,
        number: number,
        position: _selectedPosition,
        nationality: nationality,
        dateOfBirth: dob,
        height: height,
        weight: weight,
        preferredFoot: _selectedFoot,
        contractUntil: contract,
        currentMarketValue: marketValue,
        previousMarketValue: previousValue,
        status: _selectedStatus,
        sponsorPartner: sponsor.isNotEmpty ? sponsor : 'Adidas',
        avatarUrl: avatar,
        marketValueHistory: updatedMarketHistory,
      );

      // Cập nhật State và đồng bộ SharedPreferences
      await provider.updatePlayer(updated);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.surfaceNavy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppTheme.borderSubtle),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.accentCyan, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Đã cập nhật hồ sơ cầu thủ "$name"!')),
              ],
            ),
          ),
        );
      }
    } else {
      // ----------------------------------------------------------------------
      // CHẾ ĐỘ 2: TẠO MỚI CẦU THỦ (CREATE)
      // ----------------------------------------------------------------------
      final newId = 'p_${DateTime.now().millisecondsSinceEpoch}';
      // Lấy danh sách tên thuộc tính kỹ thuật tương ứng với tuyến thi đấu đã chọn
      final defaultAttrs = MockData.getAttributesForPosition(_selectedPosition);
      final Map<String, double> statsMap = {for (var attr in defaultAttrs) attr: 82.0};

      // Tạo đối tượng Player hoàn chỉnh
      final newPlayer = Player(
        id: newId,
        name: name,
        number: number,
        position: _selectedPosition,
        nationality: nationality,
        dateOfBirth: dob,
        preferredFoot: _selectedFoot,
        height: height,
        weight: weight,
        contractUntil: contract,
        avatarUrl: avatar,
        currentMarketValue: marketValue,
        previousMarketValue: marketValue,
        status: _selectedStatus,
        sponsorPartner: sponsor.isNotEmpty ? sponsor : 'Adidas',
        progressHistory: [
          PlayerStatistic(date: 'Oct', attributes: statsMap),
        ],
        marketValueHistory: [
          MarketValuePoint(date: 'Oct', valueInMillionsEuro: marketValue),
        ],
        mediaList: [],
      );

      // Thêm vào State và lưu SharedPreferences
      await provider.addPlayer(newPlayer);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.surfaceNavy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: AppTheme.borderSubtle),
            ),
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: AppTheme.accentCyan, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Đã thêm cầu thủ "$name" vào đội hình Liverpool!')),
              ],
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.isEdit;

    return Dialog(
      backgroundColor: AppTheme.surfaceNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.borderSubtle),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // --------------------------------------------------------------
              // 1. TIÊU ĐỀ HỘP THOẠI (DIALOG HEADER)
              // --------------------------------------------------------------
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isEdit ? AppTheme.accentBlue.withValues(alpha: 0.15) : AppTheme.lfcRed.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
                      color: isEdit ? AppTheme.accentCyan : AppTheme.lfcRed,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Chỉnh sửa thông tin cầu thủ' : 'Thêm cầu thủ mới vào đội hình',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Liverpool FC • Official Squad Management',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textMuted),
                    tooltip: 'Đóng',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
              const Divider(color: AppTheme.borderSubtle, height: 24),

              // --------------------------------------------------------------
              // 2. KHU VỰC CUỘN NỘI DUNG FORM (SCROLLABLE FORM CONTENT)
              // --------------------------------------------------------------
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ----------------------------------------------------
                        // MỤC ẢNH ĐẠI DIỆN: TẢI TỪ MÁY & XEM TRƯỚC (LIVE PREVIEW)
                        // ----------------------------------------------------
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceNavyLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Row(
                            children: [
                              // Avatar xem trước thời gian thực
                              PlayerAvatar(
                                imageUrl: _avatarUrlController.text,
                                radius: 34,
                                initials: _nameController.text.isNotEmpty ? _nameController.text[0] : '?',
                                borderColor: AppTheme.accentCyan,
                                borderWidth: 2,
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ảnh đại diện (Avatar)',
                                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        // Nút chọn ảnh từ máy tính/thiết bị
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.accentBlue.withValues(alpha: 0.25),
                                            foregroundColor: AppTheme.accentCyan,
                                            side: const BorderSide(color: AppTheme.accentCyan),
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            visualDensity: VisualDensity.compact,
                                          ),
                                          icon: const Icon(Icons.photo_library_outlined, size: 16),
                                          label: const Text('Chọn ảnh từ máy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                          onPressed: _pickImageFromGallery,
                                        ),
                                        // Nút gỡ ảnh nếu đã có
                                        if (_avatarUrlController.text.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: AppTheme.lfcRed,
                                              side: BorderSide(color: AppTheme.lfcRed.withValues(alpha: 0.5)),
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            icon: const Icon(Icons.delete_outline, size: 15),
                                            label: const Text('Gỡ ảnh', style: TextStyle(fontSize: 11)),
                                            onPressed: () {
                                              setState(() {
                                                _avatarUrlController.text = '';
                                              });
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ----------------------------------------------------
                        // DÒNG 1: HỌ VÀ TÊN & SỐ ÁO THI ĐẤU
                        // ----------------------------------------------------
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ô nhập Họ và tên cầu thủ
                            Expanded(
                              flex: 3,
                              child: TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Họ và tên cầu thủ *',
                                  hintText: 'VD: Federico Chiesa',
                                  prefixIcon: Icon(Icons.badge_outlined, size: 20),
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Vui lòng nhập tên cầu thủ';
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Ô nhập Số áo thi đấu
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                controller: _numberController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Số áo *',
                                  hintText: '14',
                                  prefixIcon: Icon(Icons.tag, size: 20),
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) {
                                    return 'Bắt buộc';
                                  }
                                  if (int.tryParse(val) == null) {
                                    return 'Số hợp lệ';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ----------------------------------------------------
                        // DÒNG 2: VỊ TRÍ THI ĐẤU & QUỐC TỊCH
                        // ----------------------------------------------------
                        Row(
                          children: [
                            // Tuyến vị trí thi đấu
                            Expanded(
                              child: DropdownButtonFormField<PlayerPosition>(
                                initialValue: _selectedPosition,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Vị trí thi đấu *',
                                  prefixIcon: Icon(Icons.sports_soccer, size: 20),
                                ),
                                dropdownColor: AppTheme.surfaceNavy,
                                style: const TextStyle(color: Colors.white),
                                items: PlayerPosition.values.map((pos) {
                                  String label;
                                  switch (pos) {
                                    case PlayerPosition.forward:
                                      label = 'Forward (Tiền đạo)';
                                      break;
                                    case PlayerPosition.midfielder:
                                      label = 'Midfielder (Tiền vệ)';
                                      break;
                                    case PlayerPosition.defender:
                                      label = 'Defender (Hậu vệ)';
                                      break;
                                    case PlayerPosition.goalkeeper:
                                      label = 'Goalkeeper (Thủ môn)';
                                      break;
                                  }
                                  return DropdownMenuItem(
                                    value: pos,
                                    child: Text(
                                      label,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedPosition = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Ô nhập Quốc tịch
                            Expanded(
                              child: TextFormField(
                                controller: _nationalityController,
                                decoration: const InputDecoration(
                                  labelText: 'Quốc tịch *',
                                  hintText: 'VD: England',
                                  prefixIcon: Icon(Icons.public, size: 20),
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Nhập quốc tịch' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ----------------------------------------------------
                        // DÒNG 3: CHIỀU CAO & CÂN NẶNG
                        // ----------------------------------------------------
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _heightController,
                                decoration: const InputDecoration(
                                  labelText: 'Chiều cao',
                                  hintText: 'VD: 185 cm',
                                  prefixIcon: Icon(Icons.height, size: 20),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _weightController,
                                decoration: const InputDecoration(
                                  labelText: 'Cân nặng',
                                  hintText: 'VD: 78 kg',
                                  prefixIcon: Icon(Icons.fitness_center, size: 20),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ----------------------------------------------------
                        // DÒNG 4: CHÂN THUẬN & TRẠNG THÁI ĐỘI HÌNH
                        // ----------------------------------------------------
                        Row(
                          children: [
                            // Chọn chân thuận
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedFoot,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Chân thuận',
                                  prefixIcon: Icon(Icons.directions_walk, size: 20),
                                ),
                                dropdownColor: AppTheme.surfaceNavy,
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Right',
                                    child: Text('Right (Chân phải)', overflow: TextOverflow.ellipsis),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Left',
                                    child: Text('Left (Chân trái)', overflow: TextOverflow.ellipsis),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Both',
                                    child: Text('Both (Hai chân)', overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedFoot = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Trạng thái sức khỏe / tham gia đội hình
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedStatus,
                                isExpanded: true,
                                decoration: const InputDecoration(
                                  labelText: 'Trạng thái đội hình',
                                  prefixIcon: Icon(Icons.health_and_safety_outlined, size: 20),
                                ),
                                dropdownColor: AppTheme.surfaceNavy,
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'Active',
                                    child: Text('Active (Sẵn sàng)', overflow: TextOverflow.ellipsis),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Injured',
                                    child: Text('Injured (Chấn thương)', overflow: TextOverflow.ellipsis),
                                  ),
                                  DropdownMenuItem(
                                    value: 'On Duty',
                                    child: Text('On Duty (Nghĩa vụ)', overflow: TextOverflow.ellipsis),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Loaned',
                                    child: Text('Loaned (Cho mượn)', overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedStatus = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ----------------------------------------------------
                        // DÒNG 5: NGÀY SINH & HẠN HỢP ĐỒNG (BỘ CHỌN LỊCH)
                        // ----------------------------------------------------
                        Row(
                          children: [
                            // Ngày sinh
                            Expanded(
                              child: TextFormField(
                                controller: _dobController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Ngày sinh (DOB)',
                                  prefixIcon: const Icon(Icons.cake_outlined, size: 20),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today, size: 16),
                                    onPressed: () => _selectDate(_dobController),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                onTap: () => _selectDate(_dobController),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Hạn hợp đồng
                            Expanded(
                              child: TextFormField(
                                controller: _contractController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Hạn hợp đồng',
                                  prefixIcon: const Icon(Icons.history_edu, size: 20),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today, size: 16),
                                    onPressed: () => _selectDate(_contractController),
                                  ),
                                ),
                                style: const TextStyle(color: Colors.white),
                                onTap: () => _selectDate(_contractController),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // ----------------------------------------------------
                        // DÒNG 6: GIÁ TRỊ THỊ TRƯỜNG & NHÀ TÀI TRỢ CÁ NHÂN
                        // ----------------------------------------------------
                        Row(
                          children: [
                            // Định giá thị trường
                            Expanded(
                              child: TextFormField(
                                controller: _marketValueController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: const InputDecoration(
                                  labelText: 'Giá trị thị trường (€M) *',
                                  hintText: 'VD: 50',
                                  prefixIcon: Icon(Icons.euro, size: 20),
                                  suffixText: 'Triệu €',
                                ),
                                style: const TextStyle(color: Colors.white),
                                validator: (val) {
                                  if (val == null || val.trim().isEmpty) return 'Nhập giá trị';
                                  if (double.tryParse(val) == null) return 'Số hợp lệ';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Nhà tài trợ
                            Expanded(
                              child: TextFormField(
                                controller: _sponsorController,
                                decoration: const InputDecoration(
                                  labelText: 'Nhà tài trợ cá nhân',
                                  hintText: 'Adidas',
                                  prefixIcon: Icon(Icons.storefront, size: 20),
                                ),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(color: AppTheme.borderSubtle, height: 1),
              const SizedBox(height: 16),

              // --------------------------------------------------------------
              // 3. CÁC NÚT HÀNH ĐỘNG HỦY / LƯU BIỂU MẪU (ACTION BUTTONS)
              // --------------------------------------------------------------
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Nút Hủy
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Hủy bỏ', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  // Nút Lưu thay đổi hoặc Thêm vào đội hình
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEdit ? AppTheme.accentBlue : AppTheme.lfcRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 2,
                    ),
                    icon: Icon(isEdit ? Icons.save_outlined : Icons.add, size: 18),
                    label: Text(
                      isEdit ? 'Lưu thay đổi' : 'Thêm vào đội hình',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: _submitForm,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
