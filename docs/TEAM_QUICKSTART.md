# Agent của nhóm: clone, cài và chạy

Bản học SQL mới và cập nhật clone đã có dữ liệu: [TEAM_SQL_GUIDE](TEAM_SQL_GUIDE.md). Đọc mục version/migration trước khi pull và chạy lại app trên profile cũ.

Windows x64; bản12bảng/61SP. Mỗi máy tạo DB,credential,keys riêng; không copy.local hoặc cần project cha. Agent đọc AGENTS+9memory theo thứ tự, rồi REQUIREMENTS,CONTEXT_MAP,SETUP_WINDOWS.

## Nhận source và kiểm build

```powershell
git clone https://github.com/quangbru376-blip/DBMS12_EnglishCenter.git
cd DBMS12_EnglishCenter
pwsh -NoProfile -File tools/Test-Environment.ps1 -Mode Build
pwsh -NoProfile -File tools/Test-Project.ps1
```

Cần Git,PowerShell7.4+ x64 (7.6 đã kiểm),.NET10 SDK,Node24.x/npm11+. Cài toàn máy để runtime cũng chạy được dotnet. Nguồn [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/install-powershell-on-windows), [.NET](https://learn.microsoft.com/en-us/dotnet/core/install/windows), [Node](https://nodejs.org/en/download), [Git](https://git-scm.com/downloads/win).

```powershell
winget install --id Git.Git --exact --source winget
winget install --id Microsoft.PowerShell --exact --source winget
winget install --id Microsoft.DotNet.SDK.10 --exact --source winget
```

Chọn Node24 installer từ nguồn chính thức; mở terminal mới. Chỉ sửa/build source thì đủ bước này. Đừng nâng dependency để chữa thiếu toolchain; giữ npm/NuGet locks. npm run dev chỉ là preview, chưa chạy đầy đủ ứng dụng.

## Chuẩn bị máy mới theo từng danh tính

Cài SQL Server **Database Engine**, named instance SQLEXPRESS,Windows Authentication,Shared Memory enabled; SQL2022 Express dùng cho sample. SSMS chỉ là công cụ quản lý. Bản này không nhận LocalDB/default instance/SQL từ xa. Owner đủ quyền provision; runtime không sysadmin/dbcreator/db_owner. Chi tiết quyền và cài SQL tại SETUP_WINDOWS.

Script setup chỉ dùng khi chủ máy giao cài trên clone mới; hỗ trợ -WhatIf và từ chối workspace đã provision/operator state. Account/folder/file đã có: kiểm state, làm tiếp thủ công đúng bước; không xóa/reset để chạy lại. Nếu đổi RuntimeUser/RuntimeFolder, dùng nhất quán mọi pha/config.

**Owner elevated**, tại root DBMS12:

```powershell
pwsh -NoProfile -File tools/setup/Prepare-Machine.ps1 -Phase CreateRuntime -WhatIf
pwsh -NoProfile -File tools/setup/Prepare-Machine.ps1 -Phase CreateRuntime
```

Hỏi mật khẩu SecureString; tạo user mới Dbms12Runtime thuộc Users,folder C:\ProgramData\DBMS12-Team\Runtime và RX đúng root source. Không Modify source hay mở quyền toàn ổ đĩa.

**Owner sẽ chạy launcher**, không dùng Windows admin khác để tạo DPAPI:

```powershell
pwsh -NoProfile -File tools/setup/Prepare-Machine.ps1 -Phase SaveCredential
pwsh -NoProfile -File tools/Initialize-MachineConfig.ps1
```

Credential nằm tại %LOCALAPPDATA%\DBMS12-Team\Operator\runtime.credential.clixml,DPAPI owner/machine và ACL owner/SYSTEM. Initialize tạo config/machine.json theo máy nhận và.local/setup/runtime-login.sql,không overwrite hoặc chạy SQL. Mở SQL script bằng SSMS, kết nối đúng instance bằng owner, chạy một lần để tạo Windows LOGIN runtime. Provision tạo DB/user/role mới sau đó.

**Runtime non-admin, có profile:** mở PowerShell bằng “Run as different user” hoặc `runas /profile /user:TENMAY\Dbms12Runtime pwsh.exe`. Nhập mật khẩu trong prompt Windows, không command/chat. Trong cửa sổ runtime:

```powershell
whoami
cd C:\DBMS12\DBMS12_EnglishCenter # thay bằng root thực
pwsh -NoProfile -File tools/setup/Prepare-Machine.ps1 -Phase WebCertificate
```

Tạo localhost cert/privatekey không export trong runtime CurrentUser/My,chỉ xuất public https.cer và in thumbprint. **Owner/browser** đối chiếu thumbprint rồi:

```powershell
pwsh -NoProfile -File tools/setup/Prepare-Machine.ps1 -Phase TrustWebCertificate -Thumbprint THUMBPRINT_40_KY_TU_HEX
```

Chỉ trust đúng public cert vừa tạo; dotnet dev-certs dưới owner không thay được privatekey trong runtime store.

**SQL TLS:** nếu instance đã có cert SANlocalhost/chain tin cậy cho owner/runtime thì giữ nguyên. Với instance dev mới, **owner elevated**:

```powershell
pwsh -NoProfile -File tools/setup/Prepare-Machine.ps1 -Phase SqlCertificate -SqlInstance SQLEXPRESS -WhatIf
pwsh -NoProfile -File tools/setup/Prepare-Machine.ps1 -Phase SqlCertificate -SqlInstance SQLEXPRESS
```

Tạo cert dev SQL mới LocalMachine/My,CAPI RSA KeyExchange,SAN tên máy+localhost; cấp Read đúng privatekey mới cho service account của instance; publiccert/trust LocalMachine/Root. Không export privatekey. Không dùng cert dev để public deployment.

Script không bind/restart SQL. Owner chọn đúng thumbprint trong SQL Server Configuration Manager → Protocols for SQLEXPRESS → Properties → Certificate,rồi restart đúng instance. Shared Memory phải bật. Nếu dùng chung instance, đánh giá ảnh hưởng trước khi đổi. [Microsoft: cấu hình certificate SQL](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-sql-server-encryption?view=sql-server-ver17).

Luôn Encrypt=true;TrustServerCertificate=false;HostNameInCertificate=localhost. Không dùng -C,bỏ HTTPS/TLS hoặc bỏ guard để chữa lỗi.

## Chạy và nghiệm thu máy nhận

```powershell
pwsh -NoProfile -File tools/Test-Environment.ps1 -Mode Run
./Chay-Project.cmd
```

Doctor chỉ đọc toolchain/config/account/credential/service/port; PENDING là phần cần host kiểm dưới runtime. preflightPassed không phải READY. Lần đầu launcher tạo PROJECT catalog và10mật khẩu riêng,lần sau giữ state. Mở https://localhost:8446/dbms12;Xem-TaiKhoan.cmd để xem tài khoản cục bộ.

```powershell
(Invoke-WebRequest 'https://localhost:8446/health/ready').Content
```

Kỳ vọng ready qua TLS tin cậy. Kiểm login/xem theo vai trò;Enter dừng bình thường, sau đó:

```powershell
pwsh -NoProfile -File tools/Test-Project.ps1 -CheckDatabase
```

Mở lại kiểm giữ catalog/dữ liệu. Creation receipt có nhưng thiếu profile: giữ state để điều tra,không xóa.local/drop/reseed/tạo DB khác che lỗi. Browser mutation suite không tự chạy khi setup.

Agent bàn giao OS/versions/lệnh đã chạy/build/health/DBCC/login/restart PASS/FAIL,lỗi đã che secrets và bước chưa kiểm. Không gửi.local,machine.json,CLIXML,certificate/privatekey/mật khẩu lên GitHub. Pack-Source/Export-TeamSource dùng cùng inventory và kiểm định dạng secret; vẫn duyệt staged trước push.

Repo này độc lập, source ở gốc, không clone repo lớn. Repo private: owner cấp quyền cho đúng GitHub username của thành viên qua Settings → Collaborators trước khi họ clone; agent không tự mời người chưa được owner chỉ định.

Chưa chạy các pha đặc quyền trên Windows thứ hai trong lượt chuẩn bị này; kiểm local chỉ chứng minh parser/guard/export/build. Agent nghiệm thu thực trên máy nhận.
