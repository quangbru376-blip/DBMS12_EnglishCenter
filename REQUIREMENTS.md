# Yêu cầu dự án và môi trường DBMS12

Tài liệu dành cho thành viên nhóm và agent chỉ nhận gói `DBMS12_EnglishCenter`. Không cần source hay lịch sử chat của project cha. Đọc [README](README.md), tài liệu này và [cài Windows](docs/SETUP_WINDOWS.md); agent đọc thêm đúng thứ tự trong [AGENTS](AGENTS.md).

Clone GitHub và công cụ setup theo pha: [TEAM_QUICKSTART](docs/TEAM_QUICKSTART.md). Test-Environment kiểm môi trường; Initialize-MachineConfig sinh cấu hình riêng; setup/Prepare-Machine chuẩn bị runtime/credential/chứng chỉ mới theo đúng Windows identity. Không có requirements.txt Python; ứng dụng dùng NuGet/npm locks.

## Phạm vi đã chốt

Đây là ứng dụng quản lý trung tâm tiếng Anh rút gọn để học và báo cáo môn Hệ quản trị CSDL. Giữ **12 bảng, 99 cột**, 7 function, 9 view, 12 trigger. Ngày 22/10/2026 owner chọn hướng A: **61 stored procedure** (56 operation + 5 hạ tầng), bảy database role/user nghiệp vụ, chặn quyền trực tiếp bảng. Ràng buộc 11 SP/45 batch cũ được thay thế. Mọi đọc/ghi database dùng SQL tường minh có tham số; không EF Core hoặc LINQ-to-database.

C# giữ HTTP, validation DTO, hash mật khẩu, JWT/CSRF, CSV, điều phối call/role và cleanup; theo D15, SQL sở hữu transaction nghiệp vụ (61/61 SP có TRY/CATCH/BEGIN/COMMIT/ROLLBACK), giữ truy vấn và ràng buộc nghiệp vụ, tính điểm/tiền, phân quyền theo actor/phiên. Đây là yêu cầu hiện tại đã được owner chốt, không tự đổi thành EF để dễ cài. [Decision log](memory/07_DECISIONS.md), [database](memory/04_DATABASE.md).

## Yêu cầu chức năng

|ID|Yêu cầu|Vai trò/điều kiện chính|
|---|---|---|
|FR01|Đăng nhập/đăng xuất/đổi mật khẩu; tự đăng ký Student; quản lý nhân sự|7 vai trò trong Account CHECK; mật khẩu nhân sự tạm phải đổi|
|FR02|Quản lý khóa học|AcademicAffairs; học phí, số buổi, trọng số, đúng hai điểm cố định|
|FR03|Đăng ký, xác nhận, duyệt/từ chối/hủy hồ sơ|Student sở hữu hồ sơ; Admissions duyệt và phát hành hóa đơn nguyên tử|
|FR04|Thu học phí và sửa thông tin thanh toán có lý do|Accountant; một hóa đơn/hồ sơ, thu đủ một lần, không trả góp/refund|
|FR05|Tạo/mở/bắt đầu/hoàn thành lớp; xếp lớp|AcademicAffairs; đúng khóa, đã trả tiền, còn chỗ, đủ lịch, không xung đột|
|FR06|Lập lịch từng buổi/theo tuần, dời lịch|AcademicAffairs; LESSON + FINAL_EXAM; kiểm giáo viên/phòng/lớp/học viên|
|FR07|Điểm danh tường minh và xác nhận buổi đã tổ chức|Teacher lớp mình; AcademicAffairs xác nhận HELD khi hợp lệ|
|FR08|Nhập hai điểm/nhận xét, gửi/trả lại/chốt cả bảng điểm|Teacher và AcademicAffairs; đủ toàn lớp, RV đúng; FINALIZED bất biến|
|FR09|Xem hóa đơn/lớp/lịch/kết quả cá nhân|Student chỉ thấy của mình, điểm chỉ hiện sau FINALIZED|
|FR10|Báo cáo, CSV và nhật ký|Director/Accountant/Admin đúng quyền; không chia sẻ credential|

