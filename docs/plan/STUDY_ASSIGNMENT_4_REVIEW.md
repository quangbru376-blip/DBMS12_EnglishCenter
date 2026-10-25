# STUDY_ASSIGNMENT_4 — review

24/10/2026. Reviewer Codex, checklist code-review; không delegation. **PASS cho tài liệu và kiểm phân công.** Không đánh giá năng lực học/thi của thành viên hoặc tuyên bố đã chạy các bài thực hành trên SQL.

Scope theo slice: docs/study markdown+JSON,read-only Verify-StudyAssignment,README link,note/review/evidence,memory/plan. Bổ sung sửa memory02 mục5 theo tr_Class_Lifecycle: OPEN cần khóa/giáo viên hoạt động và LESSON tương lai;đủ LESSON/1EXAM/có học viên/đến buổi đầu mới là guard ONGOING. Không đổi quy tắc hoặc source SQL.

## Kiểm thực

- Verifier parse các định nghĩa trong manifest.installOrder:12Table/61SP/7FN/9View/12Trigger/3TVP/1Sequence=105. Đủ105,khôngtrùng/thiếu/tên giả;56operationSP và5hạ tầng được phân công;27/26/26/26. Tên trong từng phần Markdown khớp JSON.
-35link nguồn/tài liệu resolve;102protected backend/SQLhash giữ nguyên.
- tools/Test-Project.ps1 PASS:62SQLpins/61SP/7roles,lockedrestore/audit/backendbuild,frontend5tests/types/lint/build. Log tại docs/evidence/study-assignment-4/build-tests.txt.
- Đọc source các FN/views/types/triggers và SP liên quan để đối chiếu học vụ/thu tiền/gửi điểm. Phân biệt hoàn thành lớp và chốt điểm,điểm0 vàNULL,HELD và điểm danh,grantedEXECUTE vàownership.

## Phạm vi đếm và điểm cần hiểu

105 là phạm vi các object chính đã công bố,không phải mọi mục sys.objects. Constraint/index học cùng bảng;securityprincipal/quyền học theo vai trò. Số lượng lệch1 là tối thiểu,không đảm bảo độkhó của mọiobject ngang nhau.

TV1 chủ trì account/session/audit. TV2 phụ trách chuỗi registration→invoice→report và minh họa RecordFailure sau rollback. TV3 chuẩn bị khóa/lớp/xếp lớp/lịch;TV4 vận hành lịch/điểm danh/điểm và minh họa BeginRead/BeginWrite. SP hạ tầng phục vụ toàn hệ thống,cả nhóm đọc tham chiếu;không mô tả thành quyền riêng hay SP riêng của một vai trò. Có các điểm bàn giao TV2→TV3→TV4→TV3→TV4 và audit/receipt chung.

Không chạy SQL/HTTP/UI ghi dữ liệu,không đổi schema/grant/session/runtime/keys/dependency;khôngcommit/push. Bài thực hành chỉ là đề xuất để học trên fixture được giao,chưa có PASS thực hành.
