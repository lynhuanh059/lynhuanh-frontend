# HƯỚNG DẪN CHẠY VÀ BÁO CÁO BÀI KIỂM TRA MÔN HỌC (40%)
**Môn học:** Lập trình Di động (Flutter & ASP.NET Core)  
**Sinh viên:** Lý Như Ánh  
**Dự án:** `lynhuanh`  
**Đề tài:** **Đề 3 - App điểm danh cho sinh viên (Nhóm: 4 con mèo)**  

---

## 🎯 DANH SÁCH TÍNH NĂNG VÀ THANG ĐIỂM ĐÃ HOÀN THÀNH 100%

### 1. Đăng ký tài khoản (Sign Up)
- Hỗ trợ đăng ký tài khoản với Họ tên, Email, Tên đăng nhập, Mật khẩu và chọn Role (Sinh viên / Giảng viên / Admin).
- API: `POST /api/Auth/register`.

### 2. Đăng nhập 2 lớp (Password + OTP)
- Đăng nhập gồm 2 bước:
  - **Bước 1:** Nhập Tên đăng nhập / Email + Mật khẩu.
  - **Bước 2:** Hệ thống tự động phát sinh mã bảo mật OTP 6 chữ số (có thời hạn 5 phút) gửi tới Email (cấu hình mục `Smtp` trong `backend_api/appsettings.json`; để trống = chế độ demo, OTP hiện trên màn hình).
  - Màn hình nhập OTP 6 số đẹp mắt, có hiển thị mã OTP mô phỏng để Thầy chấm bài test nhanh trực tiếp.
- API: `POST /api/Auth/login` và `POST /api/Auth/verify-otp`.

### 3. Phân quyền người dùng (Role-Based Access Control)
- **Admin (Quản trị viên):** 
  - Thống kê hệ thống.
  - Quản lý danh sách lớp học (CRUD: Thêm, Sửa, Xóa lớp, cấu hình phòng học & tọa độ GPS).
  - Quản lý người dùng (CRUD): xem, sửa họ tên/email/vai trò, xóa tài khoản.
- **Giảng viên (Nhân viên):**
  - Xem danh sách môn học phụ trách.
  - Mở phiên điểm danh mới (chọn môn, đặt thời lượng).
  - Chiếu mã **Dynamic QR Code** chống gian lận.
  - Xem danh sách sinh viên đã điểm danh (hiển thị thời gian quét, khoảng cách GPS thực tế tới lớp).
  - Cập nhật / Sửa trạng thái (Có mặt / Đi trễ / Vắng) hoặc Xóa bản ghi điểm danh.
- **Sinh viên (Khách hàng):**
  - Xem các ca học đang mở điểm danh.
  - Quét mã QR trực tiếp bằng camera.
  - Xác thực vân tay (Biometrics) trước khi điểm danh.
  - Tự động kiểm tra vị trí GPS phòng học (Geofencing).
  - Xem lịch sử điểm danh của bản thân.

### 4. Các chức năng CRUD (4.5 điểm)
- [x] **Create:** Thêm lớp học mới kèm tọa độ GPS phòng học; Mở ca điểm danh mới; Quét lưu bản ghi điểm danh.
- [x] **Read:** Xem danh sách lớp học; Xem các ca điểm danh; Xem lịch sử điểm danh sinh viên; Thống kê tài khoản.
- [x] **Update:** Chỉnh sửa thông tin lớp học (mã môn, tên phòng, tọa độ GPS, bán kính cho phép); Giảng viên chỉnh sửa trạng thái điểm danh của sinh viên (Có mặt -> Trễ -> Vắng).
- [x] **Delete:** Xóa lớp học; Xóa bản ghi điểm danh nếu sinh viên vi phạm/gian lận.

### 5. 3 Tính năng nâng cao đã chọn (3.5 điểm)
1. **(e) Quét mã QR & Nhận diện Vân tay (Biometrics):**
   - Tích hợp `mobile_scanner` quét mã QR bằng camera siêu nhạy.
   - Tích hợp `local_auth` xác thực vân tay chính chủ trước khi mở camera điểm danh.
2. **(b) Chia sẻ & Kiểm tra vị trí GPS (Geofencing):**
   - Tích hợp `geolocator` lấy tọa độ GPS chính xác lúc sinh viên quét mã.
   - Sử dụng công thức Haversine so khớp khoảng cách thực tế giữa sinh viên và phòng học. Nếu vượt quá bán kính quy định (ví dụ 100m) -> cảnh báo gian lận vị trí và từ chối điểm danh!
