# DBMS12 EnglishCenter

Project nhỏ quản lý trung tâm tiếng Anh để học và báo cáo môn Hệ quản trị CSDL: **12 bảng, 61 stored procedure**, 7 function, 9 view, 12 trigger. Gồm backend ASP.NET Core/.NET10, frontend React/TypeScript và SQL Server. Mọi đọc/ghi DB là SQL có tham số, không EF.

## Chạy trên máy đã chuẩn bị

1. Nhấp đúp **Chay-Project.cmd**.
2. Mở **https://localhost:8446/dbms12**.
3. Nhấp đúp **Xem-TaiKhoan.cmd** để xem 10 tài khoản mẫu, mật khẩu riêng được sinh lúc tạo DB.
4. Nhấn Enter trong launcher để dừng; mở lại giữ dữ liệu và khóa.

Project dùng database mẫu PROJECT riêng, cookie/key/profile riêng, không cần source của project cha. Đọc [Runbook](memory/05_RUNBOOK.md) về Windows/SQL Server/Node/.NET và runtime identity/certificate đã chuẩn bị. Những prerequisite của máy không nằm trong source ZIP; không có mật khẩu mặc định.

## Thành viên nhóm bắt đầu ở đây

[TEAM_QUICKSTART.md](docs/TEAM_QUICKSTART.md) có lệnh clone, kiểm môi trường, công cụ setup theo từng danh tính và tiêu chí chạy thành công trên máy riêng.

```powershell
git clone https://github.com/quangbru376-blip/DBMS12_EnglishCenter.git
cd DBMS12_EnglishCenter
pwsh -NoProfile -File tools/Test-Environment.ps1 -Mode Build
pwsh -NoProfile -File tools/Test-Project.ps1
```

Để chạy SQL/HTTPS, làm tiếp các pha trong Quickstart. Công cụ dùng account/cert riêng của máy nhận, không tự reset hoặc ghi đè cấu hình đã có.

Đây là repository độc lập, source nằm ngay ở gốc; không cần repo English-Center lớn. Repository private nên tài khoản GitHub của thành viên phải được cấp quyền trước khi clone.

1. [REQUIREMENTS.md](REQUIREMENTS.md): phạm vi chức năng, phiên bản phần mềm, quyền SQL/Windows và tiêu chí nghiệm thu.
2. [SETUP_WINDOWS.md](docs/SETUP_WINDOWS.md): chuẩn bị máy theo từng bước, phân biệt build source với chạy đủ SQL/HTTPS.
3. [CONTEXT_MAP.md](docs/CONTEXT_MAP.md): ngữ cảnh đã chốt, nơi tìm chi tiết và prompt gửi cho agent của nhóm.

Gói đủ source và ngữ cảnh cho **bản DBMS12 hiện tại**; người nhận không cần thư mục project cha. Mỗi máy phải tự chuẩn bị runtime account/SQL login/chứng chỉ và sinh sample riêng. Hướng dẫn đã đối chiếu code, chưa nghiệm thu chạy trên máy thứ hai. Word/PDF rubric và lịch sử bản cũ không kèm gói; không coi memory là bằng chứng đáp ứng toàn bộ đề môn học.

## Bố cục

```text
AGENTS.md                 Quy tắc và thứ tự đọc cho agent
memory/                   9 file project memory có thứ tự
backend/EnglishCenter.Dbms12/  Backend + crypto helpers/resources riêng
frontend/                 UI 7 vai trò, không có các màn hình bản cũ
database/dbms12-compact/   SQL/manifest, 56 operation SP + 5 SP hạ tầng
tools/                    Chạy, kiểm và đóng gói source
tests/browser/            Kiểm tích hợp tùy chọn, có ghi sample
docs/API.md               Contract và map route → SQL
docs/evidence/            Kết quả kiểm của chính project này
.local/                   State cá nhân, không đưa vào Git/ZIP
```

Agent khác bắt đầu tại [AGENTS.md](AGENTS.md), rồi [memory/00_START_HERE.md](memory/00_START_HERE.md). Source và bằng chứng hiện tại là chuẩn; memory giải thích bối cảnh, phạm vi và quyết định.

## Nghiệp vụ

