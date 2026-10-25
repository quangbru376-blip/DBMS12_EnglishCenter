# Phân công transaction hiển thị trong bảng — 25/10/2026

DATABASE_OBJECTS_4_MEMBERS.md có cột Transaction (trong SP) ngay trong bảng tổng: TV1/2/3/4 = 4/8/10/7.
Bảng của từng người có dòng Transaction riêng, ghi tên nghiệp vụ, SP và liên kết bài chạy cho đủ 29 command.
105 object và phân bố 27/26/26/26 giữ nguyên; không cộng transaction thêm lần nữa vào tổng object.
Hai bài trọng tâm/người và phân công 8 auth/5 helper/61 scope giữ nguyên như lượt trước.
Năm bài COMMIT/forced-error vẫn chỉ là các file hiện có; bài SP liên kết mặc định outer ROLLBACK.
Concurrency giữ TV2 chủ trì, TV1 chạy phiên còn lại, TV3/TV4 giải thích khóa/RV.
Verifier kiểm trực tiếp cột tổng và các dòng Transaction bên trong bảng, đủ tên và đúng người nhận SP.
Phân công/source/layout/learning và 111 liên kết PASS; không đổi source ứng dụng hoặc SQL.
Test-Project trên source sạch PASS (locked restore/build/types/lint/5 tests/build frontend); giữ nguyên host.
Không chạy lại SQL/UI mutation; đây là thay đổi cách trình bày tài liệu học.
