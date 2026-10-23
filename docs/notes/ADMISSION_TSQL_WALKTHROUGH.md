# Ví dụ lần theo T-SQL

- Owner yêu cầu một luồng cụ thể và mọi T-SQL liên quan.
- Tài liệu: docs/reports/Vi-du-luong-duyet-ho-so-TSQL.md.
- Ví dụ giả định duyệt Registration100,Course7,học phí2triệu; không chạy dữ liệu thật.
- Bao gồm profile/session/impersonation, SP nghiệp vụ, trigger/function, constraint/default/sequence.
- Tách nhánh thành công/replay/lỗi và phần auth/me + reload danh sách.
- 14 định nghĩa nguyên văn đã so khớp source và số dòng, không phải SQL execution trace.
- Lưu ý IDENTITY/SEQUENCE có thể có khoảng trống khi rollback; invoice_status suy ra khi đọc.
- Không chỉnh executable/SQL/DB/runtime hoặc thêm quyền.
- Verify-Source PASS62pins; evidence admission-tsql-walkthrough.json.
