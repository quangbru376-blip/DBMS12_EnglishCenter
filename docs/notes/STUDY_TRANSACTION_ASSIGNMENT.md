# Bổ sung phân công transaction — 25/10/2026

Bảng cũ học transaction cùng SP nhưng chưa giao rõ đầu việc cho mục 3.4.
Mỗi command có đúng một người phụ trách transaction theo người nhận SP: TV1/2/3/4 = 4/8/10/7.
Mỗi người có 2 bài trình bày trọng tâm; không giới hạn trách nhiệm vào 8 bài này.
Tổng 105 object và phân bố 27/26/26/26 giữ nguyên; transaction không cộng thành schema object mới.
61 scope gồm command/read/auth/helper đi theo người nhận SP, helper có thể dùng chung caller transaction.
Năm bài COMMIT/forced-error hiện có: TV2 nhận 3, TV3 nhận 2; TV1/TV4 dùng bài SP có outer ROLLBACK.
Concurrency thu học phí: TV2 chủ trì, TV1 chạy phiên còn lại; TV3/TV4 giải thích khóa/RV.
Mỗi người giải thích BEGIN/COMMIT/ROLLBACK, dữ liệu nguyên tử, lỗi, audit/receipt, replay và trước/sau.
Verify-StudyAssignment và 82 liên kết PASS; build sạch PASS sau khi cho phép truy cập NuGet/npm.
Build tại workspace vướng DLL đang chạy; không dừng host để sửa tài liệu. Không chạy lại SQL/UI mutation.
Hướng dẫn chi tiết: docs/study/TRANSACTIONS_4_MEMBERS.md; không thay nghiệp vụ hoặc số bài SQL.
