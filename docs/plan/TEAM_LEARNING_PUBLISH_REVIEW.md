# Review TEAM_LEARNING_PUBLISH — 25/10/2026

Verdict: **PASS; source đã commit/push và remoteSHA đã xác nhận**. Owner đã yêu cầu rõ việc xuất bản lên repository độc lập. Dùng checklist skill code-review, không delegation. [Scope](slices/TEAM_LEARNING_PUBLISH.md), [hướng dẫn nhóm](../TEAM_SQL_GUIDE.md). Source release20bdc124545279bb755f434310947682588b207d đã push main và git ls-remote khớp. Receipt trong docs/evidence/team-learning-publish/publication.json.

Bản này gồm các slice STUDY_ASSIGNMENT_4, SQL_TRANSACTIONS, SQL_OBJECT_FOLDERS và SQL_LEARNING_PACK đã hoàn thành trong chat. Không thêm nghiệp vụ hoặc nới quyền để xuất bản. Nội dung giữ12bảng99cột/61SP/7FN9VW12TG/7native roles/62SQLpins,105object và107bài học. Review từng slice và evidence gốc được giữ, không đổi hash/path lịch sử thành kết quả mới.

Hướng dẫn mới phân biệt clone mới với cập nhật profile đang có dữ liệu; dẫn đúng Quickstart/Windows identity/TLS, SQLcmd ODBC đã kiểm, fixture/SSMS và từng nhóm bài. Có đường nâng guarded NativeSecurityV2→transaction và D15→layout, yêu cầu rehearsal/identity/hash; không hướng dẫn sửa pin/reset. Giải thích5transaction là5ví dụ thật, không phải toàn bộ29commandSP. Repo access cần owner cấp theo username; không tự mời/gửi tin.

## Kiểm trước commit

|Kiểm|Kết quả|
|---|---|
|Git root/branch/origin/fetch|Đúng project độc lập,main;originDBMS12_EnglishCenter;HEAD vàorigin/main cùnge9cec8c,khôngforce|
|`Test-Project.ps1 -CheckDatabase`|PASS lockedrestore/audit,backend0warnings/errors,frontendtypes/lint/5tests/build,mainDBCC|
|`tests/tools/team-tools.ps1`|PASS20;không chạy pha đặc quyền thật|
|Source/layout/learning/study verifiers|PASS62pins/61scopes/29replay/7roles,layout byte-identical,107cases,105objects27/26/26/26|
|Source inventory và Test-Dbms12SourceContents|PASS khôngprivate/buildstate;không phát hiện các định dạngsecret bị chặn|
|Staged path set vs safe inventory|PASS936files của tree ban đầu khớp chính xác allowlist;không.local/config máy/key/credential/DB|
|Gitarchive stagedtree87d9449bb5887527b80669504257b723cd465160|PASS fresh restore/build/frontend5tests/types/lint/source62pins/layout/learning trên checkout sạch|
|Learning source hash117 và hướng dẫn links|PASS sourcebài học khôngđổi;48liên kết local của hướng dẫn chính còn tồn tại|
|Code whitespace với CRLF và generated EOF được giữ|PASS; không tính rawSTATISTICSlog có khoảng trắng định dạng|

Clean build là từ đúng staged Git tree, không dùng bin/obj/node_modules/dist của workspace. Bổ sung sau clean test chỉ gồm docs/memory/evidence; xác nhận bằng diff tree trước commit. Không claim đã chạy cài account/cert/SQL/TLS trên Windows máy thứhai. Không lặp mutation107bài trong lượt xuất bản vì source bài học đã so hash khớp; giữ bằng chứng thực SQL trước đó. Main không bị reset/reseed/revoke/restart; không đổi khóa/ACL/chứng chỉ.

Không còn finding phải sửa trong scope trước push. Các bằng chứng clean build và staged scan không chứng minh production/load/backup recovery hoặc điểm chấm toàn môn. Đã đối chiếu origin/main SHA với commit local và ghi receipt; nếu network/policy từ chối phải giữ nguyên commit để điều tra,khôngforce.

Staged whitespace audit phát hiện các dòng trống cuối file bài học và khoảng trắng do STATISTICS IO in ra. Giữ nguyên bytes đã kiểm/hash; code check loại docs/evidence và cho phép blank-at-EOF thìPASS. Không thay nội dung SQL chỉ để làm sạch log.
