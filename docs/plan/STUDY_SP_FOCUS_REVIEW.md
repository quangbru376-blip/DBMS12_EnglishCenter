# Review STUDY_SP_FOCUS — 25/10/2026

Verdict: **PASS trong phạm vi tài liệu và verifier**. Dùng skill code-review, không delegation. [Scope](slices/STUDY_SP_FOCUS.md), [phân công](../study/DATABASE_OBJECTS_4_MEMBERS.md), [đủ 61 SP và nhiệm vụ](../study/STORED_PROCEDURES_CATALOG.md), [note](../notes/STUDY_SP_FOCUS.md).

Owner muốn giảm số SP phải học sâu và đưa phần phụ khỏi báo cáo chính. Chọn 6 SP/người, tổng 24 chính và 37 hỗ trợ; inventory 61 SP và 105 object vẫn được công bố đúng. Phân loại theo ưu tiên học, không kết luận các module xác thực/hạ tầng có thể xóa. Giáo viên vẫn có thể hỏi SP ngoài phần chính; phụ lục giữ vai trò và đường tra cứu. Không thay nghiệp vụ, quyền hoặc hợp đồng API nên không có migration/decision kiến trúc.

TV1 giữ cặp LoginRead/LoginRecord để giải thích crypto ở C# và ghi phiên/throttle ở SQL; hai SP Admin vẫn là transaction trọng tâm. TV2 thêm InvoiceSearch/FinanceReport để có tìm kiếm/thống kê, giữ duyệt/thu là transaction; FinanceReport phân biệt billed/revenue theo thời gian và current_debt toàn cục. TV3 giữ vòng đời lớp và xếp lớp/lịch lô; ClassCreate và các nhánh sửa/hủy ở phụ lục. TV4 giữ HELD, điểm danh và đủ lưu/gửi/trả/chốt điểm. Tất cả 8 demo transaction thuộc 24 SP chính; đủ 5 bài COMMIT đã có vẫn là SP chính.

Nhiệm vụ 61 SP đã đối chiếu SQL/manifest và các dependency bảo mật. Không nói LoginRead kiểm hash tại SQL hoặc FinanceExport tự định dạng CSV; không nói 61 SP là 61 nghiệp vụ ghi độc lập. Catalog JSON có source file/dòng/bài chạy; verifier đối chiếu tên/file/dòng với định nghĩa thật, owner và nhiệm vụ hiển thị đúng mức. Bảng thành viên chỉ hiện 6 SP; SP hỗ trợ và danh sách transaction đầy đủ đặt trong details thu gọn, 2 demo transaction vẫn hiện trong bảng chính.

|Kiểm|Kết quả|
|---|---|
|Verify-StudyAssignment|PASS: 105 unique, 61 SP đầy đủ, 24 chính/37 hỗ trợ, đúng 6/người, 8 demo nằm trong nhóm chính|
|So JSON objects/transactionStudy với HEAD|PASS: không chuyển owner hoặc thay 29 command/8 demo|
|Verify-Source / Verify-SqlLayout / Verify-SqlLearning|PASS: 62 pins, 61 scopes, 29 replay returns, 107 bài giữ nguyên|
|Liên kết/details|PASS: 272 local links, 8 cặp details cân bằng, support đúng vị trí thu gọn|
|Export-TeamSource/secret-format/hash copy|PASS; không private/build state|
|Test-Project source sạch|PASS locked restore/audit, backend 0 warnings/errors, frontend types/lint/5 tests/build|

Không chạy lại SQL/HTTP/UI mutation vì chỉ đổi tài liệu/verifier; không coi bằng chứng cũ là lượt kiểm mới. Chưa kiểm rendering GitHub trực tiếp hoặc nghiệm thu nhóm trên máy thứ hai. Note <=15 dòng. Source sạch build dùng đúng verifier/catalog mới. Sau đó chỉ bổ sung tài liệu/bằng chứng và một assertion giữ 5 bài COMMIT trong nhóm SP chính; assertion đã chạy PASS trên source cuối. Scan/staged review trước khi cập nhật repo hướng dẫn theo yêu cầu xuất bản trước đó, không force.
