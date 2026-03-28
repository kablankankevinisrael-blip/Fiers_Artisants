# Fiers Artisans — Backend API

[![NestJS](https://img.shields.io/badge/NestJS-11-E0234E?style=for-the-badge&logo=nestjs&logoColor=white)](https://nestjs.com)
[![TypeScript](https://img.shields.io/badge/TypeScript-5-3178C6?style=for-the-badge&logo=typescript&logoColor=white)](https://www.typescriptlang.org)
[![Node.js](https://img.shields.io/badge/Node.js-20-339933?style=for-the-badge&logo=node.js&logoColor=white)](https://nodejs.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-16_+_PostGIS-4169E1?style=for-the-badge&logo=postgresql&logoColor=white)](https://www.postgresql.org)
[![MongoDB](https://img.shields.io/badge/MongoDB-7-47A248?style=for-the-badge&logo=mongodb&logoColor=white)](https://www.mongodb.com)
[![Redis](https://img.shields.io/badge/Redis-7-DC382D?style=for-the-badge&logo=redis&logoColor=white)](https://redis.io)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://www.docker.com)
[![Socket.IO](https://img.shields.io/badge/Socket.IO-Temps_réel-010101?style=for-the-badge&logo=socket.io&logoColor=white)](https://socket.io)
[![MinIO](https://img.shields.io/badge/MinIO-S3_compatible-C72E49?style=for-the-badge&logo=minio&logoColor=white)](https://min.io)
[![Swagger](https://img.shields.io/badge/Swagger-API_Docs-85EA2D?style=for-the-badge&logo=swagger&logoColor=black)](http://localhost:3000/api/docs)

> **Document de référence officiel du backend Fiers Artisans.**  
> API REST + WebSocket pour la marketplace mobile connectant les artisans ivoiriens avec leurs clients.

---

## Table des matières

1. [Présentation du projet](#1-présentation-du-projet)
2. [Arborescence du projet](#2-arborescence-du-projet)
3. [Routes API complètes](#3-routes-api-complètes)
4. [Entités PostgreSQL (TypeORM)](#4-entités-postgresql-typeorm)
5. [Schémas MongoDB (Mongoose)](#5-schémas-mongodb-mongoose)
6. [DTOs](#6-dtos)
7. [Module Common](#7-module-common)
8. [Configuration](#8-configuration)
9. [Variables d environnement](#9-variables-denvironnement)
10. [Services Docker](#10-services-docker)
11. [Dockerfile multi-stage](#11-dockerfile-multi-stage)
12. [Données de seed](#12-données-de-seed)
13. [Dépendances de production](#13-dépendances-de-production)
14. [Détails architecturaux importants](#14-détails-architecturaux-importants)
15. [Sécurité](#15-sécurité)
16. [Démarrage rapide](#16-démarrage-rapide)
17. [Exemples d appels API](#17-exemples-dappels-api)

---

## 1. Présentation du projet

**Fiers Artisans** est une marketplace mobile ivoirienne qui met en relation des artisans locaux avec leurs clients. Ce dépôt contient le backend de la plateforme : une API REST + WebSocket construite avec NestJS.

### Stack technique

| Couche | Technologie | Détails |
|--------|-------------|---------|
| **Framework** | NestJS 11 | TypeScript, architecture modulaire |
| **Runtime** | Node.js 20 | LTS |
| **Base de données relationnelle** | PostgreSQL 16 + PostGIS | Données structurées et recherche géospatiale |
| **Base de données documents** | MongoDB 7 | Portfolio, chat, notifications, analytics |
| **Cache / OTP / Sessions** | Redis 7 | TTL, anti-brute-force, sessions |
| **Stockage fichiers** | MinIO | Compatible S3, buckets portfolio / documents / media |
| **Authentification** | JWT | Access token 15 min + Refresh token 30 jours |
| **OTP** | WhatsApp Business API | Cascade vers SMS Twilio en fallback |
| **Paiement** | Wave CI | Checkout session + webhook HMAC |
| **Temps réel** | Socket.IO | Chat artisan et client |
| **Documentation API** | Swagger UI | Disponible sur `/api/docs` |

---

## 2. Arborescence du projet

```
backend/
├── src/
│   ├── main.ts                           # Bootstrap, middleware, Swagger, globalPrefix('api/v1')
│   ├── app.module.ts                     # Root module — imports all feature modules
│   ├── common/
│   │   ├── decorators/
│   │   │   ├── current-user.decorator.ts # @CurrentUser() — extrait user du JWT
│   │   │   ├── roles.decorator.ts        # @Roles('ARTISAN','ADMIN') — marque les rôles requis
│   │   │   └── index.ts
│   │   ├── filters/
│   │   │   ├── global-exception.filter.ts # Catch-all — format erreur standardisé
│   │   │   └── index.ts
│   │   ├── guards/
│   │   │   ├── roles.guard.ts            # Vérifie le rôle user vs @Roles()
│   │   │   └── index.ts
│   │   ├── interceptors/
│   │   │   ├── logging.interceptor.ts    # Log: METHOD URL STATUS — Xms
│   │   │   ├── transform.interceptor.ts  # Wrap réponses: { statusCode, data, timestamp }
│   │   │   └── index.ts
│   │   └── pipes/
│   ├── config/
│   │   ├── app.config.ts                 # NODE_ENV, APP_PORT, APP_URL, CORS_ORIGINS
│   │   ├── database-postgres.config.ts   # POSTGRES_*
│   │   ├── database-mongo.config.ts      # MONGO_*
│   │   ├── redis.config.ts               # REDIS_*
│   │   ├── jwt.config.ts                 # JWT_SECRET, JWT_REFRESH_SECRET, expirations
│   │   ├── minio.config.ts               # MINIO_*
│   │   ├── whatsapp.config.ts            # WHATSAPP_*
│   │   ├── wave.config.ts                # WAVE_*
│   │   ├── providers.config.ts           # Feature flags OTP/Payment providers
│   │   └── index.ts                      # Re-exports all configs
│   ├── database/
│   │   ├── seeds/
│   │   │   ├── categories.seed.ts        # 16 catégories + 48 sous-catégories
│   │   │   └── run-seed.ts               # Script exécutable pour seeder
│   │   └── migrations/
│   └── modules/
│       ├── health/                       # GET /health — uptime, status
│       ├── auth/                         # Register, Login, OTP, JWT refresh
│       │   ├── dto/auth.dto.ts
│       │   ├── otp/otp.service.ts        # Redis OTP + anti-brute-force + fallback cascade
│       │   ├── otp/whatsapp-otp.provider.ts
│       │   ├── strategies/jwt.strategy.ts
│       │   └── strategies/jwt-refresh.strategy.ts
│       ├── users/                        # Profils artisan/client CRUD
│       │   └── entities/ (User, ArtisanProfile, ClientProfile)
│       ├── categories/                   # Catégories + sous-catégories
│       │   └── entities/ (Category, Subcategory)
│       ├── verification/                 # Soumission/review documents identité
│       │   └── entities/ (VerificationDocument)
│       ├── reviews/                      # Avis clients (rating 1-5, unique par paire)
│       │   └── entities/ (Review)
│       ├── subscription/                 # Abonnement artisan + paiement Wave
│       │   ├── entities/ (Subscription, Payment)
│       │   └── providers/wave.provider.ts
│       ├── search/                       # Recherche géospatiale PostGIS ST_DWithin
│       ├── portfolio/                    # Portfolio artisan (MongoDB)
│       │   └── schemas/portfolio-item.schema.ts
│       ├── chat/                         # Chat temps réel Socket.IO (MongoDB)
│       │   ├── chat.gateway.ts
│       │   └── schemas/ (Conversation, Message)
│       ├── notifications/                # Push FCM + stockage MongoDB avec TTL 30j
│       │   └── schemas/notification.schema.ts
│       ├── media/                        # Upload fichiers → Sharp compression → MinIO
│       │   └── schemas/media-file.schema.ts
│       ├── analytics/                    # Logs activité (MongoDB TTL 90j)
│       │   └── schemas/activity-log.schema.ts
│       └── admin/                        # Dashboard, gestion vérifications, analytics
├── Dockerfile                            # Multi-stage: dev → build → production
├── package.json
├── tsconfig.json
└── tsconfig.build.json
```

---

## 3. Routes API complètes

> **Préfixe global** : `api/v1` (défini dans `main.ts` via `app.setGlobalPrefix('api/v1')`)

### Légende

| Symbole | Signification |
|---------|---------------|
| ✅ | Authentification JWT requise |
| ❌ | Route publique |
| 🔑 | JWT Refresh uniquement |

---

### 3.1 Health

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| `GET` | `/api/v1/health` | ❌ | Vérification santé API (status, uptime, service name) |

---

### 3.2 Auth — `/api/v1/auth`

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| `POST` | `/api/v1/auth/register/artisan` | ❌ | Inscription artisan (phone, password, nom, business) |
| `POST` | `/api/v1/auth/register/client` | ❌ | Inscription client (phone, password, nom) |
| `POST` | `/api/v1/auth/send-otp` | ❌ | Envoi OTP WhatsApp (code en console en mode DEV) |
| `POST` | `/api/v1/auth/verify-otp` | ❌ | Vérification code OTP |
| `POST` | `/api/v1/auth/login` | ❌ | Connexion (retourne access_token + refresh_token + user) |
| `POST` | `/api/v1/auth/refresh` | 🔑 JWT-Refresh | Renouvellement access token |
| `POST` | `/api/v1/auth/logout` | ✅ JWT | Déconnexion |

---

### 3.3 Users (Artisans et Clients)

| Méthode | Route | Auth | Rôle | Description |
|---------|-------|------|------|-------------|
| `GET` | `/api/v1/artisan/profile` | ✅ | `ARTISAN` | Mon profil artisan |
| `PUT` | `/api/v1/artisan/profile` | ✅ | `ARTISAN` | Mise à jour profil artisan |
| `GET` | `/api/v1/artisan/:id` | ❌ | — | Profil public d un artisan |
| `GET` | `/api/v1/client/profile` | ✅ | `CLIENT` | Mon profil client |
| `PUT` | `/api/v1/client/profile` | ✅ | `CLIENT` | Mise à jour profil client |

---

### 3.4 Categories

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| `GET` | `/api/v1/categories` | ❌ | Toutes les catégories avec sous-catégories |
| `GET` | `/api/v1/categories/:slug` | ❌ | Catégorie par slug avec sous-catégories |

---

### 3.5 Portfolio

| Méthode | Route | Auth | Rôle | Description |
|---------|-------|------|------|-------------|
| `GET` | `/api/v1/portfolio` | ✅ | `ARTISAN` | Mes réalisations |
| `POST` | `/api/v1/portfolio` | ✅ | `ARTISAN` | Ajouter une réalisation |
| `PUT` | `/api/v1/portfolio/:id` | ✅ | `ARTISAN` | Modifier une réalisation |
| `DELETE` | `/api/v1/portfolio/:id` | ✅ | `ARTISAN` | Supprimer une réalisation |
| `GET` | `/api/v1/artisan/:id/portfolio` | ❌ | — | Portfolio public d un artisan |

---

### 3.6 Reviews

| Méthode | Route | Auth | Rôle | Description |
|---------|-------|------|------|-------------|
| `POST` | `/api/v1/reviews` | ✅ | `CLIENT` | Laisser un avis (1-5 étoiles, unique par paire client/artisan) |
| `GET` | `/api/v1/artisan/:id/reviews` | ❌ | — | Avis d un artisan (public) |

---

### 3.7 Media

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| `POST` | `/api/v1/media/upload` | ✅ | Upload fichier → compression Sharp → stockage MinIO |

---

### 3.8 Verification

| Méthode | Route | Auth | Rôle | Description |
|---------|-------|------|------|-------------|
| `POST` | `/api/v1/verification/submit` | ✅ | `ARTISAN` | Soumettre un document (CNI, Passeport, Diplôme, etc.) |
| `GET` | `/api/v1/verification/status` | ✅ | — | Mon statut de vérification |

---

### 3.9 Search

| Méthode | Route | Auth | Description |
|---------|-------|------|-------------|
| `GET` | `/api/v1/search/artisans` | ❌ | Recherche géospatiale (lat, lng, radius_km, category, query) |

---

### 3.10 Subscription

| Méthode | Route | Auth | Rôle | Description |
|---------|-------|------|------|-------------|
| `POST` | `/api/v1/subscription/initiate` | ✅ | `ARTISAN` | Initier un paiement Wave (5 000 FCFA/mois) |
| `POST` | `/api/v1/subscription/wave/webhook` | ❌ | — | Webhook Wave (signature HMAC vérifiée) |
| `GET` | `/api/v1/subscription/status` | ✅ | `ARTISAN` | Mon statut d abonnement |
| `GET` | `/api/v1/subscription/providers` | ❌ | — | Providers de paiement disponibles |

---

### 3.11 Admin

| Méthode | Route | Auth | Rôle | Description |
|---------|-------|------|------|-------------|
| `GET` | `/api/v1/admin/dashboard` | ✅ | `ADMIN` | Statistiques tableau de bord |
| `GET` | `/api/v1/admin/verifications/pending` | ✅ | `ADMIN` | Documents en attente de vérification |
| `PUT` | `/api/v1/admin/verifications/:id` | ✅ | `ADMIN` | Approuver / Rejeter un document |
| `GET` | `/api/v1/admin/artisans` | ✅ | `ADMIN` | Liste de tous les artisans |
| `GET` | `/api/v1/admin/analytics` | ✅ | `ADMIN` | Analytiques de la plateforme |

---

### 3.12 Chat (WebSocket — Socket.IO)

> Ce module ne dispose pas de routes REST. Il s appuie exclusivement sur une **gateway WebSocket Socket.IO**.

- Messagerie temps réel entre artisans et clients
- Conversations et messages persistés en **MongoDB**
- Types de messages supportés : `TEXT`, `IMAGE`, `SYSTEM`
- Point d entrée : `chat.gateway.ts`

---

### 3.13 Notifications (interne)

> Pas de routes REST exposées. Le service est appelé en interne par les autres modules.

- Envoi push via **Firebase Cloud Messaging (FCM)**
- Stockage des notifications en MongoDB avec TTL 30 jours (auto-suppression)

| Type | Déclencheur |
|------|-------------|
| `NEW_MESSAGE` | Nouveau message reçu dans le chat |
| `SUBSCRIPTION_EXPIRY` | Abonnement artisan sur le point d expirer |
| `NEARBY_SEARCH` | Un client recherche dans la zone de l artisan |
| `REVIEW_RECEIVED` | Un client a laissé un avis |
| `DOCUMENT_APPROVED` | Document d identité approuvé par un admin |
| `DOCUMENT_REJECTED` | Document d identité rejeté par un admin |
| `PAYMENT_SUCCESS` | Paiement Wave confirmé avec succès |

---

### 3.14 Analytics (interne)

> Pas de routes REST exposées. Les logs sont enregistrés automatiquement en interne.

- Actions tracées et stockées en MongoDB avec TTL 90 jours :

| Action | Description |
|--------|-------------|
| `PROFILE_VIEW` | Consultation du profil d un artisan |
| `SEARCH` | Lancement d une recherche géospatiale |
| `CONTACT_CLICK` | Clic sur le contact d un artisan |
| `LOGIN` | Connexion d un utilisateur |
| `PAYMENT_ATTEMPT` | Tentative de paiement |
| `REGISTRATION` | Inscription d un nouvel utilisateur |

---

## 4. Entités PostgreSQL (TypeORM)

### 4.1 `users`

| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | `UUID` | PK, auto-généré |
| `phone_number` | `VARCHAR` | UNIQUE |
| `email` | `VARCHAR` | Nullable |
| `password_hash` | `VARCHAR` | bcrypt 12 rounds |
| `role` | `ENUM(ARTISAN, CLIENT, ADMIN)` | |
| `verification_status` | `ENUM(PENDING, VERIFIED, CERTIFIED)` | Défaut : `PENDING` |
| `is_active` | `BOOLEAN` | Défaut : `true` |
| `is_phone_verified` | `BOOLEAN` | Défaut : `false` |
| `whatsapp_number` | `VARCHAR` | Nullable |
| `country_code` | `VARCHAR` | Défaut : `CI` |
| `location` | `GEOGRAPHY(Point, 4326)` | PostGIS, Nullable |
| `created_at` | `TIMESTAMP` | Auto |
| `updated_at` | `TIMESTAMP` | Auto |

**Relations** : `OneToOne` vers `ArtisanProfile`, `ClientProfile` ; `OneToMany` vers `VerificationDocument`

---

### 4.2 `artisan_profiles`

| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | `UUID` | PK |
| `user_id` | `UUID` | FK(users), OneToOne |
| `first_name` | `VARCHAR` | |
| `last_name` | `VARCHAR` | |
| `business_name` | `VARCHAR` | Nullable |
| `bio` | `TEXT` | Nullable |
| `category_id` | `UUID` | FK(categories), Nullable, Eager |
| `city` | `VARCHAR` | Nullable |
| `commune` | `VARCHAR` | Nullable |
| `address` | `VARCHAR` | Nullable |
| `rating_avg` | `FLOAT` | Défaut : `0` |
| `total_reviews` | `INT` | Défaut : `0` |
| `years_experience` | `INT` | Défaut : `0` |
| `is_available` | `BOOLEAN` | Défaut : `true` |
| `is_subscription_active` | `BOOLEAN` | Défaut : `false`, Indexé |
| `whatsapp_number` | `VARCHAR` | Nullable |
| `working_hours` | `JSONB` | Nullable |
| `last_active_at` | `TIMESTAMP` | Nullable |
| `created_at` / `updated_at` | `TIMESTAMP` | Auto |

**Relations** : `OneToOne` vers `Subscription` ; `OneToMany` vers `Review`

---

### 4.3 `client_profiles`

| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | `UUID` | PK |
| `user_id` | `UUID` | FK(users), OneToOne |
| `first_name` | `VARCHAR` | |
| `last_name` | `VARCHAR` | |
| `city` | `VARCHAR` | Nullable |
| `commune` | `VARCHAR` | Nullable |
| `created_at` / `updated_at` | `TIMESTAMP` | Auto |

---

### 4.4 `categories`

| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | `UUID` | PK |
| `name` | `VARCHAR` | |
| `icon_url` | `VARCHAR` | Emoji |
| `slug` | `VARCHAR` | UNIQUE |
| `is_active` | `BOOLEAN` | Défaut : `true` |
| `display_order` | `INT` | Défaut : `0` |

**Relations** : `OneToMany` vers `Subcategory`

---

### 4.5 `subcategories`

| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | `UUID` | PK |
| `category_id` | `UUID` | FK(categories) |
| `name` | `VARCHAR` | |
| `slug` | `VARCHAR` | UNIQUE |

---

### 4.6 `reviews`

| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | `UUID` | PK |
| `client_id` | `UUID` | FK(client_profiles), Indexé |
| `artisan_id` | `UUID` | FK(artisan_profiles), Indexé |
| `rating` | `INT` | 1 à 5 |
| `comment` | `TEXT` | Nullable |
| `created_at` | `TIMESTAMP` | Auto |

> **Contrainte** : `UNIQUE(client_id, artisan_id)` — un seul avis par client par artisan

---

### 4.7 `verification_documents`

| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | `UUID` | PK |
| `user_id` | `UUID` | FK(users) |
| `document_type` | `ENUM(CNI, PASSPORT, DIPLOME, CERTIFICAT, ATTESTATION)` | |
| `file_url` | `VARCHAR` | URL MinIO |
| `status` | `ENUM(PENDING, APPROVED, REJECTED)` | Défaut : `PENDING` |
| `rejection_reason` | `VARCHAR` | Nullable |
| `reviewed_by` | `VARCHAR` | UUID admin, Nullable |
| `submitted_at` | `TIMESTAMP` | Auto |
| `reviewed_at` | `TIMESTAMP` | Nullable |

---

### 4.8 `subscriptions`

| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | `UUID` | PK |
| `artisan_profile_id` | `UUID` | FK(artisan_profiles), OneToOne |
| `plan` | `ENUM(MONTHLY)` | Défaut : `MONTHLY` |
| `amount_fcfa` | `INT` | Défaut : `5000` |
| `status` | `ENUM(ACTIVE, EXPIRED, CANCELLED, PENDING)` | Défaut : `PENDING` |
| `starts_at` / `expires_at` | `TIMESTAMP` | Nullable |
| `auto_renew` | `BOOLEAN` | Défaut : `false` |
| `created_at` | `TIMESTAMP` | Auto |

---

### 4.9 `payments`

| Colonne | Type | Contraintes |
|---------|------|-------------|
| `id` | `UUID` | PK |
| `subscription_id` | `UUID` | FK(subscriptions) |
| `amount_fcfa` | `INT` | |
| `provider` | `ENUM(WAVE)` | Défaut : `WAVE` |
| `status` | `ENUM(PENDING, SUCCESS, FAILED)` | Défaut : `PENDING` |
| `wave_transaction_id` | `VARCHAR` | UNIQUE, Nullable |
| `wave_checkout_id` | `VARCHAR` | Nullable |
| `paid_at` | `TIMESTAMP` | Nullable |
| `created_at` | `TIMESTAMP` | Auto |

---

## 5. Schémas MongoDB (Mongoose)

### 5.1 `portfolio_items`

| Champ | Type | Contraintes |
|-------|------|-------------|
| `artisanProfileId` | `String` | Requis, indexé |
| `title` | `String` | Requis |
| `description` | `String` | Optionnel |
| `priceFcfa` | `Number` | Optionnel |
| `imageUrls` | `[String]` | Tableau d URLs |
| `tags` | `[String]` | Indexé |
| `metadata` | `Object` | Données supplémentaires |
| `createdAt` / `updatedAt` | `Date` | Timestamps automatiques |

---

### 5.2 `media_files`

| Champ | Type | Contraintes |
|-------|------|-------------|
| `userId` | `String` | Requis |
| `bucket` | `String` | Requis : `portfolio` / `documents` / `media` |
| `objectKey` | `String` | Requis |
| `originalName` | `String` | Requis |
| `mimeType` | `String` | Requis |
| `size` | `Number` | Requis (octets) |
| `thumbnailKey` | `String` | Optionnel |
| `createdAt` / `updatedAt` | `Date` | Timestamps automatiques |

---

### 5.3 `conversations`

| Champ | Type | Contraintes |
|-------|------|-------------|
| `participants` | `[String]` | Indexé |
| `lastMessage.content` | `String` | |
| `lastMessage.sentAt` | `Date` | |
| `lastMessage.senderId` | `String` | |
| `createdAt` / `updatedAt` | `Date` | Timestamps automatiques |

---

### 5.4 `messages`

| Champ | Type | Contraintes |
|-------|------|-------------|
| `conversationId` | `String` | Indexé, requis |
| `senderId` | `String` | Requis |
| `content` | `String` | Requis |
| `type` | `ENUM(TEXT, IMAGE, SYSTEM)` | Défaut : `TEXT` |
| `mediaUrl` | `String` | Optionnel |
| `isRead` | `Boolean` | Défaut : `false` |
| `sentAt` | `Date` | |

---

### 5.5 `notifications`

| Champ | Type | Contraintes |
|-------|------|-------------|
| `userId` | `String` | Indexé, requis |
| `type` | `ENUM(NEW_MESSAGE, SUBSCRIPTION_EXPIRY, NEARBY_SEARCH, REVIEW_RECEIVED, DOCUMENT_APPROVED, DOCUMENT_REJECTED, PAYMENT_SUCCESS)` | |
| `title` | `String` | |
| `body` | `String` | |
| `data` | `Object` | Données supplémentaires |
| `isRead` | `Boolean` | Défaut : `false` |
| `createdAt` | `Date` | |
| `expireAt` | `Date` | **TTL 30 jours** (auto-suppression MongoDB) |

---

### 5.6 `activity_logs`

| Champ | Type | Contraintes |
|-------|------|-------------|
| `actorId` | `String` | Indexé |
| `action` | `ENUM(PROFILE_VIEW, SEARCH, CONTACT_CLICK, LOGIN, PAYMENT_ATTEMPT, REGISTRATION)` | Indexé |
| `targetId` | `String` | Optionnel |
| `metadata` | `Object` | Données supplémentaires |
| `ipAddress` | `String` | |
| `userAgent` | `String` | |
| `timestamp` | `Date` | **TTL 90 jours** (auto-suppression MongoDB) |

---

## 6. DTOs

### 6.1 DTOs Auth

**`RegisterArtisanDto`**

| Champ | Type | Requis | Validation |
|-------|------|--------|------------|
| `phone_number` | `string` | ✅ | Format téléphone |
| `password` | `string` | ✅ | Minimum 6 caractères |
| `first_name` | `string` | ✅ | |
| `last_name` | `string` | ✅ | |
| `business_name` | `string` | ❌ | |
| `city` | `string` | ❌ | |
| `commune` | `string` | ❌ | |
| `whatsapp_number` | `string` | ❌ | |

**`RegisterClientDto`**

| Champ | Type | Requis | Validation |
|-------|------|--------|------------|
| `phone_number` | `string` | ✅ | Format téléphone |
| `password` | `string` | ✅ | Minimum 6 caractères |
| `first_name` | `string` | ✅ | |
| `last_name` | `string` | ✅ | |
| `city` | `string` | ❌ | |
| `commune` | `string` | ❌ | |

**`SendOtpDto`** : `phone_number` (string, requis)

**`VerifyOtpDto`** : `phone_number` (string), `code` (string)

**`LoginDto`** : `phone_number` (string), `password` (string)

**`RefreshTokenDto`** : `refresh_token` (string)

---

### 6.2 DTOs Utilisateurs

**`UpdateArtisanProfileDto`**

| Champ | Type | Requis | Validation |
|-------|------|--------|------------|
| `first_name` | `string` | ❌ | |
| `last_name` | `string` | ❌ | |
| `business_name` | `string` | ❌ | |
| `bio` | `string` | ❌ | |
| `category_id` | `string` | ❌ | UUID valide |
| `city` | `string` | ❌ | |
| `commune` | `string` | ❌ | |
| `address` | `string` | ❌ | |
| `years_experience` | `number` | ❌ | Entre 0 et 60 |
| `is_available` | `boolean` | ❌ | |
| `whatsapp_number` | `string` | ❌ | |
| `working_hours` | `Record<string, any>` | ❌ | JSONB |

**`UpdateClientProfileDto`** : `first_name`?, `last_name`?, `city`?, `commune`?

---

### 6.3 DTOs Reviews

**`CreateReviewDto`**

| Champ | Type | Requis | Validation |
|-------|------|--------|------------|
| `artisan_id` | `string` | ✅ | UUID valide |
| `rating` | `number` | ✅ | Entre 1 et 5 |
| `comment` | `string` | ❌ | |

---

### 6.4 DTOs Verification

**`SubmitDocumentDto`** : `document_type` (enum : `CNI | PASSPORT | DIPLOME | CERTIFICAT | ATTESTATION`), `file_url` (string)

**`ReviewDocumentDto`** : `status` (enum : `APPROVED | REJECTED`), `rejection_reason`? (string)

---

### 6.5 DTOs Search

**`SearchArtisansDto`**

| Champ | Type | Requis | Validation | Défaut |
|-------|------|--------|------------|--------|
| `lat` | `number` | ✅ | Latitude valide | — |
| `lng` | `number` | ✅ | Longitude valide | — |
| `radius_km` | `number` | ❌ | Entre 1 et 100 | `10` |
| `category` | `string` | ❌ | | — |
| `query` | `string` | ❌ | Recherche textuelle | — |
| `page` | `number` | ❌ | Min 1 | `1` |
| `limit` | `number` | ❌ | Entre 1 et 50 | `20` |

---

## 7. Module Common

### 7.1 Décorateurs

**`@CurrentUser(data?: string)`**
Extrait l utilisateur depuis le payload JWT.

```typescript
// Récupérer tout le payload
@CurrentUser() user: JwtPayload

// Récupérer un champ spécifique
@CurrentUser('id') userId: string
```

**`@Roles(...roles: string[])`**
Marque les rôles requis pour accéder à une route.

```typescript
@Roles('ARTISAN', 'ADMIN')
@Get('exemple')
maRoute() { ... }
```

---

### 7.2 Guards

| Guard | Description |
|-------|-------------|
| `RolesGuard` | Compare `user.role` avec les rôles définis par `@Roles()`. Retourne `true` si correspondance ou si aucun rôle n est requis. |
| `AuthGuard('jwt')` | Valide le Bearer token via `JwtStrategy` |
| `AuthGuard('jwt-refresh')` | Valide le refresh token via `JwtRefreshStrategy` |

---

### 7.3 Filtres

**`GlobalExceptionFilter`** — Catch-all. Format de réponse erreur standardisé :

```json
{
  "statusCode": 400,
  "error": "BAD_REQUEST",
  "message": ["property X should not exist"],
  "timestamp": "2026-03-28T06:48:30.179Z",
  "path": "/api/v1/auth/register/artisan"
}
```

---

### 7.4 Intercepteurs

**`LoggingInterceptor`** — Enregistre chaque requête dans la console :

```
GET /api/v1/categories 200 — 12ms
```

**`TransformInterceptor`** — Enveloppe toutes les réponses dans un format standardisé :

```json
{
  "statusCode": 200,
  "data": { "..." : "..." },
  "timestamp": "2026-03-28T06:48:30.179Z"
}
```

---

## 8. Configuration

Tous les fichiers de configuration se trouvent dans `src/config/` et sont réexportés depuis `src/config/index.ts`.

### 8.1 `app.config.ts`

- **Namespace** : `app`
- Variables lues : `NODE_ENV`, `APP_PORT` (défaut : `3000`), `APP_URL`, `CORS_ORIGINS` (séparées par des virgules)

---

### 8.2 `database-postgres.config.ts`

- **Namespace** : `database.postgres`
- Variables lues : `POSTGRES_HOST`, `POSTGRES_PORT` (défaut : `5432`), `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB`, `DATABASE_POSTGRES_URL`
- `synchronize = true` en mode développement
- `logging = true` en mode développement

---

### 8.3 `database-mongo.config.ts`

- **Namespace** : `database.mongo`
- Utilise `DATABASE_MONGO_URL` en priorité, sinon construit l URL depuis : `MONGO_USER`, `MONGO_PASSWORD`, `MONGO_HOST`, `MONGO_PORT`, `MONGO_DB` avec le paramètre `?authSource=admin`

---

### 8.4 `redis.config.ts`

- **Namespace** : `redis`
- Variables lues : `REDIS_HOST`, `REDIS_PORT` (défaut : `6379`), `REDIS_PASSWORD`, `REDIS_URL`

---

### 8.5 `jwt.config.ts`

- **Namespace** : `jwt`
- Variables lues : `JWT_SECRET`, `JWT_REFRESH_SECRET`, `JWT_ACCESS_EXPIRATION` (défaut : `15m`), `JWT_REFRESH_EXPIRATION` (défaut : `30d`)

---

### 8.6 `minio.config.ts`

- **Namespace** : `minio`
- Variables lues : `MINIO_ENDPOINT`, `MINIO_PORT` (défaut : `9000`), `MINIO_USE_SSL`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET_PORTFOLIO`, `MINIO_BUCKET_DOCUMENTS`, `MINIO_BUCKET_MEDIA`

---

### 8.7 `whatsapp.config.ts`

- **Namespace** : `whatsapp`
- Variables lues : `WHATSAPP_API_URL`, `WHATSAPP_API_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_OTP_TEMPLATE_NAME`

---

### 8.8 `wave.config.ts`

- **Namespace** : `wave`
- Variables lues : `WAVE_API_URL`, `WAVE_API_KEY`, `WAVE_WEBHOOK_SECRET`, `WAVE_MERCHANT_ID`

---

### 8.9 `providers.config.ts`

- **Namespace** : `providers`
- Flags OTP :
  - `WHATSAPP` : activé, priorité 1
  - `SMS_TWILIO` : basé sur `SMS_PROVIDER_ENABLED` (variable d environnement), priorité 2
- Flags paiement :
  - `WAVE` : activé
  - `ORANGE_MONEY` : désactivé
  - `MTN_MOMO` : désactivé

---

## 9. Variables d'environnement

> Copier `.env.example` en `.env` et renseigner les valeurs avant de lancer le projet.

```bash
# PostgreSQL
POSTGRES_USER=fiers_artisans
POSTGRES_PASSWORD=fiers_dev_2025
POSTGRES_DB=fiers_artisans
POSTGRES_HOST=localhost
POSTGRES_PORT=5434

# MongoDB
MONGO_USER=fiers_artisans
MONGO_PASSWORD=fiers_mongo_dev
MONGO_DB=fiers_artisans
MONGO_HOST=localhost
MONGO_PORT=27018

# Redis
REDIS_PASSWORD=fiers_redis_dev
REDIS_HOST=localhost
REDIS_PORT=6380

# MinIO
MINIO_ACCESS_KEY=fiers_minio_dev
MINIO_SECRET_KEY=fiers_minio_secret_dev
MINIO_ENDPOINT=localhost
MINIO_PORT=9002
MINIO_USE_SSL=false
MINIO_BUCKET_PORTFOLIO=portfolio
MINIO_BUCKET_DOCUMENTS=documents
MINIO_BUCKET_MEDIA=media

# JWT
JWT_SECRET=fiers_jwt_dev_secret_32_chars_minimum_ok
JWT_REFRESH_SECRET=fiers_jwt_refresh_dev_secret_32_minimum
JWT_ACCESS_EXPIRATION=15m
JWT_REFRESH_EXPIRATION=30d

# WhatsApp Business API (vide en dev)
WHATSAPP_API_URL=https://graph.facebook.com/v18.0
WHATSAPP_API_TOKEN=
WHATSAPP_PHONE_NUMBER_ID=
WHATSAPP_OTP_TEMPLATE_NAME=fiers_artisans_otp

# SMS Fallback
SMS_PROVIDER_ENABLED=false

# Wave CI (vide en dev)
WAVE_API_URL=https://api.wave.com/v1
WAVE_API_KEY=
WAVE_WEBHOOK_SECRET=dev_webhook_secret
WAVE_MERCHANT_ID=

# Firebase Cloud Messaging
FCM_PROJECT_ID=
FCM_PRIVATE_KEY=
FCM_CLIENT_EMAIL=

# Application
NODE_ENV=development
APP_PORT=3000
APP_URL=http://localhost:3000
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:8080

# Grafana
GRAFANA_ADMIN_PASSWORD=admin
```

---

## 10. Services Docker

> **ISOLATION DES PORTS — NOTE IMPORTANTE**
>
> Les ports exposés sur l hôte ont été **délibérément choisis pour éviter tout conflit** avec les services natifs potentiellement déjà installés sur la machine de développement :
> - PostgreSQL natif typiquement sur `5432` → conteneur sur **`5434`**
> - MongoDB natif typiquement sur `27017` → conteneur sur **`27018`**
> - Redis natif typiquement sur `6379` → conteneur sur **`6380`**
> - MinIO exposé sur **`9002`** (+ console `9003`) en mode développement uniquement

Fichiers de configuration : `infrastructure/docker-compose.yml` + override `infrastructure/docker-compose.dev.yml`

| Service | Image | Port hôte et conteneur | Volume(s) | Health Check |
|---------|-------|----------------------|-----------|--------------|
| `api` | `backend/Dockerfile` | `3000:3000` | — | HTTP GET `/api/v1/health` |
| `postgres` | `postgis/postgis:16-3.4` | `5434:5432` | `postgres_data`, `init.sql` | `pg_isready` |
| `mongodb` | `mongo:7` | `27018:27017` | `mongo_data`, `init.js` | — |
| `redis` | `redis:7-alpine` | `6380:6379` | `redis_data` | `redis-cli ping` |
| `minio` | `minio/minio` | Interne (dev : `9002:9000`) | `minio_data` | — |
| `nginx` | `nginx:alpine` | `80:80`, `443:443` | `nginx.conf`, `ssl/` | — |
| `prometheus` | `prom/prometheus` | Interne | `prometheus_data` | — |
| `grafana` | `grafana/grafana` | `3001:3000` | `grafana_data` | — |

**Réseau** : `fiers-network` (bridge)

**Override développement** (`docker-compose.dev.yml`) :
- Expose MinIO sur `9002` (API) et `9003` (console web)
- Active le hot-reload pour le service `api`
- Désactive `nginx` (l API est accédée directement)

---

## 11. Dockerfile multi-stage

```dockerfile
# Stage 1 : development
FROM node:20-alpine AS development
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .

# Stage 2 : build
FROM development AS build
RUN npm run build
# Produit : /app/dist

# Stage 3 : production
FROM node:20-alpine AS production
WORKDIR /app
COPY package*.json ./
RUN npm ci --production
COPY --from=build /app/dist ./dist
USER node
EXPOSE 3000
CMD ["node", "dist/main.js"]
```

---

## 12. Données de seed

Le script `src/database/seeds/run-seed.ts` insère **16 catégories** et **48 sous-catégories** dans PostgreSQL.

```bash
npx ts-node src/database/seeds/run-seed.ts
```

### Catégories disponibles

| N° | Icône | Catégorie | Sous-catégories |
|----|-------|-----------|-----------------|
| 1 | 🧱 | Bâtiment et Construction | Maçon, Carreleur, Plâtrier, Ferblantier |
| 2 | 🪵 | Menuiserie et Ébénisterie | Menuisier bois, Menuisier aluminium, Ébéniste |
| 3 | ⚡ | Électricité | Électricien bâtiment, Électricien industriel, Domoticien |
| 4 | 🔧 | Plomberie | Plombier, Chauffagiste |
| 5 | 🎨 | Peinture et Décoration | Peintre bâtiment, Décorateur intérieur, Staffeur |
| 6 | 🏗️ | Architecture et Ingénierie | Architecte, Ingénieur civil, Géomètre |
| 7 | ✂️ | Textile et Mode | Tailleur, Couturier, Brodeur |
| 8 | ⚒️ | Métallurgie | Forgeron, Soudeur, Ferronnier d art |
| 9 | 🌸 | Fleuriste et Paysagisme | Fleuriste, Jardinier, Paysagiste |
| 10 | 🚗 | Automobile | Mécanicien auto, Électricien auto, Tôlier |
| 11 | 📸 | Services créatifs | Photographe, Vidéaste, Graphiste |
| 12 | 🧹 | Services domestiques | Agent d entretien, Femme/Homme de ménage |
| 13 | 💇 | Beauté et Bien-être | Coiffeur, Barbier, Esthéticienne |
| 14 | 🍳 | Restauration | Cuisinier, Traiteur, Pâtissier |
| 15 | 🖥️ | Tech et Numérique | Réparateur téléphone, Informaticien, Installateur réseau |
| 16 | 🪑 | Ameublement | Tapissier, Matelassier, Vitrier |

---

## 13. Dépendances de production

| Package | Version | Rôle |
|---------|---------|------|
| `@nestjs/common` | `^11.0.1` | Core NestJS |
| `@nestjs/core` | `^11.0.1` | Runtime NestJS |
| `@nestjs/config` | `^4.0.3` | Configuration centralisée |
| `@nestjs/jwt` | `^11.0.2` | Génération et validation JWT |
| `@nestjs/passport` | `^11.0.5` | Stratégies auth Passport |
| `@nestjs/platform-express` | `^11.0.1` | Adaptateur HTTP Express |
| `@nestjs/platform-socket.io` | `^11.1.17` | Adaptateur WebSocket Socket.IO |
| `@nestjs/websockets` | `^11.1.17` | Gateway WebSocket |
| `@nestjs/mongoose` | `^11.0.4` | Intégration MongoDB |
| `@nestjs/typeorm` | `^11.0.0` | Intégration PostgreSQL |
| `@nestjs/swagger` | `^11.2.6` | Documentation Swagger UI |
| `@nestjs/throttler` | `^6.5.0` | Rate limiting (30 req / 60 s) |
| `typeorm` | `^0.3.28` | ORM PostgreSQL |
| `mongoose` | `^9.3.3` | ODM MongoDB |
| `@nestjs-modules/ioredis` | `^2.2.1` | Module Redis pour NestJS |
| `ioredis` | `^5.10.1` | Client Redis |
| `passport` | `^0.7.0` | Middleware d authentification |
| `passport-jwt` | `^4.0.1` | Stratégie JWT Passport |
| `class-validator` | `^0.14.4` | Validation des DTOs |
| `class-transformer` | `^0.5.1` | Transformation des DTOs |
| `helmet` | `^8.1.0` | Headers de sécurité HTTP |
| `minio` | `^8.0.7` | Client stockage S3 (MinIO) |
| `bcrypt` | `^6.0.0` | Hachage mots de passe (12 rounds) |
| `axios` | `^1.14.0` | Client HTTP (Wave, WhatsApp) |
| `sharp` | `^0.34.5` | Traitement et compression d images |
| `uuid` | `^13.0.0` | Génération d identifiants UUID |
| `pg` | `^8.20.0` | Driver PostgreSQL natif |
| `rxjs` | `^7.8.1` | Bibliothèque réactive (RxJS) |

---

## 14. Détails architecturaux importants

### 14.1 Cascade OTP (`auth/otp/otp.service.ts`)

Le service OTP suit une logique de cascade avec protection anti-brute-force :

1. **Génération** : code à 6 chiffres, stocké dans Redis avec un TTL de 5 minutes
2. **Anti-brute-force** : maximum 5 envois par numéro de téléphone par heure
3. **Cascade de providers** :
   - **Priorité 1** : envoi WhatsApp Business API
   - **Priorité 2** : SMS via Twilio (si `SMS_PROVIDER_ENABLED=true`)
   - **Fallback** : message d erreur "service temporairement indisponible"
4. **Mode DEV** : le code OTP est affiché directement dans la console du serveur :

```
[DEV] Code OTP : 123456
```

---

### 14.2 Flux de paiement Wave (`subscription/`)

```
Artisan → POST /subscription/initiate
         ↓
    Backend crée une checkout session Wave (wave.provider.ts)
         ↓
    Retourne l URL de paiement Wave à l artisan
         ↓
    Artisan paie via Wave CI
         ↓
    Webhook reçu → POST /subscription/wave/webhook
         ↓
    Vérification signature HMAC (WAVE_WEBHOOK_SECRET)
         ↓
    Vérification idempotence (wave_transaction_id unique)
         ↓
    Succès → abonnement activé 30 jours
           → is_subscription_active = true (artisan_profiles)
```

---

### 14.3 Recherche géospatiale PostGIS (`search/search.service.ts`)

- Utilise la fonction **`ST_DWithin`** de PostGIS pour filtrer les artisans dans un rayon donné en kilomètres
- Calcule la distance précise avec **`ST_Distance`** et trie les résultats par proximité croissante
- Filtres optionnels : catégorie (par `slug`) et recherche textuelle sur le nom et le nom commercial (`business_name`)
- Colonne géographique : `users.location` de type `GEOGRAPHY(Point, 4326)`

---

### 14.4 Pipeline de traitement médias (`media/media.service.ts`)

```
1. Upload multipart → validation (type MIME, taille)
2. Compression avec Sharp
   ├── Image principale → WebP optimisé
   └── Miniature → 300px (thumbnail)
3. Stockage dans MinIO
   ├── Bucket sélectionné selon le contexte (portfolio / documents / media)
   └── Clé d objet unique (UUID)
4. Retourne une signed URL (expiration : 7 jours)
```

---

### 14.5 Format des réponses

**Succès** — wrappé par `TransformInterceptor` :

```json
{
  "statusCode": 200,
  "data": {
    "id": "uuid",
    "phone_number": "+2250700000001"
  },
  "timestamp": "2026-03-28T06:48:30.179Z"
}
```

**Erreur** — formatée par `GlobalExceptionFilter` :

```json
{
  "statusCode": 400,
  "error": "BAD_REQUEST",
  "message": ["property X should not exist"],
  "timestamp": "2026-03-28T06:48:30.179Z",
  "path": "/api/v1/auth/register/artisan"
}
```

---

## 15. Sécurité

| Mesure | Détail |
|--------|--------|
| **Helmet** | Headers HTTP de sécurité activés globalement |
| **CORS** | Origins restreintes via `CORS_ORIGINS` (variable d environnement) |
| **Rate Limiting** | 30 requêtes maximum par 60 secondes (`ThrottlerModule`) |
| **Bcrypt** | 12 rounds pour le hachage des mots de passe |
| **JWT Access Token** | Durée de vie : 15 minutes |
| **JWT Refresh Token** | Durée de vie : 30 jours, secret distinct du access token |
| **HMAC Wave** | Vérification de la signature du webhook avant traitement |
| **MinIO interne** | Aucun port exposé en production — accès exclusivement via signed URLs générées côté backend |
| **Validation DTO** | `whitelist: true` + `forbidNonWhitelisted: true` — toute propriété inconnue est rejetée avec une erreur 400 |
| **OTP anti-brute-force** | Maximum 5 envois par heure par numéro de téléphone |

---

## 16. Démarrage rapide

### Prérequis

- [Node.js 20+](https://nodejs.org)
- [Docker](https://www.docker.com) et Docker Compose
- Git

---

### Installation

```bash
# 1. Cloner le dépôt
git clone <url> fiers-artisans
cd fiers-artisans

# 2. Copier et configurer les variables d environnement
cp .env.example .env
# Éditer .env avec vos valeurs (tokens WhatsApp, Wave, Firebase, etc.)

# 3. Démarrer l infrastructure Docker (bases de données, Redis, MinIO...)
cd infrastructure
docker compose -f docker-compose.yml -f docker-compose.dev.yml --env-file ../.env up -d

# 4. Installer les dépendances du backend
cd ../backend
npm install

# 5. Seeder les catégories en base de données
npx ts-node src/database/seeds/run-seed.ts

# 6. Lancer le backend en mode développement (hot reload)
npm run start:dev
```

---

### Vérification du bon fonctionnement

```bash
# Santé de l API
curl http://localhost:3000/api/v1/health

# Documentation Swagger interactive
open http://localhost:3000/api/docs

# Toutes les catégories
curl http://localhost:3000/api/v1/categories
```

---

### Scripts npm disponibles

| Script | Commande NestJS | Description |
|--------|-----------------|-------------|
| `npm run start` | `nest start` | Démarrage en mode production |
| `npm run start:dev` | `nest start --watch` | Démarrage en mode développement (hot reload) |
| `npm run start:debug` | `nest start --debug --watch` | Démarrage en mode debug |
| `npm run build` | `nest build` | Compilation TypeScript vers `dist/` |
| `npm run test` | `jest` | Tests unitaires |
| `npm run test:e2e` | `jest --config ./test/jest-e2e.json` | Tests end-to-end |
| `npm run lint` | `eslint` | Analyse statique du code |

---

## 17. Exemples d'appels API

### Inscription artisan

```bash
curl -X POST http://localhost:3000/api/v1/auth/register/artisan \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+2250700000001",
    "password": "MonPass123!",
    "first_name": "Kouadio",
    "last_name": "Jean",
    "business_name": "Menuiserie Kouadio",
    "city": "Abidjan",
    "commune": "Cocody"
  }'
```

---

### Connexion

```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+2250700000001",
    "password": "MonPass123!"
  }'
```

Réponse :

```json
{
  "statusCode": 200,
  "data": {
    "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": "uuid",
      "phone_number": "+2250700000001",
      "role": "ARTISAN"
    }
  },
  "timestamp": "2026-03-28T06:48:30.179Z"
}
```

---

### Envoi OTP

```bash
curl -X POST http://localhost:3000/api/v1/auth/send-otp \
  -H "Content-Type: application/json" \
  -d '{ "phone_number": "+2250700000001" }'
```

Réponse en mode DEV :

```json
{
  "statusCode": 200,
  "data": {
    "sent": true,
    "message": "[DEV] Code OTP : 123456"
  },
  "timestamp": "2026-03-28T06:48:30.179Z"
}
```

---

### Recherche géospatiale d artisans

```bash
curl "http://localhost:3000/api/v1/search/artisans?lat=5.3600&lng=-4.0083&radius_km=15&category=electricite"
```

---

### Route protégée (avec token JWT)

```bash
curl http://localhost:3000/api/v1/artisan/profile \
  -H "Authorization: Bearer <access_token>"
```

---

### Renouvellement du token d accès

```bash
curl -X POST http://localhost:3000/api/v1/auth/refresh \
  -H "Authorization: Bearer <refresh_token>"
```

---

### Initier un abonnement Wave

```bash
curl -X POST http://localhost:3000/api/v1/subscription/initiate \
  -H "Authorization: Bearer <access_token>" \
  -H "Content-Type: application/json"
```

Réponse :

```json
{
  "statusCode": 201,
  "data": {
    "checkout_url": "https://pay.wave.com/checkout/...",
    "payment_id": "uuid"
  },
  "timestamp": "2026-03-28T06:48:30.179Z"
}
```

---

### Upload d un fichier média

```bash
curl -X POST http://localhost:3000/api/v1/media/upload \
  -H "Authorization: Bearer <access_token>" \
  -F "file=@/chemin/vers/image.jpg"
```

---

*Document de référence — Mettre à jour à chaque évolution de l API.*
