# Chi tiết các ràng buộc toàn vẹn trong 12 bảng CSDL DBMS12 (EnglishCenter)

> Nguồn chuẩn: `database/dbms12-compact/tables/01_schema.sql`.  
> Toàn bộ CSDL gồm **12 bảng**, **99 cột**, **12 PK**, **19 FK**, **11 UNIQUE**, **34 CHECK**, **20 DEFAULT**, cùng **2 Filtered UNIQUE Index** bảo đảm tính toàn vẹn dữ liệu và State Machine của hệ thống.

---

## 1. Bảng `Account` (Tài khoản người dùng & Hồ sơ)

Bảng trung tâm quản lý tài khoản định danh chung cho cả 7 vai trò trong hệ thống và lưu trữ thông tin hồ sơ của học viên. Bảng kiểm soát chặt chẽ trạng thái tài khoản, cơ chế băm mật khẩu và giới hạn tần suất đăng nhập sai để phòng chống tấn công dò mật khẩu.

• **Khóa chính & Duy nhất:**
- `PK_Account`: Khóa chính trên `account_id` (IDENTITY).
- `UQ_Account_01`: `UNIQUE ([email])` — Đảm bảo mỗi địa chỉ email chỉ đăng ký duy nhất 1 tài khoản trong toàn hệ thống.

• **Ràng buộc CHECK:**
- `CK_Account_01`: `role_code IN ('Student','Admissions','AcademicAffairs','Teacher','Accountant','Director','Admin') AND DATALENGTH(role_code)=LEN(role_code)`. Chốt cứng 7 vai trò nghiệp vụ của hệ thống, cấm ký tự space thừa hoặc ký tự ẩn.
- `CK_Account_02`: `status IN ('ACTIVE','LOCKED','DISABLED') AND DATALENGTH(status)=LEN(status)`. Quản lý trạng thái tài khoản theo danh mục hợp lệ, không khoảng trắng thừa.
- `CK_Account_03`: `LEN(email) BETWEEN 3 AND 254 AND DATALENGTH(email)=DATALENGTH(LTRIM(RTRIM(email)))`. Độ dài email chuẩn RFC và cấm khoảng trắng đầu/cuối.
- `CK_Account_04`: `LEN(LTRIM(RTRIM(full_name))) > 0`. Cấm đặt họ tên rỗng hoặc toàn ký tự khoảng trắng.
- `CK_Account_05`: `phone IS NULL OR (DATALENGTH(phone)=10 AND LEFT(phone,1)='0' AND phone COLLATE Latin1_General_100_BIN2 NOT LIKE '%[^0-9]%')`. Chuẩn hóa số điện thoại di động Việt Nam: đúng 10 chữ số, bắt đầu bằng chữ số `0`, không chứa ký tự chữ hay dấu câu.
- `CK_Account_06`: `(role_code='Student' AND date_of_birth IS NOT NULL) OR (role_code<>'Student' AND date_of_birth IS NULL AND address IS NULL)`. Ràng buộc nghiệp vụ tinh tế: Học viên cần ngày sinh để xác nhận độ tuổi; còn nhân sự trung tâm thì hợp đồng lao động quản lý ngoài bảng này, không lưu ngày sinh/địa chỉ trong `Account`.
- `CK_Account_07`: `security_version >= 1 AND failed_login_count >= 0`. Phiên bản bảo mật khởi tạo tối thiểu là 1; số lần đăng nhập sai không âm.
- `CK_Account_08`: State Machine bảo vệ đăng nhập và chống brute-force:
  - Nếu `failed_login_count = 0`: Cả `failure_window_started_at` và `login_throttled_until` đều phải là `NULL`.
  - Nếu `failed_login_count > 0`: `failure_window_started_at` phải `NOT NULL`, và nếu bị khóa tạm (`login_throttled_until`) thì thời điểm mở khóa phải `>= failure_window_started_at`.
