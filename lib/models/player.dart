// ============================================================================
// MÔ HÌNH DỮ LIỆU CẦU THỦ (PLAYER DATA MODEL)
// ============================================================================
// File này định nghĩa toàn bộ cấu trúc dữ liệu cho phân hệ Quản lý Cầu thủ:
// 1. PlayerPosition: Enum 4 vị trí thi đấu chính trên sân.
// 2. PlayerStatistic: Bản ghi chỉ số kỹ thuật của cầu thủ theo từng tháng.
// 3. MarketValuePoint: Mốc giá trị thị trường phục vụ vẽ biểu đồ chuyển nhượng.
// 4. PlayerMediaItem: Tư liệu truyền thông PR, video phỏng vấn, ảnh chụp.
// 5. Player: Lớp thực thể chính chứa đầy đủ thông tin cá nhân, chỉ số, hợp đồng,
//    các hàm chuyển đổi JSON và hỗ trợ cập nhật dữ liệu bất biến (copyWith).
// ============================================================================

/// Vị trí thi đấu của cầu thủ trên sân
enum PlayerPosition {
  /// Tiền đạo (Forward / Tiền đạo cánh, cắm)
  forward,

  /// Tiền vệ (Midfielder / Trung tâm, phòng ngự, tấn công)
  midfielder,

  /// Hậu vệ (Defender / Trung vệ, hậu vệ biên)
  defender,

  /// Thủ môn (Goalkeeper)
  goalkeeper,
}

/// Thống kê chỉ số kỹ năng của cầu thủ theo từng mốc thời gian
class PlayerStatistic {
  /// Thời điểm ghi nhận chỉ số (định dạng YYYY-MM hoặc tên tháng ví dụ: 'Oct', 'Nov')
  final String date;

  /// Bộ thuộc tính kỹ năng động tương ứng với vị trí thi đấu (ví dụ: Tốc độ, Dứt điểm, Chuyền bóng...)
  final Map<String, double> attributes;

  const PlayerStatistic({
    required this.date,
    required this.attributes,
  });

  /// Chuyển đổi dữ liệu thống kê thành dạng Map (JSON) để lưu trữ
  Map<String, dynamic> toJson() => {
    'date': date,
    'attributes': attributes,
  };

  /// Khởi tạo đối tượng thống kê từ dữ liệu Map (JSON) giải mã từ SharedPreferences
  factory PlayerStatistic.fromJson(Map<String, dynamic> json) => PlayerStatistic(
    date: json['date']?.toString() ?? '',
    attributes: json['attributes'] != null && json['attributes'] is Map
        ? Map<String, double>.from(
            (json['attributes'] as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
          )
        : {},
  );
}

/// Điểm mốc biến động giá trị thị trường của cầu thủ (phục vụ biểu đồ tài chính)
class MarketValuePoint {
  /// Mốc thời gian ghi nhận biến động giá (Ví dụ: 'Jan 2025', 'Now')
  final String date;

  /// Giá trị thị trường ước tính tại thời điểm đó (Đơn vị: Triệu Euro - M€)
  final double valueInMillionsEuro;

  const MarketValuePoint({
    required this.date,
    required this.valueInMillionsEuro,
  });

  /// Chuyển đổi thành Map (JSON) để lưu trữ bền vững
  Map<String, dynamic> toJson() => {
    'date': date,
    'valueInMillionsEuro': valueInMillionsEuro,
  };

