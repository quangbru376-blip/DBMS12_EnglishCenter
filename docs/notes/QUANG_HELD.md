# Xác nhận buổi học QUANG_CLASS_01
Owner yêu cầu xác nhận15LESSON còn thiếu,IDs9–21,25,26.
Phiên Giáo vụ riêng đăng nhập qua HTTPS tin cậy;API schedules/held giữ CSRF/UUID/rowversion.
Mỗi buổi ghi held_at tại thời điểm thao tác và held_by;không sửa ngày lịch.
15HTTP200 và15audit/replay được đối chiếu đúngoperation/request/schedule/actor.
Sau thao tác:16/16HELD,đủ15LESSON+1EXAM,missing_attendance0.
Hash toàn bộ Class/Attendance/GradeReport giữ nguyên;12trigger enabled.
Lớp vẫn ONGOING/DRAFT;owner tự Hoàn thành lớp học rồi gửi bảng điểm.
Không tự complete/submit/finalize hoặc can thiệp phiên owner.
Test-Project PASS;evidence docs/evidence/quang-held.