- `CK_Account_09`: `LEN(password_hash) > 0`. Mật khẩu băm không được để chuỗi rỗng.

• **Giá trị Mặc định (DEFAULT):**
- `DF_Account_status`: DEFAULT `('ACTIVE')`.
- `DF_Account_created_at`: DEFAULT `(SYSUTCDATETIME())`.
- `DF_Account_security_version`: DEFAULT `(1)`.
- `DF_Account_failed_login_count`: DEFAULT `(0)`.

---

## 2. Bảng `AuthSession` (Phiên đăng nhập người dùng)

Bảng quản lý các phiên đăng nhập hợp lệ của người dùng thông qua mã định danh phiên (SID 32 bytes) được sinh ngẫu nhiên theo chuẩn mật mã học. Bảng theo dõi thời điểm hoạt động gần nhất để kiểm soát thời gian hết hạn phiên và phục vụ việc thu hồi quyền truy cập khi đăng xuất hoặc hết hạn.

• **Khóa chính & Duy nhất:**
- `PK_AuthSession`: Khóa chính trên `sid` (`binary(32)`). Định danh phiên là một chuỗi 32 bytes ngẫu nhiên mã hóa mật mã học, ngăn chặn việc suy đoán hoặc giả mạo Session ID.

• **Khóa ngoại (Tham chiếu):**
- `FK_AuthSession_account_id`: `FOREIGN KEY ([account_id]) REFERENCES dbo.[Account]([account_id])`. Đảm bảo mỗi phiên đăng nhập luôn gắn chặt với một tài khoản xác định trong hệ thống (`ON DELETE NO ACTION ON UPDATE NO ACTION`).

• **Ràng buộc CHECK:**
- `CK_AuthSession_01`: `last_activity_at >= issued_at`. Thời điểm ghi nhận hoạt động gần nhất của người dùng không bao giờ được xảy ra trước thời điểm cấp phiên.

• **Giá trị Mặc định (DEFAULT):**
- `DF_AuthSession_issued_at`: DEFAULT `(SYSUTCDATETIME())`. Tự động lấy mốc thời gian UTC khi khởi tạo phiên.

---

## 3. Bảng `Course` (Khóa học đào tạo)

Bảng định nghĩa danh mục các chương trình đào tạo của trung tâm kèm mức học phí, số buổi học dự kiến và tỷ lệ trọng số điểm quá trình. Đây là cấu hình gốc bất biến được bảo vệ chặt chẽ để làm căn cứ phát hành hóa đơn và tính toán kết quả học tập cho học viên.

• **Khóa chính & Duy nhất:**
- `PK_Course`: Khóa chính trên `course_id` (IDENTITY).
- `UQ_Course_01`: `UNIQUE ([course_code])` — Mã khóa học (ví dụ: `IELTS65`, `TOEIC700`) là định danh duy nhất trong danh mục đào tạo, không được trùng lặp.

• **Ràng buộc CHECK:**
- `CK_Course_01`: `LEN(LTRIM(RTRIM(course_code))) > 0 AND DATALENGTH(course_code) = DATALENGTH(LTRIM(RTRIM(course_code))) AND LEN(LTRIM(RTRIM(course_name))) > 0`. Mã khóa học và tên khóa học không được rỗng, cấm ký tự space thừa ở hai đầu.
- `CK_Course_02`: `tuition_fee > 0`. Học phí khóa học bắt buộc phải là số dương lớn hơn 0 (trung tâm không vận hành khóa học miễn phí hoặc ghi nhận số tiền âm trong bảng danh mục).
- `CK_Course_03`: `(status IN ('ACTIVE','INACTIVE') AND DATALENGTH(status) = LEN(status))`. Khóa học chỉ có 2 trạng thái: `ACTIVE` (đang tuyển sinh/mở lớp) hoặc `INACTIVE` (tạm dừng đào tạo).
- `CK_Course_04`: `expected_lesson_count > 0`. Số buổi học dự kiến của khóa học bắt buộc phải lớn hơn 0.
- `CK_Course_05`: `process_weight > 0 AND process_weight < 100`. Trọng số điểm đánh giá quá trình phải nằm trong khoảng strictly `(0, 100)` %, bảo đảm điểm thi cuối khóa còn lại luôn chiếm trọng số dương (`100 - process_weight > 0`).