Luồng chính: Student đăng ký → xác nhận → Admissions duyệt/tạo hóa đơn → Accountant thu đủ → AcademicAffairs xếp lớp → Teacher điểm danh/nhập điểm/gửi bảng điểm → AcademicAffairs chốt → Student xem kết quả. Guard chi tiết, nhánh hủy và thời điểm thao tác: [DOMAIN](memory/02_DOMAIN.md), [API và route → SQL](docs/API.md), source SQL trong manifest.

Đã bỏ Band/Program, thi đầu vào/booking, workflow thi lại, Role table, Payment nhiều đợt, refund và import hàng loạt. Không khôi phục các tính năng đó chỉ vì nhớ bản cũ. Gói không kèm Word hoặc PDF rubric gốc của môn; chưa có đối chiếu chứng minh đáp ứng toàn bộ rubric. Muốn kiểm theo đề gốc phải lấy đề từ owner, không suy đoán yêu cầu giảng viên.

## Yêu cầu kỹ thuật và dữ liệu

|ID|Yêu cầu|
|---|---|
|TR01|Mọi SELECT/INSERT/UPDATE/DELETE dùng SQL có tham số; route và operation cố định, không nhận SQL/actor/SID từ browser|
|TR02|SQL sở hữu một transaction cho nghiệp vụ, audit và replay receipt; kiểm phiên, quyền, ownership và RV. 61 SP đầy đủ template; caller có transaction thì SP dùng chung, caller chốt|
|TR03|Mất phản hồi sau COMMIT: giữ trạng thái chưa rõ, lookup thủ công, không tự gửi lại|
|TR04|Tiền dùng decimal trong SQL và chuỗi chính xác tại API; tổng điểm/pass được SQL suy ra|
|TR05|HTTPS tin cậy cùng origin, cookie Secure/HttpOnly, CSRF; runtime Windows không admin, SQL không sysadmin/db_owner|
|TR06|Catalog mới có prefix PROJECT_, profile/keys/cookies riêng; restart giữ dữ liệu, không tự seed/reset|
|TR07|Mỗi máy tạo mật khẩu và khóa của máy mình; .local/config máy/credential/DB/private key không gửi trong source ZIP|
|TR08|Source và assets nằm trong project; NuGet/npm restore theo lock; SQL manifest SHA giữ nguyên bytes|

Yêu cầu 3.4 owner cung cấp ngày25/10: ít nhất5 nghiệp vụ BEGIN/COMMIT/ROLLBACK và một tình huống concurrency hoặc recovery. Hướng dẫn, script và bằng chứng: [SQL_TRANSACTIONS](docs/study/SQL_TRANSACTIONS.md). Đoạn yêu cầu này không thay thế toàn bộ rubric chưa được cung cấp.

## Phần mềm để build source

|Thành phần|Yêu cầu của project|Đã dùng trên máy kiểm 22/10/2026|
|---|---|---|
|Windows|Hướng chạy đầy đủ dùng Windows x64, tài khoản local và DPAPI; chọn Windows 11 được hỗ trợ|Chỉ kiểm trên máy Windows hiện tại|
|PowerShell|7.4+ x64 cho công cụ nhóm, gọi bằng pwsh; Windows PowerShell5.1 không đủ|7.6.5|
|.NET|**SDK 10.0**, gồm ASP.NET Core runtime; Runtime đơn lẻ không build được|SDK 10.0.200|
|Node.js|24.x được chọn làm nhánh môi trường của nhóm; package yêu cầu >=24|24.16.0|
|npm|11.x; package yêu cầu >=11; dùng `npm ci`|11.13.0|
|Mạng|Truy cập NuGet/npm khi cache chưa có|ZIP không chứa dependency folders|

