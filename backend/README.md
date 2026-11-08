# MATE Backend — Firestore Seed Scripts

Script Node.js dùng Firebase Admin SDK để seed dữ liệu vào các collection
chỉ-đọc (read-only) trong Firestore. Client Flutter không có quyền ghi
vào các collection này theo Firestore Security Rules.

## Collections được seed

| Collection       | Mô tả                                      |
|------------------|---------------------------------------------|
| `places`         | Địa điểm hẹn hò tại TP.HCM                |
| `shopItems`      | Vật phẩm trong shop (trang phục, phụ kiện) |
| `shopCategories` | Danh mục shop                              |
| `gameQuestions`   | Câu hỏi mini-game (quiz, mind-read, daily) |

## Cài đặt

```bash
cd backend
npm install
```

## Cấu hình

1. Vào [Firebase Console](https://console.firebase.google.com/) > Project `mateapp-8d44d`
2. Project Settings > Service Accounts > **Generate new private key**
3. Lưu file JSON vào `backend/serviceAccountKey.json`
4. Copy `.env.example` → `.env` và cập nhật path nếu cần

```bash
cp .env.example .env
```

## Chạy seed

```bash
# Seed tất cả collections
npm run seed

# Chỉ seed 1 collection cụ thể
npm run seed:places
npm run seed:shop
npm run seed:games
```

## Lưu ý

- Script là **idempotent**: dùng `set()` với merge nên chạy lại không tạo duplicate
- Document ID được sinh từ tên/nội dung để đảm bảo ổn định
- Dữ liệu địa điểm là các quán/địa điểm thật tại TP.HCM
- `serviceAccountKey.json` đã được thêm vào `.gitignore` — **KHÔNG commit file này**
