# CHƯƠNG 6. XÂY DỰNG ỨNG DỤNG

---

## 6.1. KIẾN TRÚC HỆ THỐNG

### 6.1.1. Mô hình kiến trúc phân tầng tổng thể
Hệ thống quản lý trung tâm tiếng Anh (DBMS12 EnglishCenter) được thiết kế theo mô hình kiến trúc ba tầng chuẩn mực (Three-Tier Architecture), phân tách rõ ràng trách nhiệm giữa giao diện người dùng, logic điều phối dịch vụ và tầng dữ liệu nghiệp vụ:

- **Tầng Trình bày (Presentation Tier / Frontend Client):** Được xây dựng dưới dạng ứng dụng đơn trang (Single Page Application - SPA) hoạt động trực tiếp trên trình duyệt web. Tầng này chịu trách nhiệm hiển thị không gian làm việc thích ứng theo 7 vai trò người dùng (Quản trị viên, Tuyển sinh, Giáo vụ, Giáo viên, Kế toán, Giám đốc và Học viên). Giao diện tiếp nhận tương tác, kiểm tra sơ bộ dữ liệu biểu mẫu phía client và truyền tải các yêu cầu thông qua giao thức bảo mật HTTPS tới máy chủ backend.
- **Tầng Ứng dụng và Điều phối Dịch vụ (Application / Backend Tier):** Được phát triển trên nền tảng ASP.NET Core, đóng vai trò là trạm trung chuyển an ninh và máy chủ phục vụ tài nguyên tĩnh cùng nguồn gốc (same-origin). Tầng này chịu trách nhiệm: định tuyến các yêu cầu cố định (Fixed Routes), kích hoạt các middleware bảo vệ (quản lý phiên làm việc JWT qua HTTP-only Cookie, phòng chống tấn công giả mạo yêu cầu CSRF, lọc và khử dữ liệu lỗi nhạy cảm), điều phối phiên kết nối và chuyển ngữ cảnh an ninh an toàn sang cơ sở dữ liệu thông qua bộ thực thi SQL chuyên dụng (`CompactSqlExecutor`).
- **Tầng Dữ liệu và Nghiệp vụ lõi (Data & Core Business Tier):** Đặt tại hệ quản trị cơ sở dữ liệu Microsoft SQL Server. Khác với các hệ thống truyền thống vốn đẩy toàn bộ logic vào code ứng dụng, hệ thống DBMS12 chuyển giao toàn bộ quy tắc nghiệp vụ, tính toán tài chính, kiểm soát giao dịch (theo Quyết định D15) và phân quyền an toàn (theo Quyết định D14) vào trực tiếp trong cơ sở dữ liệu. Tầng này bao gồm 12 bảng thực thể vật lý, 61 Stored Procedures, 12 Trigger giám sát trạng thái, 7 Hàm nghiệp vụ và 9 View dữ liệu. Toàn bộ các bảng vật lý đều bị phong tỏa bằng lệnh cấm tuyệt đối (`DENY`), mọi thao tác đều được thực thi an toàn thông qua cơ chế Chuỗi quyền sở hữu (Ownership Chaining).

---

### 6.1.2. Luồng dữ liệu và Chu trình xử lý yêu cầu (Request Pipeline)
Chu trình xử lý một yêu cầu nghiệp vụ từ khi phát sinh tại giao diện cho đến khi được lưu trữ bền vững trong cơ sở dữ liệu diễn ra theo một quy trình khép kín và an toàn:

