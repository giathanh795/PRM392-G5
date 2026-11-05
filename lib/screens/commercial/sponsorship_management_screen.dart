import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../models/sponsorship.dart';
import '../../providers/app_state_provider.dart';
import '../../services/api_service.dart';
import 'commercial_api_notice.dart';

class SponsorshipManagementScreen extends StatelessWidget {
  const SponsorshipManagementScreen({super.key});

  Future<void> _editSponsorship(
    BuildContext context, {
    Sponsorship? sponsorship,
  }) async {
    final formKey = GlobalKey<FormState>();
    final id = TextEditingController(
      text:
          sponsorship?.id ?? 'sponsor_${DateTime.now().microsecondsSinceEpoch}',
    );
    final name = TextEditingController(text: sponsorship?.name ?? '');
    final description = TextEditingController(
      text: sponsorship?.description ?? '',
    );
    final value = TextEditingController(
      text: sponsorship == null ? '' : sponsorship.value.toString(),
    );
    final startDate = TextEditingController(text: sponsorship?.startDate ?? '');
    final endDate = TextEditingController(text: sponsorship?.endDate ?? '');
    final phone = TextEditingController(text: sponsorship?.phone ?? '');
    final email = TextEditingController(text: sponsorship?.email ?? '');
    final contactPerson = TextEditingController(
      text: sponsorship?.contactPerson ?? '',
    );
    var logo = sponsorship?.logo ?? '';
    final logoUrl = TextEditingController(
      text: logo.startsWith('data:image') ? '' : logo,
    );
    var contractFileName = sponsorship?.contractFileName ?? '';
    var contractFileData = sponsorship?.contractFileData ?? '';
    var removeContract = false;
    const statuses = ['Active', 'Pending', 'Inactive', 'Expired'];
    var status = statuses.contains(sponsorship?.status)
        ? sponsorship!.status
        : 'Active';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogStateContext, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceNavy,
          title: Text(
            sponsorship == null ? 'Thêm nhà tài trợ' : 'Sửa nhà tài trợ',
          ),
          content: SizedBox(
            width: 520,
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: id,
                      readOnly: true,
                      decoration: const InputDecoration(labelText: 'ID'),
                    ),
                    const SizedBox(height: 10),
                    _input(name, 'Tên nhà tài trợ', required: true),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _LogoPreview(logo: logo, size: 54),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              try {
                                final image = await ImagePicker().pickImage(
                                  source: ImageSource.gallery,
                                  maxWidth: 500,
                                  maxHeight: 500,
                                  imageQuality: 80,
                                );
                                if (image == null) return;
                                final bytes = await image.readAsBytes();
                                final mimeType =
                                    image.name.toLowerCase().endsWith('.png')
                                    ? 'image/png'
                                    : 'image/jpeg';
                                setDialogState(() {
                                  logo =
                                      'data:$mimeType;base64,${base64Encode(bytes)}';
                                  logoUrl.clear();
                                });
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Không thể chọn logo: $error',
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Chọn logo'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: logoUrl,
                      decoration: const InputDecoration(
                        labelText: 'Hoặc nhập URL logo',
                      ),
                      onChanged: (input) => logo = input.trim(),
                    ),
                    if (logo.isNotEmpty && logo.startsWith('data:image')) ...[
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => setDialogState(() => logo = ''),
                          child: const Text('Xóa logo đã chọn'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _input(description, 'Mô tả', maxLines: 3),
                    const SizedBox(height: 10),
                    _input(
                      value,
                      'Giá trị hợp đồng',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (input) {
                        if (input == null || input.trim().isEmpty) {
                          return 'Vui lòng nhập giá trị hợp đồng';
                        }
                        final amount = double.tryParse(input.trim());
                        return amount == null || amount < 0
                            ? 'Nhập giá trị không âm hợp lệ'
                            : null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _dateInput(context, startDate, 'Ngày bắt đầu'),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _dateInput(context, endDate, 'Ngày kết thúc'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        labelText: 'Trạng thái',
                      ),
                      items: statuses
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(item),
                            ),
                          )
                          .toList(),
                      onChanged: (selected) {
                        if (selected != null) {
                          setDialogState(() => status = selected);
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    _input(
                      phone,
                      'Số điện thoại',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 10),
                    _input(
                      email,
                      'Email',
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 10),
                    _input(contactPerson, 'Người liên hệ'),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        try {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: const ['pdf', 'doc', 'docx'],
                            withData: true,
                          );
                          if (result == null) return;
                          final file = result.files.single;
                          if (file.size > 2 * 1024 * 1024) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Tệp hợp đồng tối đa 2 MB.'),
                                ),
                              );
                            }
                            return;
                          }
                          final bytes = file.bytes;
                          if (bytes == null) {
                            throw Exception('Không đọc được nội dung tệp.');
                          }
                          setDialogState(() {
                            contractFileName = file.name;
                            contractFileData = base64Encode(bytes);
                            removeContract = false;
                          });
                        } catch (error) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Không thể chọn hợp đồng: $error',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.attach_file),
                      label: Text(
                        contractFileName.isEmpty
                            ? 'Chọn hợp đồng (PDF, DOC, DOCX)'
                            : contractFileName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (contractFileName.isNotEmpty)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setDialogState(() {
                              contractFileName = '';
                              contractFileData = '';
                              removeContract = true;
                            });
                          },
                          child: const Text('Gỡ tệp'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final start = startDate.text.trim();
                final end = endDate.text.trim();
                final parsedStart = DateTime.tryParse(start);
                final parsedEnd = DateTime.tryParse(end);
                if (parsedStart == null || parsedEnd == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Vui lòng chọn ngày hợp lệ.')),
                  );
                  return;
                }
                if (parsedEnd.isBefore(parsedStart)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Ngày kết thúc phải sau ngày bắt đầu.'),
                    ),
                  );
                  return;
                }
                final item = Sponsorship(
                  id: id.text,
                  name: name.text.trim(),
                  logo: logo,
                  description: description.text.trim(),
                  contractFileName: contractFileName,
                  contractFileData: contractFileData,
                  removeContract: removeContract,
                  value: double.parse(value.text.trim()),
                  startDate: start,
                  endDate: end,
                  status: status,
                  phone: phone.text.trim(),
                  email: email.text.trim(),
                  contactPerson: contactPerson.text.trim(),
                );
                Navigator.pop(dialogContext);
                final provider = context.read<AppStateProvider>();
                if (sponsorship == null) {
                  await provider.addSponsorship(item);
                } else {
                  await provider.updateSponsorship(item);
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(sponsorship == null
                          ? 'Đã thêm nhà tài trợ "${item.name}"'
                          : 'Đã cập nhật nhà tài trợ "${item.name}"'),
                    ),
                  );
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
    id.dispose();
    name.dispose();
    description.dispose();
    value.dispose();
    startDate.dispose();
    endDate.dispose();
    phone.dispose();
    email.dispose();
    contactPerson.dispose();
    logoUrl.dispose();
  }

  Future<void> _deleteSponsorship(
    BuildContext context,
    Sponsorship sponsorship,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa nhà tài trợ?'),
        content: Text('Bạn có chắc muốn xóa “${sponsorship.name}”?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      try {
        await context.read<AppStateProvider>().deleteSponsorship(
          sponsorship.id,
        );
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể xóa nhà tài trợ: $error')),
          );
        }
      }
    }
  }

  Future<void> _openContract(
    BuildContext context,
    Sponsorship sponsorship,
  ) async {
    final uri = Uri.parse(ApiService.sponsorshipContractUrl(sponsorship.id));
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.platformDefault,
        webOnlyWindowName: '_blank',
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở tệp hợp đồng.')),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở tệp hợp đồng: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final sponsorships = provider.sponsorships;
    return Scaffold(
      appBar: AppBar(title: const Text('Sponsorship management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editSponsorship(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm nhà tài trợ'),
      ),
      body: Column(
        children: [
          CommercialApiNotice(
            error: provider.sponsorshipsError,
            isLoading: provider.sponsorshipsLoading,
            onRetry: provider.reloadCommercialData,
          ),
          Expanded(
            child: provider.sponsorshipsLoading && sponsorships.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : sponsorships.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có nhà tài trợ. Hãy thêm đối tác mới.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: sponsorships.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final sponsor = sponsorships[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _LogoPreview(logo: sponsor.logo, size: 58),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          sponsor.name,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'ID: ${sponsor.id}',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        _StatusBadge(status: sponsor.status),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Sửa nhà tài trợ',
                                    onPressed: () => _editSponsorship(
                                      context,
                                      sponsorship: sponsor,
                                    ),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      color: AppTheme.accentCyan,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Xóa nhà tài trợ',
                                    onPressed: () =>
                                        _deleteSponsorship(context, sponsor),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: AppTheme.danger,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(color: AppTheme.borderSubtle),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  sponsor.description.isEmpty
                                      ? 'Chưa có mô tả.'
                                      : sponsor.description,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 16,
                                runSpacing: 8,
                                children: [
                                  _detail(
                                    Icons.payments_outlined,
                                    _formatValue(sponsor.value),
                                  ),
                                  _detail(
                                    Icons.calendar_month_outlined,
                                    '${sponsor.startDate} – ${sponsor.endDate}',
                                  ),
                                  if (sponsor.phone.isNotEmpty)
                                    _detail(
                                      Icons.phone_outlined,
                                      sponsor.phone,
                                    ),
                                  if (sponsor.email.isNotEmpty)
                                    _detail(
                                      Icons.email_outlined,
                                      sponsor.email,
                                    ),
                                  if (sponsor.contactPerson.isNotEmpty)
                                    _detail(
                                      Icons.person_outline,
                                      sponsor.contactPerson,
                                    ),
                                ],
                              ),
                              if (sponsor.contractFileName.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Chip(
                                        avatar: const Icon(
                                          Icons.description_outlined,
                                          size: 17,
                                        ),
                                        label: Text(
                                          sponsor.contractFileName,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    TextButton.icon(
                                      onPressed: () =>
                                          _openContract(context, sponsor),
                                      icon: const Icon(
                                        Icons.download_outlined,
                                        size: 18,
                                      ),
                                      label: const Text('Tải hợp đồng'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static Widget _input(
    TextEditingController controller,
    String label, {
    bool required = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (required
              ? (input) => input == null || input.trim().isEmpty
                    ? 'Vui lòng nhập $label'
                    : null
              : null),
    );
  }

  static Widget _dateInput(
    BuildContext context,
    TextEditingController controller,
    String label,
  ) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
      ),
      validator: (input) => input == null || input.isEmpty ? 'Chọn ngày' : null,
      onTap: () async {
        final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
        final selected = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (selected != null) {
          controller.text =
              '${selected.year.toString().padLeft(4, '0')}-'
              '${selected.month.toString().padLeft(2, '0')}-'
              '${selected.day.toString().padLeft(2, '0')}';
        }
      },
    );
  }

  static Widget _detail(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppTheme.lfcYellow),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  static String _formatValue(double amount) {
    if (amount >= 1000000) {
      return '€${(amount / 1000000).toStringAsFixed(1)}M';
    }
    return '€${amount.toStringAsFixed(0)}';
  }
}

class _LogoPreview extends StatelessWidget {
  final String logo;
  final double size;

  const _LogoPreview({required this.logo, required this.size});

  @override
  Widget build(BuildContext context) {
    Widget image;
    if (logo.startsWith('data:image') && logo.contains(',')) {
      try {
        image = Image.memory(
          base64Decode(logo.substring(logo.indexOf(',') + 1)),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => _fallback(),
        );
      } on FormatException {
        image = _fallback();
      }
    } else if (logo.startsWith('http://') || logo.startsWith('https://')) {
      image = Image.network(
        logo,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _fallback(),
      );
    } else {
      image = _fallback();
    }
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(7), child: image),
    );
  }

  Widget _fallback() => const Center(
    child: Icon(Icons.storefront_outlined, color: AppTheme.textMuted),
  );
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'active' => AppTheme.success,
      'expired' || 'inactive' => AppTheme.textSecondary,
      'pending' => AppTheme.warning,
      _ => AppTheme.accentCyan,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
