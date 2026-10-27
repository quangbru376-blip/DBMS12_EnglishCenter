# CHƯƠNG 6. KẾT LUẬN

---

## 6.1. KẾT QUẢ ĐẠT ĐƯỢC

Trải qua quá trình nghiên cứu lý thuyết, khảo sát nghiệp vụ thực tế và triển khai kỹ thuật, đề tài xây dựng hệ thống cơ sở dữ liệu và ứng dụng quản lý trung tâm tiếng Anh (DBMS12 EnglishCenter) đã hoàn thành toàn diện các mục tiêu đề ra, đạt được những kết quả cụ thể sau:

Thứ nhất, về mặt mô hình hóa và thiết kế cơ sở dữ liệu, đề tài đã xây dựng thành công một lược đồ dữ liệu quan hệ hoàn chỉnh gồm 12 bảng thực thể và 99 thuộc tính, đáp ứng nghiêm ngặt chuẩn hóa dạng chuẩn 3 (3NF). Hệ thống loại bỏ hoàn toàn các dị thường thêm, xóa và sửa đổi dữ liệu. Toàn bộ các quy tắc nghiệp vụ đặc thù của trung tâm đào tạo—từ quy chế tuyển sinh, cấu trúc chương trình học, giới hạn sĩ số lớp học, điều kiện mở lớp, đến quy trình đánh giá kết quả học tập—đều được ràng buộc chặt chẽ thông qua hệ thống 44 ràng buộc khai báo (bao gồm 12 khóa chính, 15 khóa ngoại, 22 ràng buộc CHECK, 7 ràng buộc UNIQUE) cùng 12 Trigger giám sát trạng thái thời gian thực.

Thứ hai, về mặt quản lý giao dịch và bảo toàn dữ liệu, đề tài đã hiện thực hóa thành công Quyết định kiến trúc D15 với 61 Stored Procedures tự làm chủ giao dịch (gồm 56 thủ tục nghiệp vụ và 5 thủ tục hạ tầng). Việc đưa toàn bộ logic giao dịch vào T-SQL bảo đảm 100% các thao tác nghiệp vụ tuân thủ trọn vẹn bốn tiêu chuẩn ACID. Hệ thống giải quyết triệt để bài toán tranh chấp truy cập đồng thời thông qua sự phối hợp nhịp nhàng giữa kỹ thuật khóa thô tuần tự hóa và kiểm soát đồng thời lạc quan dựa trên cột phiên bản dữ liệu `row_version`. Đồng thời, cơ chế chống lặp lệnh (Idempotency) được cài đặt qua bảng `ReplayOperation` giúp hệ thống hoàn toàn miễn nhiễm với các lỗi gửi trùng yêu cầu do kết nối mạng chập chờn.

Thứ ba, về mặt kiến trúc an toàn và bảo mật thông tin, đề tài đã triển khai xuất sắc mô hình Native Security V2 theo Quyết định D14. Cơ sở dữ liệu được bảo vệ vững chắc thông qua việc áp dụng lệnh phong tỏa tuyệt đối (`DENY`) trên toàn bộ 12 bảng dữ liệu, buộc mọi truy cập phải đi qua Stored Procedure và View nhờ Chuỗi quyền sở hữu (Ownership Chaining). Mô hình định danh hai tầng kết hợp giữa tài khoản kết nối hạ tầng Windows Authentication và 7 nhóm người dùng nghiệp vụ không mật khẩu (`WITHOUT LOGIN`) đã hiện thực hóa trọn vẹn nguyên tắc đặc quyền tối thiểu và phân tách nhiệm vụ. Cơ chế bảo mật cấp dòng (Row-Level Security) độc lập với client và cơ chế Epoch Invalidation làm mất hiệu lực phiên đăng nhập tức thời khi có biến cố an ninh đã nâng cao khả năng phòng thủ của hệ thống trước các nguy cơ tấn công chiếm quyền.

Thứ tư, về mặt xây dựng phần mềm và ứng dụng thực tiễn, đề tài đã phát triển một hệ thống ứng dụng ba tầng hoàn chỉnh và đồng bộ. Tầng giao diện người dùng (React 19, TypeScript, Tailwind CSS) mang lại trải nghiệm mượt mà, phản hồi trực quan và thích ứng đa nền tảng cho 7 nhóm đối tượng sử dụng. Tầng backend (ASP.NET Core trên nền .NET 10) đóng vai trò máy chủ trung chuyển an toàn, khai thác trình điều khiển tầng thấp `Microsoft.Data.SqlClient` với các truy vấn tham số hóa thuần túy, nói không với các lớp ORM cồng kềnh. Hệ thống đã vượt qua toàn bộ các kịch bản kiểm thử tích hợp tự động, chứng minh tính ổn định và khả năng sẵn sàng ứng dụng vào thực tế quản lý đào tạo.

---

## 6.2. HẠN CHẾ

Bên cạnh những kết quả tích cực đã đạt được, trong phạm vi thời gian và nguồn lực nghiên cứu của đề tài, hệ thống vẫn tồn tại một số điểm hạn chế mang tính định hướng cần tiếp tục được hoàn thiện:

Thứ nhất, về phạm vi nghiệp vụ thanh toán và quản lý tài chính, hệ thống hiện tại mới chỉ tập trung xử lý mô hình thu học phí trọn gói một lần theo từng hóa đơn tại quầy (bằng tiền mặt hoặc chuyển khoản ngân hàng thủ công có kế toán xác nhận). Đề tài chưa xây dựng module kết nối tự động với các cổng thanh toán trực tuyến phổ biến, cũng như chưa hỗ trợ các kịch bản tài chính linh hoạt hơn như chính sách đóng học phí theo nhiều đợt, chính sách trả góp hoặc cơ chế áp dụng các mã giảm giá và học bổng khuyến học tự động.

