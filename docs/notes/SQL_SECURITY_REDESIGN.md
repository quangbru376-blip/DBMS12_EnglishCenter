# Phân quyền SQL theo hướng A
1. Giữ 12 bảng/99 cột; 56 operation chuyển thành SP, thêm 5 SP hạ tầng: tổng 61 SP.
2. Bảy role và user SQL nghiệp vụ thực sự được ứng dụng sử dụng, không chỉ tạo minh họa.
3. Windows Login runtime → Dbms12ProjectRuntime → ngữ cảnh nghiệp vụ cố định bằng EXECUTE AS USER.
4. Máy này không có bảy SQL Login riêng; không bật Mixed Mode hoặc tạo Windows account mới.
5. Backend xác thực; SP kiểm lại SID/epoch, native role và quyền sở hữu từng dòng.
6. Không nhận Actor/principal tùy ý; không cấp quyền trực tiếp bảng cho nghiệp vụ/runtime.
7. SP command tự ghi audit/receipt; C# mở/commit/rollback transaction và REVERT khi kết thúc.
8. Kết nối không pooling, không retry sau mất ACK; lookup chỉ của actor hiện tại.
9. Kiểm dùng fixture riêng; migration chỉ sửa module/quyền, so hash từng bảng trước/sau.
10. Báo cáo tham khảo docs/reports/4_2_QuanLyBaoMat.md; ma trận cụ thể SQL_SECURITY_MATRIX.md.
