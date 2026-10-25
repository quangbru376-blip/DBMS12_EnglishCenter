# Review STUDY_INDEX_ASSIGNMENT — 25/10/2026

Verdict: **PASS trong phạm vi phân công tài liệu/verifier**. Áp dụng skill code-review, không delegation. [Scope](slices/STUDY_INDEX_ASSIGNMENT.md), [bảng phân công](../study/DATABASE_OBJECTS_4_MEMBERS.md), [chi tiết index](../study/SQL_INDEXES.md), [note](../notes/STUDY_INDEX_ASSIGNMENT.md).

Đã giao toàn bộ 17 CREATE INDEX tường minh cho cả 4 thành viên (5/4/4/4), mỗi tên một owner. TV1 học tài khoản/phiên/audit/replay, TV2 đăng ký/hóa đơn, TV3 lớp/xếp lớp, TV4 lịch/điểm danh. TV4 phối hợp TV3 vốn phụ trách bảng Schedule; không đổi ownership bảng/SP. Cả 4 đều có benchmark: 1/2/1/1, đúng 5 file có sẵn. Không thêm index giả để chia đều hoặc lấy index tự sinh PK/UNIQUE tính lại.

Cột Index và dòng Index trong bảng từng thành viên hiển thị trực tiếp, không nằm trong phụ lục SP. SQL_INDEXES có owner và mục đích theo từng DDL, nguồn/dòng và benchmark. Tổng 105 core object được giữ theo quy ước cũ và ghi rõ chưa tính index; không để người đọc cộng nhầm cột. Giữ 24 SP chính/37 hỗ trợ và 8 transaction trọng tâm. Hai filtered UNIQUE được giải thích là tính duy nhất trong tập lọc; unique kỳ thi bảo đảm nhiều nhất một, không tự sinh kỳ thi. Index thường không tự ngăn xung đột lịch.

|Kiểm thực hiện|Kết quả|
|---|---|
|Verify-StudyAssignment|PASS: tên/table/dòng theo 17 DDL, unique owner, 5/4/4/4; 5 benchmark đúng owner/file 1/2/1/1; số/tên ở bảng MD khớp JSON|
|So objects/transactionStudy/reportingStudy với HEAD|PASS: không thay ownership hoặc mức học SP/transaction|
|Verify-Source / Verify-SqlLayout / Verify-SqlLearning|PASS: 62 pins/61 scopes/107 bài học giữ nguyên|
|Links tài liệu được chỉnh|PASS: 155 local links tồn tại|
|Export-TeamSource/secret-format/hash copy|PASS, không private/build state|
|Test-Project trên export source sạch|PASS locked restore/audit, backend 0 warnings/errors, frontend types/lint/5 tests/build|

Không chạy lại SQL benchmark/HTTP/UI vì đây là giao người học cho source và bài có sẵn; bằng chứng hiệu năng cũ giữ nguyên và không gọi là lượt chạy mới. Chưa kiểm trực tiếp rendering GitHub, nghiệm thu thành viên trên máy thứ hai hoặc tải production. Không đổi API/kiến trúc nên không cần migration/decision; note <=15 dòng. Bản export build chứa đúng verifier và phân công index mới; sau build chỉ bổ sung note/memory/review/evidence và chỉnh câu ngày cập nhật. Stage review rồi cập nhật hướng dẫn GitHub đã phát hành theo yêu cầu trước đó, không force.
