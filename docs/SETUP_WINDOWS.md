# Chuẩn bị máy Windows của thành viên nhóm

Hướng dẫn chi tiết cho source ZIP/GitHub. Công cụ theo pha và lệnh clone mới tại [TEAM_QUICKSTART](TEAM_QUICKSTART.md). Các bước cài/account/cert là thao tác trên máy nhận, chưa nghiệm thu trên máy thứ hai; không đổi máy tác giả. Không cần project cha. Nếu dùng script setup, không lặp lại bước tạo account/cert/file bằng tay bên dưới.

Đọc [REQUIREMENTS](../REQUIREMENTS.md) trước. Có hai mức: **build** chỉ cần toolchain; **chạy đủ ứng dụng** cần thêm SQL/identity/TLS. Launcher không tự chuẩn bị các điều kiện của Windows. Người/agent cài máy cần ghi lại từng bước đã làm và kết quả thực, không coi tài liệu này là installer tự động.

## 1. Giải nén và cài toolchain

Giải nén vào thư mục local owner có quyền ghi, ví dụ `C:\DBMS12\DBMS12_EnglishCenter`. Dùng ổ NTFS; tránh OneDrive/network share hoặc cây thư mục profile không cho runtime đi qua. Chưa copy `.local` hay cấu hình máy từ người gửi.

Cài PowerShell7.4+ x64, .NET10 **SDK** và Node24.x/npm11 từ nguồn chính thức trong REQUIREMENTS. PowerShell và .NET có thể cài bằng hai lệnh sau trong terminal của chủ máy (trình cài có thể yêu cầu quyền quản trị):

```powershell
winget install --id Microsoft.PowerShell --exact --source winget
winget install --id Microsoft.DotNet.SDK.10 --exact --source winget
```

