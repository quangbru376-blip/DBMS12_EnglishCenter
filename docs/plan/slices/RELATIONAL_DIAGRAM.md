# RELATIONAL_DIAGRAM — 22/10/2026

Owner yêu cầu vẽ lược đồ quan hệ cho project hiện tại. Chỉ đọc DDL và tạo tài liệu/sơ đồ; không đổi schema, executable, dependency, database hoặc runtime.

Nguồn: database/dbms12-compact/01_schema.sql. Acceptance: đúng 12 bảng, 99 cột, 12 PK, 19 FK; thể hiện UNIQUE, nullable và đích FK operation_id; có ảnh dùng trong báo cáo, source chỉnh sửa và giải thích cardinality. Kiểm bằng parser đối chiếu DDL, XML/ảnh và source verifier; không cần chạy suite ghi sample.

Owner bổ sung cùng ngày: vẽ theo ERD.md mẫu tại docs/database-course/schema-12-step2 của project cha, thêm thuộc tính. Giữ19quan hệ/chân quạ/nhãn/thứ tự; tạo ERD-full-attributes.* trong project hiện tại, không sửa file ngoài root. Render bằng Mermaid bundle và Playwright đã có trên máy, không install dependency. Native renderer kiểm12node/19edge/99attribute và xuấtSVG/PNG/PDF. Tên Class quote để tránh từ khóa Mermaid; không đổi model.

Owner giao thêm ERD, xác nhận chọn Chen (chữ nhật/thoi/elip). Sinh ERD-Chen.* từ DDL, giữ12thực thể/99thuộc tính/19quan hệ; PK gạch chân, cardinality theo NULL/UNIQUE, không thêm FK Audit root hoặc thực thể vai trò giả. Có SVG/PNG/drawio chỉnh sửa vàPDF13trang phóng to. Kiểm số hình/XML/PDF và source verifier; không chạy suite nghiệp vụ.

Owner gửi ảnh mẫu ERD hàng không, yêu cầu phân tích và áp dụng phong cách giáo trình. ERD-Chen-classic.* dùng nét đen mảnh/nền trắng/khối xám/tên viết hoa/elip tỏa/PKgạch chân,nhãn1/N vàđường đôi cho tham gia bắt buộc15FKNOTNULL. BốnFKnullable giữđơn; không sao chép thực thể yếu/quan hệ định danh khi model không có khóa bộ phận. Giữ12/99/19,PDF13trang/drawio chỉnh sửa; chỉ tài liệu, không đổi schema/DB/runtime. Phân tích mẫu và giới hạn ánh xạ ghi trongERD-Chen-classic.md.

Owner yêu cầu giảm khoảng cách/chỉnh chữ để dán đúngmộttrangWordA4portrait. TạoERD-Chen-A4-portrait.*: dàn lại2cột×6hàng,đủ12/99/19;ảnh18×26cm,PDFmộttrangA4;ghi cỡchữthật≈6,52pt ởWidth18cm,Wordlề1,5cm/inline. Không chỉscaleảnhngang,khôngbỏthuộctính,khôngsửaWordowner. KiểmXML/đếm hình/PDFpage/media vàxemảnh;khôngsuiteDB/runtime.

Owner gửi mẫu báo cáo khác với PK vàng/khung trắng và min/max, yêu cầu bám dữ liệu hiện tại. Thêm biến thể --sample-style xuấtERD-Chen-A4-sample.*; giữA4portrait và12/99/19,TimesNewRoman,PKvàng/inđậm/gạch chân,khungtrắng,nétđơn. Cardinality theoNULL/UNIQUE:1 hoặc0..1 phía cha,0..1/0..N phía con; không sao chép1..N của nghiệp vụkháchsạn. Kiểm12PKvàng/99elip/19thoi/38nhãn/XML/PDF1pageA4/SQLhash và xemảnh; không đổiDB/runtime/Wordowner.

Owner yêu cầu lược đồ quan hệ dạng chữ copy được vàoWord vớiPKliền/FKđứt. Tạo Luoc-do-quan-he-DBMS12.docx,đủ12/99;12PKsingle/19FKdash đúngOOXML;12pt,A4portrait,mộttrang. Skilldocuments,bundledpython-docx;render_docx.py thiếusofficeWindows,nativeWordẩn/readOnly/emptyinstanceguard được dùng đểrender tài liệu mới vàPopplerbundled rasterQA. Không sửaWordownerkhác,cácfileQAở.local;chỉdeliverDOCX.