• **Giá trị Mặc định (DEFAULT):**
- `DF_Course_status`: DEFAULT `('ACTIVE')`.
- `DF_Course_created_at`: DEFAULT `(SYSUTCDATETIME())`.

---

## 4. Bảng `Registration` (Hồ sơ đăng ký học)

Bảng quản lý toàn bộ hồ sơ đăng ký tham gia khóa học của học viên và theo dõi vòng đời xét duyệt từ khi mới nộp, xác nhận nhu cầu cho đến duyệt nhập học hoặc từ chối/hủy. Mỗi hồ sơ được gán trạng thái nghiêm ngặt để kích hoạt bước phát hành hóa đơn học phí và xếp lớp sau này.

• **Khóa chính & Duy nhất:**
- `PK_Registration`: Khóa chính trên `registration_id` (IDENTITY).

• **Khóa ngoại (Tham chiếu):**
- `FK_Registration_student_account_id`: `FOREIGN KEY ([student_account_id]) REFERENCES dbo.[Account]([account_id])`. Hồ sơ đăng ký phải thuộc về một tài khoản người dùng hợp lệ.
- `FK_Registration_course_id`: `FOREIGN KEY ([course_id]) REFERENCES dbo.[Course]([course_id])`. Hồ sơ đăng ký phải chọn một khóa học đang tồn tại trong danh mục đào tạo.

• **Ràng buộc CHECK:**
- `CK_Registration_01`: `(status IN ('PENDING','CONFIRMED','ADMITTED','REJECTED','CANCELLED') AND DATALENGTH(status) = LEN(status))`. Quản lý vòng đời hồ sơ đăng ký học viên (State Machine):
  - `PENDING`: Hồ sơ mới nộp trực tuyến, chờ tư vấn/xác nhận.
  - `CONFIRMED`: Học viên đã xác nhận nhu cầu học.
  - `ADMITTED`: Đã duyệt nhập học thành công (kích hoạt phát hành hóa đơn học phí).
  - `REJECTED`: Trung tâm từ chối tiếp nhận (ví dụ không đạt điều kiện tiên quyết).
  - `CANCELLED`: Học viên hoặc nhân viên hủy bỏ hồ sơ.

• **Giá trị Mặc định (DEFAULT):**
- `DF_Registration_status`: DEFAULT `('PENDING')`.
- `DF_Registration_created_at`: DEFAULT `(SYSUTCDATETIME())`.

---

## 5. Bảng `Class` (Lớp học mở)

Bảng quản lý thông tin các lớp học mở theo từng khóa, giáo viên phụ trách, giới hạn sĩ số (1 đến 15 học viên) và tiến trình vận hành của lớp từ lên kế hoạch đến khi hoàn thành. Bảng đồng thời liên kết với giao dịch kiểm toán chốt bảng điểm cuối cùng để bảo đảm tính toàn vẹn kết quả học tập.

• **Khóa chính & Duy nhất:**
- `PK_Class`: Khóa chính trên `class_id` (IDENTITY).
- `UQ_Class_01`: `UNIQUE ([class_code])` — Mã lớp học (ví dụ: `C2026_01`) là duy nhất trên toàn hệ thống.
- `UX_Class_CurrentGradeOperation`: `CREATE UNIQUE INDEX ... WHERE current_grade_operation_id IS NOT NULL`. Đảm bảo mỗi giao dịch hoàn tất/chốt bảng điểm (`AuditLog.operation_id`) chỉ thuộc về duy nhất 1 lớp học.