3. **(d) Đo tiếng ồn lớp học (Microphone / Noise Meter):**
   - Tích hợp `noise_meter` và `permission_handler`: khi sinh viên điểm danh, app đo mức ồn xung quanh bằng micro trong 3 giây (chỉ đo cường độ dB, không ghi âm), hiển thị trực tiếp và gửi kèm bản ghi điểm danh.
   - Giảng viên xem độ ồn của từng sinh viên và độ ồn trung bình của cả lớp trong danh sách điểm danh.

### 6. Tính năng mới sáng tạo (1.0 điểm)
- **"Dynamic Time-based QR + Anti-Proxy GPS":**
  - Mã QR của Giảng viên là mã động: server tính token từ khóa bí mật của phiên + mốc thời gian 15 giây (`GET /api/Attendance/qr-token/{sessionId}`), app tự lấy mã mới khi hết chu kỳ; khi điểm danh server chỉ chấp nhận mã của chu kỳ hiện tại hoặc liền trước.
  - Ngăn chặn hoàn toàn việc sinh viên trong lớp chụp ảnh màn hình QR gửi qua Zalo/Messenger cho bạn bè ở nhà điểm danh hộ.
  - Dù có token thì hệ thống vẫn chặn nếu khoảng cách GPS ở xa trường học.

### 7. Giao diện đẹp, mượt mà (1.0 điểm)
- Thiết kế hiện đại theo chuẩn Material 3 của Google, màu chủ đạo xanh ngọc (Campus Teal) với header gradient, thẻ bo tròn, hỗ trợ xem tốt trên cả Android Emulator, máy thật lẫn Windows.

---

## 🚀 HƯỚNG DẪN KHỞI CHẠY HỆ THỐNG

### BƯỚC 1: Khởi chạy Backend Web API (.NET 8 + SQL Server)

Bạn mở một cửa sổ Terminal tại thư mục `lynhuanh\backend_api` và chạy:
```powershell
cd D:\NhuANh\laptrinhdidong\lynhuanh\backend_api
dotnet run --launch-profile "http"
```
*(Backend sẽ tự động kết nối CSDL SQL Server `.\\SQLEXPRESS`, tự động tạo database `lynhuanh`, tạo bảng và nạp sẵn tài khoản test mẫu, lắng nghe tại cổng `http://localhost:5055`).*

Trang Swagger API (đã deploy trên Render) xem tại: https://lynhuanh-backend.onrender.com/swagger/index.html

---

### BƯỚC 2: Khởi chạy Ứng dụng Flutter (`lynhuanh`)

Trong **Android Studio**:
1. Chọn thiết bị chạy:
   - **Máy ảo Android (Pixel_8a hoặc emulator khác)** hoặc
   - **Windows (desktop)** để test siêu nhanh không cần bật máy ảo.
2. Bấm nút **Run** (tam giác xanh hoặc Shift + F10).

Hoặc chạy bằng lệnh Terminal:
```powershell
cd D:\NhuANh\laptrinhdidong\lynhuanh
flutter run -d windows
# Hoặc trên máy ảo Android:
flutter run
```

---

## 🔑 TÀI KHOẢN TEST CÓ SẴN TRONG HỆ THỐNG
*(Trên màn hình Đăng nhập của App đã có sẵn các nút bấm chọn nhanh không cần gõ)*

| Vai trò | Tên đăng nhập | Mật khẩu | Chức năng kiểm tra |
| :--- | :--- | :--- | :--- |
| **Admin** | `admin` | `123` | Quản lý Lớp học (CRUD), xem danh sách tài khoản |
| **Giảng viên** | `giangvien` | `123` | Mở ca điểm danh, chiếu mã QR động, xem/sửa sinh viên điểm danh |
| **Sinh viên** | `sinhvien` | `123` | Quét QR, xác thực vân tay, kiểm tra GPS phòng học, đo tiếng ồn lớp học |


---

## 🌐 DEPLOY API (bắt buộc theo đề: không dùng localhost)
1. Deploy `backend_api` lên hosting/VPS như Bài 6 (đổi `ConnectionStrings:DefaultConnection` sang SQL Server trên hosting).
2. Điền URL thật vào `ApiService.kDeployedBaseUrl` trong `lib/services/api_service.dart`.
3. Muốn gửi Email OTP thật: điền `Smtp:Host/Port/User/Password/From` trong `appsettings.json`.