1. **Khởi tạo và Gửi yêu cầu:** Người dùng thao tác trên giao diện web (ví dụ: cán bộ tuyển sinh bấm duyệt hồ sơ). Ứng dụng client tự động sinh một mã định danh ngẫu nhiên duy nhất dạng GUID (`request_id`) và đính kèm cookie chứa mã phiên JWT cùng tiêu đề xác thực `X-CSRF-Token`, gửi yêu cầu dạng JSON qua cổng bảo mật 8446.
2. **Tiếp nhận và Xác thực trung gian tại Backend:** Máy chủ ASP.NET Core tiếp nhận yêu cầu, kiểm tra tính hợp lệ của token CSRF và cấu trúc gói tin. Middleware ánh xạ dữ liệu vào các đối tượng truyền dữ liệu (DTO) được định nghĩa chặt chẽ, bảo đảm loại trừ các trường dữ liệu trái phép.
3. **Mở kết nối hạ tầng và Xác minh danh tính nội bộ:** Bộ thực thi `CompactSqlExecutor` mở một kết nối mới tới SQL Server bằng tài khoản dịch vụ hệ thống thông qua cơ chế Windows Authentication. Tại đây, backend gọi thủ tục hạ tầng `usp_SecuritySession` để thẩm tra mã phiên và số hiệu Epoch trong CSDL, xác định chính xác danh tính và vai trò thực sự của người dùng.
4. **Chuyển đổi ngữ cảnh an ninh nghiệp vụ:** Sau khi vai trò được xác thực, kết nối phát lệnh `EXECUTE AS USER = 'Dbms12<Role>'` (ví dụ `Dbms12Admissions`). Ngữ cảnh an ninh của phiên kết nối ngay lập tức chuyển sang người dùng nghiệp vụ tương ứng, kích hoạt các chính sách phân quyền theo vai trò trong SQL Server.
5. **Thực thi Stored Procedure và Tự quản Giao dịch:** Stored Procedure nghiệp vụ bắt đầu thực thi với cơ chế tự quản giao dịch hoàn toàn: thiết lập khóa thô bảo vệ tuần tự hóa trên danh mục khóa học, kiểm tra chống lặp lệnh qua bảng `ReplayOperation`, thực hiện các câu lệnh thao tác dữ liệu, lưu vết kiểm toán vào `AuditLog`, cập nhật thời điểm hoạt động của phiên và tự động phát lệnh `COMMIT TRANSACTION` (hoặc `ROLLBACK TRANSACTION` nếu có lỗi).
6. **Hoàn nguyên ngữ cảnh và Trả kết quả:** Ngay khi Stored Procedure kết thúc, backend lập tức phát lệnh `REVERT` để đưa kết nối trở về tài khoản dịch vụ ban đầu, đóng kết nối an toàn. Dữ liệu kết quả được chuyển đổi thành JSON và trả về cho trình duyệt. Giao diện người dùng nhận phản hồi và cập nhật trạng thái trực quan tức thì.

---

## 6.2. CÔNG NGHỆ SỬ DỤNG

### 6.2.1. Hệ quản trị Cơ sở dữ liệu và Ngôn ngữ T-SQL
- **Microsoft SQL Server 2022 (Developer / Express Edition):** Là hệ quản trị cơ sở dữ liệu quan hệ mạnh mẽ, được lựa chọn làm nền tảng lưu trữ và điều hành dữ liệu cốt lõi của trung tâm. SQL Server 2022 cung cấp hệ thống an ninh đa tầng chuyên sâu (hỗ trợ Database User không mật khẩu `WITHOUT LOGIN`, cơ chế ủy quyền ngữ cảnh `EXECUTE AS` và `REVERT`, cùng Chuỗi quyền sở hữu `Ownership Chaining`), khả năng xử lý giao dịch chuẩn ACID nghiêm ngặt, cơ chế khóa chi tiết và khả năng tiếp nhận dữ liệu bảng dạng lô thông qua Table-Valued Parameters (TVP).
- **Ngôn ngữ Transact-SQL (T-SQL):** Toàn bộ 100% logic nghiệp vụ được lập trình trực tiếp bằng T-SQL có tham số hóa tuyệt đối. Hệ thống kiên quyết không sử dụng các framework ORM (như Entity Framework hay LINQ-to-SQL) để loại bỏ hoàn toàn hiện tượng sinh truy vấn tự động không kiểm soát, giúp nhà phát triển làm chủ hoàn toàn kế hoạch thực thi (Execution Plan), tối ưu hóa chỉ mục và kiểm soát tài nguyên phần cứng chính xác.

---

