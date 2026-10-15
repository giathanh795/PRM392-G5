class TrainingSession {
  final String id;
  final String title;
  final String date; // YYYY-MM-DD
  final String startTime;
  final String endTime;
  final String type; // 'Gym', 'Tactical', 'Recovery', 'Match Prep'
  final String location;
  final String coach;
  final String description;
  final String status; // 'Upcoming', 'Completed', 'In Progress'
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
    this.playerIds = const [],
  });
}
