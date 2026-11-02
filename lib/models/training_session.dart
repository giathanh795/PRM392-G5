class TrainingSession {
  final String id;
  final String title;
  final String date; // YYYY-MM-DD
  final String startTime;
  final String endTime;
  final String type; // 'Gym', 'Tactical', 'Recovery', 'Match Prep', 'Set-Piece'
  final String location;
  final String coach;
  final String description;
  final String status; // 'Upcoming', 'Completed', 'In Progress'
  final String intensity; // 'Light', 'Moderate', 'High Intensity'
  final List<String> playerIds;

  const TrainingSession({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.location,
    required this.coach,
    required this.description,
    this.status = 'Upcoming',
    this.intensity = 'Moderate',
    this.playerIds = const [],
  });

  TrainingSession copyWith({
    String? id,
    String? title,
    String? date,
    String? startTime,
    String? endTime,
    String? type,
    String? location,
    String? coach,
    String? description,
    String? status,
    String? intensity,
    List<String>? playerIds,
  }) {
    return TrainingSession(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      type: type ?? this.type,
      location: location ?? this.location,
      coach: coach ?? this.coach,
      description: description ?? this.description,
      status: status ?? this.status,
      intensity: intensity ?? this.intensity,
      playerIds: playerIds ?? this.playerIds,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
    'type': type,
    'location': location,
    'coach': coach,
    'description': description,
    'status': status,
    'intensity': intensity,
    'playerIds': playerIds,
  };

  factory TrainingSession.fromJson(Map<String, dynamic> json) => TrainingSession(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    startTime: json['startTime']?.toString() ?? '',
    endTime: json['endTime']?.toString() ?? '',
    type: json['type']?.toString() ?? 'Tactical',
    location: json['location']?.toString() ?? 'AXA Training Ground',
    coach: json['coach']?.toString() ?? 'Andoni Iraola',
    description: json['description']?.toString() ?? '',
    status: json['status']?.toString() ?? 'Upcoming',
    intensity: json['intensity']?.toString() ?? 'Moderate',
    playerIds: (json['playerIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
  );
}
