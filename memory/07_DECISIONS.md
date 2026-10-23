# Các quyết định đã chốt

|ID|Quyết định|Lý do và hệ quả|
|---|---|---|
|D01|Đúng 12 bảng, giảm nghiệp vụ|Owner chấp nhận giảm phạm vi; 12 bảng gồm cả session/audit/replay|
|D02 (lịch sử, thay bằng D14)|Tổng 11 SP và 45 batch thường|Giữ SP chính vừa phải để báo cáo; không helper SP ngầm/giant action dispatcher|
|D03|Mọi đọc/ghi DB là SQL tường minh|C# giữ crypto, HTTP, DTO, CSV; không EF|
|D04|C# caller sở hữu transaction|Audit/receipt/kiểm phiên cùng nghiệp vụ; coarse Course lock ưu tiên tính đúng và dễ giải thích|
|D05|Bảy vai trò trong Account CHECK|Không bảng Role; D14 bổ sung7nativeSQLrole/user, runtime là nhóm kỹ thuật riêng|
|D06|Course config và hai điểm cố định|Tổng điểm, invoice facts và class grade state suy ra bằng FN/VW/Audit|
|D07|Source độc lập và sample DB riêng|Owner chọn ngày 22/10; không chuyển dữ liệu APP25/demo24 sang đây|
|D08|Port8446 và custody riêng|Chạy song song bản cũ, quay lại bằng launcher; không cần drop/restore|
|D09|Dùng lại prerequisite của máy|Cấu hình đường dẫn, không copy secrets hay tự tạo account/certificate; chưa claim installer máy mới|
|D10|Không tự reset/reseed/retry|Bảo toàn thực hành và state sau lỗi; lookup chỉ đọc|
|D11|Memory có thứ tự và trỏ nguồn|Agent sau không cần lịch sử chat hoặc đọc log khổng lồ|
|D12|Gửi riêng gói DBMS12, thêm requirements/setup/context map|Owner yêu cầu22/10; tài liệu cài máy độc lập nhưng không đổi guard, không đóng gói secrets hay claim đã cài máy thứ hai|
|D13|Owner chọn hướng A cho tái thiết kế bảo mật SQL, đang ở bước bàn kế hoạch|Cho phép điều chỉnh giới hạn11SP để nhóm nghiệp vụ truy cập qua SP/view và có SQL role/user riêng; giữ12bảng/99cột và7vai trò. Không coi role tạo thêm cho đủ báo cáo là tích hợp quyền thật. TổngSP/principal/context phải được chốt trong thiết kế; chưa sửa SQL/backend/DB. Kế hoạch docs/plan/SQL_SECURITY_REDESIGN.md|
|D14|Owner giao triển khai hướng A, thay D02|61SP=56operation+5hạ tầng;7nativebusinessrole/user được backend impersonate theo phiên. DENY bảng, module CALLER/ownership, command tự audit/replay; C# transaction/REVERT/explicitCancel. Giữ12bảng/99cột/7FN/9VW/12TG. Windows Authentication hiện tại và runtime Login giữ nguyên; không7serverlogin riêng. Migration có rehearsal/rollback, dữ liệu/sequence không đổi tại chuyển đổi. Xem docs/SQL_SECURITY.md|

Chỉ đổi quyết định phạm vi khi owner đưa yêu cầu mới. Không hỏi lại lựa chọn đã chốt; thêm decision mới nếu có steering thực sự thay đổi chúng.