• **Khóa ngoại (Tham chiếu):**
- `FK_Class_course_id`: `FOREIGN KEY ([course_id]) REFERENCES dbo.[Course]([course_id])`. Lớp học phải trực thuộc một chương trình khóa học xác định.
- `FK_Class_teacher_account_id`: `FOREIGN KEY ([teacher_account_id]) REFERENCES dbo.[Account]([account_id])`. Lớp học phải phân công cho một tài khoản giáo viên chịu trách nhiệm giảng dạy.
- `FK_Class_current_grade_operation_id`: `FOREIGN KEY ([current_grade_operation_id]) REFERENCES dbo.[AuditLog]([operation_id])`. Tham chiếu tới mã giao dịch kiểm toán khi bảng điểm của lớp đã được chốt/hoàn thành.

• **Ràng buộc CHECK:**
- `CK_Class_01`: `LEN(LTRIM(RTRIM(class_code))) > 0 AND DATALENGTH(class_code) = DATALENGTH(LTRIM(RTRIM(class_code)))`. Cấm mã lớp rỗng hoặc chứa khoảng trắng thừa.
- `CK_Class_02`: `capacity BETWEEN 1 AND 15`. Giới hạn quy mô sĩ số lớp học: tối thiểu 1 học viên và tối đa không vượt quá 15 học viên (tiêu chuẩn lớp học chất lượng cao của trung tâm).
- `CK_Class_03`: `(status IN ('PLANNED','OPEN','ONGOING','COMPLETED','CANCELLED') AND DATALENGTH(status) = LEN(status))`. Vòng đời lớp học chuẩn:
  - `PLANNED`: Lên kế hoạch, chưa nhận học viên.
  - `OPEN`: Đang mở để xếp lớp các học viên đã nộp học phí.
  - `ONGOING`: Lớp đang học, đã đủ điều kiện lịch và học viên.
  - `COMPLETED`: Khóa học kết thúc, sẵn sàng nhập và chốt điểm.
  - `CANCELLED`: Hủy lớp học.
- `CK_Class_04`: `current_grade_operation_id IS NULL OR status = 'COMPLETED'`. Bảng điểm chỉ được liên kết với giao dịch chốt điểm cuối cùng (`current_grade_operation_id NOT NULL`) khi lớp học đã ở trạng thái `COMPLETED`.

• **Giá trị Mặc định (DEFAULT):**
- `DF_Class_capacity`: DEFAULT `(15)`.
- `DF_Class_status`: DEFAULT `('PLANNED')`.
- `DF_Class_created_at`: DEFAULT `(SYSUTCDATETIME())`.

---

## 6. Bảng `StudentClassAssignment` (Phân công học viên vào lớp)

Bảng thực thể phân công học viên vào lớp sau khi hồ sơ đăng ký đã được duyệt nhập học và hoàn thành đóng học phí. Bảng đảm bảo nguyên tắc duy nhất: mỗi hồ sơ đăng ký chỉ được xếp vào duy nhất một lớp học và kiểm soát sĩ số thực tế của lớp.

• **Khóa chính & Duy nhất:**
- `PK_StudentClassAssignment`: Khóa chính trên `class_assignment_id` (IDENTITY).
- `UQ_StudentClassAssignment_01`: `UNIQUE ([registration_id])` — Đảm bảo mỗi hồ sơ đăng ký (`registration_id`) chỉ được xếp vào duy nhất 1 lớp học (quan hệ 1 - 0..1), triệt tiêu hoàn toàn khả năng xếp nhầm 1 hồ sơ vào nhiều lớp song song.

• **Khóa ngoại (Tham chiếu):**
- `FK_StudentClassAssignment_registration_id`: `FOREIGN KEY ([registration_id]) REFERENCES dbo.[Registration]([registration_id])`. Hồ sơ đăng ký được xếp lớp phải hợp lệ.
- `FK_StudentClassAssignment_class_id`: `FOREIGN KEY ([class_id]) REFERENCES dbo.[Class]([class_id])`. Tham chiếu tới lớp học được phân công.
- `FK_StudentClassAssignment_assigned_by`: `FOREIGN KEY ([assigned_by]) REFERENCES dbo.[Account]([account_id])`. Lưu vết định danh tài khoản nhân viên giáo vụ thực hiện thao tác xếp lớp.

