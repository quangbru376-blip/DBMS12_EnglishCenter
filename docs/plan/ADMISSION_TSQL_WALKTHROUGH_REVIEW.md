# ADMISSION_TSQL_WALKTHROUGH — scoped documentation review PASS

22/10/2026, Codex/code-review. Slice cùng tên. Đối chiếu AppProfile/Repository/Executor/SqlBusinessContext/Identity/Routes/Host, Workspace/api/useScrollList, manifest và các SQL nguồn.

Tài liệu lần theo một duyệt mới thành công: xác thực/profile/BeginRead, transaction ghi/CurrentSession/impersonation, usp_AdmissionApprove +4triggers/2functions/sequence/constraint, COMMIT/REVERT và auth/me/reload RegistrationList/view. Nhánh replay/failure tách rõ. Dữ liệu100/7/2triệu là giả định, không lấy hàng thực. Có ghi chênh lệch static walk-through với physical execution, optionalCSRF/additionalscroll requests, default/DDL không chạy lại mỗi click và gaps identity/sequence không rollback.

Kiểm exact14definitioncopies+line numbers và fences PASS; Verify-Source62SQLpins PASS. Không chạy HTTP/SQL/build hoặc business write; runtime/DB không đổi bởi task này. Không claim mới về ứng dụng/security/fullsuite. Source hashes receipt là nguồn phân tích. Không có lỗi cần sửa; verdict PASS.
