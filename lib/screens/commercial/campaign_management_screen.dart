import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/sponsor_campaign.dart';
import '../../providers/app_state_provider.dart';
import 'commercial_api_notice.dart';

class CampaignManagementScreen extends StatelessWidget {
  const CampaignManagementScreen({super.key});

  Future<void> _editCampaign(
    BuildContext context, {
    SponsorCampaign? campaign,
  }) async {
    final controllers = _CampaignFormControllers(campaign);
    try {
      await showDialog<void>(
        context: context,
        builder: (_) =>
            _CampaignFormDialog(campaign: campaign, controllers: controllers),
      );
    } finally {
      controllers.dispose();
    }
  }

  Future<void> _deleteCampaign(
    BuildContext context,
    SponsorCampaign campaign,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa chiến dịch?'),
        content: Text('Bạn có chắc muốn xóa “${campaign.name}”?'),
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
        await context.read<AppStateProvider>().deleteCampaign(campaign.id);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể xóa chiến dịch: $error')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppStateProvider>();
    final campaigns = provider.campaigns;
    return Scaffold(
      appBar: AppBar(title: const Text('Campaign management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _editCampaign(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm chiến dịch'),
      ),
      body: Column(
        children: [
          CommercialApiNotice(
            error: provider.campaignsError,
            isLoading: provider.campaignsLoading,
            onRetry: provider.reloadCommercialData,
          ),
          Expanded(
            child: provider.campaignsLoading && campaigns.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : campaigns.isEmpty
                ? const Center(
                    child: Text(
                      'Chưa có chiến dịch. Hãy tạo chiến dịch mới.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                    itemCount: campaigns.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final campaign = campaigns[index];
                      return Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      campaign.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusBadge(status: campaign.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${campaign.sponsorName} • ${campaign.category}',
                                style: const TextStyle(
                                  color: AppTheme.accentCyan,
                                  fontSize: 12,
                                ),
                              ),
                              if (campaign.description.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  campaign.description,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 14,
                                runSpacing: 8,
                                children: [
                                  _detail(
                                    Icons.calendar_month_outlined,
                                    '${campaign.startDate} – ${campaign.endDate}',
                                  ),
                                  _detail(
                                    Icons.payments_outlined,
                                    '€${campaign.budgetMillions}M',
                                  ),
                                  if (campaign.reach.isNotEmpty)
                                    _detail(
                                      Icons.visibility_outlined,
                                      'Reach ${campaign.reach}',
                                    ),
                                  if (campaign.engagement.isNotEmpty)
                                    _detail(
                                      Icons.thumb_up_alt_outlined,
                                      'Engagement ${campaign.engagement}',
                                    ),
                                ],
                              ),
                              if (campaign.featuredPlayerNames.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: campaign.featuredPlayerNames
                                      .map(
                                        (player) => Chip(
                                          visualDensity: VisualDensity.compact,
                                          label: Text(player),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              const Divider(color: AppTheme.borderSubtle),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () => _editCampaign(
                                      context,
                                      campaign: campaign,
                                    ),
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                    label: const Text('Sửa'),
                                  ),
                                  TextButton.icon(
                                    onPressed: () =>
                                        _deleteCampaign(context, campaign),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.danger,
                                    ),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      size: 18,
                                    ),
                                    label: const Text('Xóa'),
                                  ),
                                ],
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
              ? (value) => value == null || value.trim().isEmpty
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
      validator: (value) => value == null || value.isEmpty ? 'Chọn ngày' : null,
      onTap: () async {
        final initial = DateTime.tryParse(controller.text) ?? DateTime.now();
        final date = await showDatePicker(
          context: context,
          initialDate: initial,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (date != null && context.mounted) {
          controller.text =
              '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}';
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
}

class _CampaignFormControllers {
  _CampaignFormControllers(SponsorCampaign? campaign)
    : name = TextEditingController(text: campaign?.name ?? ''),
      sponsor = TextEditingController(text: campaign?.sponsorName ?? ''),
      description = TextEditingController(text: campaign?.description ?? ''),
      reach = TextEditingController(text: campaign?.reach ?? ''),
      engagement = TextEditingController(text: campaign?.engagement ?? ''),
      budget = TextEditingController(
        text: (campaign?.budgetMillions ?? 1.5).toString(),
      ),
      startDate = TextEditingController(text: campaign?.startDate ?? ''),
      endDate = TextEditingController(text: campaign?.endDate ?? '');

  final TextEditingController name;
  final TextEditingController sponsor;
  final TextEditingController description;
  final TextEditingController reach;
  final TextEditingController engagement;
  final TextEditingController budget;
  final TextEditingController startDate;
  final TextEditingController endDate;

  void dispose() {
    name.dispose();
    sponsor.dispose();
    description.dispose();
    reach.dispose();
    engagement.dispose();
    budget.dispose();
    startDate.dispose();
    endDate.dispose();
  }
}

class _CampaignFormDialog extends StatefulWidget {
  const _CampaignFormDialog({required this.controllers, this.campaign});

  final _CampaignFormControllers controllers;
  final SponsorCampaign? campaign;

  @override
  State<_CampaignFormDialog> createState() => _CampaignFormDialogState();
}

class _CampaignFormDialogState extends State<_CampaignFormDialog> {
  static const _categories = [
    'Footwear',
    'Apparel',
    'Digital Content',
    'Community',
  ];

  final _formKey = GlobalKey<FormState>();
  late final Set<String> _featuredPlayers;
  late String _status;
  late String _category;
  bool _isSaving = false;

  TextEditingController get _name => widget.controllers.name;
  TextEditingController get _sponsor => widget.controllers.sponsor;
  TextEditingController get _description => widget.controllers.description;
  TextEditingController get _reach => widget.controllers.reach;
  TextEditingController get _engagement => widget.controllers.engagement;
  TextEditingController get _budget => widget.controllers.budget;
  TextEditingController get _startDate => widget.controllers.startDate;
  TextEditingController get _endDate => widget.controllers.endDate;

  @override
  void initState() {
    super.initState();
    final campaign = widget.campaign;
    _featuredPlayers = {...?campaign?.featuredPlayerNames};
    _status = campaign?.status ?? 'Upcoming';
    _category = _categories.contains(campaign?.category)
        ? campaign!.category
        : _categories.first;
  }

  Future<void> _save() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    final start = _startDate.text.trim();
    final end = _endDate.text.trim();
    final parsedStart = DateTime.tryParse(start);
    final parsedEnd = DateTime.tryParse(end);
    final messenger = ScaffoldMessenger.maybeOf(context);

    if (parsedStart == null || parsedEnd == null) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngày hợp lệ.')),
      );
      return;
    }
    if (parsedEnd.isBefore(parsedStart)) {
      messenger?.showSnackBar(
        const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu.')),
      );
      return;
    }

    final campaign = widget.campaign;
    final item = SponsorCampaign(
      id: campaign?.id ?? 'camp_${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      sponsorName: _sponsor.text.trim(),
      startDate: start,
      endDate: end,
      status: _status,
      reach: _reach.text.trim(),
      engagement: _engagement.text.trim(),
      description: _description.text.trim(),
      category: _category,
      budgetMillions: double.tryParse(_budget.text.trim()) ?? 0,
      featuredPlayerNames: _featuredPlayers.toList(),
    );
    final provider = context.read<AppStateProvider>();

    setState(() => _isSaving = true);
    try {
      if (campaign == null) {
        await provider.addCampaign(item);
      } else {
        await provider.updateCampaign(item);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      messenger?.showSnackBar(
        SnackBar(content: Text('Không thể lưu chiến dịch: $error')),
      );
      return;
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final campaign = widget.campaign;
    final players = context.read<AppStateProvider>().players;

    return AlertDialog(
      backgroundColor: AppTheme.surfaceNavy,
      title: Text(campaign == null ? 'Tạo chiến dịch' : 'Sửa chiến dịch'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CampaignManagementScreen._input(
                  _name,
                  'Tên chiến dịch',
                  required: true,
                ),
                const SizedBox(height: 10),
                CampaignManagementScreen._input(
                  _sponsor,
                  'Nhà tài trợ',
                  required: true,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  items: _categories
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _category = value);
                          }
                        },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Trạng thái'),
                  items: const ['Upcoming', 'Active', 'Completed', 'Paused']
                      .map(
                        (item) =>
                            DropdownMenuItem(value: item, child: Text(item)),
                      )
                      .toList(),
                  onChanged: _isSaving
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CampaignManagementScreen._dateInput(
                        context,
                        _startDate,
                        'Ngày bắt đầu',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CampaignManagementScreen._dateInput(
                        context,
                        _endDate,
                        'Ngày kết thúc',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CampaignManagementScreen._input(_reach, 'Reach'),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CampaignManagementScreen._input(
                        _engagement,
                        'Engagement',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CampaignManagementScreen._input(
                  _budget,
                  'Ngân sách (€M)',
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    if (double.tryParse(value.trim()) == null) {
                      return 'Nhập giá trị số hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                CampaignManagementScreen._input(
                  _description,
                  'Mô tả',
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Cầu thủ tham gia',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: players.map((player) {
                    return FilterChip(
                      label: Text(player.name),
                      selected: _featuredPlayers.contains(player.name),
                      onSelected: _isSaving
                          ? null
                          : (selected) {
                              setState(() {
                                if (selected) {
                                  _featuredPlayers.add(player.name);
                                } else {
                                  _featuredPlayers.remove(player.name);
                                }
                              });
                            },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu'),
        ),
      ],
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status.toLowerCase()) {
      'active' => AppTheme.success,
      'completed' => AppTheme.textSecondary,
      'paused' => AppTheme.warning,
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