### 6.2.2. Nền tảng Tầng Ứng dụng Backend
- **Microsoft .NET 10 (C#) & ASP.NET Core Web SDK:** Được lựa chọn nhờ hiệu năng xử lý bất đồng bộ hàng đầu, tính ổn định cao và khả năng tích hợp bảo mật mức hệ điều hành. Backend được xây dựng theo kiến trúc tối giản (Minimal Host), cấu hình chạy an toàn trên cổng loopback nội bộ 8446 với chứng chỉ bảo mật TLS/HTTPS riêng biệt.
- **Thư viện truy cập dữ liệu Microsoft.Data.SqlClient (v6.1.1):** Trình điều khiển chính thức của Microsoft dành cho kết nối SQL Server hiệu năng cao. Thư viện cung cấp khả năng thao tác dữ liệu tầng thấp (ADO.NET), quản lý kết nối độc lập, hỗ trợ truyền tham số có định kiểu chặt chẽ (`SqlParameter`) và truyền cấu trúc bảng TVP trực tiếp vào các Stored Procedure mà không qua bất kỳ lớp bao bọc dư thừa nào.
- **Hệ thống Bảo mật và Mã hóa chuyên sâu:**
  - `System.IdentityModel.Tokens.Jwt (v7.7.1)`: Xây dựng và xác thực token JWT an toàn, gắn kết chặt chẽ với cơ chế vô hiệu hóa phiên tức thời Epoch Invalidation trong cơ sở dữ liệu.
  - `System.Security.Cryptography.ProtectedData (v9.0.4)`: Ứng dụng giao diện bảo vệ dữ liệu nội bộ của hệ điều hành Windows (Data Protection API - DPAPI) để mã hóa khóa bí mật và thông tin cấu hình cục bộ của máy chủ.
  - *Thuật toán băm mật khẩu an toàn:* Sử dụng chuẩn băm mật khẩu PBKDF2 kết hợp thuật toán băm HMAC-SHA256 và muối ngẫu nhiên (salt), ngăn chặn triệt để các hình thức tấn công vét cạn và dò quét bảng băm (Rainbow Table).

---

### 6.2.3. Nền tảng Giao diện người dùng Frontend
- **React 19 (`react`, `react-dom` v19.3.0):** Thư viện nền tảng hàng đầu trong xây dựng giao diện tương tác hiện đại. Mô hình phân chia Component độc lập cùng cơ chế cập nhật Virtual DOM hiệu quả giúp các thao tác nghiệp vụ phức tạp (như nhập bảng điểm, xếp lịch theo ca học) phản hồi mượt mà, tức thì mà không cần tải lại toàn bộ trang.
- **TypeScript (v6.0.3):** Ngôn ngữ mở rộng có định kiểu tĩnh nghiêm ngặt. Việc định nghĩa chặt chẽ các giao diện dữ liệu (Interface) và kiểu dữ liệu (Type) giúp đồng bộ hóa hoàn hảo với các DTO của backend, triệt tiêu các lỗi sai sót kiểu dữ liệu ngay từ giai đoạn biên dịch.
- **Vite (v8.3.2):** Công cụ đóng gói mã nguồn (Bundler) và môi trường phát triển frontend thế hệ mới. Nhờ tận dụng cơ chế native ES Modules, Vite mang lại tốc độ biên dịch và đóng gói ứng dụng cực nhanh, tối ưu hóa kích thước gói tệp tĩnh phục vụ trên máy chủ backend.
- **Tailwind CSS (v4.3.3) & Modern CSS:** Framework định kiểu giao diện hiện đại theo hướng tiện ích (Utility-First). Cung cấp hệ thống giao diện phẳng, thanh thoát, thích ứng linh hoạt trên nhiều kích thước màn hình (máy tính bàn, máy tính bảng và điện thoại di động), đồng thời chuẩn hóa hệ thống màu sắc phản hồi trực quan (xanh lá biểu thị thao tác thành công, đỏ biểu thị cảnh báo vi phạm nghiệp vụ).
- **Thư viện Giao diện bổ trợ:**
  - `lucide-react (v1.55.0)`: Bộ biểu tượng vector giao diện hiện đại, giúp bảng điều khiển nghiệp vụ trực quan và thân thiện với người dùng.
  - `@fontsource/be-vietnam-pro (v5.3.0)`: Phông chữ chuẩn hóa tiếng Việt, tối ưu độ hiển thị sắc nét cho các bảng số liệu đào tạo và chứng từ kế toán.

---

### 6.2.4. Công cụ Quản trị, Kiểm thử và Tự động hóa
- **Hệ thống Kịch bản Tự động hóa (PowerShell & Node.js):** Dự án trang bị bộ công cụ kiểm thử tích hợp chuyên sâu (`tools/Test-Project.ps1` và các kịch bản JavaScript/Node.js). Bộ công cụ này tự động thực hiện: khôi phục gói phụ thuộc có khóa phiên bản (`packages.lock.json`), biên dịch kiểm tra mã nguồn, đối chiếu mã băm an toàn của 61 file SQL (`SQL pins`), rà soát định kiểu TypeScript, và thực thi các bài kiểm thử hồi quy tự động.
- **Hệ thống Quản lý Phiên bản Git & GitHub:** Kiểm soát toàn bộ lịch sử thay đổi mã nguồn, bảo đảm tính minh bạch, hỗ trợ cộng tác nhóm an toàn và cách ly tuyệt đối các cấu hình cá nhân hoặc dữ liệu nhạy cảm khỏi kho chứa mã nguồn chung.
