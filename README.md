# 🦷 StomoTrack - Stomatologiya Klinikasi Boshqaruv Tizimi

Bu Flutter ilova stomatologlar uchun bemorlar ro'yxatini yuritish, ularning tashrif sanalarini saqlash va umumiy boshqaruvni soddalashtirish maqsadida ishlab chiqilgan. Ilova Firebase Authentication va to'lov majburlash tizimi bilan jihozlangan.

---

## 📱 Ilova haqida

Ushbu ilova quyidagi imkoniyatlarni taqdim etadi:

### 👥 Bemorlar boshqaruvi
- ✅ Bemorlar haqida ma'lumotlarni kiritish (ism, tug‘ilgan sana, telefon raqami, shikoyat, manzil va boshqalar)
- 📆 Bemorning birinchi tashrifi va keyingi barcha tashrif sanalarini saqlash
- 🖼️ Har bir bemor uchun rasm(lar)ni biriktirish
- 🔄 Avtomatik ravishda yangi tashrif sanasini qo‘shish va saqlash
- 📂 Ma’lumotlar Hive local database orqali saqlanadi (offline ishlaydi)

### 🔐 Xavfsizlik va to'lov tizimi
- 🔑 Firebase Authentication orqali foydalanuvchi autentifikatsiyasi
- 💳 To'lov majburlash tizimi - to'lov qilmagan foydalanuvchilar bloklash
- 🚫 Real-time foydalanuvchi statusini kuzatish
- ⏰ Sessiya boshqaruvi va avtomatik logout
- 🛡️ Xatoliklarni boshqarish va foydalanuvchiga xabar berish tizimi

---

## 🛠 Texnologiyalar

### Frontend
- **Flutter** – ilova interfeysini yaratish uchun
- **Hive** – yengil va tezkor lokal ma’lumotlar bazasi
- **Path Provider** – fayl tizimi bilan ishlash uchun
- **Flutter widgets** – UI qurish uchun `ListView`, `TextField`, `DatePicker` va boshqalar

### Backend va Xavfsizlik
- **Firebase Core** – Firebase xizmatlarini ishga tushirish
- **Firebase Authentication** – foydalanuvchi autentifikatsiyasi
- **Cloud Firestore** – foydalanuvchi ma'lumotlari va statusini saqlash
- **Real-time listeners** – foydalanuvchi statusini real-time kuzatish

### Arxitektura
- **Service-based architecture** – AuthService, PaymentEnforcementService, SessionManager
- **Stream-based state management** – real-time ma'lumotlar oqimi
- **Error handling system** – markazlashtirilgan xatoliklarni boshqarish

---

## ⚙️ O‘rnatish

### 1. Repository-ni yuklab oling:
```bash
git clone https://github.com/your-username/stomatologiya_app.git
cd stomatologiya_app
```

### 2. Firebase loyihasini sozlang:

#### Firebase Console da:
1. [Firebase Console](https://console.firebase.google.com/) ga kiring
2. Yangi loyiha yarating yoki mavjudini tanlang
3. **Authentication** ni yoqing:
   - Sign-in method da **Email/Password** ni yoqing
4. **Cloud Firestore** ni yoqing:
   - Test mode da boshlang (keyinroq security rules ni sozlaysiz)
5. Android/iOS ilovangizni qo'shing va konfiguratsiya fayllarini yuklab oling

#### Loyihada:
1. `lib/firebase_options.dart` faylida demo ma'lumotlarni haqiqiy Firebase konfiguratsiya bilan almashtiring
2. Android uchun: `android/app/google-services.json` faylini joylashtiring
3. iOS uchun: `ios/Runner/GoogleService-Info.plist` faylini joylashtiring

### 3. Dependencies ni o'rnating:
```bash
flutter pub get
```

### 4. Ilovani ishga tushiring:
```bash
flutter run
```

---

## 🔐 To'lov Majburlash Tizimi

### Qanday ishlaydi:
1. **Foydalanuvchi ro'yxatdan o'tadi** - Firebase Authentication orqali
2. **Dastlab faol status** - yangi foydalanuvchilar faol hisoblanadi
3. **Admin tomonidan bloklash** - to'lov qilmagan foydalanuvchilar Firestore da "disabled" status oladi
4. **Real-time kuzatish** - ilova foydalanuvchi statusini doimiy kuzatib turadi
5. **Avtomatik bloklash** - disabled foydalanuvchilar ilovadan foydalana olmaydi

### Admin funksiyalari:
```dart
// Foydalanuvchini bloklash
await PaymentEnforcementService().disableUser(userId, reason: "To'lov qilmagan");

// Foydalanuvchini faollashtirish
await PaymentEnforcementService().enableUser(userId);
```

### Firestore ma'lumotlar strukturasi:
```json
{
  "users": {
    "userId": {
      "email": "user@example.com",
      "status": "active",
      "lastPaymentDate": timestamp,
      "accountDisabledDate": timestamp,
      "disableReason": "To'lov talab qilinadi"
    }
  }
}
```

---

## 🏗️ Arxitektura

### Service lar:
- **AuthService** - Firebase Authentication bilan ishlash
- **PaymentEnforcementService** - To'lov majburlash va status kuzatish
- **SessionManager** - Foydalanuvchi sessiyasini boshqarish
- **ErrorHandler** - Xatoliklarni markazlashtirilgan boshqarish

### Ekranlar:
- **AppWrapper** - Asosiy wrapper, authentication va payment statusini tekshiradi
- **LoginScreen** - Tizimga kirish
- **RegisterScreen** - Ro'yxatdan o'tish
- **PaymentRequiredScreen** - To'lov talab qilinganida ko'rsatiladi
- **HomeScreen** - Asosiy ilova ekrani (SessionActivityTracker bilan o'ralgan)

---

## 🚀 Ishlatish

1. Ilovani ishga tushiring
2. Ro'yxatdan o'ting yoki tizimga kiring
3. Bemorlar ma'lumotlarini kiriting va boshqaring
4. To'lov muddati tugaganda, admin sizni bloklashi mumkin
5. To'lov qilgandan so'ng, admin hisobingizni qayta faollashtiradi
