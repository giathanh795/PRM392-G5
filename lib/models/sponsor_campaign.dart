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
    required this.featuredPlayerNames,
  });
}
