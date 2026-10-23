# TEAM_GITHUB_SETUP — 24/10/2026

Owner yêu cầu chuẩn bị requirements/công cụ cho agent nhóm rồi push GitHub. Steering24/10: nguồn chính xác C:\Study\SOEN\main_workplace\DBMS12_EnglishCenter,repo riêng không liên quan repo lớn;chọn quangbru376-blip/DBMS12_EnglishCenter PRIVATE,source ngay gốc,Git init mới không kế thừa history/object của cha. Không push English-Center hoặc commit thay đổi ở cha.

Scope: REQUIREMENTS/README/AGENTS, docs/SETUP_WINDOWS/CONTEXT_MAP/TEAM_QUICKSTART, config/machine.example.json, công cụ setup/check/package và kiểm công cụ; .gitignore; note/review/evidence của slice; memory/plan. Không sửa backend/frontend/SQL nghiệp vụ, dependency locks, database/runtime/account/certificate/ACL hiện tại.

Chuẩn bị công cụ theo pha: kiểm Build/Run không ghi state; tạo runtime mới, credential DPAPI của owner, chứng chỉ web trong runtime, cert SQL dev và script SQL login; cấu hình máy không overwrite. Không tự cài package hệ thống, bind/restart instance, reset hoặc bỏ TLS. Các pha setup chỉ chạy khi chủ máy nhận giao cài đặt, hỗ trợ WhatIf và từ chối workspace đã provision.

Acceptance: parser+guard/no-overwrite/WhatIf tests;doctor;Test-Project;source-only export/secret checks/SQLbytes;Gitcheckout sạch build;repo PRIVATE mới không fork/rootcommit không parent/rootTree là project12;commit/push không force và xác minh remote SHA. Chỉ stage inventory public của đúng root;parentindex giữhash. Không claim Windows thứhai. Dùng skill code-review,không delegation.

Status: COMPLETE / scoped review PASS. RepoPRIVATE riêng đã tạo/push main/remoteSHA verified,rootcommit khôngparent,forkfalse,parentindexunchanged. Clone lại từ repo riêng và Test-Project PASS;20toolchecks/doctor/SQLpins/ZIPchecks PASS. Chưa nghiệm thu Windows thứhai.