Học viên đăng ký/xác nhận → tuyển sinh duyệt và phát hành hóa đơn → kế toán thu đủ → giáo vụ xếp lớp → giáo viên điểm danh/nhập hai điểm → giáo viên gửi và giáo vụ chốt toàn lớp → học viên xem kết quả đã công bố. Có quản lý khóa/lớp/lịch, account/audit và báo cáo theo vai trò.

Đã bỏ Band/Program, thi đầu vào, workflow thi lại riêng, Payment nhiều đợt và bảng Role. Quyền dùng Account.role_code kết hợp bảy database role/user và guard theo phiên SQL. [Nghiệp vụ](memory/02_DOMAIN.md), [Database](memory/04_DATABASE.md), [API](docs/API.md).

[Lược đồ quan hệ đủ12bảng/99cột](docs/diagrams/DBMS12-relations.md): PNG/PDF dùng trong báo cáo, SVG phóng to, drawio chỉnh sửa và ERD Mermaid; kèm bảng19khóa ngoại/cardinality theo DDL.

[ERD theo mẫu owner, đầy đủ thuộc tính](docs/diagrams/ERD-full-attributes.md): bản Mermaid chân quạ hiện tại, có PNG/SVG/PDF và source để chỉnh sửa.

[ERD Chen](docs/diagrams/ERD-Chen.md):12thực thể chữ nhật,19quan hệ hình thoi,99thuộc tính elip; PNG/SVG/PDF13trang vàdrawio chỉnh sửa.

[ERD Chen theo phong cách ảnh mẫu](docs/diagrams/ERD-Chen-classic.md): bản hiện tại màu trắng/đen/xám, thuộc tính tỏa, nhãn1/N và đường đôi cho tham gia bắt buộc; kèm phân tích ký pháp,PDF/SVG/PNG/drawio.

[ERD Chen cho một trang Word A4 dọc](docs/diagrams/ERD-Chen-A4-portrait.md): bản2cột×6hàng,SVG18×26cm/PNG/PDFmộttrang/drawio; giữ đủ99thuộc tính và hướng dẫn chènWord.

[ERD theo mẫu báo cáo mới](docs/diagrams/ERD-Chen-A4-sample.md): bản ưu tiên hiện tại, khung trắng, khóa chính vàng, Times New Roman và lực lượng min/max; giữ đủ12bảng/99thuộc tính/19quan hệ trên một trangA4dọc.

[Lược đồ quan hệ dạng chữ để copy vào Word](docs/diagrams/Luoc-do-quan-he-DBMS12.docx):12quan hệ,99thuộc tính,PKgạch chân liền/FKgạch chân nét đứt bằng định dạngWord thật;A4mộttrang,chữ12pt.

## Kiểm và chia sẻ

```powershell
pwsh -NoProfile -File tools/Test-Project.ps1 -CheckDatabase
pwsh -NoProfile -File tools/Pack-Source.ps1
```

Dừng host trước khi build source thay đổi. Bộ kiểm nhanh không tự reset hay seed. Test tích hợp ghi sample chạy riêng, đọc thứ tự và điều kiện trong Runbook. Source ZIP không chứa mật khẩu/key/DB/profile hoặc thư mục build/dependency.

`tools/Export-TeamSource.ps1 -Destination <thu-muc-moi>` tạo bản source sạch dùng cho Git; dùng cùng quy tắc loại private/build files và kiểm định dạng secret với Pack-Source.

Bằng chứng và giới hạn thực tế: [review](docs/plan/REVIEW.md). Chưa claim cài máy khác, public Internet, backup/restore, tải lớn hoặc WCAG đầy đủ.

[Phân quyền SQL theo hướng A](docs/SQL_SECURITY.md), [ma trận từng SP](docs/SQL_SECURITY_MATRIX.md) và [nội dung báo cáo mục 4.2](docs/reports/4_2_QuanLyBaoMat.md). Bảy user nghiệp vụ là ngữ cảnh WITHOUT LOGIN được backend sử dụng; Windows Login runtime là định danh đăng nhập SQL thực tế.

Bản phân quyền mới đã migrate trên PROJECT và kiểm native SQL/HTTP/UI; xem [review bảo mật SQL](docs/plan/SQL_SECURITY_REVIEW.md). Bằng chứng và gói ZIP 11 SP trước đó giữ nguyên làm lịch sử; tạo ZIP mới bằng công cụ đóng gói nếu cần chia sẻ phiên bản này.
