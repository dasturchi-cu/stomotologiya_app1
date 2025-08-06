/// Foydalanuvchi statusini belgilovchi enum
enum UserStatus {
  /// Foydalanuvchi faol va to'lov qilgan
  active,
  
  /// Foydalanuvchi hisobi o'chirilgan (to'lov talab qilinadi)
  disabled,
  
  /// Foydalanuvchi hali ro'yxatdan o'tmagan
  unregistered,
  
  /// Foydalanuvchi statusini tekshirish jarayonida
  checking,
  
  /// Xatolik yuz bergan
  error
}

/// UserStatus uchun extension metodlar
extension UserStatusExtension on UserStatus {
  /// Status nomi
  String get name {
    switch (this) {
      case UserStatus.active:
        return 'Faol';
      case UserStatus.disabled:
        return 'O\'chirilgan';
      case UserStatus.unregistered:
        return 'Ro\'yxatdan o\'tmagan';
      case UserStatus.checking:
        return 'Tekshirilmoqda';
      case UserStatus.error:
        return 'Xatolik';
    }
  }

  /// Status tavsifi
  String get description {
    switch (this) {
      case UserStatus.active:
        return 'Sizning hisobingiz faol va barcha funksiyalardan foydalanishingiz mumkin.';
      case UserStatus.disabled:
        return 'Sizning hisobingiz o\'chirilgan. Davom etish uchun to\'lov qiling.';
      case UserStatus.unregistered:
        return 'Ilovadan foydalanish uchun ro\'yxatdan o\'ting.';
      case UserStatus.checking:
        return 'Sizning hisobingiz holati tekshirilmoqda...';
      case UserStatus.error:
        return 'Hisobingiz holatini tekshirishda xatolik yuz berdi.';
    }
  }

  /// Status rangini belgilaydi
  bool get isBlocked {
    return this == UserStatus.disabled || 
           this == UserStatus.unregistered || 
           this == UserStatus.error;
  }

  /// Foydalanuvchi ilovadan foydalana oladimi
  bool get canUseApp {
    return this == UserStatus.active;
  }

  /// To'lov talab qilinadimi
  bool get requiresPayment {
    return this == UserStatus.disabled;
  }
}
