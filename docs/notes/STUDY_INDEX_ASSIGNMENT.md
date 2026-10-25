# Phân công index — 25/10/2026

Chia đủ 17 CREATE INDEX tường minh: TV1 5, TV2 4, TV3 4, TV4 4; mỗi tên đúng một người.
TV1: tài khoản/phiên/audit/replay; TV2: đăng ký/hóa đơn; TV3: lớp/xếp lớp; TV4: lịch/điểm danh.
TV4 phối hợp TV3 về bảng Schedule; không chuyển người phụ trách bảng/SP.
Bảng tổng có cột Index; bảng mỗi người có dòng Index luôn hiển thị và link tới DDL thật.
SQL_INDEXES.md ghi owner, mục đích, key/INCLUDE/filter và dòng nguồn cho từng index.
Năm benchmark: TV1 AuditTime; TV2 RegistrationStudentCourse và InvoiceIssued; TV3 ClassTeacherStatus; TV4 ScheduleClassStart.
Cả 4 đều có bài đo; dùng temp replica, không xóa/tắt index bảng thật để diễn tập.
105 core object và 6 SP chính/người giữ nguyên; 17 index kiểm kê riêng, không tính index tự sinh PK/UNIQUE.
Phân biệt UNIQUE áp đặt tính duy nhất với index thường hỗ trợ tìm kiếm và chi phí ghi/lưu trữ.
Verify-StudyAssignment/Source/Layout/Learning và 155 links PASS; Test-Project source sạch PASS locked restore/build/types/lint/5tests/build.
Không sửa SQL/app/runtime/quyền hoặc chạy lại SQL/HTTP/UI mutation/benchmark.