• **Giá trị Mặc định (DEFAULT):**
- `DF_StudentClassAssignment_assigned_at`: DEFAULT `(SYSUTCDATETIME())`.

---

## 7. Bảng `Schedule` (Lịch học và lịch thi)

Bảng lập lịch chi tiết cho từng buổi học thông thường (LESSON) và kỳ thi kết thúc khóa (FINAL_EXAM) theo phòng học và khung thời gian cụ thể. Bảng ràng buộc mỗi lớp chỉ có duy nhất một lịch thi cuối khóa và yêu cầu giáo vụ xác nhận buổi học đã diễn ra thực tế sau khi giờ học kết thúc.

• **Khóa chính & Duy nhất:**
- `PK_Schedule`: Khóa chính trên `schedule_id` (IDENTITY).
- `UX_Schedule_OneFinalExam`: `CREATE UNIQUE INDEX ... WHERE schedule_type = 'FINAL_EXAM'`. Ràng buộc duy nhất có lọc (Filtered Index): Mỗi lớp học chỉ được phép có **nhiều nhất 1 buổi thi kết thúc khóa** (`FINAL_EXAM`), trong khi có thể có nhiều buổi học thông thường (`LESSON`).

• **Khóa ngoại (Tham chiếu):**
- `FK_Schedule_class_id`: `FOREIGN KEY ([class_id]) REFERENCES dbo.[Class]([class_id])`. Buổi học/thi phải thuộc về một lớp học cụ thể.
- `FK_Schedule_held_by`: `FOREIGN KEY ([held_by]) REFERENCES dbo.[Account]([account_id])`. Tài khoản nhân viên giáo vụ xác nhận buổi học đã diễn ra thực tế.

• **Ràng buộc CHECK:**
- `CK_Schedule_01`: `(schedule_type IN ('LESSON','FINAL_EXAM') AND DATALENGTH(schedule_type) = LEN(schedule_type))`. Phân loại rõ ràng loại lịch: `LESSON` (buổi học thường) hoặc `FINAL_EXAM` (buổi thi cuối kỳ).
- `CK_Schedule_02`: `end_at > start_at`. Thời điểm kết thúc buổi học bắt buộc phải sau thời điểm bắt đầu.
- `CK_Schedule_03`: `LEN(LTRIM(RTRIM(room))) > 0 AND DATALENGTH(room) = DATALENGTH(LTRIM(RTRIM(room)))`. Tên/mã phòng học không được để trống hoặc chứa khoảng trắng thừa.
- `CK_Schedule_04`: `(held_at IS NULL AND held_by IS NULL) OR (held_at IS NOT NULL AND held_by IS NOT NULL AND held_at >= end_at)`. Tính toàn vẹn nghiệp vụ tổ chức buổi học:
  - Nếu chưa diễn ra: Cả thời điểm và người xác nhận phải là `NULL`.
  - Nếu đã diễn ra (`HELD`): Bắt buộc phải có đủ người xác nhận và thời điểm xác nhận phải từ lúc buổi học kết thúc trở đi (`held_at >= end_at`), ngăn chặn việc xác nhận trước giờ học kết thúc.

---

## 8. Bảng `Attendance` (Điểm danh học viên theo buổi)

Bảng lưu trữ kết quả điểm danh có mặt hoặc vắng mặt của từng học viên trong từng buổi học cụ thể của lớp. Ràng buộc khóa phức hợp đảm bảo mỗi học viên chỉ được ghi nhận điểm danh đúng một lần cho mỗi buổi học.

