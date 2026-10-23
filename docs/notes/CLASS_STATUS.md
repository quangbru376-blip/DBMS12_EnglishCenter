# Trạng thái lớp đang chọn

- Teaching hiển thị thẻ ngay dưới Chọn lớp cho Giáo vụ và Giáo viên.
- Dùng current từ ClassList hiện có, không thêm request hoặc endpoint.
- Mã lớp, giáo viên, trạng thái lớp và bảng điểm luôn cùng bản ghi đang chọn.
- Nhãn Việt qua display.ts, badge có chữ nên không phụ thuộc màu sắc.
- Duyệt bảng điểm giải thích DRAFT/RETURNED/SUBMITTED/FINALIZED theo vai trò Giáo vụ.
- Câu hướng dẫn gửi bảng điểm cũ chỉ giữ trên giao diện Giáo viên.
- Điều kiện hiển thị/chạy nút Trả lại/Chốt giữ nguyên: SUBMITTED và ready.
- Không đổi SQL, quyền, manifest, command, điểm hoặc trạng thái thực của lớp.
- Kiểm Test-Project; Edge2roles/3widths/switch và controlled4review states.
- Evidence docs/evidence/class-status/, review docs/plan/CLASS_STATUS_REVIEW.md.
