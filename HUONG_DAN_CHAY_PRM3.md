# HƯỚNG DẪN CÀI ĐẶT & CHẠY DỰ ÁN LIVERPOOL PMS (PROJECT 3)
### Môn học: PRM392 - Lập trình Di động
### Cơ sở dữ liệu: Microsoft SQL Server (MSSQL) + Spring Boot JPA + Flutter
### Nhóm phát triển: Group 5 (Việt Long, Hùng, Huy, Gia Thành)

---

## 1. TỔNG QUAN KIẾN TRÚC HỆ THỐNG
Dự án **Liverpool Player Management System (PMS)** phiên bản `project3` là hệ sinh thái hoàn chỉnh kết hợp:
* **Frontend:** Flutter (Dart 3) đa nền tảng, 5 màn hình chính, Theme Sáng/Tối ở góc trên bên phải, Quản lý Profile cá nhân, Lưu ảnh Base64 offline/online.
* **Backend:** Spring Boot 3 (Java 17) REST API server, Spring Data JPA.
* **Database:** **Microsoft SQL Server (MSSQL)** với đầy đủ 5 bảng quan hệ chuẩn ANSI và file kịch bản SQL có sẵn `LiverpoolPMS_SqlServer.sql`.

---

## 2. HƯỚNG DẪN CÀI ĐẶT DATABASE MICROSOFT SQL SERVER

Nhóm đã tạo sẵn file script chuẩn: **`LiverpoolPMS_SqlServer.sql`** (đặt ở thư mục gốc `project3` và trong thư mục `backend`).

### Cách 1: Chạy file script bằng SQL Server Management Studio (SSMS) - (Khuyên Dùng khi nộp bài)
1. Mở phần mềm **SQL Server Management Studio (SSMS)** và đăng nhập vào máy chủ SQL Server của bạn.
2. Mở file: `C:\Users\Admin\OneDrive\Documents\ok\prm3\project3\LiverpoolPMS_SqlServer.sql`.
3. Bấm nút **Execute** (hoặc phím **F5**).
4. Hệ thống sẽ:
   - Tạo Database: `LiverpoolPMS`.
   - Tạo 5 bảng: `users`, `players`, `training_sessions`, `campaigns`, `sponsorships`.
   - Nạp sẵn toàn bộ dữ liệu mẫu (HLV Arne Slot, 25 cầu thủ, bài tập AXA, hợp đồng Adidas €75M,...).

### Cách 2: Để Spring Boot Hibernate tự động tạo bảng (Không cần chạy script dài)
1. Trong SSMS, mở cửa sổ New Query và gõ duy nhất 1 lệnh:
   ```sql
   CREATE DATABASE LiverpoolPMS;
   ```
2. Bấm **Execute**.
3. Khi bạn khởi động Backend, Hibernate sẽ tự động sinh toàn bộ bảng và `DataInitializer.java` tự nạp dữ liệu.

---

## 3. CẤU HÌNH KẾT NỐI TRONG BACKEND

Mở file: [`backend/src/main/resources/application.properties`](file:///C:/Users/Admin/OneDrive/Documents/ok/prm3/project3/backend/src/main/resources/application.properties)
Kiểm tra tài khoản và mật khẩu SQL Server của máy bạn:
```properties
spring.datasource.url=jdbc:sqlserver://localhost:1433;databaseName=LiverpoolPMS;encrypt=true;trustServerCertificate=true
spring.datasource.driverClassName=com.microsoft.sqlserver.jdbc.SQLServerDriver
spring.datasource.username=sa
spring.datasource.password=123456
```
> *(Nếu mật khẩu SQL Server trên máy bạn khác `123456`, hãy sửa lại dòng `spring.datasource.password=...` cho đúng với mật khẩu của bạn).*

---

## 4. HƯỚNG DẪN KHỞI CHẠY HỆ THỐNG

### Bước 1: Khởi động Backend (Spring Boot + SQL Server)
- Click đúp vào file [`run-backend.bat`](file:///C:/Users/Admin/OneDrive/Documents/ok/prm3/project3/backend/run-backend.bat) trong thư mục `backend`.  
- Hoặc mở PowerShell tại `project3/backend` và chạy lệnh:
  ```powershell
  mvn spring-boot:run
  ```
- Khi thấy dòng chữ:
  ```
  Started Application in X.XXX seconds
  ```
  -> Backend đã kết nối thành công vào Microsoft SQL Server tại cổng `8080`.

---

### Bước 2: Khởi chạy Ứng dụng Di động Flutter
- Click đúp vào file [`run-frontend.bat`](file:///C:/Users/Admin/OneDrive/Documents/ok/prm3/project3/run-frontend.bat) ở thư mục `project3`.  
- Hoặc mở PowerShell tại `project3` và chạy lệnh:
  ```powershell
  flutter run -d chrome
  ```
  *(Có thể chọn `-d windows` để chạy trên máy tính Windows hoặc chạy trên máy ảo Android).*

---

## 5. CÁC CÂU LỆNH SQL MẪU TRÌNH DIỄN CHO GIẢNG VIÊN TRÊN SSMS

Sau khi ứng dụng chạy hoặc sau khi thao tác thêm/sửa/xóa trên App di động, mở SSMS và chạy các câu lệnh sau để kiểm tra dữ liệu thực tế trong CSDL:

```sql
USE LiverpoolPMS;
GO

-- 1. Xem thông tin tài khoản HLV vừa chỉnh sửa trên Profile:
SELECT ID, USERNAME, FULL_NAME, ROLE, EMAIL, DEPARTMENT, UPDATED_AT FROM dbo.users;

-- 2. Xem danh sách cầu thủ xếp theo giá trị chuyển nhượng:
SELECT ID, NAME, JERSEY_NUMBER, POSITION, CURRENT_MARKET_VALUE, STATUS 
FROM dbo.players 
ORDER BY CURRENT_MARKET_VALUE DESC;

-- 3. Xem các buổi tập huấn luyện tại trung tâm AXA:
SELECT ID, TITLE, SESSION_DATE, START_TIME, TYPE, LOCATION, COACH FROM dbo.training_sessions;

-- 4. Xem danh mục đối tác và giá trị hợp đồng tài trợ (Trọng tâm Adidas):
SELECT ID, PARTNER_NAME, BRAND_CATEGORY, ANNUAL_VALUE, STATUS FROM dbo.sponsorships;

-- 5. Xem chiến dịch truyền thông:
SELECT ID, NAME, PARTNER, REACH, ENGAGEMENT, SPEND FROM dbo.campaigns;
GO
```

---

## 6. GHI CHÚ CHUYỂN ĐỔI DỰ PHÒNG (NẾU MÁY KHÁC KHÔNG CÓ SQL SERVER)
Nếu mang sang máy của bạn bè hoặc giảng viên không cài sẵn Microsoft SQL Server, bạn chỉ cần mở `application.properties`, comment phần SQL Server và bỏ comment phần H2 Database có sẵn. Dự án sẽ lập tức chuyển sang chạy CSDL file nội bộ mà không cần cài bất kỳ phần mềm nào.
