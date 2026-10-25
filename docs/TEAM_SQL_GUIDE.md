# Nhóm nhận bản SQL thực hành — 25/10/2026

Repository riêng: https://github.com/quangbru376-blip/DBMS12_EnglishCenter, nhánh `main`. Thành viên cần được chủ repository cấp quyền truy cập trước khi clone. Gửi tài liệu này cho người trong nhóm; không gửi `.local`, `config/machine.json`, mật khẩu, credential, chứng chỉ/private key hoặc database của máy tác giả.

## 1. Nhận source và kiểm được trên máy mình

```powershell
git clone https://github.com/quangbru376-blip/DBMS12_EnglishCenter.git
cd DBMS12_EnglishCenter
pwsh -NoProfile -File tools/Test-Environment.ps1 -Mode Build
pwsh -NoProfile -File tools/Test-Project.ps1
node tools/Verify-SqlLayout.cjs
node tools/Verify-SqlLearning.cjs
node tools/Verify-StudyAssignment.cjs
```

Cần Git, PowerShell7, .NET10 SDK và Node24/npm11 theo [Quickstart](TEAM_QUICKSTART.md). Build source chưa đòi database. Để chạy đầy đủ, làm đúng từng pha trong Quickstart và [Setup Windows](SETUP_WINDOWS.md): SQL Server Database Engine, Windows runtime identity/login và TLS tin cậy riêng của máy nhận. SSMS là trình quản trị; không thay Database Engine.

Phòng thực hành CLI còn cần `sqlcmd` tương thích các tham số `-Nm`, `-F`, `-f`, `-X1`. Bản đã kiểm trên máy tác giả là SQLcmd ODBC dùng ODBC18. Kiểm `Get-Command sqlcmd` và `sqlcmd -?`; chọn đúng executable trên PATH. Tải theo [Microsoft — SQLcmd](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-download-install?view=sql-server-ver17) và [tham số utility](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility?view=sql-server-ver17), không bỏ TLS để chữa khác phiên bản. Playwright chỉ cần cho kiểm browser tùy chọn, không cần cho các bước học SQL bên dưới.

## 2. Chạy ứng dụng và tạo phòng học riêng

Sau khi hoàn tất môi trường máy mới:

```powershell
pwsh -NoProfile -File tools/Test-Environment.ps1 -Mode Run
./Chay-Project.cmd
```

Mở https://localhost:8446/dbms12. Tài khoản mẫu của **máy mình** xem bằng Xem-TaiKhoan.cmd. Lần đầu tạo catalog mới; lần sau giữ dữ liệu. Enter ở launcher để đóng host bình thường trước bước tạo fixture/build cần thiết.

Đã build và host đã đóng:

```powershell
./tools/Invoke-SecurityRehearsal.ps1 -SkipBrowser
./tools/Invoke-SqlLearning.ps1 -Prepare
```

Lệnh đầu tạo catalog fixture riêng, kiểm schema/DBCC/native roles/transaction và lưu profile private. Không chạy lại để sửa một receipt đang lỗi; giữ state để điều tra. Lệnh thứ hai chỉ nhận profile fixture đúng danh tính/source pin, đánh dấu phòng học và sinh `.local/operator/sql-learning/SSMS_SESSION.sql`. Khi fixture đã có, có thể mở lại app chính; việc chạy bài SQL dùng catalog fixture riêng, không cần tắt app.

## 3. Chạy riêng khi giáo viên yêu cầu

1. Owner kết nối SQL Server bằng SSMS, chọn database fixture ghi ở đầu SSMS_SESSION.sql.
2. Chạy SSMS_SESSION.sql một lần trên query window đó.
3. Mở [danh mục107 bài](../database/practice/README.md), chọn file của SP/Function/View/Trigger/Transaction, copy vào cùng query window rồi F5 toàn bài. Không cần SQLCMD Mode.
4. Đọc phần chuẩn bị, kết quả TRƯỚC/SAU, PASS hoặc lỗi mong đợi. Mặc định rollback để chạy lại. SID/hash/password không được hiển thị.

