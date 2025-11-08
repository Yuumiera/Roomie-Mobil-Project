# Roomie-Mobil-Project

## Firestore Güvenlik Kuralları Ayarlama

Bu uygulama Firestore kullanıyor. İzin hatası alıyorsanız, Firebase Console'dan güvenlik kurallarını ayarlamanız gerekiyor:

### Adımlar:

1. [Firebase Console](https://console.firebase.google.com/)'a gidin
2. Projenizi seçin
3. Sol menüden **Firestore Database** > **Rules** sekmesine gidin
4. Aşağıdaki güvenlik kurallarını yapıştırın ve **Publish** butonuna tıklayın:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection - kullanıcılar kendi verilerini okuyup yazabilir
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Listings collection - authenticated kullanıcılar okuyup yazabilir
    match /listings/{listingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        (resource.data.ownerId == request.auth.uid || request.auth.uid == request.resource.data.ownerId);
    }
    
    // Conversations collection - sadece üyeler erişebilir
    match /conversations/{conversationId} {
      // Okuma ve güncelleme - sadece üyeler
      allow read, update: if request.auth != null && 
        request.auth.uid in resource.data.members;
      
      // Yeni konuşma oluştururken - kullanıcı members listesinde olmalı
      allow create: if request.auth != null && 
        request.auth.uid in request.resource.data.members;
      
      // Silme - sadece üyeler (opsiyonel, gerekirse kaldırılabilir)
      allow delete: if request.auth != null && 
        request.auth.uid in resource.data.members;
      
      // Messages subcollection - konuşma üyeleri erişebilir
      match /messages/{messageId} {
        allow read: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.members;
        allow create: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.members &&
          request.resource.data.senderId == request.auth.uid;
        allow update, delete: if false; // Mesajlar güncellenemez veya silinemez
      }
    }
  }
}
```

**ÖNEMLİ:** Bu kurallar development/test için uygundur. Production için daha sıkı kurallar kullanmanız önerilir.

### Hızlı Test İçin (Sadece Development)

Eğer sadece test ediyorsanız ve hızlı bir çözüm istiyorsanız, geçici olarak aşağıdaki açık kuralları kullanabilirsiniz (SADECE TEST İÇİN, PRODUCTION'DA KULLANMAYIN):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

Bu kurallar authenticated (giriş yapmış) tüm kullanıcılara tüm koleksiyonlara erişim verir. Production için yukarıdaki detaylı kuralları kullanın.