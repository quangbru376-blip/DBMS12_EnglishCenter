# Bộ Script SQL Chương 3: Cài đặt Cơ sở Dữ liệu

> Thư mục tập hợp các script SQL cho **Chương 3: Cài đặt Cơ sở Dữ liệu** phục vụ chèn vào báo cáo Word hoặc đồ án môn học.  
> Được tối ưu hóa định dạng gọn gàng, súc tích (compact), loại bỏ các dòng trống thừa để kiểm soát và tiết kiệm số trang in theo đúng yêu cầu đề tài.

---

## Danh mục 7 File Script theo thứ tự đề mục báo cáo

| Đề mục báo cáo | File Script SQL | Số lượng đối tượng | Mô tả nội dung |
|---|---|---|---|
| **3.1. QUAN HỆ** | [`3.1_QuanHe.sql`](3.1_QuanHe.sql) | 1 Sequence, 3 TVPs, 12 Tables | DDL tạo `InvoiceNumberSequence`, 3 User-Defined Table Types (`ScheduleBatch`, `AttendanceBatch`, `GradeManifest`) và 12 bảng chuẩn hóa 3NF. |
| **3.2. RÀNG BUỘC** | [`3.2_RangBuoc.sql`](3.2_RangBuoc.sql) | 19 FKs, 11 UQs, 2 Filtered UQs, 34 CKs | Toàn bộ 19 Khóa ngoại (`ALTER TABLE ... ADD CONSTRAINT FK_...`), các ràng buộc UNIQUE, 2 Filtered Unique Indexes và tổng hợp 34 ràng buộc CHECK nghiệp vụ. |
| **3.3. TRIGGER** | [`3.3_Trigger.sql`](3.3_Trigger.sql) | 12 Triggers | 12 Trigger nghiệp vụ bảo vệ tính toàn vẹn, kiểm soát State Machine hồ sơ/lớp học, chống trùng lịch và bảo vệ nhật ký kiểm toán bất biến. |
| **3.4. VIEW** | [`3.4_View.sql`](3.4_View.sql) | 9 Views | 9 Khung nhìn tổng hợp phục vụ giao diện và báo cáo: `v_ClassState`, `v_RegistrationFacts`, `v_CurrentSchedule`, `v_ClassRoster`, `v_FinalizedGrades`, `v_InvoiceFacts`, `v_ClassProgress`, `v_DirectorAggregate`, `v_AuditSafe`. |
| **3.5. INDEX** | [`3.5_Index.sql`](3.5_Index.sql) | 17 Indexes | 2 Filtered Unique Indexes và 15 Non-clustered Indexes có INCLUDE columns được phân chia đều cho 4 thành viên (5/4/4/4), kèm ghi chú 5 bài đo hiệu năng thực nghiệm trên 100.000 dòng dữ liệu. |
| **3.6. STORED PROCEDURE** | [`3.6_StoredProcedure.sql`](3.6_StoredProcedure.sql) | 24 SPs chính | 24 Stored Procedure cốt lõi học sâu của 4 thành viên (6 SP/thành viên), bao quát đầy đủ các tác vụ tạo dữ liệu, tìm kiếm, thống kê, xác thực, giao dịch nguyên tử (D15) và phân quyền bảo mật (D14). |
| **3.7. FUNCTION** | [`3.7_Function.sql`](3.7_Function.sql) | 7 Functions | 7 Hàm người dùng định nghĩa (Scalar Functions): `fn_GradeTotal`, `fn_InvoiceDueDate`, `fn_RegistrationUnfinished`, `fn_ClassProgress`, `fn_InvoiceDebtFlags`, `fn_ActionRootKind`, `fn_ValidScore`. |
