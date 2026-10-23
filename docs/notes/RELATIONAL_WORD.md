# Lược đồ quan hệ Word

Owner cần dạng TênBảng(thuộc tính), PK gạch chân liền, FK nét đứt.
Đã tạo Luoc-do-quan-he-DBMS12.docx với 12 quan hệ và 99 thuộc tính.
PK dùng Word single underline; FK dùng Word dash underline.
Kiểm OOXML theo DDL: 12 single, 19 dash, 68 thuộc tính thường PASS.
Times New Roman 12pt, A4 dọc một trang, nội dung là text chỉnh sửa được.
Dùng skill documents và bundled Python/python-docx.
render_docx.py thiếu LibreOffice trên Windows; không dùng LibreOffice desktop.
Render bằng Word ẩn riêng, chỉ nhận instance rỗng, mở readonly và đóng noSave.
Đã xuất PDF và PNG QA bằng bundled Poppler, xem ảnh một trang sạch.
Word renderer không đổi hash DOCX; không đọc/sửa tài liệu Word cũ.
Evidence relational-word.json; không thao tác DB/runtime/schema.