  /// Khởi tạo điểm mốc giá trị thị trường từ Map (JSON)
  factory MarketValuePoint.fromJson(Map<String, dynamic> json) => MarketValuePoint(
    date: json['date']?.toString() ?? '',
    valueInMillionsEuro: (json['valueInMillionsEuro'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Mục tư liệu truyền thông hoặc Video PR của cầu thủ
class PlayerMediaItem {
  /// Mã định danh duy nhất của mục tư liệu (ví dụ: m_1730000000)
  final String id;

  /// Tiêu đề bài viết / video / chiến dịch truyền thông
  final String title;

  /// Phân loại tư liệu: 'video' (clip PR), 'photo' (ảnh chụp), 'interview' (phỏng vấn), 'campaign' (chiến dịch)
  final String type;

  /// Đường dẫn tệp nội bộ trên thiết bị, chuỗi Base64 Data URI hoặc đường link mạng (URL/YouTube)
  final String url;

  /// Ngày phát hành tư liệu truyền thông (YYYY-MM-DD)
  final String date;

  const PlayerMediaItem({
    required this.id,
    required this.title,
    required this.type,
    required this.url,
    required this.date,
  });

  /// Chuyển đổi tư liệu truyền thông thành Map (JSON)
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'type': type,
    'url': url,
    'date': date,
  };

  /// Khởi tạo tư liệu truyền thông từ Map (JSON)
  factory PlayerMediaItem.fromJson(Map<String, dynamic> json) => PlayerMediaItem(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    type: json['type']?.toString() ?? 'video',
    url: json['url']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
  );
}

/// Thực thể Cầu thủ đại diện cho một cầu thủ trong đội hình Liverpool FC
class Player {
  /// Mã định danh duy nhất (UUID hoặc chuỗi định dạng p_timestamp)
  final String id;

  /// Họ và tên cầu thủ (Ví dụ: Mohamed Salah, Virgil van Dijk)
  final String name;

  /// Số áo thi đấu chính thức (Ví dụ: 11, 4, 1)
  final int number;

  /// Tuyến vị trí thi đấu (Tiền đạo, Tiền vệ, Hậu vệ, Thủ môn)
  final PlayerPosition position;

  /// Quốc tịch của cầu thủ (Ví dụ: Egypt, Netherlands, England)
  final String nationality;

  /// Ngày tháng năm sinh (Định dạng: YYYY-MM-DD)
  final String dateOfBirth;

  /// Chân thuận (Ví dụ: 'Left', 'Right', 'Both')
  final String preferredFoot;

  /// Chiều cao cầu thủ (Đơn vị: '185 cm')
  final String height;

  /// Cân nặng cầu thủ (Đơn vị: '78 kg')
  final String weight;

  /// Thời hạn hợp đồng hiện tại với câu lạc bộ (Định dạng: YYYY-MM-DD)
  final String contractUntil;

  /// Đường dẫn ảnh đại diện (Có thể là link web, Base64 Data URI hoặc tệp máy)
  final String avatarUrl;

  /// Giá trị chuyển nhượng thị trường hiện tại (Đơn vị: Triệu Euro - M€)
  final double currentMarketValue;

  /// Giá trị chuyển nhượng thị trường ở kỳ cập nhật liền kề trước đó
  final double previousMarketValue;

  /// Trạng thái thi đấu hiện tại ('Active': Sẵn sàng, 'Injured': Chấn thương, 'On Duty': Nghĩa vụ quốc gia)
  final String status;

  /// Đối tác / Nhà tài trợ đồ thể thao cá nhân (Ví dụ: Adidas, Nike, Puma...)
  final String sponsorPartner;

  /// Lịch sử tiến trình phát triển chỉ số kỹ năng qua từng giai đoạn
  final List<PlayerStatistic> progressHistory;

  /// Lịch sử các mốc biến động giá trị thị trường để dựng biểu đồ đường
  final List<MarketValuePoint> marketValueHistory;

  /// Danh sách các tư liệu truyền thông PR và video highlight của cầu thủ
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

  /// Tên vị trí hiển thị đầy đủ kèm mã viết tắt quốc tế
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

  /// Điểm chỉ số tổng quát (Overall Rating OVR) tính trung bình từ các chỉ số kỹ năng mới nhất
  int get overallRating {
    if (progressHistory.isEmpty || latestAttributes.isEmpty) return 82;
    final vals = latestAttributes.values;
    if (vals.isEmpty) return 82;
    final avg = vals.reduce((a, b) => a + b) / vals.length;
    return avg.round();
  }

  /// Thuộc tính kỹ thuật viết tắt trả về latestAttributes
  Map<String, double> get attributes => latestAttributes;

  /// Lấy bản ghi chỉ số kỹ năng mới nhất của cầu thủ (phục vụ hiển thị biểu đồ Radar / Thanh tiến trình)
  Map<String, double> get latestAttributes {
    if (progressHistory.isEmpty) return {};
    return progressHistory.last.attributes;
  }

  /// Tính tỷ lệ phần trăm thay đổi giá trị thị trường so với mốc trước (+% hoặc -%)
  double get marketValueChangePercent {
    if (previousMarketValue == 0) return 0.0;
    return ((currentMarketValue - previousMarketValue) / previousMarketValue) * 100;
  }

  /// Phương thức sao chép và cập nhật dữ liệu (Immutable Pattern)
  /// Cho phép tạo ra một đối tượng Player mới với một số trường thay đổi mà vẫn giữ nguyên các trường còn lại.
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

  /// Tuần tự hóa (Serialize) đối tượng Player thành định dạng Map (JSON) để lưu xuống SharedPreferences
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

  /// Giải mã (Deserialize) đối tượng Player từ cấu trúc Map (JSON) đọc từ SharedPreferences
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
