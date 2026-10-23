# Chạy, kiểm thử và bàn giao

## Chạy trên máy hiện tại

1. Nhấp đúp Chay-Project.cmd, mở https://localhost:8446/dbms12.
2. Nhấp đúp Xem-TaiKhoan.cmd để mở 10 mật khẩu mẫu riêng tại .local/operator/tai-khoan.md. Không có mật khẩu mặc định và không dùng credential của APP25/demo24.
3. Enter trong launcher để dừng bình thường. Mở lại giữ dữ liệu và khóa. Launcher thứ hai chỉ reuse khi PID/startTime/dll/profile/ready khớp; cổng bận không đúng receipt thì từ chối, không kill process khác.

Lần đầu launcher chạy npm ci nếu thiếu node_modules, NuGet locked restore và audit, build backend/frontend, tạo catalog mới và fixture, rồi chạy host dưới Windows runtime identity. Những lần sau không seed lại DB. Network chỉ cần khi dependency chưa có trong cache.

## Điều kiện môi trường

Người nhận source ZIP: đọc [REQUIREMENTS](../REQUIREMENTS.md) và [SETUP_WINDOWS](../docs/SETUP_WINDOWS.md) để chuẩn bị máy theo bước. Chỉ cần build thì chưa cần SQL/account/cert; để chạy đủ phải hoàn tất tất cả prerequisite bên dưới. File example dùng placeholder;Initialize-MachineConfig sinh đường dẫn máy nhận trước provision lần đầu. CheckOnly chỉ là path/identity/port/ACL preflight, không chứng minh credential/TLS/SQL đã hoạt động.

- Windows, PowerShell7, .NET10 SDK, Node>=24/npm>=11, SQL Server có TLS thật tin cậy với hostname localhost.
- Launcher copy config/machine.example.json thành config/machine.json nếu thiếu. Kiểm các đường dẫn; chỉ cho local SQL transport lpc.
- Owner chạy launcher cần quyền CREATE DATABASE/CREATE USER trên SQL. Dedicated non-admin Windows runtime user và SQL Windows login phải tồn tại. Trên máy hiện tại đó là EcM0Runtime đã được chuẩn bị.
- runtimeCredentialPath trỏ tới PSCredential CLIXML được DPAPI bảo vệ theo owner, khớp MACHINE\runtimeUser. Không đặt mật khẩu trong JSON.
- httpsCertificatePath là public certificate runtime đọc được; cert và private key đúng thumbprint nằm trong CurrentUser/My của runtime, localhost đã được máy/browser trust. Owner có thể không đọc được path này do ACL; host xác minh certificate dưới runtime identity.
- Runtime phải có RX source/binary và được truy cập đường dẫn project. Launcher chỉ thiết lập ACL cho .local mới; nếu chuyển sang thư mục bị khóa, operator kiểm quyền RX đúng thư mục project, không mở quyền rộng hay đổi custody cũ.

Launcher không tự cài SQL/.NET/Node, tạo Windows account/certificate hoặc thay ACL của môi trường cũ. Trên máy mới cần operator chuẩn bị các điều kiện này; chưa claim installer hoặc nghiệm thu máy khác. Source độc lập không có nghĩa là đóng gói cả SQL Server và key của máy.

## Kiểm nhanh

```powershell
node tools/Verify-Source.cjs
pwsh -NoProfile -File tools/Test-Project.ps1
pwsh -NoProfile -File tools/Test-Project.ps1 -CheckDatabase
```

Dừng host trước khi build có thay đổi source để tránh DLL đang khóa. Test-Project build frontend/dist cho kiểm thử; host phục vụ .local/web do launcher build. CheckDatabase chỉ SELECT/DBCC đúng profile, không tự tạo fixture. Phải chạy launcher một lần trước khi có profile.

## Kiểm tích hợp tùy chọn, có ghi sample

Cần Edge và driver Playwright đã cài. Nếu Node không resolve driver, đặt EC_PLAYWRIGHT_MODULE tới module đó. Application không phụ thuộc Playwright và không tự cài test framework. Không dùng ignore TLS hoặc xuất debug headers.

Thứ tự trên fixture mới: browser-smoke → ui-teacher (điểm danh/điểm nháp) → http-journey (hoàn thành và chốt lớp2) → ui-journey (cohort mới/mất ACK) → ui-weekly-move → audit-rollback → final-http. Tên file nằm trong tests/browser/.

HTTP cohort test không thể chạy vô hạn trên cùng fixture đã chốt điểm. Không tự reseed để che lỗi; xem receipt/state rồi chọn fixture mới trong phạm vi owner giao. Không chạy audit-rollback song song UI tạo khóa: trigger thử nghiệm cố ý chặn audit course create, chỉ ở PROJECT catalog đã guard và được dọn trong finally.

## Lỗi và phục hồi

- TLS không tin cậy: sửa trust/binding đúng, không TrustServerCertificate/ignoreHTTPS.
- Port8446 bận: kiểm receipt; không kill PID chưa xác minh.
- Ownership/creation receipt có nhưng thiếu profile: giữ state để điều tra, không tự CREATE catalog lần hai hoặc reset.
- Mất ACK: dùng Kiểm tra kết quả; không tự gửi lại. Receipt vắng chưa chứng minh rollback.
- Mất mật khẩu tạm: Admin cấp lại bằng một thao tác mới, không replay cũ để lấy password.
- Chuyển vị trí: source sạch tại root mới sẽ tạo sample DB riêng khi môi trường đã chuẩn bị. Không copy .local cũ, sửa Workspace hoặc mang DPAPI sang máy khác tùy ý.

## Gửi cho agent khác

Dùng tools/Pack-Source.ps1 tạo ZIP source; script bỏ .local, config/machine.json, node_modules, bin/obj/dist và các file key/DB. Agent đọc AGENTS.md và memory trước. Muốn chuyển dữ liệu hiện hành cần task backup/restore riêng, không phải source pack.

## Bảo mật SQL V2 và migration

61SP/62SQLfile,7nativebusinessrole/user. Xem docs/SQL_SECURITY.md và ma trận. Fresh provision tự cài bản mới; không chạy lại schema/sample trên catalog hiện có. Legacy đúng manifest cũ chỉ được nâng bằng CLI --rehearse-security-migration / --migrate-security sau khi host dừng; guard name/ID/GUID/file,11definitionhash, fingerprint12bảng/sequence và private rollback receipt. Không sửa profile chỉ để vượt pin.

Kiểm có ghi dùng tools/Invoke-SecurityRehearsal.ps1 (fixture riêng). --verify-security từ chối workspace thường. Các driver browser nhận EC_DBMS12_TEST_ROOT và EC_DBMS12_EVIDENCE_ROOT để không ghi đè bằng chứng cũ. Đọc receipt khi chạy lại; không reset fixture finalized.

Máy nhóm/GitHub: docs/TEAM_QUICKSTART.md; tools/Test-Environment.ps1 chỉread preflight;tools/setup/Prepare-Machine.ps1 theoidentity/freshworkspace/WhatIf; tools/Initialize-MachineConfig.ps1 khôngoverwrite. Cácpha privileged chưa nghiệmthu Windows thứhai,khôngchạylên máy hiện tại để thử. Sourceexport/ZIP dùng chunginventory/secret-format check;không gửi state.
