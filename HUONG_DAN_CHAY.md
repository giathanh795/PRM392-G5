# HƯỚNG DẪN KẾT NỐI BACKEND (SPRING BOOT - INTELLIJ) & FRONTEND (FLUTTER - ANDROID STUDIO)

## Cấu trúc thư mục:
```
C:\Users\Admin\OneDrive\Documents\ok\prm2\
├── prm2-backend\   <-- Backend Spring Boot (Mở bằng IntelliJ IDEA)
└── project2\       <-- Frontend Flutter (Mở bằng Android Studio)
```

---

## 1. CÁCH MỞ VÀ CHẠY BACKEND TRÊN INTELLIJ IDEA:
1. Mở **IntelliJ IDEA**.
2. Chọn **Open** $\rightarrow$ Trỏ tới thư mục: `C:\Users\Admin\OneDrive\Documents\ok\prm2\prm2-backend`.
3. IntelliJ sẽ tự nhận diện project Maven (Java 17).
4. Tìm file: `src/main/java/com/liverpool/pms/Prm2BackendApplication.java`.
5. Bấm nút **Run (Tam giác xanh)** để chạy Backend.
   * Server sẽ khởi động tại: `http://localhost:8080`
   * Endpoint danh sách cầu thủ: `http://localhost:8080/api/players`
   * File dữ liệu lưu tự động tại: `prm2-backend/data/players.json`.

> **Mẹo chạy nhanh không cần mở IntelliJ:**
> Click đúp vào file `run-backend.bat` trong thư mục `prm2-backend` là server tự khởi động!

---

## 2. CÁCH CHẠY FRONTEND TRÊN ANDROID STUDIO:
1. Mở **Android Studio**.
2. Chọn **Open** $\rightarrow$ Trỏ tới thư mục: `C:\Users\Admin\OneDrive\Documents\ok\prm2\project2`.
3. Bấm **Run** app trên Chrome hoặc Android Emulator.

---

## 3. CƠ CHẾ HOẠT ĐỘNG (HYBRID CONNECTIVITY):
* Khi Backend chạy: App Flutter tự động kết nối API `http://localhost:8080/api/players` (hoặc `http://10.0.2.2:8080` trên Android Emulator).
* Khi bạn đổi ảnh, thêm video PR $\rightarrow$ App gửi API cập nhật thẳng vào file `data/players.json` của Backend.
* Khi thành viên khác clone repo về và bật Backend lên $\rightarrow$ Tất cả dữ liệu mới nhất bạn đã lưu sẽ hiển thị ngay lập tức!
* Nếu Backend tắt: App vẫn tự động fallback nạp từ bộ nhớ cục bộ để không bao giờ bị gián đoạn.
