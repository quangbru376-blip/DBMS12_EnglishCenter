# Project DBMS12 độc lập
1. Chạy Chay-Project.cmd; host cùng frontend ở localhost8446/dbms12.
2. Marker root thay đường dẫn cố định; mọi source/resource/SQL nằm trong project.
3. Machine config chỉ chứa địa chỉ/đường dẫn; credential nằm ngoài source, được DPAPI bảo vệ.
4. Owner tạo PROJECT catalog mới, sinh 10 password ngẫu nhiên; không tái seed khi restart.
5. Runtime không admin, DB user Dbms12ProjectRuntime thuộc dbms12_runtime.
6. API cố định → SQL session → executor → một transaction business/audit/receipt.
7. Tất cả đọc/ghi là SQL có tham số; 11 SP và 45 batch giữ nguyên SHA.
8. C# giữ hash/JWT/CSRF/DTO/CSV; UI giữ pending trong RAM và không tự gửi lại lệnh.
9. Agent đọc AGENTS rồi chín file memory theo thứ tự; source và bằng chứng là chuẩn.
10. Test-Project kiểm build/5tests/SQLguard; browser suites ghi sample chạy riêng.
11. Enter dừng bình thường, restart giữ dữ liệu/khóa; không đổi bản cũ hay checkpoint.
12. Pack-Source bỏ state/keys/DB/build/dependencies; source ZIP có thể build độc lập.
13. Môi trường Windows/SQL/TLS phải chuẩn bị; không claim installer máy khác hoặc backup.