Đóng/mở terminal để nhận PATH mới; chọn Node24 installer từ [Node.js](https://nodejs.org/en/download), kiểm npm>=11. Các lệnh Microsoft theo [cài PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows) và [cài .NET](https://learn.microsoft.com/en-us/dotnet/core/install/windows). Không cần cài .NET runtime riêng khi đã có SDK tương ứng.

Từ root project, dùng PowerShell7:

```powershell
pwsh --version
dotnet --list-sdks
dotnet --list-runtimes
node --version
npm.cmd --version
node tools/Verify-Source.cjs
pwsh -NoProfile -File tools/Test-Project.ps1
```

Đến đây có thể đọc/sửa/build source, không cần SQL hay credential. Nếu restore thất bại, sửa network/proxy/PATH/SDK; giữ lock file, không dùng cập nhật tất cả dependency để chữa lỗi môi trường.

## 2. Cài named SQL instance và xác định ba danh tính

Chọn Database Engine SQL Server2022 Express, named instance **SQLEXPRESS**, Windows Authentication, Shared Memory enabled. Có thể dùng named instance khác với tên chữ/số/underscore; sửa `sqlServer` tương ứng ở bước6. Không dùng LocalDB/default instance/SQL từ xa vì guard hiện tại không nhận. SSMS là công cụ quản trị, không thay thế Database Engine.

Trong quá trình cài mới, chỉ định Windows user của chủ máy làm SQL administrator để provision local dev. Có thể dùng owner với quyền được DBA cấp hẹp hơn, nhưng phải đủ tạo database/DDL/permissions và metadata; chưa kiểm mọi tổ hợp least-privilege của owner. **Không cấp các quyền đó cho runtime.**

|Danh tính|Công việc|
|---|---|
|Owner/operator|User chạy launcher, giữ CLIXML và ledger, tạo sampleDB; không chạy launcher bằng runtime|
|Runtime Windows user|Ví dụ `TENMAY\Dbms12Runtime`, non-admin; host chạy dưới user này, chỉ quyền dbms12_runtime trong DB do provision tạo|
|SQL service account|Identity của dịch vụ SQL Server trong Configuration Manager; cần đọc private key của **cert SQL**|

SQL service account không phải runtime Windows user. Login web Student/Admin cũng không phải Windows/SQL login. Không thêm runtime vào sysadmin/dbcreator/db_owner để sửa lỗi kết nối.

## 3. Tạo runtime Windows user và credential riêng

Chỉ làm trên máy mới hoặc account riêng mà chủ máy giao chuẩn bị. Từ PowerShell7 **Run as administrator** của chủ máy:

```powershell
$taskRuntimeName = 'Dbms12Runtime'
$taskRuntimePassword = Read-Host 'Nhap mat khau rieng cho runtime Windows user' -AsSecureString
New-LocalUser -Name $taskRuntimeName -Password $taskRuntimePassword -Description 'DBMS12 local runtime'
Add-LocalGroupMember -Group (Get-LocalGroup -SID 'S-1-5-32-545') -Member $taskRuntimeName
$taskRuntimePassword.Dispose()
$taskRuntimeIdentity = "$env:COMPUTERNAME\$taskRuntimeName"
$taskRuntimeFolder = 'C:\ProgramData\DBMS12-Team\Runtime'
New-Item -ItemType Directory -Path $taskRuntimeFolder -ErrorAction Stop
icacls.exe $taskRuntimeFolder /grant:r "${taskRuntimeIdentity}:(OI)(CI)M"
```

SID S-1-5-32-545 là nhóm Users thông thường, tránh phụ thuộc tên nhóm theo ngôn ngữ Windows. Không thêm Administrators. Nếu account/folder đã tồn tại, dừng kiểm danh tính/quyền, không xóa hoặc đặt lại mật khẩu tài nguyên cũ. Chính sách máy có thể cần cấp quyền đăng nhập cho user này; không dùng `/netonly`, vì host phải chạy thật bằng runtime local user. Mật khẩu hết hạn/bị đổi cần cập nhật CLIXML của chính owner.

Trong terminal của **đúng Windows owner sẽ chạy launcher** (không phải user admin khác dùng để trợ giúp cài), tạo credential. Đây là ví dụ folder ngoài project:

```powershell
$taskOwnerPrivate = Join-Path $env:LOCALAPPDATA 'DBMS12-Team\Operator'
$taskOwnerIdentity = [Security.Principal.WindowsIdentity]::GetCurrent().Name
New-Item -ItemType Directory -Path $taskOwnerPrivate -ErrorAction Stop
icacls.exe $taskOwnerPrivate /grant:r "${taskOwnerIdentity}:(OI)(CI)F"
icacls.exe $taskOwnerPrivate /inheritance:r
$taskCredentialFile = Join-Path $taskOwnerPrivate 'runtime.credential.clixml'
$taskCredential = Get-Credential -UserName "$env:COMPUTERNAME\Dbms12Runtime" -Message 'Mat khau Windows runtime vua tao'
if ($taskCredential.UserName -cne "$env:COMPUTERNAME\Dbms12Runtime") { throw 'Sai runtime identity' }
$taskCredential | Export-Clixml -LiteralPath $taskCredentialFile -NoClobber
$taskCredential.Password.Dispose()
```

Kiểm kết quả `icacls` từng lệnh thành công, folder private chỉ owner có quyền truy cập thông thường; không in nội dung CLIXML. Nếu folder đã có, kiểm trước thay vì chạy đè. DPAPI của Windows gắn credential với user và máy tạo file; **không mang file của tác giả sang máy khác**. [Microsoft Export-Clixml](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/export-clixml).

Trong SSMS, kết nối đúng instance bằng owner/SQL administrator; thay **TENMAY** bằng tên máy thật và chạy một lần:

```sql
USE [master];
GO
CREATE LOGIN [TENMAY\Dbms12Runtime] FROM WINDOWS;
GO
SELECT name, type_desc, is_disabled
FROM sys.server_principals
WHERE name = N'TENMAY\Dbms12Runtime';
```

Nếu login đã tồn tại, kiểm đúng account và server-role memberships trước khi dùng; không tự drop/recreate. Không cần tạo DB hoặc DB user bằng tay: OwnerProvision tạo `Dbms12ProjectRuntime` và thêm vào `dbms12_runtime` trong catalog mới.

## 4. Chuẩn bị SQL TLS

Ứng dụng và provision dùng `Encrypt=true`, `TrustServerCertificate=false`, `HostNameInCertificate=localhost`. Một kết nối SSMS thành công với “Trust server certificate” được tick **chưa đủ** chứng minh ứng dụng sẽ kết nối được.

Operator chuẩn bị cert SQL riêng cho instance mới theo [yêu cầu certificate Microsoft](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/certificate-requirements?view=sql-server-ver17): server authentication, còn hạn, SAN chứa `localhost`, private key với KeySpec/provider SQL hỗ trợ, SQL service account đọc được. Chain/root CA phải được cả owner và runtime trust. Với máy dev cô lập có thể dùng cert tự ký do chủ máy tạo và trust đúng public cert đó; không dùng cert/private key của người gửi.

Làm theo [quy trình bind cert của Microsoft](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-sql-server-encryption?view=sql-server-ver17): cài cert trong Local Computer/Personal, cấp quyền đọc private key cho **SQL service account**, chọn cert trong SQL Server Configuration Manager → SQL Server Network Configuration → Protocols for SQLEXPRESS → Properties → Certificate. Restart đúng instance sau khi bind và kiểm lại dịch vụ. Chỉ đổi instance mới dành cho bài này; nếu dùng instance có ứng dụng khác, operator phải đánh giá ảnh hưởng trước khi đổi binding/restart.

Nếu root là CA riêng/self-signed, chủ máy xác minh thumbprint rồi trust public root/cert trong LocalMachine/Trusted Root để cả hai user dùng được. Không export private key vào source. Việc tạo/cấp cert phụ thuộc CA/chính sách máy nên tài liệu không đưa một PFX/mật khẩu dùng chung. **Bước này phải hoàn tất trước provision**; không chữa lỗi bằng cách tắt Encrypt hoặc bật TrustServerCertificate.

## 5. Tạo HTTPS localhost trong profile của runtime

Web HTTPS và SQL TLS là hai kết nối/cert riêng. Cert web nằm trong CurrentUser/My của **runtime**, không phải CurrentUser/My của owner. Mở một PowerShell7 interactive dưới runtime, có nạp user profile. Có thể dùng Windows “Run as different user” hoặc lệnh `runas /profile` với đúng `TENMAY\Dbms12Runtime`; đăng nhập bằng mật khẩu ở bước3. Không dùng `/netonly`.

Trong cửa sổ runtime, kiểm identity rồi tạo cert web dev mới:

```powershell
whoami
$taskHttpsCert = New-SelfSignedCertificate -DnsName 'localhost' -Type SSLServerAuthentication -CertStoreLocation 'Cert:\CurrentUser\My' -FriendlyName 'DBMS12 localhost web' -KeyExportPolicy NonExportable -NotAfter (Get-Date).AddYears(1)
Export-Certificate -Cert $taskHttpsCert -FilePath 'C:\ProgramData\DBMS12-Team\Runtime\https.cer' -NoClobber
$taskHttpsCert.Thumbprint
```

Thư mục Runtime từ bước3 cho runtime quyền ghi public `.cer`; private key vẫn nằm trong profile runtime. Chỉ tạo mới khi chưa có cert của ứng dụng này; không chạy đè cert cũ. Trong cửa sổ owner, xác minh đúng thumbprint từ cửa sổ runtime và import **public cert vừa tạo** để browser/launcher trust:

```powershell
Import-Certificate -FilePath 'C:\ProgramData\DBMS12-Team\Runtime\https.cer' -CertStoreLocation 'Cert:\CurrentUser\Root'
```

Nếu operator quản trị trust bằng CA hoặc machine store thì làm theo chính sách tương ứng. Không trust cert không rõ nguồn. `dotnet dev-certs https --trust` chạy dưới owner đơn thuần không đặt private key vào store runtime mà host kiểm. Khi cert hết hạn cần quy trình thay đúng cert/profile runtime và trust; không bỏ guard.

## 6. Cấp quyền đọc source và điền cấu hình

Owner giữ quyền ghi source. Runtime cần RX thư mục project/binaries, và quyền đi qua các thư mục cha. Ví dụ với root đã chọn, owner/administrator cấp đúng user (không Everyone) tại root này; **không chạy trên ổ C: hoặc thư mục chứa các dự án khác**:

```powershell
$taskProjectRoot = 'C:\DBMS12\DBMS12_EnglishCenter'
$taskRuntimeIdentity = "$env:COMPUTERNAME\Dbms12Runtime"
icacls.exe $taskProjectRoot /grant:r "${taskRuntimeIdentity}:(OI)(CI)RX"
```

Kiểm các thư mục con/binaries nhận quyền kế thừa; nếu cây source có ACL riêng, chỉ điều chỉnh đúng phần cần RX. Không dùng recursive reset ACL. Launcher tự tạo `.local` và tách quyền operator/config/runtime/web; không cấp runtime quyền đọc `.local/operator` hoặc Modify toàn project.

Tại root, tạo cấu hình trước khi chạy launcher lần đầu:

```powershell
Copy-Item -LiteralPath config/machine.example.json -Destination config/machine.json -ErrorAction Stop
```

Chỉ chạy copy nếu `config/machine.json` chưa có; nếu đã có thì mở kiểm, không ghi đè. Điền ví dụ dưới đây, thay `TENOWNER` bằng đường dẫn credential thực ở bước3 (hoặc dùng đúng absolute path đã tạo):

```json
{
  "sqlServer": "lpc:.\\SQLEXPRESS",
  "sqlHostName": "localhost",
  "runtimeUser": "Dbms12Runtime",
  "runtimeCredentialPath": "C:\\Users\\TENOWNER\\AppData\\Local\\DBMS12-Team\\Operator\\runtime.credential.clixml",
  "httpsCertificatePath": "C:\\ProgramData\\DBMS12-Team\\Runtime\\https.cer"
}
```

JSON dùng `\\` cho separator. Không đưa password, connection string với SQL password hay catalog/DBID/GUID tác giả vào JSON. machine.example.json dùng placeholder; Initialize-MachineConfig.ps1 điền path/tên máy nhận mà không overwrite. Chỉnh machine.json trước provision; sau provision máy được pin trong.local/config/profile.json,đổi machine.json đơn lẻ không chuyển môi trường đã chạy.

## 7. Preflight, chạy lần đầu và kiểm

Từ root, bằng owner:

```powershell
pwsh -NoProfile -File tools/Start-Project.ps1 -CheckOnly
```

CheckOnly kiểm identity/path/port và tạo ACL thư mục `.local`; **không** chứng minh credential giải mã/đăng nhập đúng, SQL TLS, private key/runtime cert hay quyền SQL đã đạt. Nó không build/provision/start. Không coi PASS này là nghiệm thu môi trường đầy đủ.

Nhấp đúp `Chay-Project.cmd`. Launcher restore/build rồi owner tạo catalog tên `EnglishCenter_DBMS12_PROJECT_<GUID mới>`, cài SQL và sample, sinh10mật khẩu riêng; runtime khởi động host. Mở `https://localhost:8446/dbms12`; dùng `Xem-TaiKhoan.cmd` để đọc tài khoản tại máy mình. Signup không tự login; account nhân sự mới có password tạm phải đổi.

Health từ terminal owner phải thành công không bỏ TLS:

```powershell
(Invoke-WebRequest -Uri 'https://localhost:8446/health/ready').Content
```

Kỳ vọng `ready`. Đăng nhập/xem theo vai trò. Nhấn Enter trong cửa sổ launcher để dừng bình thường; kiểm port đã đóng. Sau đó:

```powershell
pwsh -NoProfile -File tools/Test-Project.ps1 -CheckDatabase
```

Kỳ vọng build/tests và exact schema/DBCC PASS; mở launcher lại giữ nguyên catalog/keys/dữ liệu. Các suite HTTP/browser có ghi sample chạy riêng theo [Runbook](../memory/05_RUNBOOK.md), không chạy tự động để “kiểm nhanh”. Không tự reset vì thấy mẫu đã bị dùng.

## 8. Chẩn đoán và giới hạn

|Triệu chứng|Cần kiểm|
|---|---|
|pwsh/dotnet/npm không tìm thấy|Cài đúng bản, mở terminal mới, PATH toàn máy runtime truy cập được; SDK10 + Microsoft.AspNetCore.App10|
|Prepared runtime credential missing|Điền absolute path của máy mình, tạo CLIXML bằng đúng owner|
|Logon failure / credential decrypt|UserName chính xác TENMAY\\runtimeUser, password/Windows policy/profile; không copy DPAPI|
|SQL login failed / runtime mismatch|Đúng named instance/Windows login, runtime không sysadmin/db_owner; DB user do provision tạo|
|SQL certificate chain/name error|Cert bound đúng instance, SANlocalhost, chain trust cả owner/runtime; không tick bypass để cho qua|
|Missing trusted local HTTPS certificate|Đúng runtime CurrentUser/My, private key, public.cer thumbprint, hạn/SAN và trust owner/browser|
|Access denied source/dll/dotnet|RX và quyền đi qua cây thư mục; toolchain cài cho cả runtime; không mở toàn ổ đĩa|
|Port8446 occupied|Đối chiếu receipt/PID/startTime; không kill process chưa xác minh|
|Creation/ownership receipt nhưng chưa có profile|Giữ nguyên DB/.local, xem log và catalog ID/GUID; nhờ agent điều tra phần cài dở. Không xóa receipt/reseed/tạo DB khác che lỗi|
|Manifest/schema mismatch|Không sửa profile/SHA để vượt guard; dùng quy trình thay SQL có đánh giá dữ liệu|

Ghi version, bước đã đạt, lỗi đã che credential/header và evidence vào task của máy nhận. Không gửi `.local`, machine.json, CLIXML, PFX/private key, backup hoặc ledger vào Git/ZIP/chat. Có thể gửi source bằng Pack-Source; nếu ZIP đích đã có thì chọn tên mới. Chưa có nghiệm thu cài máy thứ hai/public/LAN/backup-restore hoặc tải lớn; phạm vi tài liệu này là hướng dẫn chuẩn bị local dev.

## Native Security V2

Provision mới tạo 61 SP và bảy database role/user nghiệp vụ. User nghiệp vụ WITHOUT LOGIN là ngữ cảnh backend thực sự dùng bằng EXECUTE AS USER; runtime được GRANT IMPERSONATE đúng bảy user và chỉ EXECUTE các SP xác thực/hạ tầng. Runtime/nghiệp vụ bị DENY bảng trực tiếp. Không cấp db_owner/sysadmin hoặc SELECT/EXECUTE toàn schema để chữa lỗi.

Windows Login runtime ở hướng dẫn là login SQL thật; không có bảy server login/mật khẩu SQL riêng. Nếu giáo viên yêu cầu đăng nhập trực tiếp theo nhân sự, operator chuẩn bị Windows Login riêng rồi ánh xạ User → Role thích hợp. Không tự đổi Windows Authentication sang Mixed Mode. Xem SQL_SECURITY.md trước khi triển khai hoặc migration.
