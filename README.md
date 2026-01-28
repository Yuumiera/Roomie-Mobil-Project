# Roomie - Smart Housing Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.5.4-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Cloud-FFCA28?logo=firebase)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A comprehensive mobile application designed to streamline the process of finding and listing residential accommodations. Built with Flutter and Firebase, Roomie offers a modern solution for students, professionals, and property owners seeking housing opportunities.
## 🎯 Overview

Roomie is a cross-platform mobile application that bridges the gap between property seekers and property owners. The platform provides an intuitive interface for browsing various types of accommodations, including apartments, houses, and dormitories, while facilitating direct communication between interested parties.

### Key Objectives

- **Accessibility**: Provide an easy-to-use platform for finding suitable accommodations
- **Communication**: Enable real-time messaging between property seekers and owners
- **Security**: Implement robust authentication and data protection mechanisms
- **Scalability**: Design a system capable of handling growing user bases and listings
- **Personalization**: Offer customized experiences through user preferences and alerts

## ✨ Features

### 1. User Authentication & Authorization
- **Multi-provider Authentication**: Support for email/password and Google Sign-In
- **Secure Password Management**: Password reset and change functionality
- **Profile Management**: Comprehensive user profile with avatar upload capabilities
- **Role-based Access Control**: Differentiated permissions for property owners and seekers

### 2. Property Listings Management
- **Multi-category Support**: Apartments, houses, dormitories, and specialized listings
- **Rich Media Upload**: Image upload and management for property listings
- **Detailed Descriptions**: Comprehensive property information including:
  - Location and address details
  - Pricing and availability
  - Property specifications
  - Owner contact information
- **CRUD Operations**: Create, read, update, and delete listing capabilities

### 3. Real-time Messaging System
- **Private Conversations**: One-on-one chat between users
- **Message Notifications**: Real-time push notifications for new messages
- **Unread Message Tracking**: Visual indicators for unread messages
- **Message History**: Persistent conversation storage

### 4. Search & Discovery
- **Advanced Filtering**: Filter properties by type, location, and price
- **Categorized Browse**: Separate views for different property types
- **Listing Details**: Comprehensive property information display

### 5. Premium Features
- **Alert Subscriptions**: Customized notifications for new listings matching criteria
- **Priority Support**: Enhanced customer service for premium users
- **Extended Listings**: Increased visibility for premium property listings

### 6. Internationalization
- **Multi-language Support**: Turkish and English language options
- **Localization**: Date, currency, and measurement unit localization
- **Dynamic Language Switching**: Runtime language preference changes

### 7. User Interface
- **Material Design**: Modern, intuitive UI following Material Design principles
- **Responsive Layout**: Adaptive design for various screen sizes
- **Custom Theming**: Consistent color scheme and branding
- **Bottom Navigation**: Easy access to main application sections

## 🏗 Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Mobile Client                      │
│                   (Flutter)                         │
├─────────────────────────────────────────────────────┤
│  Presentation Layer                                 │
│  ├── Screens (UI Components)                        │
│  ├── Widgets (Reusable Components)                  │
│  └── Theme & Localization                           │
├─────────────────────────────────────────────────────┤
│  Business Logic Layer                               │
│  ├── Services (API, Auth, Messaging)                │
│  ├── Models (Data Structures)                       │
│  └── Controllers (State Management)                 │
└─────────────┬───────────────────────────────────────┘
              │
              │ HTTP/Firebase SDK
              │
┌─────────────▼───────────────────────────────────────┐
│              Backend Services                       │
├─────────────────────────────────────────────────────┤
│  Node.js API Server                                 │
│  ├── REST Endpoints                                 │
│  ├── WebSocket Support                              │
│  └── Middleware (Auth, Logging)                     │
├─────────────────────────────────────────────────────┤
│  Firebase Services                                  │
│  ├── Authentication                                 │
│  ├── Cloud Firestore (Database)                     │
│  ├── Cloud Storage (File Storage)                   │
│  └── Cloud Messaging (Notifications)                │
└─────────────────────────────────────────────────────┘
```

### Design Patterns

- **Service Pattern**: Separation of business logic from UI components
- **Repository Pattern**: Abstraction of data access layer
- **Observer Pattern**: Real-time data synchronization with Firestore
- **Singleton Pattern**: Shared service instances (e.g., API service)
- **Factory Pattern**: Object creation for models and services

## 🛠 Technology Stack

### Frontend
- **Framework**: Flutter 3.5.4
- **Language**: Dart SDK ^3.5.4
- **State Management**: Provider/StatefulWidget
- **Navigation**: Flutter Navigator 2.0

### Backend
- **Runtime**: Node.js
- **Framework**: Express.js
- **API Style**: RESTful

### Cloud Services
- **Authentication**: Firebase Authentication
- **Database**: Cloud Firestore (NoSQL)
- **Storage**: Firebase Cloud Storage
- **Notifications**: Firebase Cloud Messaging

### Key Dependencies
```yaml
firebase_core: ^3.6.0           # Firebase SDK
firebase_auth: ^5.3.1           # Authentication
cloud_firestore: ^5.4.3         # Database
firebase_storage: ^12.3.4       # File storage
google_sign_in: ^6.2.1          # Google OAuth
image_picker: ^1.1.2            # Image selection
flutter_local_notifications: ^17.2.2  # Local notifications
shared_preferences: ^2.2.3      # Local storage
http: ^1.2.2                    # HTTP client
```

## 📥 Installation

### Prerequisites

- Flutter SDK (version 3.5.4 or higher)
- Dart SDK (version 3.5.4 or higher)
- Android Studio / Xcode (for platform-specific builds)
- Firebase account with active project
- Node.js (version 14 or higher) for backend


#### Email/Password Authentication
1. Navigate to Firebase Console → Authentication → Sign-in method
2. Enable Email/Password provider

#### Google Sign-In
1. Enable Google provider in Firebase Authentication
2. Add SHA-1 and SHA-256 fingerprints:
   ```bash
   cd android
   ./gradlew signingReport
   ```
3. Copy SHA-1 and SHA-256 from the output
4. Add to Firebase Console → Project Settings → Your apps → Android app

### Step 6: Set Firestore Security Rules

Navigate to Firestore Database → Rules and apply the following:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Listings collection
    match /listings/{listingId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && 
        resource.data.ownerId == request.auth.uid;
    }
    
    // Conversations collection
    match /conversations/{conversationId} {
      allow read, update: if request.auth != null && 
        request.auth.uid in resource.data.members;
      allow create: if request.auth != null && 
        request.auth.uid in request.resource.data.members;
      
      // Messages subcollection
      match /messages/{messageId} {
        allow read: if request.auth != null && 
          request.auth.uid in get(/databases/$(database)/documents/conversations/$(conversationId)).data.members;
        allow create: if request.auth != null && 
          request.resource.data.senderId == request.auth.uid;
      }
    }
  }
}
```