• **Khóa chính & Duy nhất:**
- `PK_Attendance`: Khóa chính trên `attendance_id` (IDENTITY).
- `UQ_Attendance_01`: `UNIQUE ([schedule_id], [class_assignment_id])` — Khóa phức hợp duy nhất: Mỗi học viên trong lớp (`class_assignment_id`) chỉ được điểm danh duy nhất 1 lần trong 1 buổi học cụ thể (`schedule_id`).

• **Khóa ngoại (Tham chiếu):**
- `FK_Attendance_schedule_id`: `FOREIGN KEY ([schedule_id]) REFERENCES dbo.[Schedule]([schedule_id])`. Điểm danh phải gắn với một buổi học cụ thể trong lịch.
- `FK_Attendance_class_assignment_id`: `FOREIGN KEY ([class_assignment_id]) REFERENCES dbo.[StudentClassAssignment]([class_assignment_id])`. Điểm danh đúng học viên đã được phân công vào lớp.

• **Giá trị Mặc định (DEFAULT):**
- `DF_Attendance_recorded_at`: DEFAULT `(SYSUTCDATETIME())`.

---

## 9. Bảng `GradeReport` (Bảng điểm và kết quả học tập)

Bảng lưu trữ kết quả học tập của từng học viên trong lớp bao gồm điểm đánh giá quá trình và điểm thi kết thúc khóa theo thang điểm chuẩn [0, 100]. Dữ liệu điểm tại đây được dùng làm căn cứ để các hàm của CSDL tính toán điểm tổng kết có trọng số và xác định kết quả đạt hay không đạt.

• **Khóa chính & Duy nhất:**
- `PK_GradeReport`: Khóa chính trên `report_id` (IDENTITY).
- `UQ_GradeReport_01`: `UNIQUE ([class_assignment_id])` — Mỗi học viên trong lớp (`class_assignment_id`) chỉ sở hữu duy nhất 1 bản ghi kết quả điểm số.

• **Khóa ngoại (Tham chiếu):**
- `FK_GradeReport_class_assignment_id`: `FOREIGN KEY ([class_assignment_id]) REFERENCES dbo.[StudentClassAssignment]([class_assignment_id])`. Kết quả điểm số liên kết trực tiếp với phân công học viên vào lớp.

• **Ràng buộc CHECK:**
- `CK_GradeReport_01`: `continuous_score IS NULL OR continuous_score BETWEEN 0 AND 100`. Điểm đánh giá quá trình có thể chưa nhập (`NULL`), nhưng khi đã nhập thì bắt buộc phải nằm trong thang điểm chuẩn [0, 100].
- `CK_GradeReport_02`: `final_exam_score IS NULL OR final_exam_score BETWEEN 0 AND 100`. Điểm thi cuối kỳ có thể chưa thi (`NULL`), khi đã nhập thì bắt buộc phải nằm trong thang điểm chuẩn [0, 100].

• **Giá trị Mặc định (DEFAULT):**
- `DF_GradeReport_updated_at`: DEFAULT `(SYSUTCDATETIME())`.

---

## 10. Bảng `Invoice` (Hóa đơn học phí)

Bảng quản lý hóa đơn học phí phát hành tương ứng cho từng hồ sơ nhập học theo chính sách thu học phí trọn gói một lần. Bảng kiểm soát chặt chẽ trạng thái thanh toán, lưu vết kế toán thu tiền, phương thức thanh toán và mã giao dịch tham chiếu.

• **Khóa chính & Duy nhất:**
- `PK_Invoice`: Khóa chính trên `invoice_id` (IDENTITY).
- `UQ_Invoice_01`: `UNIQUE ([invoice_number])` — Số hóa đơn được sinh từ Sequence toàn cục `InvoiceNumberSequence`, bảo đảm tính duy nhất và liên tục.
- `UQ_Invoice_02`: `UNIQUE ([registration_id])` — Mỗi hồ sơ đăng ký nhập học (`registration_id`) chỉ phát hành duy nhất 1 hóa đơn học phí (chính sách thu học phí trọn gói 1 lần).

