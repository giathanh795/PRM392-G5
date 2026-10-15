# Liverpool FC - Player Management & Commercial System (PMS)

Hệ thống quản lý cầu thủ & thương mại dành cho ban huấn luyện và ban quản lý của **Liverpool Football Club**, tích hợp quản lý đối tác thương mại **Adidas**.

## 📁 Cấu trúc thư mục chuẩn Flutter Project

```
lib/
├── core/
│   └── theme/
│       └── app_theme.dart          # Màu sắc chủ đạo (LFC Red, LFC Yellow, Adidas Dark) & ThemeData
├── data/
│   └── mock_data.dart              # Dữ liệu mẫu cầu thủ, thống kê, lịch tập & chiến dịch Adidas
├── models/
│   ├── player.dart                 # Entity Cầu thủ, Chỉ số (Statistic), Định giá (Market Value), Media
│   ├── training_session.dart       # Lịch & nội dung tập luyện theo ngày/tuần
│   └── sponsor_campaign.dart       # Chiến dịch tài trợ (Adidas Partnership & Campaigns)
├── providers/
│   └── app_state_provider.dart     # State Management (Provider) - tìm kiếm, lọc, CRUD cầu thủ & lịch tập
├── screens/
│   ├── auth/
│   │   └── login_screen.dart       # Màn hình đăng nhập Liverpool Staff & Ban quản lý
│   ├── dashboard/
│   │   └── dashboard_screen.dart   # Tổng quan đội bóng (KPIs, lịch hôm nay, định giá, nhà tài trợ)
│   ├── player/
│   │   ├── player_list_screen.dart # Danh sách cầu thủ, tìm kiếm theo tên/số áo, lọc theo vị trí
│   │   ├── player_detail_screen.dart # Hồ sơ chi tiết, hợp đồng, thể hình, media PR
│   │   └── player_stats_screen.dart  # Radar Chart theo vị trí & biểu đồ tiến bộ theo thời gian (Bật/tắt chỉ số)
│   ├── training/
│   │   └── training_schedule_screen.dart # Lịch tập theo tuần/ngày, phân loại Gym/Tactical/Recovery
│   ├── commercial/
│   │   └── commercial_screen.dart  # Định giá thị trường & Chiến dịch hợp tác thương mại Adidas
│   └── main_navigation_screen.dart # Điều hướng BottomNavigationBar chính của ứng dụng
├── widgets/
│   ├── custom_header_card.dart     # Widget tiêu đề thẻ tái sử dụng
│   ├── player_card_item.dart       # Card hiển thị cầu thủ với số áo, vị trí, giá trị
│   ├── radar_chart_widget.dart     # CustomPainter Radar Chart linh hoạt theo từng vị trí
│   └── stat_progress_bar.dart      # Thanh đo lường chỉ số năng lực
└── main.dart                       # Entry point ứng dụng, khởi tạo MultiProvider
```

## 🚀 Các điểm nổi bật đã hoàn thành trong khung ứng dụng
1. **Adaptive Position Metrics & Radar Chart**: Bộ chỉ số tự thích ứng theo 4 vị trí:
   - **Forward**: Pace, Shooting, Dribbling, Positioning, Passing, Physical
   - **Midfielder**: Passing, Vision, Dribbling, Ball Control, Defending, Stamina
   - **Defender**: Tackling, Interception, Heading, Positioning, Strength, Passing
   - **Goalkeeper**: Reflexes, Diving, Handling, Positioning, Kicking, One-on-one
2. **Progress Timeline với nút Bật/Tắt (Toggle Chips)**: Cho phép so sánh sự phát triển phong độ qua các tháng bằng `fl_chart`.
3. **Training & Calendar**: Lịch trình tập luyện trực quan theo ngày trong tuần, phân loại Gym, Chiến thuật, Hồi phục.
4. **Media & PR**: Danh mục hình ảnh, video phỏng vấn, chiến dịch PR của từng cầu thủ.
5. **Commercial Management & Adidas**: Định giá thị trường chuyển nhượng toàn đội + theo dõi hợp đồng và chiến dịch quảng bá chính thức với Adidas.

## 🛠 Hướng dẫn chạy trên Android Studio
1. Mở thư mục `C:\Users\Admin\OneDrive\Documents\ok\prm\project` bằng **Android Studio**.
2. Đảm bảo chạy `flutter pub get`.
3. Chọn thiết bị giả lập (Android Emulator) hoặc Chrome/Windows và nhấn **Run (Shift + F10)**.
