# Vai trò và quyền SQL

[08_permissions.sql](08_permissions.sql) tạo7 role/user nghiệp vụ, chặn quyền trực tiếp bảng và cấp quyền gọi module/impersonation theo allowlist.

Đọc [mô hình bảo mật](../../../docs/SQL_SECURITY.md) và [ma trận quyền từng SP](../../../docs/SQL_SECURITY_MATRIX.md). Account.role_code là vai trò ứng dụng; native role/user là ngữ cảnh SQL. Bảy user WITHOUT LOGIN được backend sử dụng qua Windows runtime login hiện có.

[Bản đồ SQL](../README.md).
