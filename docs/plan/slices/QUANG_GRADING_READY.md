# QUANG_GRADING_READY — 23/10/2026

Owner yêu cầu đưa riêng QUANG_CLASS_01, hiện có1học viên, tới giai đoạn nhập điểm và bổ sung điều kiện thiếu. Target đọc được: PROJECTDB26/GUID E94F523E-AC86-448C-8E5B-79BE6C31D97B,Class5/Course5/Teacher9,Assignment5/Registration7/Report5,OPEN/DRAFT,13futureLESSON/0exam,gradesblank/noattendance/noHELD.

Chuẩn bị fixture minh họa để nhập được cả2điểm ngay: giữ13schedule hiện có và1assignment,thêm2LESSON+1FINAL_EXAM theo lịch MWF tiếp nối,điều chỉnh toàn lịch riêng lớp lùi6tuần,OPEN→ONGOING/DRAFT bằng ClassLifecycle guard hiện có. Không tự điểm danh,khôngghiHELD/COMPLETED/điểm/submit/finalize. Lịch là syntheticscenario theo yêu cầu owner,không giả nhận đã tổ chức buổi học hoặc audit quá khứ.

T-SQL hiện tại cấm backdate lịch qua API. Operator fixture chạy transaction/lock,giới hạn ID/code/course/teacher/1student/nullgrades/noattendance/profileID+GUID+fileGUID. Thêm lịch tương lai với guard bật; chỉ tạmDISABLEtr_Schedule_Guard để backdate đúng16schedule củaClass5,sau đó ENABLE ngay,UPDATE no-op chạy lại guardcount/conflicts và giữ tất cả trigger khác. Không sửa definition/source/grant/schema/manifest;kiểm đủ12trigger enabled trướccommit. Audit OPERATOR.SEED hiện tại,actorNULL/nêu fixture,khônglùioccurred_at. Fullrollbackrehearsal trướccommit;protectedrowhash/module-permissionhash/invariants/DBCC. Rehearsal có thể tạo identity/rowversioncounter gaps;khôngclaim counterbyteidentical.

Scope: private SQL/receipts/before-after dưới .local/operator/quang-grading-20261023; docs/evidence/quang-grading/**; docs/notes/QUANG_GRADING_READY.md; docs/plan/QUANG_GRADING_READY_REVIEW.md; docs/plan/plan.md; memory/01_CURRENT_STATE.md và memory/08_TASKS.md. Không executable/SQLsource/dependency/UI/API/ownerkeys/session/APP25/demo24.

Kiểm: rehearsalrollback+freshread,commitexactlyonce+protectedhash/definitions/permissions/12enabledtriggers/trustedconstraints,rollbackGradeReportprobe cả2điểm rồi giữblank;actualTeachertrustedEdge chọnlớp/openreport/NútLưu enabled,khôngdurablegradecommand;Test-Project/sourcepins. Khôngreset/reseedtoànbộ/drop/restore/revokeowner/restart/commitGit/push.

Status: COMPLETE / scoped operator/data review PASS. Rehearsalrollback vàcommitexactlyonce PASS;ONGOING/DRAFT15LESSON1EXAM1student/blankgrades/12triggers;guardprobe+protectedhash+DBCC+TeacherUI3widths(businessPOST0)+Test-Project PASS. Điểm/chưaHELD/chưaattendance giữ nguyên, không tựchốt lớp/bảngđiểm.
