class SponsorCampaign {
  final String id;
  final String name;
  final String sponsorName; // e.g. Adidas
  final String startDate;
  final String endDate;
  final String status; // 'Active', 'Completed', 'Upcoming'
  final String reach; // e.g. '4.2M'
  final String engagement; // e.g. '11.1%'
  final String description;
  final String category; // 'Footwear', 'Apparel', 'Digital Content', 'Community'
  final double budgetMillions; // e.g. 2.5
  final List<String> featuredPlayerNames;

  const SponsorCampaign({
    required this.id,
    required this.name,
    this.sponsorName = 'Adidas',
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.reach,
    required this.engagement,
    required this.description,
    this.category = 'Footwear',
    this.budgetMillions = 1.5,
    required this.featuredPlayerNames,
  });

  SponsorCampaign copyWith({
    String? id,
    String? name,
    String? sponsorName,
    String? startDate,
    String? endDate,
    String? status,
    String? reach,
    String? engagement,
    String? description,
    String? category,
    double? budgetMillions,
    List<String>? featuredPlayerNames,
  }) {
    return SponsorCampaign(
      id: id ?? this.id,
      name: name ?? this.name,
      sponsorName: sponsorName ?? this.sponsorName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      reach: reach ?? this.reach,
      engagement: engagement ?? this.engagement,
      description: description ?? this.description,
      category: category ?? this.category,
      budgetMillions: budgetMillions ?? this.budgetMillions,
      featuredPlayerNames: featuredPlayerNames ?? this.featuredPlayerNames,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sponsorName': sponsorName,
    'startDate': startDate,
    'endDate': endDate,
    'status': status,
    'reach': reach,
    'engagement': engagement,
    'description': description,
    'category': category,
    'budgetMillions': budgetMillions,
    'featuredPlayerNames': featuredPlayerNames,
  };

  factory SponsorCampaign.fromJson(Map<String, dynamic> json) => SponsorCampaign(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    sponsorName: json['sponsorName']?.toString() ?? 'Adidas',
    startDate: json['startDate']?.toString() ?? '',
    endDate: json['endDate']?.toString() ?? '',
    status: json['status']?.toString() ?? 'Active',
    reach: json['reach']?.toString() ?? '1.0M',
    engagement: json['engagement']?.toString() ?? '5.0%',
    description: json['description']?.toString() ?? '',
    category: json['category']?.toString() ?? 'Footwear',
    budgetMillions: (json['budgetMillions'] as num?)?.toDouble() ?? 1.0,
    featuredPlayerNames: (json['featuredPlayerNames'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
  );
}
