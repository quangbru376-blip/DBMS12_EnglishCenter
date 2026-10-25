# Review STUDY_TRANSACTION_ASSIGNMENT — 25/10/2026

Verdict: **PASS trong phạm vi tài liệu và kiểm tra phân công**. Áp dụng skill code-review; không delegation. [Scope](slices/STUDY_TRANSACTION_ASSIGNMENT.md), [phân công transaction](../study/TRANSACTIONS_4_MEMBERS.md), [note](../notes/STUDY_TRANSACTION_ASSIGNMENT.md).

Bảng cũ có nhắc transaction trong SP/luồng nhưng chưa giao thành đầu việc rõ. Bản bổ sung giao đủ 29 command cho đúng owner SP, gồm 4/8/10/7 nghiệp vụ; thêm 2 bài trình bày trọng tâm mỗi người. Không gọi 29 command là toàn bộ các SP thay đổi dữ liệu: TV1 còn 8 module auth. Cả 61 scope đọc/auth/helper đi theo owner SP; helper chia sẻ caller transaction khi đã có. Tổng 105 object và phân bố 27/26/26/26 không thay đổi so với HEAD trước sửa.

Năm bài COMMIT/forced-error có sẵn vẫn thuộc TV2/TV3 theo nghiệp vụ, không giả định TV1/TV4 có cùng cờ thử nghiệm. Tám bài trọng tâm dẫn tới các bài SP có outer ROLLBACK; tài liệu phân biệt cách chạy đó với SQL tự COMMIT khi SP sở hữu transaction. Concurrency thu học phí giao TV2 chủ trì, TV1 chạy phiên còn lại, TV3/TV4 giải thích khóa/rowversion. Không thêm SP hoặc script SQL để tăng số lượng.

|Kiểm thực hiện|Kết quả|
|---|---|
|node tools/Verify-StudyAssignment.cjs|PASS: 105 unique, đủ 29 command đúng owner, 2 demo/người, 5 file transaction, concurrency owner/partner, auth/helper theo manifest|
|So phân công objects với git show HEAD|PASS: giữ nguyên mọi người nhận và mọi object|
|Liên kết local trong 3 hướng dẫn|PASS: 82 đích tồn tại|
|Verify-Source / Verify-SqlLayout / Verify-SqlLearning|PASS: 62 SQL pins, 61 scope, 29 replay return, layout và 107 bài học|
|Test-Project tại workspace|FAIL do DLL bị host đang chạy giữ; không dừng host|
|Export-TeamSource và kiểm hash/secret-format|PASS: source sạch không private/build state, copy hash khớp|
|Test-Project trên source sạch|Lần sandbox FAIL NU1900 do không truy cập được NuGet; chạy lại với network PASS locked restore/audit, backend build, types/lint/5 test/build frontend|
|Diff và source SQL/app|PASS: không đổi backend/frontend/database; không có DDL/DML hoặc migration|

Bản export build gồm đúng verifier mới; các thay đổi tiếp sau chỉ chỉnh câu chữ/tài liệu và bằng chứng. Kiểm liên kết/phân công được chạy lại trên bản cuối. Không kiểm lại SQL/UI thực thi, không coi kết quả cũ là lần chạy mới. Không có thay đổi API nên không sửa hợp đồng API; không có đổi kiến trúc cần decision. Note 13 dòng. Không còn finding cần sửa trong scope. Không claim tải lớn, production, máy Windows thứ hai hoặc toàn bộ rubric.

Git: đúng repository độc lập, main và origin/main đồng bộ trước sửa; không force. Cập nhật tài liệu là phần sửa của yêu cầu xuất bản và hướng dẫn nhóm trước đó. Hash commit/remote sau push ghi trong receipt private và trả cho owner; không ghi hash tự tham chiếu trong commit.
