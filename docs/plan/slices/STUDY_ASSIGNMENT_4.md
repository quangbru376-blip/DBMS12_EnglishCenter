# STUDY_ASSIGNMENT_4 — 24/10/2026

Owner cần chia đều Database Object cho4thành viên học theo nghiệp vụ. Chỉ lập tài liệu/phân công,không đổi schema/quyền/dữ liệu/source ứng dụng;không commit/push.

Scope: docs/study/DATABASE_OBJECTS_4_MEMBERS.json và.md;tools/Verify-StudyAssignment.cjs chỉ đọc;README link;note/review/evidence;memory01/08 vàplan.md. Sửa memory02 mục5 nếu đối chiếu nguồn phát hiện guardOPEN/ONGOING được diễn đạt sai;không đổi SQL.

Đơn vị kiểm:105object do project khai báo thuộc7nhóm Table12/SP61/FN7/View9/Trigger12/TVP3/Sequence1. Mỗi object có đúng1người phụ trách trình bày,chưa tính riêng constraint/index/securityprincipal. Các mục này học cùng bảng/quyền nghiệp vụ và cả nhóm cùng nắm nền tảng. Objecthạ tầng chung vẫn cóownertrìnhbày,không bị diễn giải thành chỉ phục vụ1nghiệp vụ.

Chia27/26/26/26 theo4cụm:account/session/audit;registration/admission/invoice/reporting;course/class/placement/scheduleplanning;sessiondelivery/attendance/grades. Tài liệu đủ tên105object,đườngdẫnSQL,luồng/guard/testcase/câu hỏi/điểmbàn giao. Chưa có tên thật nên dùngTV1–TV4.

Acceptance: đối chiếu manifest installOrder vàDDL,đủ105khôngtrùng/thiếu,61SP gồm5hạ tầng,tên nguồn đúng;Markdown vàJSON nhấtquán;Test-Project PASS;chỉdocs/read-onlytool thayđổi. Không testwriteDB hay claim đã đào tạo/thi vấnđáp thành công.

Status: COMPLETE / scoped review PASS.105object đầy đủ/unique/tênnguồn đúng,27/26/26/26;35linksresolve;102protectedhash unchanged;Test-Project PASS. Chỉ tài liệu/read-onlytool,không thực hànhSQLwrite/commit/push.
