# Kế hoạch phân quyền SQL theo nhóm nghiệp vụ

**Trạng thái hiện tại: COMPLETE / scoped code-review PASS.** Owner đã giao triển khai sau kế hoạch. Kết quả:61SP,7nativebusinessrole/user,12bảng99cột; PROJECT đã migrate giữ dữ liệu, kiểm mới tại SQL_SECURITY_REVIEW.md và ../evidence/sql-security/summary.json. Thiết kế thực tế: ../SQL_SECURITY.md. Nội dung PLAN ONLY bên dưới giữ làm lịch sử quyết định, không còn là trạng thái hiện tại.

Ngày 22/10/2026. Trạng thái: PLAN ONLY. Owner chọn hướng A trong trao đổi: truy cập nghiệp vụ qua SP/view và quyền SQL riêng, cho phép điều chỉnh giới hạn 11 SP khi cần. Chưa triển khai, chưa tạo login/user/role, chưa cấp hoặc thu hồi quyền trên database đang dùng.

## Phạm vi đã chốt

Giữ 12 bảng, 99 cột và nghiệp vụ hiện tại của 7 vai trò. SQL user/role là đối tượng bảo mật, không tạo bảng Role trong mô hình ứng dụng. Tiếp tục SQL có tham số, HTTPS tin cậy, Windows runtime non-admin, transaction nghiệp vụ/audit/receipt nguyên tử, kiểm phiên/RV và xử lý mất ACK bằng tra cứu riêng. Chỉ bản PROJECT/8446 thuộc phạm vi; APP25/demo24 không thay đổi.

Giới hạn đúng 11 SP của D02 được mở cho thiết kế bảo mật này. Tổng SP cuối cùng phải có danh sách tường minh, gồm cả SP hạ tầng nếu có; không dùng procedure khổng lồ nhận tên operation/SQL tùy ý để giữ một con số hình thức. Đây không phải yêu cầu thêm nghiệp vụ.

## Kiểm kê nguồn hiện tại

