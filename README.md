# 🎮 Lords Mobile Bot - Test Get User Info

Script test cơ bản để lấy thông tin người chơi từ Lords Mobile API (reverse engineered).

## ⚠️ CẢNH BÁO

- API này **KHÔNG chính thức** từ IGG
- Sử dụng có thể **vi phạm ToS** và bị **ban account**
- Chỉ dành cho **mục đích học tập**

## 🚀 Cài Đặt

```bash
# Clone repository
git clone https://github.com/TranThienApk/lords-mobile-bot.git
cd lords-mobile-bot

# Install dependencies
pip install -r requirements.txt
```

## 📋 Yêu Cầu

1. **UDID** - Device ID từ thiết bị/emulator
2. **SECRET_KEY** - Từ reverse engineering (capture network)
3. **Region** - Server region (ap-seoul, eu-frankfurt, etc.)

## 🎯 Sử Dụng

### Chạy test cơ bản:

```bash
python test_get_user_info.py
```

### Test từng function:

```python
from test_get_user_info import *

# 1. Login
token = login_by_udid("your_udid_here")

# 2. Get user info
get_user_info(user_id=123456)

# 3. Get castle detail
get_castle_detail(x=500, y=600)

# 4. Refresh token
refresh_token(old_token)
```

## 📊 API Endpoints Đã Test

| Endpoint | Method | Tính Năng |
|----------|--------|-----------|
| `/api/login_by_udid` | POST | Login và lấy token |
| `/api/get_user_info` | POST | Thông tin người chơi |
| `/api/get_castle_detail` | POST | Chi tiết lâu đài |
| `/api/refresh_token` | POST | Refresh token |

## 🔧 Cấu Hình

Sửa file `config.json`:

```json
{
  "region": "ap-seoul",
  "kingdom_id": 1234,
  "secret_key": "your_secret_key_here",
  "device_id": "your_device_id",
  "token": ""
}
```

## 📖 Hướng Dẫn Lấy SECRET_KEY

1. Cài **mitmproxy**: `pip install mitmproxy`
2. Chạy: `mitmproxy -p 8080`
3. Setup proxy trên emulator → IP:8080
4. Capture requests từ Lords Mobile
5. So sánh MD5 signature để tìm SECRET_KEY

## 🐛 Troubleshooting

### Login thất bại?
- Kiểm tra UDID đúng chưa
- SECRET_KEY có đúng không
- Region có đúng không

### Response 401 Unauthorized?
- Token hết hạn (24h)
- Gọi `refresh_token()`

### Response 403 Forbidden?
- IP bị ban tạm thời
- Đổi proxy/VPN

## 📝 TODO

- [ ] WebSocket realtime tracking
- [ ] Auto farm module
- [ ] Guild bank commands
- [ ] Monster hunt automation
- [ ] Shield drop alerts

## 📄 License

MIT License - Chỉ dùng cho học tập

## 👤 Author

**TranThienApk**
- GitHub: [@TranThienApk](https://github.com/TranThienApk)

---

**Ngày tạo:** 2025-11-22 13:12:52  
**Version:** 1.0.0-test
