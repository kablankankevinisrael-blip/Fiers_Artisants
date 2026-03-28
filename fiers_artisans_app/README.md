# Fiers Artisans — Application Mobile Flutter

[![Flutter](https://img.shields.io/badge/Flutter-3.41.4-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.1-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/Riverpod-2.6-00B0FF?style=for-the-badge&logo=dart&logoColor=white)](https://riverpod.dev)
[![GoRouter](https://img.shields.io/badge/GoRouter-14.8-6200EA?style=for-the-badge&logo=dart&logoColor=white)](https://pub.dev/packages/go_router)
[![Material3](https://img.shields.io/badge/Material_3-Design-757575?style=for-the-badge&logo=materialdesign&logoColor=white)](https://m3.material.io)
[![Android](https://img.shields.io/badge/Android-SDK-34A853?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-Compatible-000000?style=for-the-badge&logo=apple&logoColor=white)](https://developer.apple.com)

> **Document de référence officiel du frontend Fiers Artisans.**  
> Application mobile Flutter pour la marketplace connectant les artisans ivoiriens avec leurs clients.

---

## Table des matières

1. [Présentation du projet](#1-présentation-du-projet)
2. [Stack technique](#2-stack-technique)
3. [Arborescence du projet](#3-arborescence-du-projet)
4. [Configuration](#4-configuration)
5. [Couche Core (réseau, stockage, utilitaires)](#5-couche-core-réseau-stockage-utilitaires)
6. [Modèles de données](#6-modèles-de-données)
7. [Repositories](#7-repositories)
8. [Providers (State Management)](#8-providers-state-management)
9. [Widgets communs](#9-widgets-communs)
10. [Écrans](#10-écrans)
11. [Navigation (GoRouter)](#11-navigation-gorouter)
12. [Système de thèmes](#12-système-de-thèmes)
13. [Internationalisation (i18n)](#13-internationalisation-i18n)
14. [Dépendances](#14-dépendances)
15. [Démarrage rapide](#15-démarrage-rapide)

---

## 1. Présentation du projet

**Fiers Artisans** est une application mobile Flutter pour la marketplace ivoirienne qui met en relation des artisans locaux avec leurs clients. Ce dépôt contient le frontend mobile de la plateforme.

### Points clés

- **Architecture Clean** — Séparation stricte : `core/` → `data/` → `providers/` → `presentation/`
- **Repository Pattern** — Abstraction complète de la couche données via des repositories dédiés
- **State Management** — Riverpod avec `StateNotifierProvider` pour un état réactif et testable
- **Navigation** — GoRouter avec shell routes et transitions personnalisées
- **Thème dual** — Mode sombre (défaut) et clair avec palette dorée signature
- **Bilingue** — Français et anglais via EasyLocalization avec 170 clés de traduction

---

## 2. Stack technique

| Couche | Technologie | Détails |
|--------|-------------|---------|
| **Framework** | Flutter 3.41.4 | Dart 3.11.1, Material 3 |
| **State Management** | Riverpod 2.6 | `StateNotifierProvider` |
| **Navigation** | GoRouter 14.8 | Shell routes, transitions personnalisées |
| **HTTP** | Dio 5.7 | Intercepteurs auth + refresh automatique JWT |
| **i18n** | EasyLocalization 3.0 | FR/EN, fichiers JSON de traduction |
| **Stockage sécurisé** | FlutterSecureStorage 9.2 | Tokens chiffrés (`EncryptedSharedPreferences`) |
| **Préférences** | SharedPreferences 2.5 | Thème, locale, onboarding |
| **Images** | CachedNetworkImage 3.4 | Cache réseau, placeholders |
| **Géolocalisation** | Geolocator 13.0 | GPS, recherche par rayon |
| **Polices** | Google Fonts 6.2 | Typeface Inter |
| **Temps réel** | WebSocketChannel 3.0 | Chat en direct |
| **Animations** | flutter_animate 4.5, Lottie 3.3, Shimmer 3.0 | Transitions, chargement |

---

## 3. Arborescence du projet

```
lib/
├── app.dart                              # Widget racine MaterialApp.router
├── main.dart                             # Point d'entrée, initialisation providers
├── config/
│   ├── app_config.dart                   # URLs API, timeouts, paramètres métier
│   ├── constants.dart                    # Clés storage, rôles, durées, rayons
│   ├── theme.dart                        # Thèmes sombre/clair, typographie, composants
│   └── routes.dart                       # Configuration GoRouter, shell routes
├── core/
│   ├── network/
│   │   ├── api_client.dart               # Client Dio singleton, intercepteurs
│   │   └── api_endpoints.dart            # Tous les endpoints API centralisés
│   ├── storage/
│   │   └── secure_storage.dart           # FlutterSecureStorage — tokens, user info
│   └── utils/
│       ├── validators.dart               # Validation formulaires (téléphone CI, OTP, etc.)
│       └── formatters.dart               # Formatage FCFA, téléphone, distance, date
├── data/
│   ├── models/
│   │   ├── user_model.dart               # Utilisateur (auth, profil)
│   │   ├── artisan_model.dart            # Profil artisan (géoloc, stats, badges)
│   │   ├── category_model.dart           # Catégorie + sous-catégories
│   │   ├── portfolio_model.dart          # Item portfolio artisan
│   │   ├── review_model.dart             # Avis client (rating 1-5)
│   │   ├── subscription_model.dart       # Abonnement artisan
│   │   ├── conversation_model.dart       # Conversation chat
│   │   └── message_model.dart            # Message individuel
│   └── repositories/
│       ├── auth_repository.dart          # Auth: login, register, OTP, refresh
│       ├── artisan_repository.dart       # Profil, avis, portfolio
│       ├── search_repository.dart        # Recherche géospatiale
│       ├── chat_repository.dart          # Conversations, messages, WebSocket
│       └── subscription_repository.dart  # Statut abonnement, paiement Wave
├── providers/
│   ├── app_providers.dart                # Thème, locale, onboarding, helpers
│   ├── auth_provider.dart                # État authentification + actions
│   ├── artisan_provider.dart             # Détail artisan, avis, portfolio
│   ├── search_provider.dart              # Recherche avec pagination infinie
│   ├── chat_provider.dart                # Conversations + messages temps réel
│   ├── categories_provider.dart          # Catégories avec cache
│   └── subscription_provider.dart        # Abonnement artisan + paiement
└── presentation/
    ├── auth/                             # 7 écrans (splash, onboarding, login, register, OTP)
    ├── client/                           # 4 écrans (dashboard, recherche, profil artisan, avis)
    ├── artisan/                          # 4 écrans (dashboard, portfolio, vérification, abonnement)
    ├── chat/                             # 2 écrans (liste conversations, chat)
    ├── shared/                           # 2 écrans (notifications, paramètres)
    └── common/                           # 9 widgets réutilisables
```

---

## 4. Configuration

### 4.1 `app_config.dart` — Paramètres de l'application

```dart
class AppConfig {
  // Identité
  static const String appName = 'Fiers Artisans';
  static const String appVersion = '1.0.0';

  // API
  static const String apiBaseUrl = 'http://10.0.2.2:3000/api/v1'; // Android emulator → localhost
  static const String wsBaseUrl = 'ws://10.0.2.2:3000';

  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  // OTP
  static const int otpLength = 6;
  static const Duration otpResendDelay = Duration(seconds: 60);

  // Recherche géospatiale
  static const double defaultSearchRadius = 10.0; // km
  static const double maxSearchRadius = 50.0;     // km

  // Pagination
  static const int defaultPageSize = 20;

  // Abonnement
  static const int subscriptionAmountFCFA = 5000;

  // Téléphone
  static const String phonePrefix = '+225';
}
```

### 4.2 `constants.dart` — Constantes globales

#### Clés de stockage

| Clé | Description |
|-----|-------------|
| `keyAccessToken` | JWT access token |
| `keyRefreshToken` | JWT refresh token |
| `keyUserId` | ID de l'utilisateur connecté |
| `keyUserRole` | Rôle de l'utilisateur (`artisan`, `client`, `admin`) |
| `keyThemeMode` | Mode thème (`dark`, `light`) |
| `keyLocale` | Langue sélectionnée (`fr`, `en`) |
| `keyOnboardingCompleted` | Flag onboarding terminé |

#### Rôles utilisateur

| Constante | Valeur | Description |
|-----------|--------|-------------|
| `roleArtisan` | `"artisan"` | Artisan inscrit |
| `roleClient` | `"client"` | Client consommateur |
| `roleAdmin` | `"admin"` | Administrateur |

#### Statuts de vérification

| Constante | Valeur |
|-----------|--------|
| `statusPending` | `"pending"` |
| `statusApproved` | `"approved"` |
| `statusRejected` | `"rejected"` |

#### Statuts d'abonnement

| Constante | Valeur |
|-----------|--------|
| `subActive` | `"active"` |
| `subExpired` | `"expired"` |
| `subPending` | `"pending"` |

#### Durées d'animation

| Constante | Durée | Usage |
|-----------|-------|-------|
| `animFast` | 150 ms | Micro-interactions |
| `animNormal` | 300 ms | Transitions standard |
| `animSlow` | 500 ms | Transitions complexes |
| `animSplash` | 800 ms | Animation splash screen |

#### Rayons de bordure

| Constante | Valeur | Usage |
|-----------|--------|-------|
| `radiusSmall` | 8 px | Éléments compacts |
| `radiusMedium` | 12 px | Champs de saisie |
| `radiusLarge` | 16 px | Cartes |
| `radiusXLarge` | 24 px | Bottom sheets |
| `radiusRound` | 100 px | Badges, avatars |

---

## 5. Couche Core (réseau, stockage, utilitaires)

### 5.1 `ApiClient` — Client HTTP Dio

Client singleton encapsulant toutes les communications réseau avec le backend.

#### Méthodes publiques

```dart
class ApiClient {
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters});
  Future<Response> post(String path, {dynamic data});
  Future<Response> put(String path, {dynamic data});
  Future<Response> patch(String path, {dynamic data});
  Future<Response> delete(String path);
  Future<Response> uploadFile(String path, {required File file, String fieldName = 'file'});
}
```

#### Intercepteurs

| Intercepteur | Rôle |
|--------------|------|
| `_AuthInterceptor` | Ajoute le header `Authorization: Bearer <token>` à chaque requête. En cas de réponse `401`, tente un refresh automatique via `POST /auth/refresh`. Si le refresh échoue, vide le stockage sécurisé et redirige vers le login. |
| `_LoggingInterceptor` | Log les requêtes et réponses en mode debug uniquement (`kDebugMode`). Format : `[REQUEST] METHOD url` / `[RESPONSE] statusCode url`. |

### 5.2 Endpoints API

> Tous les endpoints sont centralisés dans `api_endpoints.dart` pour éviter les chaînes en dur.

#### Auth (6 endpoints)

| Constante | Méthode | Path |
|-----------|---------|------|
| `login` | `POST` | `/auth/login` |
| `registerArtisan` | `POST` | `/auth/register/artisan` |
| `registerClient` | `POST` | `/auth/register/client` |
| `refreshToken` | `POST` | `/auth/refresh` |
| `sendOtp` | `POST` | `/auth/otp/send` |
| `verifyOtp` | `POST` | `/auth/otp/verify` |

#### Users (3 endpoints)

| Constante | Méthode | Path |
|-----------|---------|------|
| `profile` | `GET` | `/users/profile` |
| `updateProfile` | `PATCH` | `/users/profile` |
| `userById(id)` | `GET` | `/users/:id` |

#### Categories (2 endpoints)

| Constante | Méthode | Path |
|-----------|---------|------|
| `categories` | `GET` | `/categories` |
| `categoryById(id)` | `GET` | `/categories/:id` |

#### Search (1 endpoint)

| Constante | Méthode | Path |
|-----------|---------|------|
| `search` | `GET` | `/search` (avec query params) |

#### Reviews (2 endpoints)

| Constante | Méthode | Path |
|-----------|---------|------|
| `reviews` | `POST` | `/reviews` |
| `reviewsByArtisan(id)` | `GET` | `/reviews/artisan/:id` |

#### Portfolio (2 endpoints)

| Constante | Méthode | Path |
|-----------|---------|------|
| `portfolio` | `POST` | `/portfolio` |
| `portfolioByArtisan(id)` | `GET` | `/portfolio/artisan/:id` |

#### Subscription (2 endpoints)

| Constante | Méthode | Path |
|-----------|---------|------|
| `subscription` | `GET` | `/subscription` |
| `subscriptionStatus` | `GET` | `/subscription/status` |

#### Verification (2 endpoints)

| Constante | Méthode | Path |
|-----------|---------|------|
| `verification` | `GET` | `/verification` |
| `verificationSubmit` | `POST` | `/verification/submit` |

#### Chat (2 endpoints)

| Constante | Méthode | Path |
|-----------|---------|------|
| `conversations` | `GET` | `/chat/conversations` |
| `messages(id)` | `GET` | `/chat/conversations/:id/messages` |

#### Media (1 endpoint)

| Constante | Méthode | Path |
|-----------|---------|------|
| `upload` | `POST` | `/media/upload` |

#### Health (1 endpoint)

| Constante | Méthode | Path |
|-----------|---------|------|
| `health` | `GET` | `/health` |

### 5.3 `SecureStorage` — Stockage sécurisé

Encapsulation de `FlutterSecureStorage` pour la gestion des tokens et informations utilisateur. Sur Android, utilise `EncryptedSharedPreferences`.

```dart
class SecureStorage {
  Future<void> saveTokens({required String accessToken, required String refreshToken});
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveUserInfo({required String userId, required String userRole});
  Future<String?> getUserId();
  Future<String?> getUserRole();
  Future<void> clearAll();
  Future<bool> isLoggedIn();
}
```

### 5.4 `Validators` — Validation de formulaires

| Méthode | Règle | Message d'erreur |
|---------|-------|------------------|
| `required(value)` | Non vide | « Ce champ est requis » |
| `phone(value)` | 10 chiffres (format CI) | « Numéro invalide (10 chiffres) » |
| `password(value)` | Minimum 6 caractères | « Minimum 6 caractères » |
| `confirmPassword(value, password)` | Identique au mot de passe | « Les mots de passe ne correspondent pas » |
| `email(value)` | Format email (optionnel) | « Email invalide » |
| `otp(value)` | Exactement 6 chiffres | « Code invalide (6 chiffres) » |
| `minLength(value, min)` | Longueur minimale | « Minimum {min} caractères » |

### 5.5 `Formatters` — Formatage de données

| Méthode | Entrée | Sortie | Exemple |
|---------|--------|--------|---------|
| `fcfa(amount)` | `5000` | `String` | `"5 000 FCFA"` |
| `phone(number)` | `"0701020304"` | `String` | `"07 01 02 03 04"` |
| `distance(km)` | `1.5` | `String` | `"1.5 km"` |
| `distance(km)` | `0.5` | `String` | `"500 m"` |
| `relativeDate(date)` | `DateTime.now()` | `String` | `"À l'instant"` |
| `relativeDate(date)` | `DateTime(-5min)` | `String` | `"Il y a 5 min"` |
| `rating(value)` | `4.5` | `String` | `"4.5"` |
| `truncate(text, max)` | `"Lorem..."` | `String` | `"Lorem ip..."` |

---

## 6. Modèles de données

> 8 modèles immutables avec `copyWith()`, `fromJson()` et `toJson()`.

### 6.1 `UserModel`

| Champ | Type | Notes |
|-------|------|-------|
| `id` | `String` | UUID |
| `phone` | `String` | Format CI (+225) |
| `firstName` | `String` | Prénom |
| `lastName` | `String` | Nom |
| `role` | `String` | `artisan` \| `client` \| `admin` |
| `email` | `String?` | Optionnel |
| `isPhoneVerified` | `bool` | Vérifié par OTP |
| `isActive` | `bool` | Compte actif |
| `createdAt` | `DateTime` | Date de création |

**Getter :** `fullName` → `"$firstName $lastName"`  
**Méthodes :** `copyWith()`, `fromJson()`, `toJson()`

### 6.2 `ArtisanModel`

| Champ | Type | Notes |
|-------|------|-------|
| `id` | `String` | UUID profil artisan |
| `userId` | `String` | Référence vers `UserModel` |
| `firstName` | `String` | Prénom |
| `lastName` | `String` | Nom |
| `phone` | `String` | Téléphone |
| `email` | `String?` | Optionnel |
| `profession` | `String` | Métier exercé |
| `city` | `String` | Ville |
| `commune` | `String` | Commune |
| `latitude` | `double?` | Coordonnée GPS |
| `longitude` | `double?` | Coordonnée GPS |
| `averageRating` | `double` | Note moyenne (défaut : `0.0`) |
| `totalReviews` | `int` | Nombre d'avis (défaut : `0`) |
| `profilePhotoUrl` | `String?` | URL photo de profil |
| `isVerified` | `bool` | Identité vérifiée |
| `isCertified` | `bool` | Certifié Fiers Artisans |
| `isAvailable` | `bool` | Disponible pour travaux |
| `hasActiveSubscription` | `bool` | Abonnement actif |
| `categoryId` | `String?` | ID catégorie |
| `categoryName` | `String?` | Nom catégorie |
| `distance` | `double?` | Distance calculée (km) |
| `createdAt` | `DateTime?` | Date de création |

### 6.3 `CategoryModel`

| Champ | Type | Notes |
|-------|------|-------|
| `id` | `String` | UUID |
| `name` | `String` | Nom de la catégorie |
| `icon` | `String?` | Nom de l'icône |
| `description` | `String?` | Description |
| `subcategories` | `List<SubcategoryModel>` | Sous-catégories associées |

### 6.4 `PortfolioModel`

| Champ | Type | Notes |
|-------|------|-------|
| `id` | `String` | UUID |
| `artisanId` | `String` | Référence artisan |
| `title` | `String` | Titre du projet |
| `description` | `String?` | Description |
| `imageUrls` | `List<String>` | URLs des images |
| `price` | `double?` | Prix indicatif |
| `createdAt` | `DateTime?` | Date de création |

### 6.5 `ReviewModel`

| Champ | Type | Notes |
|-------|------|-------|
| `id` | `String` | UUID |
| `clientId` | `String` | Auteur de l'avis |
| `artisanId` | `String` | Artisan évalué |
| `clientName` | `String?` | Nom affiché du client |
| `rating` | `int` | Note de 1 à 5 |
| `comment` | `String?` | Commentaire optionnel |
| `createdAt` | `DateTime` | Date de publication |

### 6.6 `SubscriptionModel`

| Champ | Type | Notes |
|-------|------|-------|
| `id` | `String` | UUID |
| `artisanId` | `String` | Artisan abonné |
| `status` | `String` | `active` \| `expired` \| `pending` |
| `startDate` | `DateTime?` | Début de l'abonnement |
| `endDate` | `DateTime?` | Fin de l'abonnement |
| `amountFcfa` | `int` | Montant en FCFA |
| `paymentMethod` | `String?` | Méthode de paiement (ex. Wave) |

**Getters :**
- `isActive` → `status == "active" && endDate.isAfter(now)`
- `isExpired` → `status == "expired" || endDate.isBefore(now)`
- `daysRemaining` → nombre de jours restants avant expiration

### 6.7 `ConversationModel`

| Champ | Type | Notes |
|-------|------|-------|
| `id` | `String` | UUID conversation |
| `participantId` | `String` | ID de l'autre participant |
| `participantName` | `String` | Nom affiché |
| `participantAvatarUrl` | `String?` | URL avatar |
| `lastMessage` | `String?` | Dernier message |
| `lastMessageAt` | `DateTime?` | Horodatage dernier message |
| `unreadCount` | `int` | Messages non lus |

### 6.8 `MessageModel`

| Champ | Type | Notes |
|-------|------|-------|
| `id` | `String` | UUID message |
| `conversationId` | `String` | Référence conversation |
| `senderId` | `String` | Auteur du message |
| `content` | `String` | Contenu textuel |
| `type` | `String?` | Type de message (défaut : `"text"`) |
| `createdAt` | `DateTime` | Horodatage |
| `isRead` | `bool` | Lu par le destinataire |

---

## 7. Repositories

> Couche d'abstraction entre les providers et le client HTTP. Chaque repository gère un domaine métier.

### 7.1 `AuthRepository`

```dart
class AuthRepository {
  Future<Map<String, dynamic>> login({required String phone, required String password});

  Future<Map<String, dynamic>> registerArtisan({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required String profession,
    required String city,
    required String commune,
    String? email,
    String? description,
    int? experienceYears,
    String? categoryId,
  });

  Future<Map<String, dynamic>> registerClient({
    required String phone,
    required String password,
    required String firstName,
    required String lastName,
    required String city,
    required String commune,
    String? email,
  });

  Future<void> sendOtp(String phone);
  Future<Map<String, dynamic>> verifyOtp({required String phone, required String code});
  Future<Map<String, dynamic>> refreshToken(String refreshToken);
  Future<UserModel> getProfile();
}
```

### 7.2 `ArtisanRepository`

```dart
class ArtisanRepository {
  Future<ArtisanModel> getArtisan(String userId);
  Future<List<ReviewModel>> getReviews(String artisanId, {int? page});
  Future<void> submitReview({required String artisanId, required int rating, String? comment});
  Future<List<PortfolioModel>> getPortfolio(String artisanId);
  Future<void> addPortfolioItem({
    required String title,
    String? description,
    double? price,
    required List<String> imageUrls,
  });
}
```

### 7.3 `SearchRepository`

```dart
class SearchRepository {
  Future<List<ArtisanModel>> searchArtisans({
    double? latitude,
    double? longitude,
    double? radius,
    String? categoryId,
    String? query,
    int page = 1,
    int limit = 20,
  });
}
```

### 7.4 `ChatRepository`

```dart
class ChatRepository {
  Future<List<ConversationModel>> getConversations();
  Future<List<MessageModel>> getMessages(String conversationId, {int? page});
  Future<WebSocketChannel> connectWebSocket();
  void sendMessage(Map<String, dynamic> message);
  void disconnect();
}
```

### 7.5 `SubscriptionRepository`

```dart
class SubscriptionRepository {
  Future<SubscriptionModel?> getStatus();
  Future<Map<String, dynamic>> initiatePayment();
}
```

---

## 8. Providers (State Management)

> Architecture Riverpod avec `StateNotifierProvider`. Chaque provider encapsule un état immutable et un notifier pour les mutations.

### 8.1 `AuthProvider`

#### État

```dart
enum AuthStatus { initial, authenticated, unauthenticated, loading }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? error;
}
```

#### Méthodes du `AuthNotifier`

| Méthode | Description |
|---------|-------------|
| `checkAuth()` | Vérifie si un token valide existe au démarrage |
| `login(phone, password)` | Connexion, sauvegarde tokens, charge le profil |
| `registerArtisan({...})` | Inscription artisan complet |
| `registerClient({...})` | Inscription client |
| `sendOtp(phone)` | Envoi du code OTP |
| `verifyOtp(phone, code)` | Vérification OTP |
| `logout()` | Supprime tokens, réinitialise l'état |

### 8.2 `ArtisanDetailProvider`

#### État

```dart
class ArtisanDetailState {
  final ArtisanModel? artisan;
  final List<ReviewModel> reviews;
  final List<PortfolioModel> portfolio;
  final bool isLoading;
  final String? error;
}
```

#### Méthodes

| Méthode | Description |
|---------|-------------|
| `loadArtisan(userId)` | Charge profil + avis + portfolio en parallèle (`Future.wait`) |
| `submitReview(artisanId, rating, comment?)` | Soumet un avis et recharge les données |

### 8.3 `SearchProvider`

#### État

```dart
class SearchState {
  final List<ArtisanModel> results;
  final bool isLoading;
  final String? error;
  final String? query;
  final String? categoryId;
  final double radius;
  final int page;
  final bool hasMore;
}
```

#### Méthodes

| Méthode | Description |
|---------|-------------|
| `search(latitude, longitude, {query?, categoryId?, radius?})` | Lance une nouvelle recherche (reset page) |
| `loadMore()` | Charge la page suivante (pagination infinie) |
| `clear()` | Réinitialise les résultats et filtres |

### 8.4 `ChatProvider`

#### État

```dart
class ChatState {
  final List<ConversationModel> conversations;
  final List<MessageModel> messages;
  final bool isLoading;
  final String? activeConversationId;
}
```

#### Méthodes

| Méthode | Description |
|---------|-------------|
| `loadConversations()` | Charge la liste des conversations |
| `loadMessages(conversationId)` | Charge les messages d'une conversation |
| `addMessage(message)` | Ajoute un message localement (envoi WebSocket) |
| `disconnect()` | Ferme la connexion WebSocket |

### 8.5 `CategoriesProvider`

#### État

```dart
class CategoriesState {
  final List<CategoryModel> categories;
  final bool isLoading;
}
```

#### Méthodes

| Méthode | Description |
|---------|-------------|
| `load()` | Charge les catégories depuis l'API avec mise en cache |

### 8.6 `SubscriptionProvider`

#### État

```dart
class SubscriptionState {
  final SubscriptionModel? subscription;
  final bool isLoading;
  final String? error;
}
```

#### Méthodes

| Méthode | Description |
|---------|-------------|
| `loadStatus()` | Charge le statut d'abonnement courant |
| `initiatePayment()` | Déclenche le processus de paiement Wave |

### 8.7 `AppProviders` — Préférences globales

#### `ThemeNotifier`

```dart
class ThemeNotifier extends StateNotifier<ThemeMode> {
  void setDark();      // Bascule en mode sombre
  void setLight();     // Bascule en mode clair
  void toggle();       // Inverse le mode courant
  bool get isDark;     // Lecture rapide
}
```

> Persiste le choix dans `SharedPreferences` via la clé `keyThemeMode`.

#### `LocaleNotifier`

```dart
class LocaleNotifier extends StateNotifier<Locale> {
  void setFrench();      // Locale fr
  void setEnglish();     // Locale en
  void toggleLocale();   // Inverse la langue courante
}
```

> S'intègre avec `EasyLocalization` pour mettre à jour les traductions en temps réel.

#### `OnboardingNotifier`

```dart
class OnboardingNotifier extends StateNotifier<bool> {
  Future<void> complete(); // Marque l'onboarding comme terminé
}
```

> Persiste dans `SharedPreferences` via `keyOnboardingCompleted`.

#### Extension `ThemeHelper`

```dart
extension ThemeHelper on BuildContext {
  ThemeData get theme;
  ColorScheme get colors;
  TextTheme get textTheme;
  bool get isDark;
  Color get goldColor; // Couleur dorée signature
}
```

---

## 9. Widgets communs

> 9 widgets réutilisables dans `presentation/common/`.

### 9.1 `AppButton`

Bouton principal de l'application avec gradient doré.

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `text` | `String` | — | Texte du bouton |
| `onPressed` | `VoidCallback?` | `null` | Action au tap (désactivé si `null`) |
| `isLoading` | `bool` | `false` | Affiche un spinner |
| `isOutlined` | `bool` | `false` | Style contour au lieu de rempli |
| `icon` | `IconData?` | `null` | Icône à gauche du texte |
| `width` | `double?` | `null` | Largeur fixe (pleine largeur si `null`) |

**Caractéristiques :**
- Gradient doré (`#E8A020` → `#C87D2A`)
- Animation shimmer (boucle 2 secondes)
- Retour haptique au tap
- Spinner de chargement intégré
- Hauteur fixe : **52 px**

### 9.2 `AppTextField`

Champ de saisie unifié avec validation intégrée.

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `controller` | `TextEditingController` | — | Contrôleur du champ |
| `label` | `String?` | `null` | Label flottant |
| `hint` | `String` | — | Texte indicatif |
| `validator` | `FormFieldValidator?` | `null` | Fonction de validation |
| `keyboardType` | `TextInputType` | `text` | Type de clavier |
| `obscureText` | `bool` | `false` | Masquer le texte (mot de passe) |
| `prefixIcon` | `IconData?` | `null` | Icône de préfixe |
| `suffix` | `Widget?` | `null` | Widget suffixe personnalisé |
| `maxLines` | `int` | `1` | Nombre de lignes |
| `autofocus` | `bool` | `false` | Focus automatique |
| `textInputAction` | `TextInputAction` | `next` | Action du clavier |
| `onChanged` | `ValueChanged?` | `null` | Callback de changement |
| `onSubmitted` | `ValueChanged?` | `null` | Callback de soumission |
| `focusNode` | `FocusNode?` | `null` | Nœud de focus |

**Caractéristiques :** Toggle visibilité mot de passe, icône de préfixe, intégration validation `Form`

### 9.3 `ArtisanCard`

Carte affichant le résumé d'un artisan.

| Prop | Type | Description |
|------|------|-------------|
| `artisan` | `ArtisanModel` | Données de l'artisan |
| `onTap` | `VoidCallback?` | Action au tap |

**Caractéristiques :**
- Layout en `Row` : avatar (56×56 px) + informations
- `CachedNetworkImage` pour l'avatar ou initiales en fallback
- Badges vérification/certification
- Affichage distance si disponible
- Animation scale `0.97` au press (120 ms)

### 9.4 `BadgeVerified`

Badge de vérification/certification avec animation.

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `type` | `String` | — | `"verified"` ou `"certified"` |
| `size` | `double` | `18` | Taille du badge |

**Couleurs :**
- `verified` → Vert (`Colors.green`)
- `certified` → Doré (couleur primaire)

**Animation :** Pulsation continue (scale `1.0` → `1.12`, boucle de 2 secondes)

### 9.5 `CategoryChip`

Chip de sélection de catégorie.

| Prop | Type | Description |
|------|------|-------------|
| `label` | `String` | Nom de la catégorie |
| `icon` | `String?` | Icône optionnelle |
| `isSelected` | `bool` | État de sélection |
| `onTap` | `VoidCallback?` | Action au tap |

**Animation :** `AnimatedContainer` (200 ms). État sélectionné : fond primaire à 0.15 alpha.

### 9.6 `EmptyState`

Indicateur d'état vide pour les listes.

| Prop | Type | Description |
|------|------|-------------|
| `icon` | `IconData` | Icône centrale |
| `title` | `String` | Message principal |
| `subtitle` | `String?` | Message secondaire |
| `actionLabel` | `String?` | Texte du bouton d'action |
| `onAction` | `VoidCallback?` | Action du bouton |

**Layout :** Centré verticalement, icône 64 sp.

### 9.7 `LoadingOverlay`

Overlay de chargement superposé à un contenu.

| Prop | Type | Description |
|------|------|-------------|
| `isLoading` | `bool` | Afficher l'overlay |
| `child` | `Widget` | Contenu sous-jacent |
| `message` | `String?` | Message de chargement |

**Rendu :** `Stack` avec overlay noir à 0.4 alpha, spinner centré.

### 9.8 `RatingStars`

Affichage et saisie d'étoiles de notation.

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `rating` | `double` | — | Note (0.0 à 5.0) |
| `size` | `double` | `18` | Taille des étoiles |
| `interactive` | `bool` | `false` | Mode saisie interactive |
| `onRatingChanged` | `ValueChanged<int>?` | `null` | Callback de notation |

**Rendu :** Étoiles pleines, demi-étoiles et vides. Couleur dorée. Mode interactif avec tap-to-rate.

### 9.9 `SkeletonLoader`

Placeholder de chargement avec animation shimmer.

| Prop | Type | Défaut | Description |
|------|------|--------|-------------|
| `width` | `double` | — | Largeur du skeleton |
| `height` | `double` | `16` | Hauteur du skeleton |
| `borderRadius` | `double` | `8` | Rayon de bordure |

**Animation :** Shimmer à 3 couleurs.  
**Factory :** `SkeletonLoader.artisanCard()` — Skeleton pré-configuré en forme de carte artisan.

---

## 10. Écrans

> 19 écrans répartis en 5 sections.

### 10.1 Auth — 7 écrans

#### `SplashScreen`

- **Route :** `/`
- **UI :** Fond dégradé doré, logo centré
- **Animations :** Fade-in + slide du logo (800 ms)
- **Logique :** Navigation automatique après 2.5 s → onboarding (première fois) ou login (retour)

#### `OnboardingScreen`

- **Route :** `/onboarding`
- **UI :** `PageView` de 3 pages avec illustrations
- **Fonctionnalités :** Toggle thème sombre/clair, toggle langue FR/EN, indicateur de points, bouton « Commencer »

#### `LoginScreen`

- **Route :** `/login`
- **UI :** Formulaire téléphone + mot de passe
- **Logique :** Routing basé sur le rôle après connexion (`/client` ou `/artisan`), snackbar d'erreur

#### `RegisterChoiceScreen`

- **Route :** `/register`
- **UI :** 2 cartes de choix (Artisan / Client) avec animation scale
- **Logique :** Navigation vers le formulaire correspondant

#### `RegisterArtisanScreen`

- **Route :** `/register/artisan`
- **UI :** Formulaire scrollable — nom, prénom, téléphone, mot de passe, email, profession, ville, commune, description, années d'expérience, dropdown catégorie
- **Validation :** Validators intégrés sur tous les champs requis

#### `RegisterClientScreen`

- **Route :** `/register/client`
- **UI :** Formulaire simplifié — nom, prénom, téléphone, mot de passe, email, ville, commune

#### `OtpVerificationScreen`

- **Route :** `/otp`
- **UI :** 6 champs de saisie individuelle pour le code OTP
- **Fonctionnalités :** Auto-avancement du focus entre les champs, timer de renvoi 60 s, vérification automatique dès saisie complète

### 10.2 Client — 4 écrans

#### `ClientDashboard`

- **Route :** `/client`
- **UI :** `SliverAppBar`, message d'accueil personnalisé, barre de recherche, scroll horizontal des catégories
- **Chargement :** Skeleton loaders pendant le chargement

#### `SearchScreen`

- **Route :** `/client/search`
- **UI :** Résultats de recherche avec cartes artisans
- **Fonctionnalités :** Demande permission GPS, coordonnées Abidjan par défaut, slider rayon 10-50 km, filtre par catégorie, pagination infinie (scroll)

#### `ArtisanProfileScreen`

- **Route :** `/client/artisan/:userId`
- **UI :** `SliverAppBar` avec dégradé, avatar, badges vérification/certification
- **Sections :** Carrousel portfolio, liste des avis, boutons de contact (WhatsApp, Appel, Chat)

#### `ReviewScreen`

- **Route :** `/client/review/:artisanId`
- **UI :** Étoiles interactives, champ de commentaire, bouton de soumission

### 10.3 Artisan — 4 écrans

#### `ArtisanDashboard`

- **Route :** `/artisan`
- **UI :** Message d'accueil, carte de statut d'abonnement (gradient doré), grille 4 tuiles (portfolio, vérification, paramètres, avis)

#### `PortfolioScreen`

- **Route :** `/artisan/portfolio`
- **UI :** Grille de projets, FAB pour ajouter un item, état vide si aucun projet

#### `VerificationScreen`

- **Route :** `/artisan/verification`
- **UI :** Upload de pièce d'identité + diplôme, indicateurs de statut (pending/approved/rejected)

#### `SubscriptionScreen`

- **Route :** `/artisan/subscription`
- **UI :** Carte de statut, bouton paiement Wave, compteur à rebours avant expiration

### 10.4 Chat — 2 écrans

#### `ConversationsListScreen`

- **Route :** `/chat`
- **UI :** Liste des conversations — avatar, nom, dernier message, horodatage, badge messages non lus

#### `ChatScreen`

- **Route :** `/chat/:conversationId`
- **UI :** Bulles de message (doré = envoyé, surface = reçu), barre de saisie
- **Temps réel :** WebSocket pour les messages en direct

### 10.5 Shared — 2 écrans

#### `NotificationsScreen`

- **Route :** `/notifications`
- **UI :** État vide placeholder (fonctionnalité à venir)

#### `SettingsScreen`

- **Route :** `/settings`
- **UI :** Toggle thème, toggle langue, profil, section « À propos » avec version, déconnexion avec dialogue de confirmation

---

## 11. Navigation (GoRouter)

### Configuration des routes

#### Routes d'authentification

| Path | Écran | Description |
|------|-------|-------------|
| `/` | `SplashScreen` | Écran de démarrage |
| `/onboarding` | `OnboardingScreen` | Introduction première utilisation |
| `/login` | `LoginScreen` | Connexion |
| `/register` | `RegisterChoiceScreen` | Choix type de compte |
| `/register/artisan` | `RegisterArtisanScreen` | Inscription artisan |
| `/register/client` | `RegisterClientScreen` | Inscription client |
| `/otp` | `OtpVerificationScreen` | Vérification OTP |

#### Shell Route Client (BottomNavigationBar — 4 onglets)

| Path | Écran | Onglet |
|------|-------|--------|
| `/client` | `ClientDashboard` | 🏠 Accueil |
| `/client/search` | `SearchScreen` | — (navigation depuis dashboard) |
| `/client/artisan/:userId` | `ArtisanProfileScreen` | — (navigation depuis recherche) |
| `/client/review/:artisanId` | `ReviewScreen` | — (navigation depuis profil) |

#### Shell Route Artisan (BottomNavigationBar — 4 onglets)

| Path | Écran | Onglet |
|------|-------|--------|
| `/artisan` | `ArtisanDashboard` | 🏠 Dashboard |
| `/artisan/portfolio` | `PortfolioScreen` | — (navigation depuis dashboard) |
| `/artisan/verification` | `VerificationScreen` | — (navigation depuis dashboard) |
| `/artisan/subscription` | `SubscriptionScreen` | — (navigation depuis dashboard) |

#### Routes partagées

| Path | Écran | Onglet BottomNav |
|------|-------|------------------|
| `/chat` | `ConversationsListScreen` | 💬 Messages |
| `/chat/:conversationId` | `ChatScreen` | — |
| `/notifications` | `NotificationsScreen` | 🔔 Notifications |
| `/settings` | `SettingsScreen` | ⚙️ Paramètres |

### Onglets BottomNavigationBar

| Index | Label | Icône |
|-------|-------|-------|
| 0 | Accueil / Dashboard | `Icons.home` |
| 1 | Messages | `Icons.chat_bubble` |
| 2 | Notifications | `Icons.notifications` |
| 3 | Paramètres | `Icons.settings` |

### Transitions personnalisées

```dart
CustomTransitionPage(
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.05, 0), // Décalage léger
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      )),
      child: FadeTransition(opacity: animation, child: child),
    );
  },
  transitionDuration: const Duration(milliseconds: 350),
)
```

---

## 12. Système de thèmes

> Deux thèmes complets avec Material 3. Le thème sombre est le défaut.

### 12.1 Palette de couleurs

#### Thème sombre (défaut)

| Rôle | Hex | Aperçu |
|------|-----|--------|
| Background | `#0D0D0F` | ![#0D0D0F](https://via.placeholder.com/16/0D0D0F/0D0D0F) |
| Surface | `#1A1A1E` | ![#1A1A1E](https://via.placeholder.com/16/1A1A1E/1A1A1E) |
| Surface Elevated | `#242428` | ![#242428](https://via.placeholder.com/16/242428/242428) |
| On Background | `#F5F5F5` | ![#F5F5F5](https://via.placeholder.com/16/F5F5F5/F5F5F5) |
| On Surface Muted | `#9E9EA8` | ![#9E9EA8](https://via.placeholder.com/16/9E9EA8/9E9EA8) |
| Divider | `#2A2A2E` | ![#2A2A2E](https://via.placeholder.com/16/2A2A2E/2A2A2E) |
| Primary | `#E8A020` | ![#E8A020](https://via.placeholder.com/16/E8A020/E8A020) |
| Secondary | `#C87D2A` | ![#C87D2A](https://via.placeholder.com/16/C87D2A/C87D2A) |

#### Thème clair

| Rôle | Hex | Aperçu |
|------|-----|--------|
| Background | `#F7F7F9` | ![#F7F7F9](https://via.placeholder.com/16/F7F7F9/F7F7F9) |
| Surface | `#FFFFFF` | ![#FFFFFF](https://via.placeholder.com/16/FFFFFF/FFFFFF) |
| Surface Elevated | `#EFEFEF` | ![#EFEFEF](https://via.placeholder.com/16/EFEFEF/EFEFEF) |
| On Background | `#1A1A1E` | ![#1A1A1E](https://via.placeholder.com/16/1A1A1E/1A1A1E) |
| On Surface Muted | `#6B6B75` | ![#6B6B75](https://via.placeholder.com/16/6B6B75/6B6B75) |
| Divider | `#E0E0E6` | ![#E0E0E6](https://via.placeholder.com/16/E0E0E6/E0E0E6) |
| Primary | `#C87D2A` | ![#C87D2A](https://via.placeholder.com/16/C87D2A/C87D2A) |
| Secondary | `#E8A020` | ![#E8A020](https://via.placeholder.com/16/E8A020/E8A020) |

#### Gradient doré

```dart
const goldGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFFE8A020), Color(0xFFC87D2A)],
);
```

### 12.2 Typographie (Inter)

| Style | Taille | Poids | Usage |
|-------|--------|-------|-------|
| `displayLarge` | 32 sp | `w700` (Bold) | Titres principaux |
| `displayMedium` | 28 sp | `w700` (Bold) | Titres secondaires |
| `headlineLarge` | 24 sp | `w600` (SemiBold) | En-têtes de section |
| `headlineMedium` | 20 sp | `w600` (SemiBold) | Sous-en-têtes |
| `titleLarge` | 18 sp | `w500` (Medium) | Titres de cartes |
| `titleMedium` | 16 sp | `w500` (Medium) | Titres secondaires |
| `bodyLarge` | 16 sp | `w400` (Regular) | Texte courant |
| `bodyMedium` | 14 sp | `w400` (Regular) | Texte standard |
| `bodySmall` | 12 sp | `w400` (Regular) | Texte auxiliaire |
| `labelLarge` | 15 sp | `w600` (SemiBold) | Labels de boutons |
| `labelMedium` | 13 sp | `w400` (Regular) | Labels de champs |
| `labelSmall` | 11 sp | `w400` (Regular) | Annotations |

### 12.3 Thèmes de composants

| Composant | Personnalisation |
|-----------|------------------|
| **AppBar** | Fond transparent, sans ombre, centré |
| **BottomNavigationBar** | Fond surface, indicateur primaire |
| **Cards** | Rayon de bordure 16 px, ombre subtile |
| **Buttons** | Hauteur 52 px, coins arrondis |
| **Input Fields** | Rayon de bordure 12 px, bordure outline |
| **Chips** | Rayon de bordure 20 px |
| **SnackBars** | Coins arrondis, thème cohérent |
| **BottomSheets** | Rayon supérieur 24 px |

---

## 13. Internationalisation (i18n)

### Configuration

- **Bibliothèque :** EasyLocalization 3.0
- **Langues :** Français (`fr.json`), Anglais (`en.json`)
- **Emplacement :** `assets/translations/`
- **Langue par défaut :** Français
- **Nombre de clés :** ~170 par langue

### Sections de traduction

| Section | Exemples de clés | Description |
|---------|-------------------|-------------|
| `app` | `app.name`, `app.version` | Identité de l'application |
| `theme` | `theme.dark`, `theme.light` | Labels des thèmes |
| `language` | `language.french`, `language.english` | Labels des langues |
| `onboarding` | `onboarding.title1`, `onboarding.desc1` | Textes d'introduction |
| `auth` | `auth.login`, `auth.register`, `auth.otp.*` | Authentification et OTP |
| `home` | `home.greeting`, `home.search` | Dashboard et accueil |
| `search` | `search.placeholder`, `search.radius` | Recherche d'artisans |
| `artisan` | `artisan.profile`, `artisan.contact.*`, `artisan.verification.*` | Profil et actions artisan |
| `portfolio` | `portfolio.title`, `portfolio.add` | Gestion portfolio |
| `subscription` | `subscription.status`, `subscription.pay` | Abonnement |
| `review` | `review.submit`, `review.rating` | Avis clients |
| `chat` | `chat.conversations`, `chat.send` | Messagerie |
| `notifications` | `notifications.empty` | Notifications |
| `settings` | `settings.theme`, `settings.language`, `settings.logout` | Paramètres |
| `error` | `error.network`, `error.unknown`, `error.unauthorized` | Messages d'erreur |
| `common` | `common.loading`, `common.retry`, `common.cancel` | Labels communs |

### Utilisation

```dart
// Dans un widget
Text('auth.login'.tr())

// Avec des paramètres
Text('home.greeting'.tr(args: [userName]))
```

---

## 14. Dépendances

### Dépendances de production (23)

| Package | Version | Rôle |
|---------|---------|------|
| `flutter_riverpod` | 2.6.1 | State management réactif |
| `go_router` | 14.8.1 | Navigation déclarative |
| `dio` | 5.7.0 | Client HTTP avec intercepteurs |
| `flutter_secure_storage` | 9.2.4 | Stockage sécurisé des tokens |
| `shared_preferences` | 2.5.3 | Préférences légères (thème, locale) |
| `easy_localization` | 3.0.7 | Internationalisation FR/EN |
| `cached_network_image` | 3.4.1 | Cache et affichage d'images réseau |
| `geolocator` | 13.0.2 | Géolocalisation GPS |
| `geocoding` | 3.0.0 | Géocodage adresses |
| `google_fonts` | 6.2.1 | Police Inter depuis Google Fonts |
| `web_socket_channel` | 3.0.2 | Communication WebSocket |
| `flutter_animate` | 4.5.2 | Animations déclaratives |
| `lottie` | 3.3.1 | Animations Lottie (JSON) |
| `shimmer` | 3.0.0 | Effet shimmer de chargement |
| `image_picker` | 1.1.2 | Sélection d'images (galerie/caméra) |
| `file_picker` | 8.1.6 | Sélection de fichiers |
| `url_launcher` | 6.3.1 | Ouverture URLs (WhatsApp, téléphone) |
| `intl` | 0.19.0 | Formatage dates et nombres |
| `equatable` | 2.0.7 | Comparaison d'objets immutables |
| `json_annotation` | 4.9.0 | Annotations sérialisation JSON |
| `flutter_svg` | 2.0.17 | Rendu d'images SVG |
| `permission_handler` | 11.3.1 | Gestion des permissions (GPS) |
| `path_provider` | 2.1.5 | Chemins système (cache, documents) |

### Dépendances de développement (5)

| Package | Version | Rôle |
|---------|---------|------|
| `flutter_test` | SDK | Tests unitaires et widgets |
| `flutter_lints` | 5.0.0 | Règles de lint recommandées |
| `build_runner` | 2.4.14 | Génération de code |
| `json_serializable` | 6.9.4 | Génération sérialisation JSON |
| `flutter_launcher_icons` | 0.14.3 | Génération icônes de lancement |

---

## 15. Démarrage rapide

### Prérequis

| Outil | Version minimale |
|-------|-----------------|
| Flutter SDK | 3.41.4+ |
| Dart SDK | 3.11.1+ |
| Android Studio | Dernière version stable |
| Android SDK | API 21+ (Android 5.0) |
| Appareil / Émulateur | Android ou iOS |

### Installation et lancement

```bash
# 1. Naviguer vers le projet
cd fiers_artisans_app

# 2. Installer les dépendances
flutter pub get

# 3. Vérifier l'analyse statique (0 issues attendues)
flutter analyze

# 4. Lancer l'application (appareil/émulateur connecté)
flutter run

# 5. Construire un APK debug
flutter build apk --debug
```

### Configuration du backend

> L'application attend le backend sur `http://10.0.2.2:3000/api/v1` (adresse spéciale de l'émulateur Android pour `localhost`).  
> Assurez-vous que le backend Fiers Artisans est démarré avant de lancer l'application.  
> Voir le [README du backend](../backend/README.md) pour les instructions de démarrage.

---

> **Fiers Artisans** — Connecter les artisans ivoiriens avec leurs clients. 🇨🇮