• **Khóa ngoại (Tham chiếu):**
- `FK_Invoice_registration_id`: `FOREIGN KEY ([registration_id]) REFERENCES dbo.[Registration]([registration_id])`. Hóa đơn gắn liền với hồ sơ đăng ký hợp lệ.
- `FK_Invoice_paid_by`: `FOREIGN KEY ([paid_by]) REFERENCES dbo.[Account]([account_id])`. Lưu vết tài khoản nhân viên kế toán thực hiện thu tiền và xác nhận thanh toán.

• **Ràng buộc CHECK:**
- `CK_Invoice_01`: `invoice_number > 0 AND amount > 0`. Số hóa đơn và số tiền học phí phải là số dương lớn hơn 0.
- `CK_Invoice_02`: State Machine quản lý giao dịch thanh toán chặt chẽ:
  ```sql
  (paid_at IS NULL AND paid_by IS NULL AND payment_method IS NULL AND payment_reference IS NULL)
  OR
  (
      paid_at IS NOT NULL 
      AND paid_by IS NOT NULL 
      AND payment_method IS NOT NULL 
      AND (payment_method IN ('CASH','BANK_TRANSFER') AND DATALENGTH(payment_method) = LEN(payment_method)) 
      AND paid_at >= issued_at 
      AND (payment_reference IS NULL OR LEN(LTRIM(RTRIM(payment_reference))) > 0)
  )
  ```
  - **Khi chưa thanh toán:** Toàn bộ 4 trường thông tin thu tiền (`paid_at`, `paid_by`, `payment_method`, `payment_reference`) bắt buộc phải là `NULL`.
  - **Khi đã thanh toán:** Bắt buộc phải có ngày thu tiền (`paid_at >= issued_at`), kế toán thu tiền (`paid_by`), phương thức hợp lệ (`CASH` hoặc `BANK_TRANSFER`), và nếu có mã giao dịch tham chiếu ngân hàng (`payment_reference`) thì cấm để chuỗi rỗng.

• **Giá trị Mặc định (DEFAULT):**
- `DF_Invoice_invoice_number`: DEFAULT `(NEXT VALUE FOR dbo.InvoiceNumberSequence)`.
- `DF_Invoice_issued_at`: DEFAULT `(SYSUTCDATETIME())`.

---

## 11. Bảng `AuditLog` (Nhật ký kiểm toán hệ thống)

Bảng nhật ký kiểm toán bất biến ghi nhận mọi giao dịch ghi nghiệp vụ trong hệ thống cùng mã thao tác (Operation UUID), người thực hiện, thời gian, kết quả và lý do thay đổi. Dữ liệu trong bảng được bảo vệ toàn vẹn tuyệt đối để phục vụ tra cứu lịch sử, kiểm tra an toàn thông tin và liên kết trạng thái bảng điểm.

• **Khóa chính & Duy nhất:**
- `PK_AuditLog`: Khóa chính trên `audit_id` (IDENTITY `bigint`).
- `UQ_AuditLog_01`: `UNIQUE ([operation_id])` — Mỗi hành vi thực thi hệ thống được định danh bởi một mã GUID `operation_id` duy nhất, phục vụ truy vết giao dịch và liên kết dữ liệu nghiệp vụ.

• **Khóa ngoại (Tham chiếu):**
- `FK_AuditLog_actor_account_id`: `FOREIGN KEY ([actor_account_id]) REFERENCES dbo.[Account]([account_id])`. Tài khoản thực hiện hành động (cho phép `NULL` đối với các hành vi ẩn danh hoặc thất bại trước khi định danh, ví dụ đăng nhập sai hoặc đăng ký mới).