Thứ hai, về cơ chế điều phối tranh chấp ở quy mô tải cực lớn, việc áp dụng kỹ thuật khóa thô độc quyền (`Course WITH(TABLOCKX, HOLDLOCK)`) là một giải pháp tối ưu giúp bảo đảm tính đúng đắn và an toàn tuyệt đối cho các giao dịch nghiệp vụ trong điều kiện hoạt động tiêu chuẩn của một trung tâm quy mô vừa và nhỏ. Tuy nhiên, nếu hệ thống được triển khai mở rộng cho chuỗi nhiều cơ sở đào tạo với hàng nghìn giao dịch ghi dữ liệu phát sinh đồng thời trong các đợt cao điểm khai giảng, cơ chế khóa tuần tự hóa này có thể dẫn đến việc kéo dài thời gian chờ đợi trong hàng đợi của hệ quản trị cơ sở dữ liệu.

Thứ ba, về trải nghiệm tương tác và kênh truyền thông tự động, hệ thống hiện đang vận hành theo cơ chế tương tác một chiều trên nền tảng ứng dụng web, đòi hỏi người dùng phải chủ động đăng nhập vào phần mềm để tra cứu thông tin. Hệ thống chưa tích hợp các dịch vụ truyền thông đa kênh bên ngoài để tự động gửi thông báo thời gian thực (như gửi Email thông báo hóa đơn, tin nhắn SMS nhắc lịch học, hay cảnh báo vắng học tới học viên và phụ huynh).

---

## 6.3. ĐỀ XUẤT PHÁT TRIỂN

Nhằm khắc phục các hạn chế đã chỉ ra và nâng cao năng lực ứng dụng của hệ thống trong môi trường quản lý đào tạo hiện đại, đề tài định hướng bốn hướng phát triển trọng tâm trong giai đoạn tiếp theo:

Thứ nhất, tích hợp cổng thanh toán trực tuyến tự động và mở rộng chính sách tài chính linh hoạt (nhằm giải quyết hạn chế thứ nhất). Hệ thống sẽ phát triển thêm các module giao tiếp API với các cổng thanh toán điện tử uy tín (như VNPay, VietQR, ZaloPay, MoMo) thông qua cơ chế phản hồi tự động (Instant Payment Notification - IPN). Khi học viên quét mã thanh toán thành công, hệ thống CSDL sẽ tự động ghi nhận giao dịch và kích hoạt biên nhận trong thời gian thực mà không cần sự can thiệp thủ công của kế toán. Đồng thời, cấu trúc dữ liệu hóa đơn sẽ được nâng cấp để hỗ trợ quản lý học phí theo từng kỳ đóng và tích hợp chính sách miễn giảm học phí cho các diện ưu tiên.

Thứ hai, tinh chỉnh mức độ chi tiết của khóa và áp dụng kỹ thuật phân vùng dữ liệu (nhằm giải quyết hạn chế thứ hai). Trong tương lai, cơ chế kiểm soát đồng thời sẽ được cải tiến từ khóa cấp bảng sang cơ chế khóa mịn hơn ở cấp hàng (Row-level Lock) kết hợp cùng kỹ thuật hàng đợi phi đồng bộ (Message Queue) tại tầng ứng dụng để điều tiết lưu lượng truy cập. Ngoài ra, việc ứng dụng kỹ thuật phân vùng bảng (Table Partitioning) trên các bảng có tốc độ tăng trưởng nhanh như `Schedule`, `Attendance` và `AuditLog` theo niên khóa hoặc chi nhánh sẽ giúp tối ưu hóa kế hoạch thực thi câu lệnh và duy trì hiệu năng ổn định khi quy mô dữ liệu mở rộng lên hàng triệu bản ghi.

Thứ ba, xây dựng hệ thống thông báo đa kênh tự động (Omnichannel Notification Service). Đề tài hướng tới việc tích hợp dịch vụ gửi thư điện tử tự động (SMTP/SendGrid) và tin nhắn thương hiệu (SMS Brandname / Zalo ZNS). Khi có các sự kiện học vụ quan trọng—chẳng hạn như hồ sơ được duyệt, hóa đơn phát hành, lớp học dời lịch do sự cố đột xuất hoặc kết quả điểm thi được công bố—hệ thống sẽ tự động gửi thông báo tức thì đến thiết bị của học viên và phụ huynh, gia tăng tính chuyên nghiệp và sự gắn kết trong dịch vụ đào tạo.

Thứ tư, nghiên cứu phát triển ứng dụng di động (Mobile App) và ứng dụng Trí tuệ nhân tạo trong phân tích học tập. Bên cạnh nền tảng web, việc xây dựng ứng dụng di động dành riêng cho học viên và giảng viên sẽ giúp việc điểm danh bằng mã QR và tra cứu lịch học trở nên tiện lợi hơn. Đặc biệt, hệ thống có thể ứng dụng các mô hình học máy (Machine Learning) để phân tích chuyên sâu dữ liệu điểm số và tần suất tham gia lớp học, từ đó đưa ra cảnh báo sớm về các học viên có nguy cơ bỏ dở khóa học, hỗ trợ cán bộ giáo vụ kịp thời đưa ra các giải pháp đồng hành và nâng cao chất lượng đào tạo của trung tâm.
