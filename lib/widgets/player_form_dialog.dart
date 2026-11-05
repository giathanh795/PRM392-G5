import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';
import '../data/mock_data.dart';
import '../models/player.dart';
import '../providers/app_state_provider.dart';
import 'player_avatar.dart';

/// ============================================================================
/// HỘP THOẠI BIỂU MẪU CẦU THỦ (PLAYER FORM DIALOG)
/// ============================================================================
/// Mục đích:
/// - Dùng chung cho cả 2 thao tác: THÊM MỚI (Create) và CHỈNH SỬA (Update) cầu thủ.
/// - Nhận vào tham số tùy chọn `player`:
///   + Nếu `player == null`: Chế độ THÊM MỚI -> khởi tạo giá trị mặc định.
///   + Nếu `player != null`: Chế độ SỬA -> nạp dữ liệu hiện có của cầu thủ vào form.
/// - Cho phép tải ảnh đại diện trực tiếp từ thiết bị (ImagePicker) và mã hóa
///   dưới dạng Base64 Data URI để lưu trữ offline không lo mất liên kết.
/// - Kiểm tra tính hợp lệ dữ liệu (Form validation) trước khi lưu.
/// - Tự động khởi tạo bộ chỉ số năng lực mặc định dựa theo vị trí thi đấu
///   (MockData.getAttributesForPosition) khi tạo cầu thủ mới.
/// - Ghi đè hoặc thêm mới vào AppStateProvider và đồng bộ SharedPreferences.
/// ============================================================================

Future<bool?> showPlayerFormDialog(BuildContext context, {Player? player}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) => PlayerFormDialog(player: player),
  );
}

class PlayerFormDialog extends StatefulWidget {
  final Player? player;

  const PlayerFormDialog({super.key, this.player});

  bool get isEdit => player != null;

  @override
  State<PlayerFormDialog> createState() => _PlayerFormDialogState();
}

class _PlayerFormDialogState extends State<PlayerFormDialog> {
  final _formKey = GlobalKey<FormState>();

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

  late PlayerPosition _selectedPosition;
  late String _selectedFoot;
  late String _selectedStatus;

  final ImagePicker _picker = ImagePicker();



  @override
  void initState() {
    super.initState();
    final p = widget.player;
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
    _avatarUrlController = TextEditingController(
      text: p?.avatarUrl ?? '',
    );

    _selectedPosition = p?.position ?? PlayerPosition.forward;
    _selectedFoot = p?.preferredFoot ?? 'Right';
    _selectedStatus = p?.status ?? 'Active';
  }

  @override
  void dispose() {
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

  /// LUỒNG CHỌN ẢNH TỪ THIẾT BỊ:
  /// 1. Mở thư viện ảnh (gallery) của máy qua plugin image_picker.
  /// 2. Đọc luồng byte của ảnh đã chọn và mã hóa thành chuỗi Base64 Data URI ('data:image/jpeg;base64,...').
  /// 3. Lưu vào _avatarUrlController để PlayerAvatar hiển thị ngay tức thì và lưu trữ vĩnh viễn.
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
  /// 1. Kiểm tra validation toàn bộ các trường nhập liệu (validate form).
  /// 2. Thu thập và chuẩn hóa dữ liệu từ các Controller và Dropdown.
  /// 3. Phân nhánh xử lý:
  ///    - NẾU LÀ CHỈNH SỬA (widget.isEdit == true):
  ///      + Sao chép dữ liệu cũ kèm thông tin mới qua phương thức copyWith.
  ///      + Cập nhật lịch sử biến động định giá (marketValueHistory) nếu giá thị trường thay đổi.
  ///      + Gọi AppStateProvider.updatePlayer(updated) để cập nhật danh sách và lưu SharedPreferences.
  ///    - NẾU LÀ THÊM MỚI (widget.isEdit == false):
  ///      + Tạo mã định danh duy nhất (id) theo thời gian thực (p_${timestamp}).
  ///      + Sinh bộ chỉ số kỹ năng ban đầu (82 điểm) phù hợp với vị trí thi đấu đã chọn.
  ///      + Khởi tạo đối tượng Player mới và gọi AppStateProvider.addPlayer(newPlayer).
  /// 4. Đóng hộp thoại và hiển thị SnackBar thông báo thành công.
  /// ==========================================================================
  void _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

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
      // Cập nhật cầu thủ đã có
      final oldPlayer = widget.player!;
      final double previousValue = (marketValue != oldPlayer.currentMarketValue)
          ? oldPlayer.currentMarketValue
          : oldPlayer.previousMarketValue;

      List<MarketValuePoint> updatedMarketHistory = List.from(oldPlayer.marketValueHistory);
      if (marketValue != oldPlayer.currentMarketValue) {
        updatedMarketHistory.add(MarketValuePoint(date: 'Now', valueInMillionsEuro: marketValue));
      }

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
      // Tạo mới cầu thủ
      final newId = 'p_${DateTime.now().millisecondsSinceEpoch}';
      final defaultAttrs = MockData.getAttributesForPosition(_selectedPosition);
      final Map<String, double> statsMap = {for (var attr in defaultAttrs) attr: 82.0};

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
              // Dialog Header
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

              // Scrollable Form Content
              Flexible(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceNavyLight,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.borderSubtle),
                          ),
                          child: Row(
                            children: [
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

                        // Row 1: Tên & Số áo
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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

                        // Row 2: Vị trí & Quốc tịch
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<PlayerPosition>(
                                initialValue: _selectedPosition,
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
                                  return DropdownMenuItem(value: pos, child: Text(label, style: const TextStyle(fontSize: 13)));
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedPosition = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
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

                        // Row 3: Chiều cao & Cân nặng
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

                        // Row 4: Chân thuận & Trạng thái thi đấu
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedFoot,
                                decoration: const InputDecoration(
                                  labelText: 'Chân thuận',
                                  prefixIcon: Icon(Icons.directions_walk, size: 20),
                                ),
                                dropdownColor: AppTheme.surfaceNavy,
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: 'Right', child: Text('Right (Chân phải)')),
                                  DropdownMenuItem(value: 'Left', child: Text('Left (Chân trái)')),
                                  DropdownMenuItem(value: 'Both', child: Text('Both (Hai chân)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedFoot = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _selectedStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Trạng thái đội hình',
                                  prefixIcon: Icon(Icons.health_and_safety_outlined, size: 20),
                                ),
                                dropdownColor: AppTheme.surfaceNavy,
                                style: const TextStyle(color: Colors.white),
                                items: const [
                                  DropdownMenuItem(value: 'Active', child: Text('Active (Sẵn sàng)')),
                                  DropdownMenuItem(value: 'Injured', child: Text('Injured (Chấn thương)')),
                                  DropdownMenuItem(value: 'On Duty', child: Text('On Duty (Nghỉ vụ)')),
                                  DropdownMenuItem(value: 'Loaned', child: Text('Loaned (Cho mượn)')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedStatus = val);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Row 5: Ngày sinh & Hạn hợp đồng
                        Row(
                          children: [
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

                        // Row 6: Giá thị trường & Nhà tài trợ
                        Row(
                          children: [
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

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Hủy bỏ', style: TextStyle(color: AppTheme.textSecondary)),
                  ),
                  const SizedBox(width: 12),
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