• **Ràng buộc CHECK:**
- `CK_AuditLog_01`: `LEN(action_code) > 7 AND action_code LIKE 'DBMS12.%'`. Chuẩn hóa mã hành động hệ thống: bắt buộc có tiền tố phân loại `DBMS12.` (ví dụ: `DBMS12.ACCOUNT.CREATE_STAFF`, `DBMS12.INVOICE.COLLECT`).
- `CK_AuditLog_02`: `(result_code IN ('SUCCESS','DENIED','FAILURE') AND DATALENGTH(result_code) = LEN(result_code))`. Kết quả thực thi bắt buộc thuộc 3 trạng thái chuẩn:
  - `SUCCESS`: Thực thi thành công.
  - `DENIED`: Bị từ chối do vi phạm phân quyền bảo mật.
  - `FAILURE`: Thất bại do lỗi nghiệp vụ hoặc vi phạm ràng buộc dữ liệu.
- `CK_AuditLog_03`: `root_entity_id IS NULL OR root_entity_id > 0`. ID thực thể gốc bị tác động (nếu có) phải là số nguyên dương hợp lệ.
- `CK_AuditLog_04`: `reason IS NULL OR LEN(LTRIM(RTRIM(reason))) > 0`. Lý do thực thi (nếu ghi nhận) không được để chuỗi khoảng trắng rỗng.
- `CK_AuditLog_05`: `ip_address IS NULL OR LEN(ip_address) > 0`. Địa chỉ IP ghi nhận không được rỗng.

• **Giá trị Mặc định (DEFAULT):**
- `DF_AuditLog_occurred_at`: DEFAULT `(SYSUTCDATETIME())`.
- `DF_AuditLog_change_details`: DEFAULT `(N'')`.

---

## 12. Bảng `ReplayOperation` (Chống lặp lệnh & Bất biến Idempotency)

Bảng bảo đảm tính bất biến và chống lặp lệnh (Idempotency) cho các giao dịch nhạy cảm khi gặp sự cố mạng hoặc client gửi lại yêu cầu. Bảng lưu trữ bộ ba định danh (người dùng, mã thao tác, mã yêu cầu) cùng mã băm dữ liệu đầu vào để trả ngay kết quả đã lưu mà không ghi trùng dữ liệu vào hệ thống.

• **Khóa chính & Duy nhất:**
- `PK_ReplayOperation`: Khóa chính trên `replay_id` (IDENTITY `bigint`).
- `UQ_ReplayOperation_01`: `UNIQUE ([actor_account_id], [action_code], [request_id])` — Bộ ba định danh tính bất biến (Idempotency): Một người dùng (`actor_account_id`) gửi cùng một mã yêu cầu (`request_id`) cho cùng một tác vụ (`action_code`) sẽ không bị thực thi 2 lần; hệ thống sẽ trả lại kết quả đã lưu mà không lặp lại tác vụ ghi DB.
- `UQ_ReplayOperation_02`: `UNIQUE ([operation_id])` — Mỗi bản ghi ReplayOperation liên kết duy nhất 1-1 với bản ghi AuditLog tương ứng.

• **Khóa ngoại (Tham chiếu):**
- `FK_ReplayOperation_actor_account_id`: `FOREIGN KEY ([actor_account_id]) REFERENCES dbo.[Account]([account_id])`. Tài khoản gửi yêu cầu lệnh.
- `FK_ReplayOperation_operation_id`: `FOREIGN KEY ([operation_id]) REFERENCES dbo.[AuditLog]([operation_id])`. Tham chiếu tới bản ghi nhật ký kiểm toán trong `AuditLog` để trích xuất kết quả đã lưu trữ khi xảy ra replay.

• **Ràng buộc CHECK:**
- `CK_ReplayOperation_01`: `LEN(action_code) > 7 AND action_code LIKE 'DBMS12.%'`. Mã hành động kiểm soát lặp lệnh bắt buộc phải tuân thủ đúng định dạng chuẩn có tiền tố `DBMS12.`.

• **Giá trị Mặc định (DEFAULT):**
- `DF_ReplayOperation_completed_at`: DEFAULT `(SYSUTCDATETIME())`.
