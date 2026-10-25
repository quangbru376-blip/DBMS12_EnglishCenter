# Review SQL_LEARNING_PACK — 25/10/2026

Verdict: **PASS trong phạm vi bộ học và tự đối chiếu phầnSQL đã nhận**. Áp dụng skill code-review, không delegation. [Scope](slices/SQL_LEARNING_PACK.md), [summary](../evidence/sql-learning/summary.json), [hướng dẫn](../study/SQL_LEARNING_START.md).

## Kết quả

Lưu nội dung rubric3.1–3.5 owner cung cấp; tạo matrix từ source, lược đồ12quan hệ/99cột/19FK và lập luận candidate keys/FD/3NF, danh sách17index tường minh cùng5lý do/benchmark. ERD99thuộc tính vàChen hiện có được liên kết lại; không dựng claim3NF từ số bảng hoặc thay mô hình.

107bài riêng trong database/practice:61SP,7FN,9VW,12TG,5transaction,5index,6constraint,2security. Định nghĩa source thật giữ nguyên; các bài chỉ gọi/chuẩn bị dữ liệu/quan sát. OBJECT_INDEX105 và README từngnhóm có linkChạy riêng cho89SP/FN/VW/TG. Một số file definition vẫn chứa nhiều object; bài gọi tách riêng từng object. Coverage verifier so đúng tập tên với manifest/installOrder, guard/defaultrollback/câu gọi thực/expectederrors và structure.

Phòng học dùng profile fixture có workspace/name/ID/GUID/fileGUID/source pin được kiểm. Prepare chỉ thêm extended property đánh dấu fixture và ghi SSMS session script private. Từngcase yêu cầu marker cùngSESSION_CONTEXT đúngGUID vàowner/depth0;main profile từ chối trướcSQL. SID/hash sinh/đọc trongRAM, kết quả LoginRead/PasswordSnapshot/LoginRecord capture trong temp table rồi chỉ chiếu cột an toàn. Không nhậnSQL/Actor từbrowser,khôngcấpthêmquyềnbảng/EXECUTEASOWNER/tắttrigger. Hash fixture tái dùng để minh họa session/CAS/thu hồi phiên,không phải testcrypto/loginpassword.

Case SP/trigger có dữ liệu trước/quan sát sau hoặc expected rejection. Default outerROLLBACK cho phép chạy lại,SP mượn transaction củacaller;web vẫndepth0/SQLowner. ClassStart chuẩn bị đúngADMITTED/PAID/OPEN/schedule/student, đợi16giây theo đồng hồ thật rồiONGOING; không temporalbypass. Bootstrap expected51236 khi đã có account;không xóaaccount để ép success. Cácbài trigger DMLowner nhằm kích hoạt businessguard;caseStudentdirecttable riêng phải bịDENY229.

Năm transaction cóoptincommit vàforcederror sauSP; xóa riêngsession đãtạo trướccommit,không xóa/revokeowner. Forcedcatch kiểmCourse thử/receipt/auditSUCCESS khôngcòn. Giữ cáccohortLAB đãcommit trênfixture,khôngreset/reseed.5benchmark dùng100000dòng/temp replica với key/INCLUDE/predicate giốngindex khảo sát,cùngrows/checksum;khôngDROP/DISABLEindexcủabảngthật/khôngclearcache/khôngclaimproduction.

## Kiểm đã chạy

|Kiểm|Kết quả|
|---|---|
|`Generate-SqlLearningPack.cjs`, `Generate-SqlLearningDocs.cjs`, `Generate-SqlStudyIndex.cjs`|PASS107bài/index source105/schema/3NF/index rationale|
|`Invoke-SqlLearning.ps1 -Prepare`|PASS đúngfixtureDB30,marker/sessionfile;khôngchuẩnbịaccount/cert/ACL|
|`Invoke-SqlLearning.ps1 -All` bảncuối|PASS107,thựcthi từngfile trênSQLServer vớiassert/expectederror/context/depth cleanup|
|`-Group transactions -ForceRollback`|PASS5;forcedafterbusiness/audit/receipt đềurollback|
|`-Group transactions -CommitTransactions`|PASS5,datafixture giữ thật,sessionthử dọn riêng|
|`-Group indexes` và trongAll|PASS5;logicalreads485→3,385→3,723→3,497→11,881→16;samerows/checksum|
|`-FixtureProfile .local/config/profile.json -Prepare`|PASS từchối main profile trướcbấtkỳSQL/metadatawrite|
|`Verify-SqlLearning.cjs`|PASS tập61/7/9/12,107case,guard/defaultrollback,5transaction/5index|
|`Verify-Source.cjs`, `Verify-SqlLayout.cjs`, `Verify-StudyAssignment.cjs`|PASS62pins/61scopes/29replay/7roles,byte-identicallayout,105objects27/26/26/26|
|`tools/Test-Project.ps1`|PASS lockedrestore/audit,backend0warnings/errors,frontendtypes/lint/5tests/build|
|Main source/manifest/runtime|Manifestbyte-identicaltaskentry,61SQLbodies+Installpin unchanged,PID33452/startUTC unchanged,ready200;khôngmainDDL/businessDML|
|Docslinks/note/sourcehashes|PASS chi tiết trongsummary;note13dòng|

## Vấn đề phát hiện và đã sửa

1. SQLcmd mặcđịnhQUOTED_IDENTIFIER không phùhợpfilteredindexes: thêm bộSEToptions tươngthích vào từng bài,giữràngbuộcchính.
2. Ví dụClassEdit banđầu20 vượtCHECK1–15: sửa input10;không nớiCHECK.
3. CaClassGradeDecision banđầu vướngCHECKClasschưahoànthành trước trigger: chuẩn bịHELD/attendance/scores/ClassCOMPLETED hợp lệ rồi mới vi phạm quyếtđịnh điểm;đúng51127.
4. Parserlogicalread banđầu chưa táchLOB/escape: chỉ đọc dòngTable '#Lab', khẳngđịnhexact1metric mỗi giai đoạn; kếtquảđãchạy thật,không điền sốdựđoán.
5. ClassStart banđầu chỉnegative51218: hoànthiện caOPEN→ONGOING bằng đầyđủprerequisite và chờ thời gianthật. Khôngclaimhappybranch từcasebị từchối.

Không còn finding phải sửa trongscope. Chưa kiểm trực tiếp ứng dụngSSMS quaUI; SQLbatch không cầnSQLCMDMode được thực thi quaSQLcmd cùngSQLServer. Concurrency tái dùngscriptvàevidenceD15/D16thực đãcó,không gọi làrecovery/backup.3NF làlập luận theoFD nghiệpvụ đượcghi,cầntrìnhbàyvàđượcgiáoviênđánhgiá;Role7WITHOUTLOGIN khôngđượcmô tả thành7Loginđộc lập. Khôngclaimproduction/load/máyWindows thứhai hoặc toànđề chưađược cungcấp. Khôngcommit/push.
