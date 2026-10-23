# Khung giao diện DBMS12

- Dbms12App bọc shell bằng ec12-app để giới hạn CSS trong ứng dụng này.
- Table dùng ec-card chung: nền trắng, viền, tiêu đề và bảng cuộn bên trong.
- Tiêu đề trang, bộ lọc, phân trang có khung và khoảng đệm riêng.
- Navigation có nền trắng; mỗi mục có viền, mục đang chọn có màu xanh và vạch cạnh trái.
- Các Form và thẻ báo cáo dùng cùng token nền/viền/khoảng cách.
- Dòng bảng đang chọn có nền xanh nhạt; trạng thái chọn vẫn do React hiện có điều khiển.
- Mobile giảm khoảng đệm; giữ menu dạng dialog và bảng cuộn ngang nội bộ.
- CSS in ẩn khung tiêu đề/bộ lọc/phân trang, bỏ viền card.
- Chỉ đổi trình bày; handler, API, phân quyền, SQL và dữ liệu nghiệp vụ giữ nguyên.
- Kiểm: Test-Project, 72 menu-width cases/7 vai trò, Teacher selection và read states.
- Evidence: docs/evidence/ui-panels/; review: docs/plan/UI_PANELS_REVIEW.md.
