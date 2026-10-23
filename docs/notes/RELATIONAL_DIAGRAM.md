# RELATIONAL_DIAGRAM — 22/10/2026

Owner yêu cầu sơ đồ quan hệ của bản12 hiện tại.
Nguồn duy nhất cho bảng/cột/khóa là 01_schema.sql; không suy từ bản24.
Đã tạo PNG/PDF/SVG, drawio chỉnh sửa, Mermaid và thuyết minh19FK.
Đủ12bảng/99cột/12PK; gồm FK Class → AuditLog.operation_id (UK).
Cardinality lấy từ NOT NULL/UNIQUE, kể cả filtered UNIQUE của Class.
GradeReport là0..1 theoDDL; ứng dụng tạo stub khi xếp lớp.
Tổng điểm/trạng thái suy ra không được thêm thành cột vật lý.
Generator cần Python/Pillow và fontArial trênWindows; không thêm dependency ứng dụng.
Lệnh generator và Verify-Source PASS; đã kiểm ảnh xuất vàXML.
Không build/test nghiệp vụ, không thao tác DB/runtime/keys/custody.
Evidence riêng giữ schemaSHA vàhash artifact; evidence cũ không đổi.
Owner bổ sung mẫu ERD.md: kết quả chính ERD-full-attributes.* dùng Mermaid chân quạ.
Native render kiểm12node/19edge/99attribute PASS; không install, không sửa file mẫu gốc.
