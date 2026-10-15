enum PlayerPosition { forward, midfielder, defender, goalkeeper }

class PlayerStatistic {
  final String date; // YYYY-MM
  final Map<String, double> attributes; // Dynamic based on position

  const PlayerStatistic({
    required this.date,
    required this.attributes,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'attributes': attributes,
  };

  factory PlayerStatistic.fromJson(Map<String, dynamic> json) => PlayerStatistic(
    date: json['date']?.toString() ?? '',
    attributes: json['attributes'] != null && json['attributes'] is Map
        ? Map<String, double>.from(
            (json['attributes'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
          )
        : {},
  );
}

class MarketValuePoint {
  final String date;
  final double valueInMillionsEuro;

  const MarketValuePoint({
    required this.date,
    required this.valueInMillionsEuro,
  });

  Map<String, dynamic> toJson() => {
    'date': date,
    'valueInMillionsEuro': valueInMillionsEuro,
  };

  factory MarketValuePoint.fromJson(Map<String, dynamic> json) => MarketValuePoint(
    date: json['date']?.toString() ?? '',
    valueInMillionsEuro: (json['valueInMillionsEuro'] as num?)?.toDouble() ?? 0.0,
  );
}

class PlayerMediaItem {
  final String id;
  final String title;
  final String type; // 'photo' | 'video' | 'interview' | 'campaign'
  final String url;
  final String date;

  const PlayerMediaItem({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'url': url,
    'date': date,
  };

  factory PlayerMediaItem.fromJson(Map<String, dynamic> json) => PlayerMediaItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    type: json['type']?.toString() ?? 'video',
    url: json['url']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
  );
}

class Player {
  final String id;
  final String name;
  final int number;
  final PlayerPosition position;
  final String nationality;
  final String dateOfBirth;
  final String preferredFoot;
  final String height;
  final String weight;
  final String contractUntil;
  final String avatarUrl;
  final double currentMarketValue; // in Millions Euro
  final double previousMarketValue;
  final String status; // 'Active', 'Injured', 'On Duty'
  final String sponsorPartner; // 'Adidas', etc.
  final List<PlayerStatistic> progressHistory;
  final List<MarketValuePoint> marketValueHistory;
  final List<PlayerMediaItem> mediaList;

  const Player({
    required this.id,
    required this.name,
    required this.number,
    required this.position,
    required this.nationality,
    required this.dateOfBirth,
    required this.preferredFoot,
    required this.height,
    required this.weight,
    required this.contractUntil,
    required this.avatarUrl,
    required this.currentMarketValue,
    required this.previousMarketValue,
    this.status = 'Active',
    this.sponsorPartner = 'Adidas',
    required this.progressHistory,
    required this.marketValueHistory,
    required this.mediaList,
  });

  String get positionName {
    switch (position) {
      case PlayerPosition.forward:
        return 'Forward (FW)';
      case PlayerPosition.midfielder:
        return 'Midfielder (MF)';
      case PlayerPosition.defender:
        return 'Defender (DF)';
      case PlayerPosition.goalkeeper:
        return 'Goalkeeper (GK)';
    }
  }

  // Get current / latest attributes
  Map<String, double> get latestAttributes {
    if (progressHistory.isEmpty) return {};
    return progressHistory.last.attributes;
  }

  double get marketValueChangePercent {
    if (previousMarketValue == 0) return 0.0;
    return ((currentMarketValue - previousMarketValue) / previousMarketValue) * 100;
  }

  Player copyWith({
    String? id,
    String? name,
    int? number,
    PlayerPosition? position,
    String? nationality,
    String? dateOfBirth,
    String? preferredFoot,
    String? height,
    String? weight,
    String? contractUntil,
    String? avatarUrl,
    double? currentMarketValue,
    double? previousMarketValue,
    String? status,
    String? sponsorPartner,
    List<PlayerStatistic>? progressHistory,
    List<MarketValuePoint>? marketValueHistory,
    List<PlayerMediaItem>? mediaList,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      number: number ?? this.number,
      position: position ?? this.position,
      nationality: nationality ?? this.nationality,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      preferredFoot: preferredFoot ?? this.preferredFoot,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      contractUntil: contractUntil ?? this.contractUntil,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      currentMarketValue: currentMarketValue ?? this.currentMarketValue,
      previousMarketValue: previousMarketValue ?? this.previousMarketValue,
      status: status ?? this.status,
      sponsorPartner: sponsorPartner ?? this.sponsorPartner,
      progressHistory: progressHistory ?? this.progressHistory,
      marketValueHistory: marketValueHistory ?? this.marketValueHistory,
      mediaList: mediaList ?? this.mediaList,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'number': number,
    'position': position.name,
    'nationality': nationality,
    'dateOfBirth': dateOfBirth,
    'preferredFoot': preferredFoot,
    'height': height,
    'weight': weight,
    'contractUntil': contractUntil,
    'avatarUrl': avatarUrl,
    'currentMarketValue': currentMarketValue,
    'previousMarketValue': previousMarketValue,
    'status': status,
    'sponsorPartner': sponsorPartner,
    'progressHistory': progressHistory.map((s) => s.toJson()).toList(),
    'marketValueHistory': marketValueHistory.map((m) => m.toJson()).toList(),
    'mediaList': mediaList.map((media) => media.toJson()).toList(),
  };

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      number: (json['number'] as num?)?.toInt() ?? 0,
      position: PlayerPosition.values.firstWhere(
        (e) => e.name == json['position'],
        orElse: () => PlayerPosition.forward,
      ),
      nationality: json['nationality']?.toString() ?? '',
      dateOfBirth: json['dateOfBirth']?.toString() ?? '',
      preferredFoot: json['preferredFoot']?.toString() ?? '',
      height: json['height']?.toString() ?? '',
      weight: json['weight']?.toString() ?? '',
      contractUntil: json['contractUntil']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString() ?? '',
      currentMarketValue: (json['currentMarketValue'] as num?)?.toDouble() ?? 0.0,
      previousMarketValue: (json['previousMarketValue'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'Active',
      sponsorPartner: json['sponsorPartner']?.toString() ?? 'Adidas',
      progressHistory: (json['progressHistory'] as List<dynamic>?)
              ?.map((e) => PlayerStatistic.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      marketValueHistory: (json['marketValueHistory'] as List<dynamic>?)
              ?.map((e) => MarketValuePoint.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      mediaList: (json['mediaList'] as List<dynamic>?)
              ?.map((e) => PlayerMediaItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
