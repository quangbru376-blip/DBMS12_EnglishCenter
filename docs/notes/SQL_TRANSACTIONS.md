# SQL_TRANSACTIONS — 25/10/2026
1. Owner cung cấp mục3.4: ít nhất5 nghiệp vụ transaction và một ca concurrency/recovery; giao chuyển toàn bộ.
2. 61/61 SP đã có XACT_ABORT, TRY/CATCH, BEGIN/COMMIT/ROLLBACK; 56 operation=29command+19read+8auth, cộng5helper.
3. SQL tự mở/chốt ở depth0; ở depth1 thì dùng transaction của caller, không chốt thay caller.
4. 29 replay RETURN cũng COMMIT nếu SP sở hữu giao dịch; audit/receipt cùng nghiệp vụ.
5. C# bỏ BEGIN/COMMIT bình thường, giữ typed call, fixed role, cleanup ROLLBACK/REVERT; cancel sau dispatch giữ unknown.
6. Đọc docs/study/SQL_TRANSACTIONS.md, index61 và ba script trong database/examples/transactions/.
7. Fixture riêng:5commit+5forced rollback, replay, concurrency2writers/oneeffect, cancel đang chờ khóa/no false FAILURE PASS.
8. SQL học5transaction và hai phiên A/B PASS; B chờ rồi lỗi51214. Native1477/HTTP77/UIwrites/lostACK PASS.
9. MainPROJECT26 rehearsal/rollback.sql/ALTER61SP giữ12tablehash/quyền/sequence, DBCC/ready200/7roles3widths PASS.
10. Test-Project -CheckDatabase PASS; snapshot guard bổ sung sau HTTP77, đã build/native/main kiểm cuối; không claim load/fullrubric.
11. Giữ state fixture/private receipts; không reset/reseed/đổi keys/ACL/phiênowner; không commit/push.