Ví dụ bằng CLI:

```powershell
./tools/Invoke-SqlLearning.ps1 -Case functions/fn_GradeTotal.sql
./tools/Invoke-SqlLearning.ps1 -Case stored-procedures/usp_AdmissionApprove.sql
./tools/Invoke-SqlLearning.ps1 -Group views
./tools/Invoke-SqlLearning.ps1 -Group triggers
./tools/Invoke-SqlLearning.ps1 -Group indexes
```

Chạy toàn bộ và các nhánh transaction:

```powershell
./tools/Invoke-SqlLearning.ps1 -All
./tools/Invoke-SqlLearning.ps1 -Group transactions -ForceRollback
./tools/Invoke-SqlLearning.ps1 -Group transactions -CommitTransactions
```

COMMIT giữ dữ liệu LAB thật trên fixture. Thực hành tuần tự; chỉ bài concurrency mới chủ động dùng hai phiên cùng lúc. ClassStart có chờ16giây để đến giờ học thật. Bootstrap bị từ chối đúng51236 vì đã có tài khoản; các bài trigger PASS khi lệnh vi phạm bị chặn đúng lỗi. Xem giải thích trong [hướng dẫn học](study/SQL_LEARNING_START.md).

## 4. Đọc và chia phần cho4 người

|Mục tiêu|Tài liệu|
|---|---|
|Biết đề yêu cầu gì|[Rubric3.1–3.5](study/RUBRIC_SQL_SERVER.md), [bảng đối chiếu](study/SQL_RUBRIC_MATRIX.md)|
|Tìm định nghĩa và câu gọi của từng object|[Index105 object](../database/dbms12-compact/OBJECT_INDEX.md), cộtChạy riêng|
|Chia nhóm học theo nghiệp vụ|[4thành viên:27/26/26/26 object](study/DATABASE_OBJECTS_4_MEMBERS.md)|
|Rút gọn SP để báo cáo|[6 SP chính/người; đủ 61 SP và nhiệm vụ](study/STORED_PROCEDURES_CATALOG.md)|
|Transaction mỗi thành viên|[29 nghiệp vụ, 2 bài trọng tâm mỗi người](study/TRANSACTIONS_4_MEMBERS.md)|
|Giải thích bảng/quan hệ/3NF|[Relational schema vàFD](study/SQL_SCHEMA_3NF.md), [ERD99thuộc tính](diagrams/ERD-full-attributes.md)|
|Index và minh chứng|[17index,5benchmark](study/SQL_INDEXES.md)|
|Giao dịch và concurrency|[Transaction](study/SQL_TRANSACTIONS.md), [5bài riêng](../database/practice/README.md#transactions)|
|Quyền SQL|[Policy](SQL_SECURITY.md), [matrix](SQL_SECURITY_MATRIX.md)|

**5transaction trong bài học là5nghiệp vụ thật được chọn làm ví dụ**, không phải toàn bộ transaction của dự án. Có29commandSP,19read,8auth và5helper, tổng61SP có quản lý transaction. Helper có thể dùng chung giao dịch caller. Ngoài5ví dụ, các nghiệp vụ lịch, điểm danh và gửi/trả/chốt bảng điểm cũng quan trọng. Mỗi thành viên phải hiểu đầu vào, trước/sau, guard, quyền và transaction của phần mình.

## 5. Cập nhật clone đang có dữ liệu

Không chạy lại Prepare-Machine, không xóa `.local` hoặc chạy installer/sample trên database cũ. Đóng host bình thường, kiểm `git status` và lưu thay đổi của mình trước khi nhận bản mới. Khi checkout sạch:

```powershell
git pull --ff-only origin main
pwsh -NoProfile -File tools/Test-Project.ps1
```

Đọc riêng `ManifestSha256` trong profile để chọn đường nâng, không in toàn bộ profile lên chat:

```powershell
(Get-Content .local/config/profile.json -Raw | ConvertFrom-Json).ManifestSha256
(Get-FileHash database/dbms12-compact/manifest.json -Algorithm SHA256).Hash
```

|Profile đang có|Cách xử lý|
|---|---|
|Không có profile và chưa provision|Đi theo setup máy mới; để launcher tạo catalog mới|
|Hash đã khớp manifest hiện tại|Mở lại ứng dụng; không migrate lại|
|NativeSecurityV2 trướcD15, hash bắt đầuF72E0E99|Chạy rehearsal transaction rồi migration nếuPASS, theo các lệnh dưới|
|D15 đã có transaction, hash bắt đầuF24FCEA4|Chỉ chuyển đường dẫn bằng `--rebind-sql-layout`, không ALTER lại dữ liệu|
|Hash khác, partial receipt hoặc đã sửa module|Dừng để agent đối chiếu source/profile/DB; không sửa pin/reset để vượt guard|

Với đúng bản trướcD15:

```powershell
dotnet backend/EnglishCenter.Dbms12/bin/Debug/net10.0/EnglishCenter.Dbms12.dll --rehearse-sql-transactions .local/config/profile.json
# Chỉ chạy tiếp khi lệnh trên thành công và đã đọc kết quả:
dotnet backend/EnglishCenter.Dbms12/bin/Debug/net10.0/EnglishCenter.Dbms12.dll --migrate-sql-transactions .local/config/profile.json
```

Với đúng bảnD15 chỉ đổi thư mục:

```powershell
dotnet backend/EnglishCenter.Dbms12/bin/Debug/net10.0/EnglishCenter.Dbms12.dll --rebind-sql-layout .local/config/profile.json
```

Các CLI kiểm hash đầy đủ và exact database identity; tiền tố trên chỉ giúp nhận diện, không thay guard. Receipt/profile rollback nằm private. Bản11SP cũ dùng migration bảo mật riêng trong [Runbook](../memory/05_RUNBOOK.md); không đoán lệnh từ bảng trên. Source và profile phải khớp module đã cài, không chỉ đổi chuỗi SHA.

## 6. Khi tự sửa và gửi bài nhóm

Tạo nhánh riêng trước khi sửa, ví dụ `codex/ten-thanh-vien`; sửa đúng phần được giao. SQL định nghĩa ở dbms12-compact, câu gọi/tham số thực hành ở practice. Chỉ lưu file hoặc bấm Tải lại web chưa triển khai SP/Function mới vào database; luyện ALTER trên fixture trước, giữ source chuẩn và main nguyên trạng. Generator ghi đè các file được sinh, nên giữ bản thử riêng trước khi sinh lại.

Trước gửi thay đổi: chạy Test-Project và verifier phù hợp, ghi đã kiểm/chưa kiểm và kiểm `git diff`. Thay source SQL phải cập nhật manifest có chủ đích và đánh giá migration; không chỉ sửa profile. Gửi pull request để nhóm review. Không commit config máy, credential, ledger, session, key, backup, bin/obj/node_modules/dist.

Prompt có thể gửi agent của thành viên:

> Đọc AGENTS.md và9memory đúng thứ tự, rồi docs/TEAM_SQL_GUIDE.md, TEAM_QUICKSTART.md, REQUIREMENTS.md. Kiểm source/build trước; chỉ chuẩn bị môi trường mới khi chủ máy giao và theo đúng Windows identity. Mỗi máy tự tạo credential/keys/catalog, không lấy .local của tác giả. Dùng fixture cho107bài, giữ61SP/12bảng99cột/native roles và SQL có tham số. Nếu checkout đã có profile thì kiểm version/identity và migration guard, không reset/reseed/đổi pin để cho qua. Báo lệnh và PASS/FAIL/chưa kiểm, không xuất secrets.

Bằng chứng trong repository là của lần chạy trên máy tác giả. Clone/build được kiểm sạch trước publish; cài account/cert/SQL/SSMS trên máy Windows thứhai vẫn phải nghiệm thu thật ở máy nhận. Không coi đủ số object là đã hiểu hoặc được chấm đạt toàn bộ môn.