Cài từ nguồn chính thức: [.NET Windows](https://learn.microsoft.com/en-us/dotnet/core/install/windows), [PowerShell Windows](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows), [Node.js downloads](https://nodejs.org/en/download). Chọn nhánh trên, không cần trùng từng patch của máy kiểm. Không tự nâng package/lock để khớp một Node hoặc SDK cũ.

Không cần Visual Studio, Python, Docker hoặc project cha. Git cần cho clone/push GitHub; người nhận ZIP không cần Git để build ứng dụng. VS Code/Visual Studio tùy chọn. Dependency ứng dụng đã được khai báo trong `.csproj` + `packages.lock.json` và `frontend/package.json` + `package-lock.json`.

## Điều kiện bổ sung để chạy ứng dụng với database

|Thành phần|Điều kiện bắt buộc|
|---|---|
|SQL Server|Database Engine Windows dạng named instance local, ví dụ SQLEXPRESS; Shared Memory bật; `sqlServer` dạng `lpc:.\SQLEXPRESS` hoặc `lpc:localhost\TENINSTANCE`|
|Nhánh cài gợi ý|SQL Server 2022 Express cho sample; Developer nếu nhóm đã dùng cho dev/test. Đây là cấu hình hướng dẫn, chưa có matrix kiểm mọi edition/version|
|Công cụ SQL|SSMS hữu ích cho cài login/chứng chỉ/kiểm DB; cài SSMS đơn lẻ không cài Database Engine|
|Owner/operator|Windows user chạy launcher; có quyền tạo catalog, schema/user/role và đọc metadata/DBCC cho catalog của mình|
|Runtime|Local Windows user riêng, tên chữ/số/underscore tối đa20, bắt đầu bằng chữ, **không Administrators**, có profile và SQL Windows login chỉ quyền cơ bản|
|Credential|PSCredential CLIXML do đúng owner tạo trên đúng máy, userName chính xác `TENMAY\runtimeUser`; password không nằm trong JSON|
|SQL TLS|Chứng chỉ SQL hợp lệ cho hostname `localhost`, chain được owner và runtime trust; `Encrypt=true;TrustServerCertificate=false`|
|Web HTTPS|Chứng chỉ localhost có private key trong **CurrentUser/My của runtime**; public `.cer` đúng cert và runtime đọc được; owner/browser trust|
|Filesystem|Owner ghi project; runtime RX source/binary và đi qua thư mục cha; launcher chỉ cấp quyền cần thiết trong .local|
|Port|8446 trống; URL cố định `https://localhost:8446/dbms12`|
|Browser|Edge để khớp kiểm đã chạy; browser tích hợp phải trust chứng chỉ localhost|

Không hỗ trợ trực tiếp LocalDB `(localdb)`, SQL login/password, default instance `.`, SQL từ xa, Linux/macOS, Docker SQL hoặc sửa port bằng machine.json trong bản hiện tại. Đó là giới hạn guard code, không phải kết luận SQL Server không có các khả năng này. Hướng dẫn đầy đủ: [SETUP_WINDOWS](docs/SETUP_WINDOWS.md). Phân biệt edition theo [Microsoft SQL Server 2022](https://learn.microsoft.com/en-us/sql/sql-server/editions-and-components-of-sql-server-2022?view=sql-server-ver16).

## Lệnh kiểm theo mức

Chạy từ thư mục chứa `.dbms12-project.json` bằng PowerShell7:

```powershell
pwsh --version
dotnet --list-sdks
dotnet --list-runtimes
node --version
npm.cmd --version
pwsh -NoProfile -File tools/Test-Environment.ps1 -Mode Build
node tools/Verify-Source.cjs
pwsh -NoProfile -File tools/Test-Project.ps1
```

Các lệnh trên chưa tạo database hay cần runtime credential. Sau khi hoàn tất SETUP_WINDOWS, dùng `Chay-Project.cmd`; lần đầu tạo sample riêng. Khi đã có profile, dừng host bằng Enter rồi dùng `pwsh -NoProfile -File tools/Test-Project.ps1 -CheckDatabase`. Chỉ muốn đọc source hoặc build không cần hoàn tất bước account/cert/SQL.

Playwright chỉ dành cho bộ kiểm browser tùy chọn, không là dependency của ứng dụng. Cài driver trên máy kiểm theo nhu cầu rồi trỏ `EC_PLAYWRIGHT_MODULE`; suite tích hợp có ghi dữ liệu và thứ tự cụ thể tại [RUNBOOK](memory/05_RUNBOOK.md). Không tự chạy lại cohort đã chốt điểm.

## Tiêu chí nghiệm thu trên máy của người nhận

- Source verifier, restore/build/types/lint/5 client tests PASS.
- Launcher báo READY; `GET https://localhost:8446/health/ready` trả200 `ready` qua TLS thật tin cậy.
- Xem tài khoản cục bộ, đăng nhập theo vai trò; kiểm `-CheckDatabase` khớp12 bảng/99cột/61SP/7FN/9VW/12TG.
- Enter dừng bình thường; mở lại giữ catalog và dữ liệu, không seed lần hai.
- Ghi lại version và kết quả trên máy đó. Bằng chứng máy tác giả không thay thế nghiệm thu máy người nhận.

Source pack không chuyển dữ liệu thực hành, session hay mật khẩu của máy tác giả. Memory đủ ngữ cảnh **bản DBMS12 hiện tại**; nguồn chi tiết và giới hạn bàn giao nằm trong [CONTEXT_MAP](docs/CONTEXT_MAP.md).

## Công cụ cho agent cài máy nhận

|Công cụ|Thực hiện|Danh tính|
|---|---|---|
|Test-Environment.ps1 -Mode Build/Run|Chỉ kiểm môi trường;JSON với -AsJson,exit1 khi thiếu,không giả READY|Owner|
|Initialize-MachineConfig.ps1|Tạo machine.json không overwrite và script Windows LOGIN không tự thực thi|Owner máy mới|
|setup/Prepare-Machine.ps1 -Phase CreateRuntime|Tạo account/folder mới,Users và RX đúng source root|Owner elevated|
|… -Phase SaveCredential|Credential qua secure prompt,DPAPI/ACL riêng|Owner chạy launcher|
|… -Phase WebCertificate|Localhost cert/privatekey trong runtime profile|Runtime non-admin|
|… -Phase TrustWebCertificate|Trust publicwebcert đã đối chiếu thumbprint|Owner/browser|
|… -Phase SqlCertificate|Cert SQL dev mới,Read key đúng service;khôngbind/restart|Owner elevated|
|Export-TeamSource.ps1 / Pack-Source.ps1|Source sạch,không overwrite,kiểm định dạng secret|Owner|
|tests/tools/team-tools.ps1|Parser/guard/no-overwrite/WhatIf/export trong fixture file riêng|Developer|

Các pha setup hỗ trợ -WhatIf và từ chối workspace đã provision. Không chạy để sửa máy tác giả đang hoạt động. Binding/restart SQL và nghiệm thu dưới runtime vẫn là bước theo Quickstart, không đánh dấu PASS chỉ vì đã tạo config.

Phân quyền chi tiết: docs/SQL_SECURITY.md. Máy hiện tại dùng Windows Login runtime và bảy user WITHOUT LOGIN được impersonate theo phiên; không tuyên bố có bảy server login riêng hoặc tự bật Mixed Mode.

## PhầnSQL của đề đã nhận ngày25/10

Owner đã cung cấp nội dung3.1–3.5 và xác nhận cần chạy riêngSP/Function/Trigger/View/Transaction. Bản ghi: docs/study/RUBRIC_SQL_SERVER.md; đối chiếu: SQL_RUBRIC_MATRIX.md; thực hành: SQL_LEARNING_START.md và database/practice. Đã có12bảng/61SP/7FN/9VW/12TG/17index tường minh, nhưng cần giải thích3NF,policy và minh chứng index/transaction; không chỉ đủ số lượng. Các phần còn lại của đề chưa nhận.