Nguồn: database/dbms12-compact/manifest.json và infrastructure/*.sql.

| Nhóm operation | Tổng | SP hiện có | Batch hiện có |
|---|---:|---:|---:|
| Lệnh nghiệp vụ |29|11|18|
| Đọc dữ liệu |19|0|19|
| Xác thực và vận hành |8|0|8|
| Tổng |56|11|45|

Ngoài 56 operation, executor còn chạy SQL kiểm phiên, khóa Course, đọc replay, hoàn tất audit/receipt/activity và ghi lỗi sau rollback; repository còn truy vấn hash mật khẩu hiện tại. Các đường này phải được tính vào thiết kế khi thu hồi quyền trực tiếp bảng. Không kết luận tổng cuối cùng là 56 SP nếu còn cần module hạ tầng riêng.

## Nhóm quyền nghiệp vụ dự kiến

| SQL role | Vai trò ứng dụng | Phạm vi qua module được cấp |
|---|---|---|
| role_QuanTri |Admin|Nhân sự, tài khoản, trạng thái, cấp lại mật khẩu tạm, nhật ký|
| role_TuyenSinh |Admissions|Danh mục khóa học, hồ sơ và quyết định tuyển sinh|
| role_GiaoVu |AcademicAffairs|Khóa, lớp, lịch, xếp lớp, xác nhận buổi, duyệt bảng điểm|
| role_GiaoVien |Teacher|Lớp phụ trách, lịch dạy, roster, điểm danh và bảng điểm|
| role_KeToan |Accountant|Hóa đơn, thu tiền, điều chỉnh thông tin thu và báo cáo tài chính/CSV|
| role_GiamDoc |Director|Báo cáo tổng hợp, chỉ đọc|
| role_HocVien |Student|Hồ sơ, đăng ký, hóa đơn, lớp, lịch và kết quả của chính mình|

Các nhóm kỹ thuật phục vụ xác thực, vận hành và cài đặt phải tách khỏi 7 nhóm nghiệp vụ. Admin trong ứng dụng không đồng nghĩa SQL sysadmin/db_owner hoặc Windows administrator. Không cấp schema-wide EXECUTE/SELECT cho Giám đốc như vai trò quản lý nhà hàng trong mẫu; giữ đúng trách nhiệm đã chốt của trung tâm.

Role kiểm soát quyền đối tượng; Actor/SID/epoch, trạng thái và ownership tiếp tục kiểm soát từng dòng và thao tác. Quyền đọc một view không tự chứng minh học viên chỉ xem dữ liệu của mình. Các view toàn cục không được cấp thẳng cho nhóm học viên/giáo viên nếu chưa bảo đảm phạm vi dữ liệu.

## Thiết kế cần hoàn tất trước khi viết migration

1. Lập ma trận đầy đủ: operation → vai trò → SP/view/type/function → dữ liệu đọc/ghi → trường hợp bị cấm. Tách operation công khai, auth nội bộ và operator-only.
2. Liệt kê các SP đích: chuyển các operation cần thiết thành SP chuyên biệt; quyết định vị trí kiểm phiên, replay, completion, password lookup và audit lỗi sau rollback. Đối chiếu tổng SP rõ ràng và giữ giao dịch do C# điều phối.
3. Chốt đường kết nối/ngữ cảnh SQL: backend xác thực trước, ánh xạ role từ kết quả SQL tin cậy sang SQL user/context cố định. Không nhận tên principal từ browser. Nếu dùng EXECUTE AS, phải có allowlist, kiểm native role, REVERT/cleanup và kiểm không rò ngữ cảnh sau thành công/lỗi. Không tiếp tục chạy nghiệp vụ bằng user có toàn bộ quyền bảng rồi chỉ tạo role để minh họa.
4. Chốt định danh phục vụ minh họa Login → User → Role. Khảo sát cấu hình xác thực hiện có trước; không tự bật Mixed Mode, tạo Windows user, đổi certificate hoặc restart instance dùng chung. User WITHOUT LOGIN có thể dùng cho kiểm impersonation, nhưng không thay bằng chứng đăng nhập nếu tiêu chí yêu cầu login thật. Credential minh họa được quản lý riêng tại máy.

## Trình tự triển khai sau khi được giao thực hiện

### Bước 1 Ma trận và hợp đồng bảo mật

Hoàn tất ma trận, danh sách SP, sơ đồ kết nối và cách chứng minh quyền theo từng principal. Ghi rõ các thay đổi contract nội bộ; ưu tiên giữ HTTP/UI hiện tại. Lập danh sách file và migration trước khi thu hồi quyền.

### Bước 2 SQL và kiểm quyền độc lập

Thực hiện trên catalog thử PROJECT được xác minh name/ID/GUID. Tạo roles/users, GRANT module phù hợp và DENY truy cập bảng trực tiếp cho nhóm nghiệp vụ theo ma trận; không DENY bảng mù quáng làm cản trở đường gọi được thiết kế. Kiểm quyền hiệu lực, ownership chaining, type/function permissions và native role checks. Không cấp sysadmin/db_owner cho người dùng nghiệp vụ.

Kịch bản REVOKE minh họa một quyền được cấp tạm, thu hồi và kiểm lại hành vi; không coi REVOKE là DENY hoặc dùng REVOKE thay biện pháp bảo vệ hóa đơn/nhật ký. Kiểm quyền kế thừa từ role/schema/public.

### Bước 3 Backend và giao dịch

Cập nhật repository/executor/profile/provision/manifest/verifier cho mô hình mới. Các thao tác dữ liệu của nhóm nghiệp vụ chạy dưới đúng SQL principal. Giữ kiểm phiên, ownership, RV, password-change scope, audit/receipt cùng transaction và không retry sau mất ACK. Nếu dùng quyền nâng trong module, phạm vi phải hẹp, không mở SQL động tùy ý.

### Bước 4 Kiểm tích hợp và giao diện

Chạy kiểm native SQL rồi kiểm HTTP/UI theo 7 vai trò. Chỉ chạy test có ghi trên dữ liệu kiểm riêng. Không tái chạy cohort đã finalized hoặc reset sample đang dùng để che lỗi. Kiểm normal stop/restart và launcher sau thay đổi, không đổi custody cũ.

### Bước 5 Chuyển đổi database hiện hành

Chuẩn bị migration thay đổi module/permissions không xóa bảng hay dữ liệu; nhận diện đúng catalog. Lưu trạng thái định nghĩa/quyền trước thay đổi và có script hoàn tác trong phạm vi thay đổi. Dừng host bình thường khi cần. Chỉ cập nhật manifest/profile pin theo phiên bản đã kiểm chứng, không sửa pin để vượt drift guard. Chỉ chuyển runtime sau khi database thử đạt kiểm.

### Bước 6 Tài liệu và báo cáo

Cập nhật API nếu contract đổi, Runbook/setup, requirements, verifier, decision, memory và số SP thực tế. Viết mục 4.2 theo nguyên tắc, định danh và quyền của 7 nhóm trung tâm; kèm script và bằng chứng cho phép/từ chối/thu hồi quyền. Các bằng chứng 11 SP cũ giữ nguyên ngày và phạm vi, không đổi nhãn thành kết quả mới.

## Tiêu chí nghiệm thu dự kiến

- Mỗi nhóm có database role/user và minh chứng membership; có login thật nếu tiêu chí yêu cầu.
- Người dùng nghiệp vụ không thực hiện được SELECT/INSERT/UPDATE/DELETE trực tiếp trên bảng bị cấm.
- Chỉ module được cấp mới chạy được; vượt vai trò bị SQL từ chối ngay cả khi gọi ngoài UI.
- Admin không thu tiền/sửa điểm; Teacher không thu tiền/quản lý tài khoản; Accountant không sửa điểm; Director không ghi nghiệp vụ.
- Student không đọc/sửa hồ sơ người khác; Teacher không thao tác lớp không phụ trách. Kiểm cả giả mạo Actor và SID sai role.
- Luồng hợp lệ vẫn hoàn tất qua ứng dụng, rollback khi audit lỗi, receipt chống lặp, mất ACK không gửi lại.
- Quyền/context không lan sang yêu cầu tiếp theo; failure/cancellation cleanup được kiểm.
- Module count, manifest hashes và SQL permissions có bằng chứng mới; 12 bảng/99 cột và dữ liệu hiện hành được bảo toàn.
- Demo GRANT/REVOKE/DENY dùng tài khoản kiểm, không thu hồi phiên hoặc quyền của owner ngoài phạm vi migration được giao.

## Việc chưa làm tại bước kế hoạch (lịch sử)

Đây là kế hoạch sau lựa chọn hướng A. Chưa chốt tổng SP cuối cùng hoặc phương án principal/context, chưa khảo sát authentication mode trực tiếp, chưa viết/chạy migration hoặc tạo credential/login, chưa thay backend/SQL/runtime. Bước tiếp theo trong thảo luận là duyệt ma trận operation và thiết kế thực thi; owner chưa yêu cầu triển khai lên database đang dùng.
