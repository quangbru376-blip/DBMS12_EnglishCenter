# CHƯƠNG 4. QUẢN LÝ GIAO DỊCH VÀ BẢO MẬT HỆ THỐNG CƠ SỞ DỮ LIỆU

---

## 4.1. QUẢN LÝ GIAO DỊCH (TRANSACTION MANAGEMENT)

### 4.1.1. Triết lý thiết kế và Chuẩn ACID trong hệ thống
Nhằm bảo đảm tính toàn vẹn dữ liệu ở mức cao nhất, hệ thống DBMS12 EnglishCenter áp dụng **Quyết định kiến trúc D15**: Chuyển giao toàn bộ quyền sở hữu và điều phối giao dịch từ tầng ứng dụng (C#) vào trực tiếp mã nguồn T-SQL của **61/61 Stored Procedures** (gồm 56 thủ tục nghiệp vụ và 5 thủ tục hạ tầng). Mọi thao tác ghi dữ liệu đều đáp ứng trọn vẹn 4 tiêu chuẩn của mô hình ACID:

- **Tính nguyên tử (Atomicity):** Mọi tác vụ trong một nghiệp vụ—gồm cập nhật trạng thái thực thể, kiểm tra ràng buộc, lưu vết kiểm toán (`AuditLog`), ghi nhận chống lặp lệnh (`ReplayOperation`) và gia hạn phiên làm việc (`AuthSession.last_activity_at`)—đều được thực thi trong duy nhất một giao dịch CSDL. Bất kỳ sự cố nào xảy ra giữa chừng đều khiến toàn bộ các thay đổi trước đó bị hủy bỏ (`ROLLBACK`), triệt tiêu hoàn toàn rủi ro dữ liệu dở dang (như học viên được duyệt nhập học nhưng không sinh hóa đơn).
- **Tính nhất quán (Consistency):** Giao dịch đưa CSDL từ một trạng thái hợp lệ sang một trạng thái hợp lệ mới. Toàn bộ 44 ràng buộc khai báo (Primary Key, Foreign Key, Check, Unique) cùng 12 Trigger nghiệp vụ luôn được thẩm định khắt khe trước khi giao dịch được chấp thuận.
- **Tính cô lập (Isolation):** Hệ thống kết hợp cơ chế khóa thô tuần tự hóa (`Course WITH(TABLOCKX, HOLDLOCK)`) và kiểm soát đồng thời lạc quan (OCC) qua cột `row_version`, loại bỏ hoàn toàn các hiện tượng đọc bẩn (Dirty Read), đọc không lặp lại (Non-repeatable Read) và ghi đè mất dữ liệu (Lost Update).
- **Tính bền vững (Durability):** Khi lệnh `COMMIT TRANSACTION` hoàn tất, toàn bộ dữ liệu, biên nhận và dấu vết kiểm toán được lưu trữ vĩnh viễn trên đĩa cứng của SQL Server, không bị thất thoát ngay cả khi xảy ra sự cố sập nguồn hay mất kết nối mạng.

---

### 4.1.2. Cơ chế kiểm soát độ sâu giao dịch và bẫy lỗi trong T-SQL
Mỗi Stored Procedure ghi dữ liệu đều tích hợp cơ chế tự kiểm soát độ sâu thực thi và xử lý ngoại lệ theo mẫu chuẩn hóa:
- **Ngắt lỗi nghiêm ngặt với `SET XACT_ABORT ON`:** Được đặt ở đầu mỗi thủ tục nhằm bảo đảm khi phát sinh lỗi runtime, SQL Server tự động chuyển giao dịch sang trạng thái không thể xác nhận (`XACT_STATE() = -1`), ngăn ngừa tình trạng bỏ qua câu lệnh lỗi làm trôi giao dịch.
- **Quản lý độ sâu qua cờ `@SqlOwnTransaction`:** Dựa vào biến hệ thống `@@TRANCOUNT`. Nếu `@@TRANCOUNT = 0` (được gọi từ tầng ứng dụng), biến cờ bằng 1 và thủ tục chủ động phát lệnh `BEGIN TRANSACTION`. Nếu `@@TRANCOUNT > 0` (được gọi lồng từ một thủ tục khác), biến cờ bằng 0; thủ tục sẽ tham gia vào giao dịch cha mà không phát lệnh mở hay đóng sớm, bảo toàn tính toàn vẹn của chuỗi nghiệp vụ bao ngoài.
- **Xử lý ngoại lệ với `TRY...CATCH`:** Nếu thành công và nắm cờ sở hữu (`@SqlOwnTransaction = 1`), thủ tục phát lệnh `COMMIT TRANSACTION`. Nếu phát sinh lỗi, khối `CATCH` kiểm tra `XACT_STATE() <> 0` để phát lệnh `ROLLBACK TRANSACTION`, sau đó dùng lệnh `THROW` tái phát sinh lỗi nguyên bản về cho tầng ứng dụng.

---

### 4.1.3. Cơ chế chống lặp lệnh (Idempotency) và Năm quy trình tiêu biểu
Để ngăn chặn nguy cơ người dùng bấm đúp hoặc đường truyền gửi lặp yêu cầu, hệ thống triển khai bảng `ReplayOperation` lưu trữ: mã người thực hiện (`actor_account_id`), mã hành động (`action_code`), mã định danh duy nhất dạng GUID (`request_id`), và mã băm SHA-256 của nội dung đầu vào (`input_digest`). 

Trong cửa sổ 24 giờ, nếu Stored Procedure phát hiện một `request_id` đã được xử lý thành công với cùng mã băm dữ liệu, thủ tục sẽ lập tức đọc lại kết quả cũ từ `AuditLog` và trả về kết quả kèm cờ `replayed = 1` mà không chạy lại các câu lệnh ghi dữ liệu. Nếu phát hiện trùng mã yêu cầu nhưng sai khác mã băm nội dung, thủ tục ném mã lỗi 51205 để từ chối ngay lập tức.

Tính nguyên tử của hệ thống được thể hiện qua **5 quy trình giao dịch nghiệp vụ cốt lõi**:
1. **Duyệt nhập học và Phát hành hóa đơn (`usp_AdmissionApprove`):** Chuyển hồ sơ sang `ADMITTED`, đọc học phí hiện hành của khóa học, khởi tạo hóa đơn chưa thu trong `Invoice`, ghi `AuditLog` và `ReplayOperation`. Nếu tạo hóa đơn thất bại, hồ sơ hoàn tác về `CONFIRMED`.
2. **Thu học phí trọn gói (`usp_InvoiceCollect`):** Kiểm tra hóa đơn chưa thu, cập nhật thời điểm thu (`paid_at`), người thu (`paid_by`), phương thức, số tham chiếu chứng từ, sinh biên nhận và lưu kiểm toán. Nếu sai phiên bản dữ liệu, giao dịch hoàn tác, chống thu tiền trùng.
3. **Xếp lớp và Khởi tạo bảng điểm (`usp_PlacementCreate`):** Kiểm tra hồ sơ đã nhập học, đã đóng đủ học phí, lớp đang mở và còn chỉ tiêu sĩ số. Giao dịch đồng thời chèn học viên vào lớp (`StudentClassAssignment`) và tạo ngay bảng điểm rỗng ở trạng thái nháp (`GradeReport DRAFT`). Nếu tạo bảng điểm thất bại, thao tác xếp lớp bị hủy bỏ.
4. **Lập lịch học theo lô (`usp_ScheduleBatch`):** Nhận toàn bộ danh sách buổi học qua kiểu tham số bảng (TVP). Chèn đồng loạt vào bảng `Schedule` và kích hoạt trigger `tr_Schedule_Guard` kiểm tra xung đột phòng học và giáo viên. Chỉ cần một buổi học bị trùng, toàn bộ lô lịch đều bị `ROLLBACK`.
5. **Duyệt và Chốt bảng điểm toàn lớp (`usp_GradeFinalize`):** Kiểm tra điểm số của toàn bộ học viên theo quy chế đào tạo, ghi nhận trạng thái `FINALIZED` vào `AuditLog` và cập nhật con trỏ quản lý của lớp (`current_grade_operation_id`). Nếu phát hiện thiếu điểm hoặc sai lệch phiên bản, giao dịch lập tức bị hủy bỏ.

---

### 4.1.4. Kiểm soát tranh chấp truy cập đồng thời (Concurrency Control)
Xét kịch bản điển hình: Hai nhân viên kế toán cùng mở một hóa đơn chưa thanh toán và cùng nhấn nút "Xác nhận thu tiền" tại cùng một thời điểm. Hệ thống giải quyết tranh chấp bằng cơ chế hai tầng:

- **Tầng 1 - Tuần tự hóa bằng khóa độc quyền (Pessimistic Coarse Lock):** Khi thủ tục của Kế toán 1 bắt đầu, câu lệnh `SELECT COUNT_BIG(*) FROM dbo.Course WITH(TABLOCKX, HOLDLOCK)` chiếm giữ khóa độc quyền (`X-Lock`) trên bảng danh mục. Yêu cầu của Kế toán 2 gửi tới sau vài mili-giây sẽ bị đưa vào trạng thái chờ (`BLOCKED`) cho đến khi Kế toán 1 kết thúc giao dịch.
- **Tầng 2 - Kiểm tra phiên bản lạc quan (OCC qua `row_version`):** Kế toán 1 kiểm tra hóa đơn hợp lệ (`paid_at IS NULL` và đúng `row_version`), cập nhật trạng thái đã thu, ghi kiểm toán và `COMMIT`. Khi commit, SQL Server tự động tăng giá trị cột `row_version` của bản ghi hóa đơn và giải phóng khóa. Kế toán 2 được đánh thức và thực thi câu lệnh cập nhật kèm điều kiện phiên bản cũ:
  ```sql
  UPDATE i SET paid_at = SYSUTCDATETIME(), paid_by = @Actor, ...
  FROM dbo.Invoice i 
  WHERE i.invoice_id = @InvoiceId AND i.row_version = @InvoiceVersion AND i.paid_at IS NULL;
  ```
  Vì `row_version` đã thay đổi và `paid_at` không còn là NULL, câu lệnh của Kế toán 2 khớp 0 dòng (`@@ROWCOUNT = 0`). Thủ tục phát hiện điều kiện `IF @@ROWCOUNT <> 1`, lập tức ném lỗi 51214 và thực thi `ROLLBACK TRANSACTION`.

Kết quả: Hóa đơn chỉ được thu đúng 1 lần duy nhất, doanh thu không bị trùng lặp và tính toàn vẹn tài chính được bảo đảm tuyệt đối.

---

## 4.2. KIẾN TRÚC PHÂN QUYỀN (NATIVE SECURITY V2)

### 4.2.1. Triết lý bảo mật và Cơ chế phong tỏa bảng (DENY) kết hợp Chuỗi quyền sở hữu
Kiến trúc an ninh Native Security V2 (theo **Quyết định D14**) được xây dựng trên hai nguyên tắc căn bản: **Đặc quyền tối thiểu (Least Privilege)** (mọi tài khoản chỉ nhận đúng quyền hạn cần thiết, không cấp quyền quản trị máy chủ hay sở hữu CSDL) và **Phân tách nhiệm vụ (Separation of Duties)** (phân định chức năng rõ ràng giữa 7 vai trò, không có vai trò nào nắm trọn chu trình nghiệp vụ).

Cốt lõi của mô hình là cơ chế **phong tỏa toàn bộ bảng dữ liệu vật lý**:
```sql
DENY SELECT, INSERT, UPDATE, DELETE ON dbo.[Account] TO 
    [role_QuanTri], [role_TuyenSinh], [role_GiaoVu], [role_GiaoVien], 
    [role_KeToan], [role_GiamDoc], [role_HocVien], [dbms12_runtime];
-- Áp dụng đồng loạt cho toàn bộ 12 bảng trong cơ sở dữ liệu.
```
Lệnh `DENY` biến 12 bảng vật lý thành vùng dữ liệu bất khả xâm phạm đối với mọi truy vấn SQL tự do từ bên ngoài. Mọi tương tác nghiệp vụ bắt buộc phải thông qua các **Stored Procedure** và **View**. 

Nhờ các thủ tục, view và bảng vật lý đều thuộc sở hữu của cùng một lược đồ (`dbo`), SQL Server kích hoạt cơ chế **Chuỗi quyền sở hữu (Ownership Chaining)**: Hệ thống chỉ kiểm tra quyền `EXECUTE` trên thủ tục hoặc `SELECT` trên view của người dùng mà bỏ qua lệnh cấm `DENY` trên các bảng bên dưới. Tất cả các thủ tục đều duy trì chế độ mặc định `EXECUTE AS CALLER`, tuyệt đối không dùng `EXECUTE AS OWNER` nhằm loại bỏ triệt để nguy cơ tấn công leo thang đặc quyền (Privilege Escalation).

---

### 4.2.2. Mô hình định danh hai tầng (Two-Tier Identity Architecture)
Để vừa bảo đảm an toàn ở cấp CSDL, vừa tối ưu hiệu năng và tránh phải tạo hàng trăm tài khoản Windows phức tạp, hệ thống thiết kế mô hình định danh 2 tầng:

- **Tầng 1 - Ngữ cảnh hạ tầng (`Dbms12ProjectRuntime`):** Ứng dụng ASP.NET Core kết nối với SQL Server bằng cơ chế Windows Authentication qua một tài khoản non-admin nội bộ (`MACHINE\runtimeUser`), được ánh xạ thành Database User `Dbms12ProjectRuntime` thuộc role `dbms12_runtime`. Tài khoản này bị `DENY` toàn bộ quyền bảng, không có quyền `sysadmin` hay `db_owner`, chỉ được phép thực thi các thủ tục xác thực hạ tầng ban đầu (`usp_SecuritySession`, `usp_LoginRead`, `usp_LoginRecord`) và quyền `IMPERSONATE` trên 7 Database User nghiệp vụ.
- **Tầng 2 - Bảy người dùng nghiệp vụ không mật khẩu (`WITHOUT LOGIN`):** Hệ thống khởi tạo 7 Database Role (`role_QuanTri`, `role_TuyenSinh`, `role_GiaoVu`, `role_GiaoVien`, `role_KeToan`, `role_GiamDoc`, `role_HocVien`) và 7 Database User tương ứng (`Dbms12Admin`, `Dbms12Admissions`, `Dbms12AcademicAffairs`, `Dbms12Teacher`, `Dbms12Accountant`, `Dbms12Director`, `Dbms12Student`). Các User này được tạo với tùy chọn `WITHOUT LOGIN`, tức không có tài khoản đăng nhập máy chủ và không có mật khẩu, loại trừ hoàn toàn nguy cơ bị truy cập trực tiếp từ bên ngoài.

**Quy trình chuyển đổi ngữ cảnh an toàn:** Khi nhận yêu cầu từ client, backend dùng tài khoản hạ tầng gọi `usp_SecuritySession` để xác minh phiên và vai trò của người dùng. Sau khi xác thực hợp lệ, backend phát lệnh `EXECUTE AS USER = 'Dbms12<Role>'` để chuyển sang ngữ cảnh vai trò tương ứng nhằm thực thi Stored Procedure nghiệp vụ được cấp phép. Ngay khi thủ tục kết thúc, backend lập tức phát lệnh `REVERT` để hoàn nguyên về ngữ cảnh hạ tầng ban đầu, triệt tiêu nguy cơ rò rỉ quyền hạn giữa các phiên làm việc dùng chung kết nối.

---

### 4.2.3. Phân định quyền hạn cho 7 Vai trò nghiệp vụ
Mỗi vai trò được cấp quyền thực thi Stored Procedure và đọc View theo đúng phạm vi nhiệm vụ, đồng thời bị giới hạn bởi các vùng cấm nghiêm ngặt:
- **Quản trị viên (`Admin` / `role_QuanTri`):** Cấp quyền quản lý tài khoản nhân sự (`usp_AccountCreateStaff`, `usp_AccountSetStatus`, `usp_AccountResetPassword`) và xem nhật ký an toàn (`usp_AuditList`). Tuyệt đối bị cấm can thiệp thu tiền, xếp lớp, nhập hay chốt điểm.
- **Tuyển sinh (`Admissions` / `role_TuyenSinh`):** Cấp quyền tra cứu, duyệt và từ chối hồ sơ đăng ký (`usp_RegistrationList`, `usp_AdmissionApprove`, `usp_AdmissionReject`, View `v_RegistrationFacts`). Không được quản trị tài khoản, thu học phí hay điều hành lớp học.
- **Giáo vụ (`AcademicAffairs` / `role_GiaoVu`):** Toàn quyền quản lý khóa học, mở lớp, xếp lịch, xếp lớp và duyệt chốt điểm (`usp_Course*`, `usp_Class*`, `usp_Schedule*`, `usp_PlacementCreate`, `usp_GradeFinalize`, các View trạng thái đào tạo). Bị cấm thu tiền và không quản trị tài khoản.
- **Giáo viên (`Teacher` / `role_GiaoVien`):** Cấp quyền xem lịch dạy, điểm danh học viên và nhập điểm thành phần cho các lớp mình phụ trách (`usp_Attendance*`, `usp_GradeSave`, `usp_GradeSubmit`, View `v_CurrentSchedule`). Bị cấm truy cập lớp của giáo viên khác và không có thẩm quyền chốt bảng điểm chính thức.
- **Kế toán (`Accountant` / `role_KeToan`):** Cấp quyền quản lý hóa đơn, thu học phí, đính chính chứng từ và kết xuất báo cáo tài chính (`usp_Invoice*`, `usp_FinanceReport`, View `v_InvoiceFacts`). Bị cấm can thiệp bảng điểm, xếp lớp hay thay đổi học phí gốc của khóa học.
- **Giám đốc (`Director` / `role_GiamDoc`):** Vai trò thuần túy chỉ đọc (Read-Only), cấp quyền tra cứu báo cáo tổng hợp và nhật ký an toàn (`usp_DirectorReport`, View `v_DirectorAggregate`, `v_AuditSafe`). Tuyệt đối không được cấp bất kỳ quyền ghi dữ liệu nào.
- **Học viên (`Student` / `role_HocVien`):** Cấp quyền tự phục vụ gồm cập nhật hồ sơ cá nhân, đăng ký khóa học và xem kết quả học tập của chính mình (`usp_ProfileUpdate`, `usp_Registration*`, `usp_StudentGrades`, `usp_StudentHome`). Bị cô lập hoàn toàn, không thể thấy dữ liệu của học viên khác.

---

### 4.2.4. Bảo mật cấp dòng (Row-Level Security) và Vô hiệu hóa phiên (Epoch Security)
Hệ thống triển khai hai cơ chế an ninh chuyên sâu nhằm bảo vệ dữ liệu ở mức chi tiết nhất:

- **Bảo mật cấp dòng (Row-Level Ownership):** Chống tấn công mạo danh mã định danh (IDOR). Không một Stored Procedure nào nhận mã tài khoản (`ActorAccountId`) từ phía client truyền xuống. Client chỉ gửi mã phiên (`@Sid`) và số hiệu Epoch (`@Epoch`). Thủ tục `usp_SecuritySession` trực tiếp xác thực và truy xuất mã tài khoản hợp lệ từ bảng `AuthSession` trong CSDL, sau đó áp đặt điều kiện lọc sở hữu dòng (ví dụ giáo viên chỉ truy vấn `WHERE teacher_account_id = @Actor`, học viên chỉ truy vấn `WHERE student_account_id = @Actor`).
- **Cơ chế Epoch Invalidation làm mất hiệu lực token:** Bảng `Account` lưu trữ số hiệu an ninh `security_version` (khởi tạo bằng 1). Khi có biến cố bảo mật xảy ra—như người dùng đổi mật khẩu (`usp_PasswordChange`) hoặc quản trị viên khóa tài khoản (`usp_AccountSetStatus`)—hệ thống lập tức tăng `security_version = security_version + 1` và xóa toàn bộ các bản ghi phiên trong bảng `AuthSession`. Ngay ở yêu cầu kế tiếp, mọi JWT token cũ còn lưu trên trình duyệt đều bị thủ tục `usp_SecuritySession` từ chối tức thì, loại trừ hoàn toàn nguy cơ chiếm đoạt phiên đăng nhập.

---

### 4.2.5. Phân biệt ý nghĩa học thuật giữa GRANT, DENY và REVOKE
Hệ thống vận dụng chính xác ngữ nghĩa của ba mệnh đề điều khiển dữ liệu (DCL) trong SQL Server:
- **`GRANT` (Cấp quyền):** Trao quyền truy cập hoặc thực thi có chọn lọc trên các Stored Procedure và View cho từng vai trò nghiệp vụ tương ứng, tạo ra các lối giao tiếp hợp lệ theo thiết kế.
- **`DENY` (Cấm quyền - Mức ưu tiên cao nhất):** Theo nguyên tắc an ninh SQL Server, lệnh `DENY` luôn chiến thắng lệnh `GRANT`. Ngay cả khi một tài khoản vô tình thuộc nhóm có quyền đọc bảng, lệnh `DENY` trên 12 bảng vật lý vẫn bảo đảm người dùng bị từ chối tuyệt đối nếu cố truy xuất trực tiếp bảng mà không thông qua Stored Procedure.
- **`REVOKE` (Thu hồi quyền):** Gỡ bỏ quyền đã cấp (`GRANT`) hoặc lệnh cấm đã thiết lập (`DENY`), đưa đối tượng trở về trạng thái trung lập chưa xác định. Trong hệ thống, `REVOKE` được sử dụng trong các kịch bản kiểm thử bảo mật tự động (`--verify-security`) để thu hồi quyền thử nghiệm của tài khoản tạm sau khi hoàn tất kiểm tra, đưa CSDL về trạng thái an toàn tuyệt đối.