## ⚙️ Configuration

### Update Base URL

For local development, update the API base URL in `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://YOUR_LOCAL_IP:3000';
```

Replace `YOUR_LOCAL_IP` with your machine's IP address.

### Language Configuration

The app supports Turkish (tr) and English (en). Default language is set in `lib/services/language_controller.dart`.

## 📱 Usage

### For Property Seekers

1. **Register/Login**: Create an account or sign in with Google
2. **Browse Listings**: Navigate through different property categories
3. **View Details**: Tap on listings to view comprehensive information
4. **Contact Owners**: Use the messaging feature to communicate with property owners
5. **Save Preferences**: Subscribe to alerts for new matching listings (Premium)

### For Property Owners

1. **Create Listing**: Add new property listings with images and details
2. **Manage Listings**: Edit or delete your existing listings
3. **Respond to Inquiries**: Reply to messages from interested seekers
4. **Premium Features**: Subscribe to premium for enhanced visibility

## 📂 Project Structure

```
roomie_mobil_project/
├── android/                    # Android-specific files
├── ios/                        # iOS-specific files
├── lib/
│   ├── l10n/                   # Localization files
│   ├── models/                 # Data models
│   │   ├── chat_model.dart
│   │   └── listing_model.dart
│   ├── screens/                # UI screens
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── home_screen.dart
│   │   ├── apartment_list_screen.dart
│   │   ├── house_list_screen.dart
│   │   ├── dormitory_list_screen.dart
│   │   ├── listing_detail_screen.dart
│   │   ├── profile_screen.dart
│   │   ├── messages_screen.dart
│   │   ├── chat_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── change_password_screen.dart
│   │   └── user_profile_screen.dart
│   ├── services/               # Business logic services
│   │   ├── api_service.dart
│   │   ├── image_upload_service.dart
│   │   ├── language_controller.dart
│   │   ├── message_notification_service.dart
│   │   ├── alert_subscription_service.dart
│   │   ├── premium_service.dart
│   │   ├── unread_service.dart
│   │   └── local_unread_tracker.dart
│   ├── theme/                  # App theming
│   │   └── app_theme.dart
│   ├── utils/                  # Utility functions
│   │   └── validators.dart
│   ├── widgets/                # Reusable widgets
│   │   ├── app_drawer.dart
│   │   ├── bottom_nav_bar.dart
│   │   ├── listing_card.dart
│   │   ├── message_bubble.dart
│   │   ├── image_carousel.dart
│   │   ├── custom_button.dart
│   │   └── custom_text_field.dart
│   └── main.dart               # Application entry point
├── backend/                    # Node.js backend
│   ├── server.js               # Express server
│   ├── mark_read_endpoint.js   # Message read status endpoint
│   └── package.json
├── assets/                     # Static assets
│   └── images/
├── test/                       # Unit and widget tests
├── pubspec.yaml                # Flutter dependencies
└── README.md                   # This file
```

## 🔌 API Documentation

### Authentication Endpoints

#### POST `/api/auth/register`
Register a new user account.

**Request Body:**
```json
{
  "email": "user@example.com",
  "password": "securePassword123",
  "name": "John Doe",
  "phone": "+1234567890"
}
```

**Response:**
```json
{
  "success": true,
  "userId": "user123",
  "token": "jwt_token_here"
}
```

### Listings Endpoints

#### GET `/api/listings`
Retrieve all listings or filter by category.

**Query Parameters:**
- `category`: (optional) Filter by property type (apartment, house, dormitory)
- `limit`: (optional) Number of results to return
- `offset`: (optional) Pagination offset

**Response:**
```json
{
  "success": true,
  "listings": [
    {
      "id": "listing123",
      "title": "Modern 2BR Apartment",
      "category": "apartment",
      "price": 1500,
      "location": "Downtown",
      "images": ["url1", "url2"],
      "ownerId": "user123"
    }
  ]
}
```

### Messaging Endpoints

#### POST `/api/messages/mark-read`
Mark messages as read in a conversation.

**Request Body:**
```json
{
  "conversationId": "conv123",
  "userId": "user123"
}
```






