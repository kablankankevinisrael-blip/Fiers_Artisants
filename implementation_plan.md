# 🔨 Fiers Artisans — Architecture Complète v2.0

> **Application marketplace mobile** mettant en relation les artisans et ouvriers ivoiriens
> avec des clients, géolocalisée, avec système de vérification et abonnement.

---

## 1. Vue d'ensemble du projet

### 1.1 Concept

**Fiers Artisans** est une plateforme mobile qui permet aux clients de trouver des artisans
vérifiés et certifiés à proximité — maçons, menuisiers, électriciens, plombiers, peintres,
tailleurs, forgerons, architectes, fleuristes, etc. — de consulter leur profil et portfolio,
et de les contacter directement.

### 1.2 Acteurs principaux

| Acteur | Description |
|--------|-------------|
| **Artisan** | Professionnel qui s'inscrit, se fait vérifier/certifier, paie l'abonnement et propose ses services |
| **Client** | Particulier ou entreprise qui recherche un artisan par catégorie et proximité |
| **Admin** | Gestionnaire de la plateforme : validation des documents, modération, analytics |

### 1.3 Modèle économique

- Abonnement artisan : **5 000 FCFA / mois** (payable via Wave)
- Après inscription + vérification → paiement obligatoire pour être visible sur le marché
- Sans abonnement actif : le compte existe mais n'apparaît pas dans les recherches clients

### 1.4 Périmètre géographique

- **Phase 1** : Côte d'Ivoire uniquement (Abidjan et autres villes)
- **Phase 2+** : Expansion vers d'autres pays d'Afrique de l'Ouest, puis du continent

---

## 2. Stack Technique

### 2.1 Vue Architecture Globale

```mermaid
graph TB
    subgraph "📱 Frontend Mobile"
        FLUTTER["Flutter (Dart)<br/>iOS + Android"]
    end

    subgraph "🌐 API Gateway"
        NGINX["Nginx<br/>Reverse Proxy + SSL"]
    end

    subgraph "🐳 Backend Docker (VPS)"
        API["NestJS (Node.js)<br/>API REST + WebSocket"]
        AUTH["Auth Service<br/>JWT + OTP WhatsApp"]
        SEARCH["Search Service<br/>Recherche géolocalisée"]
        PAY["Payment Service<br/>Wave (actif)"]
        NOTIF["Notification Service<br/>Push Notifications"]
        CHAT["Chat Service<br/>Messagerie temps réel"]
        MEDIA["Media Service<br/>Upload images/docs"]
    end

    subgraph "💾 Bases de données Hybrides"
        PG["PostgreSQL 16 + PostGIS<br/>Données relationnelles critiques"]
        MONGO["MongoDB 7<br/>Données flexibles et volumineuses"]
        REDIS["Redis 7<br/>Cache + Sessions + Pub/Sub"]
        MINIO["MinIO (S3-compatible)<br/>Stockage fichiers et images"]
    end

    subgraph "🔌 Services Externes"
        WA_OTP["WhatsApp Business Cloud API (Meta)<br/>Vérification OTP"]
        WA_CHAT["WhatsApp Business API<br/>Contact artisan"]
        WAVE["Wave CI API<br/>Paiement abonnements"]
        FCM["Firebase Cloud Messaging<br/>Push Notifications"]
        MAPS["OpenStreetMap / Mapbox<br/>Géolocalisation"]
    end

    FLUTTER --> NGINX
    NGINX --> API
    API --> AUTH
    API --> SEARCH
    API --> PAY
    API --> NOTIF
    API --> CHAT
    API --> MEDIA
    AUTH --> PG
    AUTH --> REDIS
    AUTH --> WA_OTP
    SEARCH --> PG
    SEARCH --> REDIS
    PAY --> PG
    PAY --> WAVE
    NOTIF --> FCM
    CHAT --> REDIS
    CHAT --> MONGO
    CHAT --> WA_CHAT
    MEDIA --> MINIO
    MEDIA --> MONGO
    API --> MONGO
```

### 2.2 Tableau du Stack

| Couche | Technologie | Justification |
|--------|-------------|---------------|
| **Mobile** | Flutter (Dart) | Cross-platform iOS/Android, performances natives, UI riche |
| **Backend API** | NestJS (TypeScript) | Modulaire, structuré, excellent support WebSocket, TypeORM + Mongoose |
| **BDD Relationnelle** | PostgreSQL 16 + PostGIS | Données critiques avec relations strictes, requêtes géospatiales natives |
| **BDD NoSQL** | MongoDB 7 | Données flexibles et volumineuses — chat, portfolio, notifications, analytics |
| **Cache & Pub/Sub** | Redis 7 | Sessions, stockage OTP temporaire, pub/sub pour le chat temps réel |
| **Stockage fichiers** | MinIO (S3-compatible) | Auto-hébergé, stockage photos de portfolio, pièces d'identité, diplômes |
| **Reverse Proxy** | Nginx | SSL/TLS, load balancing, rate limiting |
| **Conteneurisation** | Docker + Docker Compose | Isolation des services, déploiement reproductible |
| **OTP** | WhatsApp Business Cloud API (Meta) | Gratuit jusqu'à 1 000 conv/mois — WhatsApp omniprésent en CI |
| **Push Notifications** | Firebase Cloud Messaging | Gratuit, fiable, cross-platform iOS/Android |
| **Paiement** | Wave CI API ✅ | Leader en Côte d'Ivoire, seul provider actif en Phase 1 |
| **Géolocalisation** | OpenStreetMap + Mapbox | Bonne couverture Afrique, gratuit/freemium |
| **Contact artisan** | WhatsApp Business API | Redirection directe vers WhatsApp de l'artisan |
| **CI/CD** | GitHub Actions | Déploiement automatisé sur VPS |
| **Monitoring** | Prometheus + Grafana | Métriques, alertes, tableaux de bord |
| **Logs** | Loki + Grafana | Centralisation des logs Docker |

### 2.3 Organisation de l'équipe par domaine technique

Chaque domaine de base de données est assigné à une équipe dédiée pour éviter les conflits et garantir la cohérence cross-bases.

| Domaine | Base de données | Responsabilité équipe |
|---------|-----------------|----------------------|
| Auth, Users, Subscriptions, Payments, Reviews, Verification | **PostgreSQL** | Équipe Backend-Core |
| Chat, Portfolio, Notifications, Analytics | **MongoDB** | Équipe Backend-Realtime |
| OTP, Sessions, Pub/Sub WebSocket | **Redis** | Équipe Backend-Core |
| Fichiers (photos, documents) | **MinIO** | Équipe Backend-Media |

**Règle de cohérence cross-bases :** Toute référence à un UUID PostgreSQL dans MongoDB (ex: `artisanProfileId` dans `portfolio_items`) doit être validée par le backend avant insertion — MongoDB ne peut pas vérifier les FK par lui-même. Cette validation est de la responsabilité du service métier côté NestJS.

---

## 3. Base de Données Hybride

### 3.1 Logique de répartition

```
┌──────────────────────────────────────────────────────────────────────┐
│                      RÈGLE DE RÉPARTITION                            │
│                                                                      │
│  PostgreSQL  →  Données RELATIONNELLES, TRANSACTIONS ACID,           │
│                 COHÉRENCE FORTE, REQUÊTES GÉOSPATIALES               │
│                                                                      │
│  MongoDB     →  Données FLEXIBLES, VOLUMINEUSES, SCHÉMA VARIABLE,   │
│                 SCALABILITÉ HORIZONTALE                              │
│                                                                      │
│  Redis       →  CACHE COURT TERME, OTP, SESSIONS, PUB/SUB           │
└──────────────────────────────────────────────────────────────────────┘
```

### 3.2 Répartition des données

| Entité | Base de données | Raison |
|--------|-----------------|--------|
| `users` | **PostgreSQL** | Auth, rôles, relations strictes |
| `artisan_profiles` | **PostgreSQL** | Données critiques, jointures fréquentes, PostGIS pour la géoloc |
| `client_profiles` | **PostgreSQL** | Liées aux users, simples et stables |
| `categories` / `subcategories` | **PostgreSQL** | Référentiel stable avec relations |
| `subscriptions` | **PostgreSQL** | Données financières — ACID obligatoire |
| `payments` | **PostgreSQL** | Transactions financières — ACID obligatoire |
| `verification_documents` | **PostgreSQL** | Workflow strict avec états et validations |
| `reviews` | **PostgreSQL** | Intégrité des avis, calcul de moyenne fiable |
| `messages` | **MongoDB** | Volume élevé, lecture/écriture rapide, schéma simple |
| `conversations` | **MongoDB** | Métadonnées flexibles, mises à jour fréquentes |
| `portfolio_items` | **MongoDB** | Schéma variable selon le métier, tableau d'images |
| `notifications` | **MongoDB** | Volume élevé, TTL d'expiration automatique |
| `activity_logs` | **MongoDB** | Analytics et logs d'actions — volume important |
| `otp_codes` | **Redis** | TTL court (5 min), accès ultra-rapide |
| `sessions` | **Redis** | Cache des refresh tokens JWT |

### 3.3 Schéma PostgreSQL

```mermaid
erDiagram
    USER ||--o| ARTISAN_PROFILE : "has"
    USER ||--o| CLIENT_PROFILE : "has"
    USER ||--o{ VERIFICATION_DOCUMENT : "uploads"
    ARTISAN_PROFILE }o--|| CATEGORY : "belongs to"
    ARTISAN_PROFILE ||--o| SUBSCRIPTION : "pays"
    SUBSCRIPTION ||--o{ PAYMENT : "has"
    CLIENT_PROFILE ||--o{ REVIEW : "writes"
    ARTISAN_PROFILE ||--o{ REVIEW : "receives"
    CATEGORY ||--o{ SUBCATEGORY : "has"

    USER {
        uuid id PK
        string phone_number UK
        string email
        string password_hash
        enum role "ARTISAN | CLIENT | ADMIN"
        enum verification_status "PENDING | VERIFIED | CERTIFIED"
        boolean is_active
        boolean is_phone_verified
        string whatsapp_number
        string country_code "CI par defaut"
        point location "PostGIS"
        timestamp created_at
        timestamp updated_at
    }

    ARTISAN_PROFILE {
        uuid id PK
        uuid user_id FK
        string first_name
        string last_name
        string business_name
        text bio
        uuid category_id FK
        string city
        string commune
        string address
        float rating_avg
        int total_reviews
        int years_experience
        boolean is_available
        boolean is_subscription_active
        string whatsapp_number
        jsonb working_hours
        timestamp last_active_at
    }

    CLIENT_PROFILE {
        uuid id PK
        uuid user_id FK
        string first_name
        string last_name
        string city
        string commune
    }

    VERIFICATION_DOCUMENT {
        uuid id PK
        uuid user_id FK
        enum document_type "CNI | PASSPORT | DIPLOME | CERTIFICAT | ATTESTATION"
        string file_url
        enum status "PENDING | APPROVED | REJECTED"
        string rejection_reason
        uuid reviewed_by FK
        timestamp submitted_at
        timestamp reviewed_at
    }

    CATEGORY {
        uuid id PK
        string name
        string icon_url
        string slug
        boolean is_active
        int display_order
    }

    SUBCATEGORY {
        uuid id PK
        uuid category_id FK
        string name
        string slug
    }

    SUBSCRIPTION {
        uuid id PK
        uuid artisan_profile_id FK
        enum plan "MONTHLY"
        int amount_fcfa "5000"
        enum status "ACTIVE | EXPIRED | CANCELLED | PENDING"
        timestamp starts_at
        timestamp expires_at
        boolean auto_renew
    }

    PAYMENT {
        uuid id PK
        uuid subscription_id FK
        int amount_fcfa
        enum provider "WAVE"
        enum status "PENDING | SUCCESS | FAILED"
        string wave_transaction_id
        string wave_checkout_id
        timestamp paid_at
    }

    REVIEW {
        uuid id PK
        uuid client_id FK
        uuid artisan_id FK
        int rating "1 a 5"
        text comment
        timestamp created_at
    }
```

### 3.4 Collections MongoDB

```javascript
// ── Collection : messages ──────────────────────────────────────────
{
  _id: ObjectId,
  conversationId: String,       // référence vers conversations._id
  senderId: String,             // UUID user (PostgreSQL)
  content: String,
  type: "TEXT" | "IMAGE" | "SYSTEM",
  mediaUrl: String,             // si type IMAGE
  isRead: Boolean,
  sentAt: Date
}

// ── Collection : conversations ────────────────────────────────────
{
  _id: ObjectId,
  participants: [String],       // UUIDs des users (PostgreSQL)
  lastMessage: {
    content: String,
    sentAt: Date,
    senderId: String
  },
  createdAt: Date,
  updatedAt: Date
}

// ── Collection : portfolio_items ──────────────────────────────────
{
  _id: ObjectId,
  artisanProfileId: String,     // UUID PostgreSQL
  title: String,
  description: String,
  priceFcfa: Number,
  imageUrls: [String],          // URLs MinIO
  tags: [String],
  metadata: Object,             // données spécifiques selon le métier
  createdAt: Date
}

// ── Collection : notifications ────────────────────────────────────
{
  _id: ObjectId,
  userId: String,               // UUID PostgreSQL
  type: "NEW_MESSAGE" | "SUBSCRIPTION_EXPIRY" | "NEARBY_SEARCH" | "REVIEW_RECEIVED",
  title: String,
  body: String,
  data: Object,                 // payload flexible
  isRead: Boolean,
  createdAt: Date,
  expireAt: Date                // TTL index — suppression automatique après 30 jours
}

// ── Collection : activity_logs ────────────────────────────────────
{
  _id: ObjectId,
  actorId: String,
  action: "PROFILE_VIEW" | "SEARCH" | "CONTACT_CLICK" | "LOGIN" | "PAYMENT_ATTEMPT",
  targetId: String,
  metadata: Object,
  ipAddress: String,
  userAgent: String,
  timestamp: Date
}
```

---

## 4. Authentification — OTP via WhatsApp

### 4.1 Stratégie

La vérification du numéro de téléphone repose **exclusivement** sur WhatsApp Business Cloud API
(Meta). Si l'API WhatsApp est indisponible, l'application affiche une notification invitant
l'utilisateur à réessayer. Aucune alternative SMS n'est prévue en Phase 1.

**Pourquoi WhatsApp :**
- Taux de pénétration de WhatsApp en Côte d'Ivoire supérieur à 85% des smartphones
- 1 000 conversations gratuites par mois offertes par Meta
- ~6 FCFA par conversation au-delà du quota gratuit (contre ~50 FCFA pour un SMS classique)
- Une conversation dure 24h : renvoyer plusieurs OTP dans la même journée ne coûte rien de plus

### 4.2 Flux OTP

```mermaid
flowchart TD
    A["Utilisateur entre son numero de telephone"] --> B["POST /api/v1/auth/send-otp"]
    B --> C["Backend genere un code OTP a 6 chiffres<br/>Stockage Redis — TTL 5 minutes"]
    C --> D["Envoi via WhatsApp Business Cloud API Meta"]
    D --> E{"Reponse de l'API WhatsApp"}
    E -->|Succes| F["Message WhatsApp recu<br/>Code OTP affiche dans le chat WhatsApp"]
    E -->|Erreur API| G["Notification in-app :<br/>Envoi du code impossible.<br/>Veuillez reessayer dans quelques instants."]
    G --> B
    F --> H["Utilisateur saisit le code OTP dans l'app"]
    H --> I{"Code valide ?<br/>TTL 5 min — Redis"}
    I -->|Oui| J["Telephone verifie — Generation du JWT"]
    I -->|Non ou expire| K["Code incorrect — Renvoyer le code"]
    K --> B
```

### 4.3 Template WhatsApp (pré-approuvé Meta)

```
Votre code de vérification Fiers Artisans est : {{1}}
Ce code expire dans 5 minutes. Ne le partagez jamais.
```

### 4.4 Configuration Redis OTP

```typescript
// Clé   : otp:{phone_number}
// TTL   : 300 secondes (5 minutes)
// Valeur: { code: "485291", attempts: 0 }

// Règles anti-abus :
// - Maximum 3 envois OTP par numéro par heure
// - Blocage temporaire 15 minutes après 5 tentatives de vérification échouées
```

### 4.5 Coût WhatsApp Business Cloud API

| Tranche | Coût |
|---------|------|
| 0 – 1 000 conversations / mois | **Gratuit** (quota Meta) |
| Au-delà de 1 000 | ~0,01 $ (~6 FCFA) / conversation |

### 4.6 Fallback SMS — Feature Flag (Non bloquant)

Un fallback SMS est prévu comme **filet de sécurité** si WhatsApp Business API est indisponible.

**Comportement de cascade :**

```
WhatsApp OK                          → OTP envoyé via WhatsApp ✅
WhatsApp KO + SMS provider configuré → OTP envoyé via SMS ✅
WhatsApp KO + SMS non configuré      → Notification in-app 🔔
WhatsApp KO + SMS KO                 → Notification in-app 🔔
```

> 💬 Message affiché : *"Service d'envoi de code actuellement indisponible. Veuillez réessayer dans quelques instants."*

Le fallback est **entièrement non bloquant** : aucune erreur fatale, aucun crash applicatif.

```typescript
// config/otp-providers.config.ts

export const OTP_PROVIDERS = {
  WHATSAPP: {
    enabled: true,              // ✅ ACTIF — Provider principal
    priority: 1,
  },
  SMS_TWILIO: {
    enabled: false,             // 🔒 Désactivé — Activer si TWILIO_ACCOUNT_SID + TWILIO_AUTH_TOKEN configurés
    priority: 2,
    // TODO : Renseigner les variables Twilio dans .env pour activer
  },
  SMS_ORANGE: {
    enabled: false,             // 🔒 Désactivé — Activer si Orange SMS API disponible
    priority: 3,
  },
};
```

**Logique dans `otp.service.ts` :**
- Itère sur les providers actifs par ordre de priorité
- En cas d'échec sur un provider → passe au suivant
- Si aucun provider ne répond → retourne un message utilisateur gracieux (pas d'exception levée)

---

## 5. Paiement — Wave CI

### 5.1 Principe

Wave est le **seul fournisseur de paiement actif** en Phase 1. C'est le service de Mobile Money
le plus utilisé en Côte d'Ivoire. Orange Money et MTN MoMo sont prévus comme features futures,
maintenus via des feature flags désactivés dans le code — prêts à être activés sans refactoring.

### 5.2 Flux de paiement

```mermaid
flowchart TD
    A["Artisan initie le paiement — 5 000 FCFA / mois"] --> B["POST /api/v1/subscription/initiate"]
    B --> C["Backend cree une Checkout Session Wave"]
    C --> D["Wave API retourne un checkout_url"]
    D --> E["Redirection vers l'interface Wave<br/>app Wave ou navigateur"]
    E --> F["Artisan confirme le paiement sur Wave"]
    F --> G{"Resultat"}
    G -->|Succes| H["Wave envoie webhook<br/>POST /api/v1/subscription/wave/webhook"]
    G -->|Echec ou annulation| I["Notification d'echec — Retenter"]
    H --> J["Backend valide la signature HMAC-SHA256"]
    J --> K["Mise a jour PostgreSQL :<br/>Payment — SUCCESS<br/>Subscription — ACTIVE"]
    K --> L["Profil artisan visible sur le marche"]
    K --> M["Notification push de confirmation"]
```

### 5.3 Interface Wave

```typescript
// modules/subscription/providers/wave.provider.ts

interface WaveCheckoutSession {
  checkout_id: string;
  checkout_url: string;         // URL de paiement Wave
  amount: number;               // 5000
  currency: "XOF";
  merchant_reference: string;   // UUID subscription PostgreSQL
}

// Webhook — vérification signature HMAC-SHA256 obligatoire
// Endpoint : POST /api/v1/subscription/wave/webhook
```

### 5.4 Feature flags — Providers futurs

```typescript
// modules/subscription/payment-providers.config.ts

export const PAYMENT_PROVIDERS = {
  WAVE: {
    enabled: true,              // ✅ ACTIF
    label: "Wave",
  },
  ORANGE_MONEY: {
    enabled: false,             // 🔒 Désactivé — API non encore disponible
    label: "Orange Money",
    // TODO : Activer quand l'accès à l'API Orange Money est obtenu
  },
  MTN_MOMO: {
    enabled: false,             // 🔒 Désactivé — API non encore disponible
    label: "MTN Mobile Money",
    // TODO : Activer quand l'accès à l'API MTN MoMo est obtenu
  },
};
```

---

## 6. Parcours Utilisateurs

### 6.1 Parcours Artisan

```mermaid
flowchart TD
    A["Ouvrir l'app"] --> B["Inscription Artisan<br/>Numero WhatsApp + OTP"]
    B --> C["Remplir le profil<br/>Nom, metier, categorie, localisation"]
    C --> D["Upload piece d'identite<br/>CNI ou Passeport"]
    D --> E["En attente de verification Admin"]
    E --> F{"Admin approuve ?"}
    F -->|Non| G["Rejet avec motif — Renvoyer le document"]
    G --> D
    F -->|Oui| H["Statut : VERIFIE"]
    H --> I["Upload diplomes / certificats — optionnel"]
    I --> J{"Admin approuve ?"}
    J -->|Oui| K["Statut : CERTIFIE"]
    J -->|Non soumis| L["Reste VERIFIE"]
    K --> M["Payer l'abonnement — 5 000 FCFA / mois via Wave"]
    L --> M
    M --> N{"Paiement reussi ?"}
    N -->|Oui| O["Profil visible sur le marche"]
    N -->|Non| P["Compte non visible — Retenter"]
    O --> Q["Remplir le portfolio<br/>Photos, descriptions, prix"]
    Q --> R["Recevoir des demandes clients"]
```

### 6.2 Parcours Client

```mermaid
flowchart TD
    A["Ouvrir l'app"] --> B["Inscription Client<br/>Numero WhatsApp + OTP"]
    B --> C["Dashboard Client"]
    C --> D["Lancer une recherche"]
    D --> E["Choisir une categorie<br/>Plombier, Menuisier, Electricien..."]
    E --> F["Detection GPS automatique"]
    F --> G["Resultats : artisans tries par proximite"]
    G --> H{"Resultats trouves ?"}
    H -->|Non| I["Elargir le rayon de recherche"]
    I --> G
    H -->|Oui| J["Parcourir les profils<br/>Note, portfolio, distance"]
    J --> K["Voir le profil de l'artisan"]
    K --> L{"Mode de contact"}
    L --> M["Chat in-app"]
    L --> N["Appel direct"]
    L --> O["Ouvrir WhatsApp"]
    M --> P["Echange et accord"]
    N --> P
    O --> P
    P --> Q["Laisser un avis apres la prestation"]
```

---

## 7. Architecture Backend — Modules NestJS

```
backend/
├── src/
│   ├── app.module.ts
│   ├── common/
│   │   ├── decorators/
│   │   ├── guards/
│   │   ├── interceptors/
│   │   ├── filters/
│   │   ├── pipes/
│   │   └── dto/
│   ├── config/
│   │   ├── database-postgres.config.ts
│   │   ├── database-mongo.config.ts
│   │   ├── redis.config.ts
│   │   ├── jwt.config.ts
│   │   ├── whatsapp.config.ts
│   │   ├── wave.config.ts
│   │   └── app.config.ts
│   ├── modules/
│   │   ├── auth/                              # Authentification
│   │   │   ├── auth.module.ts
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── otp/
│   │   │   │   ├── otp.service.ts             # Génération & vérification — Redis
│   │   │   │   └── whatsapp-otp.provider.ts   # Envoi OTP via WhatsApp Cloud API
│   │   │   ├── strategies/                    # JWT, Local
│   │   │   ├── guards/
│   │   │   └── dto/
│   │   ├── users/                             # Gestion utilisateurs
│   │   │   ├── users.module.ts
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   ├── entities/                      # TypeORM — PostgreSQL
│   │   │   │   ├── user.entity.ts
│   │   │   │   ├── artisan-profile.entity.ts
│   │   │   │   └── client-profile.entity.ts
│   │   │   └── dto/
│   │   ├── verification/                      # Vérification & Certification
│   │   │   ├── verification.module.ts
│   │   │   ├── verification.controller.ts
│   │   │   ├── verification.service.ts
│   │   │   ├── entities/                      # TypeORM — PostgreSQL
│   │   │   │   └── verification-document.entity.ts
│   │   │   └── dto/
│   │   ├── categories/                        # Catégories d'artisans
│   │   │   ├── categories.module.ts
│   │   │   ├── categories.controller.ts
│   │   │   ├── categories.service.ts
│   │   │   └── entities/                      # TypeORM — PostgreSQL
│   │   │       ├── category.entity.ts
│   │   │       └── subcategory.entity.ts
│   │   ├── portfolio/                         # Portfolio artisan
│   │   │   ├── portfolio.module.ts
│   │   │   ├── portfolio.controller.ts
│   │   │   ├── portfolio.service.ts
│   │   │   └── schemas/                       # Mongoose — MongoDB
│   │   │       └── portfolio-item.schema.ts
│   │   ├── search/                            # Recherche géolocalisée
│   │   │   ├── search.module.ts
│   │   │   ├── search.controller.ts
│   │   │   ├── search.service.ts              # Requêtes PostGIS — PostgreSQL
│   │   │   └── dto/
│   │   ├── subscription/                      # Abonnements & Paiements
│   │   │   ├── subscription.module.ts
│   │   │   ├── subscription.controller.ts
│   │   │   ├── subscription.service.ts
│   │   │   ├── entities/                      # TypeORM — PostgreSQL
│   │   │   │   ├── subscription.entity.ts
│   │   │   │   └── payment.entity.ts
│   │   │   ├── providers/
│   │   │   │   ├── wave.provider.ts           # ACTIF
│   │   │   │   ├── orange-money.provider.ts   # Désactivé (feature future)
│   │   │   │   └── mtn-momo.provider.ts       # Désactivé (feature future)
│   │   │   ├── payment-providers.config.ts    # Feature flags
│   │   │   └── dto/
│   │   ├── chat/                              # Messagerie temps réel
│   │   │   ├── chat.module.ts
│   │   │   ├── chat.gateway.ts                # WebSocket Gateway
│   │   │   ├── chat.service.ts
│   │   │   └── schemas/                       # Mongoose — MongoDB
│   │   │       ├── conversation.schema.ts
│   │   │       └── message.schema.ts
│   │   ├── notifications/                     # Notifications
│   │   │   ├── notifications.module.ts
│   │   │   ├── notifications.service.ts
│   │   │   ├── schemas/                       # Mongoose — MongoDB
│   │   │   │   └── notification.schema.ts
│   │   │   └── providers/
│   │   │       └── fcm.provider.ts
│   │   ├── reviews/                           # Avis & Notes
│   │   │   ├── reviews.module.ts
│   │   │   ├── reviews.controller.ts
│   │   │   ├── reviews.service.ts
│   │   │   └── entities/                      # TypeORM — PostgreSQL
│   │   │       └── review.entity.ts
│   │   ├── media/                             # Upload fichiers
│   │   │   ├── media.module.ts
│   │   │   ├── media.controller.ts
│   │   │   ├── media.service.ts
│   │   │   └── schemas/                       # Mongoose — MongoDB
│   │   │       └── media-file.schema.ts
│   │   ├── analytics/                         # Statistiques & Logs
│   │   │   ├── analytics.module.ts
│   │   │   ├── analytics.service.ts
│   │   │   └── schemas/                       # Mongoose — MongoDB
│   │   │       └── activity-log.schema.ts
│   │   └── admin/                             # Back-office Admin
│   │       ├── admin.module.ts
│   │       ├── admin.controller.ts
│   │       └── admin.service.ts
│   └── database/
│       ├── migrations/                        # Migrations PostgreSQL
│       └── seeds/
├── test/
├── Dockerfile
├── .env.example
├── nest-cli.json
├── tsconfig.json
└── package.json
```

---

## 8. Application Mobile — Structure Flutter

```
fiers_artisans_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── config/
│   │   ├── app_config.dart
│   │   ├── theme.dart
│   │   ├── routes.dart
│   │   └── constants.dart
│   ├── core/
│   │   ├── network/
│   │   │   ├── api_client.dart            # Dio HTTP client
│   │   │   ├── api_endpoints.dart
│   │   │   └── interceptors/
│   │   ├── storage/
│   │   │   └── secure_storage.dart        # Stockage sécurisé des tokens
│   │   ├── services/
│   │   │   ├── location_service.dart      # GPS
│   │   │   └── notification_service.dart
│   │   └── utils/
│   │       ├── validators.dart
│   │       └── formatters.dart
│   ├── data/
│   │   ├── models/
│   │   │   ├── user_model.dart
│   │   │   ├── artisan_model.dart
│   │   │   ├── category_model.dart
│   │   │   ├── review_model.dart
│   │   │   ├── portfolio_model.dart
│   │   │   ├── subscription_model.dart
│   │   │   ├── conversation_model.dart
│   │   │   └── message_model.dart
│   │   └── repositories/
│   │       ├── auth_repository.dart
│   │       ├── artisan_repository.dart
│   │       ├── search_repository.dart
│   │       ├── chat_repository.dart
│   │       └── subscription_repository.dart
│   ├── providers/                         # Riverpod — State Management
│   │   ├── auth_provider.dart
│   │   ├── search_provider.dart
│   │   ├── artisan_provider.dart
│   │   ├── chat_provider.dart
│   │   └── subscription_provider.dart
│   └── presentation/
│       ├── common/                        # Widgets réutilisables
│       │   ├── app_button.dart
│       │   ├── app_text_field.dart
│       │   ├── rating_stars.dart
│       │   ├── artisan_card.dart
│       │   ├── category_chip.dart
│       │   └── loading_overlay.dart
│       ├── auth/
│       │   ├── splash_screen.dart
│       │   ├── onboarding_screen.dart
│       │   ├── login_screen.dart
│       │   ├── register_artisan_screen.dart
│       │   ├── register_client_screen.dart
│       │   └── otp_verification_screen.dart
│       ├── client/
│       │   ├── client_dashboard.dart
│       │   ├── search_screen.dart
│       │   ├── search_results_screen.dart
│       │   ├── artisan_profile_screen.dart
│       │   └── review_screen.dart
│       ├── artisan/
│       │   ├── artisan_dashboard.dart
│       │   ├── portfolio_screen.dart
│       │   ├── add_portfolio_item.dart
│       │   ├── verification_screen.dart
│       │   ├── subscription_screen.dart
│       │   └── artisan_settings.dart
│       ├── chat/
│       │   ├── conversations_list.dart
│       │   └── chat_screen.dart
│       └── shared/
│           ├── profile_screen.dart
│           ├── notifications_screen.dart
│           └── settings_screen.dart
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── test/
├── pubspec.yaml
└── analysis_options.yaml
```

---

## 9. API Endpoints

### 9.1 Authentification

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/api/v1/auth/register/artisan` | Inscription artisan |
| `POST` | `/api/v1/auth/register/client` | Inscription client |
| `POST` | `/api/v1/auth/send-otp` | Envoyer un code OTP via WhatsApp |
| `POST` | `/api/v1/auth/verify-otp` | Vérifier le code OTP |
| `POST` | `/api/v1/auth/login` | Connexion (téléphone + mot de passe) |
| `POST` | `/api/v1/auth/refresh` | Rafraîchir le token JWT |
| `POST` | `/api/v1/auth/logout` | Déconnexion |

### 9.2 Profils

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/artisan/profile` | Mon profil artisan |
| `PUT` | `/api/v1/artisan/profile` | Mettre à jour mon profil |
| `GET` | `/api/v1/artisan/:id` | Profil public d'un artisan |
| `GET` | `/api/v1/client/profile` | Mon profil client |
| `PUT` | `/api/v1/client/profile` | Mettre à jour mon profil client |

### 9.3 Vérification

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/api/v1/verification/submit` | Soumettre un document |
| `GET` | `/api/v1/verification/status` | Statut de ma vérification |
| `GET` | `/api/v1/admin/verifications/pending` | *(Admin)* Documents en attente |
| `PUT` | `/api/v1/admin/verifications/:id` | *(Admin)* Approuver ou rejeter |

### 9.4 Portfolio

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/portfolio` | Mes réalisations |
| `POST` | `/api/v1/portfolio` | Ajouter une réalisation |
| `PUT` | `/api/v1/portfolio/:id` | Modifier une réalisation |
| `DELETE` | `/api/v1/portfolio/:id` | Supprimer une réalisation |
| `GET` | `/api/v1/artisan/:id/portfolio` | Portfolio public d'un artisan |

### 9.5 Recherche Géolocalisée

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/search/artisans` | Rechercher des artisans |
| | | `?lat=5.36&lng=-4.00&radius_km=10&category=plombier` |
| `GET` | `/api/v1/search/categories` | Lister les catégories disponibles |

### 9.6 Abonnement & Paiement

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/api/v1/subscription/initiate` | Initier un paiement Wave → retourne `checkout_url` |
| `POST` | `/api/v1/subscription/wave/webhook` | Webhook Wave (signature HMAC-SHA256 vérifiée) |
| `GET` | `/api/v1/subscription/status` | Statut de mon abonnement |
| `GET` | `/api/v1/subscription/providers` | Fournisseurs disponibles (Wave uniquement) |

### 9.7 Chat

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/api/v1/chat/conversations` | Mes conversations |
| `POST` | `/api/v1/chat/conversations` | Créer une conversation |
| `GET` | `/api/v1/chat/conversations/:id/messages` | Messages d'une conversation |
| `WS` | `/ws/chat` | WebSocket — chat temps réel |

### 9.8 Avis

| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/api/v1/reviews` | Laisser un avis |
| `GET` | `/api/v1/artisan/:id/reviews` | Avis d'un artisan |

---

## 10. Sécurité

### 10.1 Niveaux de vérification artisan

```mermaid
flowchart LR
    A["INSCRIT<br/>Telephone WhatsApp verifie"]
    B["VERIFIE<br/>CNI validee par Admin"]
    C["CERTIFIE<br/>Diplomes et certificats valides"]
    A --> B --> C

    style A fill:#fef3cd,stroke:#856404
    style B fill:#d4edda,stroke:#155724
    style C fill:#cce5ff,stroke:#004085
```

### 10.2 Mesures de sécurité

| Mesure | Détails |
|--------|---------|
| **Authentification** | JWT — access token 15 min + refresh token 30 jours |
| **OTP WhatsApp** | Code 6 chiffres, TTL 5 min, max 3 envois par heure par numéro |
| **Anti-brute force** | Blocage 15 min après 5 tentatives de vérification échouées |
| **RBAC** | Rôles `ARTISAN`, `CLIENT`, `ADMIN` avec guards NestJS |
| **Webhook Wave** | Vérification signature HMAC-SHA256 obligatoire |
| **Validation entrées** | DTOs avec `class-validator` sur tous les endpoints |
| **Upload sécurisé** | Validation type MIME et taille maximale des fichiers |
| **HTTPS** | SSL/TLS via Let's Encrypt + Nginx |
| **Documents sensibles** | Pièces d'identité chiffrées au repos dans MinIO |
| **CORS** | Configuration stricte — origines autorisées uniquement |
| **Helmet** | Protection des headers HTTP |
| **MongoDB** | Auth activée, accès réseau interne Docker uniquement |

---

## 11. Infrastructure Docker

### 11.1 Docker Compose

```yaml
services:

  # ── Backend API ────────────────────────────────────────────────────
  api:
    build: ./backend
    ports: ["3000:3000"]
    depends_on: [postgres, mongodb, redis, minio]
    environment:
      - DATABASE_POSTGRES_URL=postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/fiers_artisans
      - DATABASE_MONGO_URL=mongodb://${MONGO_USER}:${MONGO_PASSWORD}@mongodb:27017/fiers_artisans
      - REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379
      - MINIO_ENDPOINT=minio:9000
      - MINIO_ACCESS_KEY=${MINIO_ACCESS_KEY}
      - MINIO_SECRET_KEY=${MINIO_SECRET_KEY}
      - WHATSAPP_API_TOKEN=${WHATSAPP_API_TOKEN}
      - WHATSAPP_PHONE_NUMBER_ID=${WHATSAPP_PHONE_NUMBER_ID}
      - WAVE_API_KEY=${WAVE_API_KEY}
      - WAVE_WEBHOOK_SECRET=${WAVE_WEBHOOK_SECRET}
      - JWT_SECRET=${JWT_SECRET}
      - JWT_REFRESH_SECRET=${JWT_REFRESH_SECRET}

  # ── PostgreSQL — Données relationnelles ───────────────────────────
  postgres:
    image: postgis/postgis:16-3.4
    volumes: [postgres_data:/var/lib/postgresql/data]
    environment:
      - POSTGRES_DB=fiers_artisans
      - POSTGRES_USER=${DB_USER}
      - POSTGRES_PASSWORD=${DB_PASSWORD}

  # ── MongoDB — Données flexibles ────────────────────────────────────
  mongodb:
    image: mongo:7
    volumes: [mongo_data:/data/db]
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_USER}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_PASSWORD}
      - MONGO_INITDB_DATABASE=fiers_artisans

  # ── Redis — Cache, OTP, Pub/Sub ────────────────────────────────────
  redis:
    image: redis:7-alpine
    volumes: [redis_data:/data]
    command: redis-server --requirepass ${REDIS_PASSWORD}

  # ── MinIO — Stockage fichiers ──────────────────────────────────────
  minio:
    image: minio/minio
    command: server /data --console-address ":9001"
    volumes: [minio_data:/data]
    environment:
      - MINIO_ROOT_USER=${MINIO_ACCESS_KEY}
      - MINIO_ROOT_PASSWORD=${MINIO_SECRET_KEY}
    # ⚠️ SÉCURITÉ PRODUCTION : Aucun port exposé — MinIO interne Docker uniquement.
    # Les fichiers sont servis via signed URLs générées par le backend NestJS.
    # Console MinIO accessible uniquement via tunnel SSH : ssh -L 9001:minio:9001 user@vps
    # ── Voir docker-compose.dev.yml pour l'override local (ports exposés pour les tests) ──

  # ── Nginx — Reverse Proxy ──────────────────────────────────────────
  nginx:
    image: nginx:alpine
    ports: ["80:80", "443:443"]
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf
      - ./nginx/ssl:/etc/nginx/ssl
    depends_on: [api]

  # ── Monitoring ─────────────────────────────────────────────────────
  prometheus:
    image: prom/prometheus
    volumes: [./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml]

  grafana:
    image: grafana/grafana
    ports: ["3001:3000"]
    depends_on: [prometheus]

volumes:
  postgres_data:
  mongo_data:
  redis_data:
  minio_data:
```

### 11.2 Structure infrastructure

```
infrastructure/
├── docker-compose.yml
├── docker-compose.prod.yml
├── nginx/
│   ├── nginx.conf
│   └── ssl/
├── postgres/
│   └── init.sql                  # PostGIS + extensions
├── mongodb/
│   └── init.js                   # Index TTL notifications, index géo
├── minio/
│   └── policies/
├── monitoring/
│   ├── prometheus.yml
│   └── grafana/
│       └── dashboards/
└── scripts/
    ├── deploy.sh
    └── backup.sh
```

### 11.3 VPS recommandé (Phase 1)

| Spec | Recommandation |
|------|----------------|
| **Fournisseur** | Contabo, Hetzner ou OVH |
| **CPU** | 4 vCPU minimum |
| **RAM** | 12 Go minimum (PostgreSQL + MongoDB + Redis) |
| **Stockage** | 100 Go SSD |
| **OS** | Ubuntu 24.04 LTS |
| **Budget estimé** | ~15 – 25 € / mois |

---

## 12. Catégories d'Artisans

| Catégorie | Sous-catégories |
|-----------|-----------------|
| 🧱 Bâtiment & Construction | Maçon, Carreleur, Plâtrier, Ferblantier |
| 🪵 Menuiserie & Ébénisterie | Menuisier bois, Menuisier aluminium, Ébéniste |
| ⚡ Électricité | Électricien bâtiment, Électricien industriel, Domoticien |
| 🔧 Plomberie | Plombier, Chauffagiste |
| 🎨 Peinture & Décoration | Peintre bâtiment, Décorateur intérieur, Staffeur |
| 🏗️ Architecture & Ingénierie | Architecte, Ingénieur civil, Géomètre |
| ✂️ Textile & Mode | Tailleur, Couturier, Brodeur |
| ⚒️ Métallurgie | Forgeron, Soudeur, Ferronnier d'art |
| 🌸 Fleuriste & Paysagisme | Fleuriste, Jardinier, Paysagiste |
| 🚗 Automobile | Mécanicien auto, Électricien auto, Tôlier |
| 📸 Services créatifs | Photographe, Vidéaste, Graphiste |
| 🧹 Services domestiques | Agent d'entretien, Femme/Homme de ménage |
| 💇 Beauté & Bien-être | Coiffeur, Barbier, Esthéticienne |
| 🍳 Restauration | Cuisinier, Traiteur, Pâtissier |
| 🖥️ Tech & Numérique | Réparateur téléphone, Informaticien, Installateur réseau |
| 🪑 Ameublement | Tapissier, Matelassier, Vitrier |

---

## 13. Fonctionnalités à Valeur Ajoutée

| Fonctionnalité | Description | Priorité |
|----------------|-------------|----------|
| 🆘 **Mode Urgence** | Trouver un artisan disponible maintenant — artisans en ligne uniquement | Haute |
| 📊 **Dashboard artisan** | Vues du profil, demandes reçues, note moyenne | Haute |
| 🏷️ **Badges de confiance** | Vérifié ✅, Certifié 🏆, Top Artisan ⭐ | Haute |
| 📍 **Zones de couverture** | L'artisan définit ses zones d'intervention géographiques | Moyenne |
| 🔔 **Alertes proximité** | Notification quand un client cherche dans ta catégorie près de toi | Moyenne |
| 💳 **Orange Money** | 🔒 Feature future — activer quand API disponible | Future |
| 💳 **MTN MoMo** | 🔒 Feature future — activer quand API disponible | Future |
| 📅 **Prise de rendez-vous** | Créneaux et booking intégré | Future |
| 💳 **Paiement in-app** | Le client paie l'artisan via l'app avec commission plateforme | Future |
| 📋 **Devis en ligne** | L'artisan envoie un devis structuré au client | Future |

---

## 14. Planning de Développement

| Phase | Durée estimée | Livrables |
|-------|--------------|-----------|
| **Phase 1 — Fondations** | 2 – 3 semaines | Docker (PostgreSQL + MongoDB + Redis), Auth, OTP WhatsApp |
| **Phase 2 — Core Features** | 3 – 4 semaines | Profils, Vérification, Catégories, Portfolio (MongoDB), Recherche géo (PostGIS) |
| **Phase 3 — Monétisation** | 1 – 2 semaines | Abonnement Wave, webhook, activation compte artisan |
| **Phase 4 — Communication** | 2 – 3 semaines | Chat temps réel (MongoDB + WebSocket), Notifications, contact WhatsApp |
| **Phase 5 — Mobile** | 4 – 6 semaines | App Flutter complète — client + artisan |
| **Phase 6 — Admin & Launch** | 2 semaines | Back-office Admin, tests, déploiement VPS |
| **Phase 7 — Extensions** | Future | Orange Money, MTN MoMo, RDV, devis en ligne |

---

> **Prochaine étape :** Validation de cette architecture v2.0.
> Une fois approuvée → **Phase 1** : mise en place de Docker avec PostgreSQL + MongoDB + Redis,
> puis implémentation de l'Auth avec OTP WhatsApp Business Cloud API.

---

## 15. Panel Admin — Architecture

### 15.1 Décision d'architecture

| Composant | Technologie | Hébergement |
|-----------|-------------|-------------|
| **Backend Admin** | NestJS (partagé avec l'app) — module `/admin` + guards RBAC | VPS (Docker) |
| **Frontend Admin** | Next.js 14 (App Router, TypeScript) | Vercel / Netlify / VPS sous-domaine |
| **Frontend Mobile** | Flutter (iOS + Android) | Stores (App Store / Play Store) |
| **API commune** | `/api/v1/` — routes admin protégées par `ADMIN` role guard | VPS (Docker) |

> ✅ **Cette architecture est cohérente, sécurisée et scalable.** Un seul backend sert les deux frontends. Les routes admin sont protégées par double couche : JWT valide + rôle `ADMIN`. Le frontend admin peut être restreint par IP whitelist Nginx sans impacter l'app mobile.

### 15.2 Schéma d'architecture Admin

```mermaid
graph TB
    subgraph "📱 Frontend Mobile"
        FLUTTER["Flutter App<br/>iOS + Android<br/>Hébergé sur les Stores"]
    end

    subgraph "🖥️ Frontend Admin"
        NEXTJS["Next.js 14 Admin Panel<br/>TypeScript + shadcn/ui<br/>admin.fierartisans.ci<br/>Hébergé sur Vercel / Netlify"]
    end

    subgraph "🌐 VPS — Docker (services conteneurisés)"
        NGINX["Nginx<br/>Reverse Proxy + SSL<br/>Routing par sous-domaine"]
        API["NestJS API<br/>api.fierartisans.ci<br/>Port 3000"]

        subgraph "Modules NestJS"
            AUTH_MOD["auth/"]
            USER_MOD["users/"]
            SEARCH_MOD["search/"]
            CHAT_MOD["chat/"]
            ADMIN_MOD["admin/<br/>🔒 ADMIN role guard"]
            VERIF_MOD["verification/"]
            SUB_MOD["subscription/"]
        end

        PG["PostgreSQL + PostGIS"]
        MONGO["MongoDB"]
        REDIS["Redis"]
        MINIO["MinIO<br/>Réseau interne Docker"]
    end

    FLUTTER -->|"HTTPS → api.fierartisans.ci"| NGINX
    NEXTJS -->|"HTTPS → api.fierartisans.ci/admin"| NGINX
    NGINX --> API
    API --> AUTH_MOD & USER_MOD & SEARCH_MOD & CHAT_MOD & ADMIN_MOD & VERIF_MOD & SUB_MOD
    AUTH_MOD & USER_MOD & VERIF_MOD & SUB_MOD --> PG
    CHAT_MOD --> MONGO & REDIS
    ADMIN_MOD --> PG & MONGO
    API -->|"Signed URLs internes"| MINIO
```

### 15.3 Fonctionnalités du Panel Admin (Next.js)

| Section | Fonctionnalités |
|---------|-----------------|
| **Dashboard** | KPIs : artisans actifs, revenus du mois, nouvelles inscriptions, documents en attente |
| **Vérifications** | Liste des documents soumis, visualisation CNI/diplômes (signed URL MinIO), Approuver / Rejeter avec motif |
| **Artisans** | Recherche, visualisation profil, suspension/réactivation de compte |
| **Clients** | Gestion des comptes clients signalés |
| **Abonnements** | Historique des paiements, statuts Wave, remboursements |
| **Avis** | Modération des avis signalés |
| **Analytics** | Graphiques Recharts : inscriptions, paiements, recherches par zone géo |
| **Logs** | Consultation des `activity_logs` MongoDB |

### 15.4 Sécurité Admin

```typescript
// Nginx — restriction IP optionnelle pour le sous-domaine admin
// server { server_name admin.fierartisans.ci; allow 41.X.X.X; deny all; }

// NestJS — Guard double couche
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles('ADMIN')
@Controller('admin')
export class AdminController { ... }
```

### 15.5 Stack Frontend Admin

| Outil | Usage |
|-------|-------|
| **Next.js 14** (App Router) | Framework React SSR/SSG |
| **TypeScript** | Typage complet |
| **shadcn/ui** ou **Tremor** | Composants UI Dashboard |
| **TanStack Query** | Fetching & cache API |
| **Recharts** | Graphiques analytics |
| **next-auth** | Session admin sécurisée (wrapper JWT) |

---

## 16. Haute Disponibilité (HA) — Warm Standby

### 16.1 Concept

Architecture **warm standby avec failover automatique** : un VPS secondaire répliqué tourne en veille et prend le relais automatiquement si le VPS primaire tombe.

```
VPS Primaire (ACTIF)          VPS Secondaire (STANDBY)
┌─────────────────────┐       ┌──────────────────────────┐
│  NestJS API         │       │  NestJS API (idle)        │
│  PostgreSQL PRIMARY │──────▶│  PostgreSQL STANDBY       │ streaming replication
│  MongoDB PRIMARY    │──────▶│  MongoDB SECONDARY        │ replica set
│  Redis MASTER       │──────▶│  Redis REPLICA            │ Redis Sentinel
│  MinIO PRIMARY      │──────▶│  MinIO MIRROR             │ mc mirror
│  Nginx              │       │  Nginx (standby)          │
└─────────────────────┘       └──────────────────────────┘
         │                                │
         └──────────┐ ┌──────────────────┘
                    ▼ ▼
         ┌────────────────────┐
         │  Keepalived /      │
         │  Floating IP       │  ← bascule automatique <30s
         └────────────────────┘
                    │
                    ▼
         api.fierartisans.ci
```

### 16.2 Technologies de réplication par service

| Service | Technologie HA | Comportement en cas de panne |
|---------|---------------|------------------------------|
| **PostgreSQL** | Streaming Replication (async) | Le standby devient primary automatiquement via `pg_promote()` |
| **MongoDB** | Replica Set (1 primary + 1 secondary + 1 arbiter) | Election automatique d'un nouveau primary (<10s) |
| **Redis** | Redis Sentinel (1 master + 1 replica + sentinel) | Sentinel promeut le replica si le master est down |
| **MinIO** | `mc mirror --watch` en continu | Bascule manuelle ou script de failover |
| **NestJS API** | Image Docker identique sur les deux VPS | Démarré par keepalived au failover |
| **IP publique** | Hetzner Floating IP ou Keepalived VRRP | Rebascule vers VPS2 en cas de panne VPS1 |

### 16.3 Quand activer

| Phase | Stratégie HA |
|-------|-------------|
| **Phase 1** | Backups automatiques quotidiens uniquement (restauration <1h acceptable) |
| **Phase 2-3** | Warm standby PostgreSQL + MongoDB Replica Set |
| **Phase 4+** | Full HA (tous services répliqués + Floating IP) |
| **Futur** | Migration vers Docker Swarm ou Kubernetes si trafic > 10 000 artisans |

> ✅ Cette stratégie est **cohérente avec le projet**, **scalable** (migration vers K8s sans refactoring applicatif), et **économique** (un second VPS Hetzner CX22 ≈ 5-7€/mois).

---

## 17. Stratégie de Tests

### 17.1 Niveaux de tests

| Niveau | Outil | Cible | Coverage minimum |
|--------|-------|-------|-----------------|
| **Tests unitaires** | Jest (NestJS) | Services, Guards, Providers | 70% |
| **Tests d'intégration** | Supertest + Jest | Endpoints REST critiques | Tous les endpoints auth, paiement, vérification |
| **Tests Flutter** | `flutter_test` | Widgets, Providers Riverpod | Composants réutilisables |
| **Tests E2E Flutter** | `integration_test` | Parcours complets (inscription, recherche, paiement) | Parcours artisan + parcours client |

### 17.2 Modules prioritaires à tester en premier

```
🔴 Critique (tests avant tout autre développement) :
  - auth.service.ts          → OTP, JWT, refresh token
  - otp.service.ts           → Génération, vérification, TTL, anti-brute-force
  - subscription.service.ts  → Initiation paiement, webhook Wave, idempotence
  - wave.provider.ts         → Vérification signature HMAC-SHA256

🟠 Important :
  - verification.service.ts  → Workflow de validation documents
  - search.service.ts        → Requêtes PostGIS (rayon, tri par distance)
  - review.service.ts        → Contrainte un avis par client par artisan

🟡 Standard :
  - Tous les autres modules
```

### 17.3 Idempotence du webhook Wave

```typescript
// subscription.service.ts — Protection contre les doublons webhook
async handleWaveWebhook(payload: WaveWebhookDto): Promise<void> {
  // 1. Vérifier signature HMAC-SHA256 en premier (sécurité)
  this.verifyWaveSignature(payload);

  // 2. Idempotence : ignorer si déjà traité
  const existing = await this.paymentRepository.findOne({
    where: { wave_transaction_id: payload.transaction_id }
  });
  if (existing?.status === PaymentStatus.SUCCESS) {
    return; // Webhook déjà traité — ne pas retraiter
  }

  // 3. Traitement normal
  await this.markPaymentSuccess(payload);
}
```

---

## 18. Pipeline CI/CD — GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, staging]

jobs:
  # ── 1. Lint & Type Check ─────────────────────────────────────────
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run lint && npm run type-check

  # ── 2. Tests ─────────────────────────────────────────────────────
  test:
    needs: lint
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgis/postgis:16-3.4
      mongo:
        image: mongo:7
      redis:
        image: redis:7-alpine
    steps:
      - uses: actions/checkout@v4
      - run: npm ci && npm run test:cov

  # ── 3. Build Image Docker ────────────────────────────────────────
  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: docker build -t fierartisans-api:${{ github.sha }} .
      - run: docker push ghcr.io/${{ github.repository }}/api:${{ github.sha }}

  # ── 4. Deploy sur VPS ───────────────────────────────────────────
  deploy:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - name: Deploy via SSH
        run: |
          ssh user@vps "
            cd /opt/fierartisans &&
            docker compose pull api &&
            docker compose up -d --no-deps api &&
            docker image prune -f
          "
```

### 18.1 Environnements

| Branche | Environnement | VPS |
|---------|--------------|-----|
| `develop` | Local / Tests | Docker local |
| `staging` | Staging | VPS secondaire (standby) |
| `main` | Production | VPS primaire |

---

## 19. Gestion des Erreurs & Zones d'ombre résolues

### 19.1 Format de réponse d'erreur unifié (API)

```typescript
// Toutes les erreurs de l'API retournent ce format :
{
  "statusCode": 400,
  "error": "BAD_REQUEST",
  "message": "Le numéro de téléphone est invalide.",
  "timestamp": "2025-01-15T10:30:00.000Z",
  "path": "/api/v1/auth/send-otp"
}
```

### 19.2 Intégrité des avis

```typescript
// Règle : un seul avis par client par artisan
// reviews.service.ts
async createReview(clientId: string, artisanId: string, dto: CreateReviewDto) {
  const existing = await this.reviewRepository.findOne({
    where: { client_id: clientId, artisan_id: artisanId }
  });
  if (existing) {
    throw new ConflictException('Vous avez déjà laissé un avis pour cet artisan.');
  }
  // Créer l'avis + recalculer rating_avg sur artisan_profile
}
```

### 19.3 Localisation artisan — Clarification

| Question | Décision |
|----------|---------|
| Position stockée | **Adresse fixe** de l'artisan (commune/quartier), pas de tracking GPS temps réel |
| Ce que voit le client | **Distance en km** uniquement (ex: "à 2,3 km") — jamais la position exacte |
| Mise à jour | L'artisan met à jour sa localisation depuis ses paramètres |

### 19.4 Expiration d'abonnement

| Événement | Action |
|-----------|--------|
| **J-7 avant expiration** | Notification push + WhatsApp de rappel à l'artisan |
| **J-3 avant expiration** | 2ème rappel |
| **J0 (expiration)** | `is_subscription_active = false` → profil invisible dans les recherches |
| **Période de grâce** | 48h — le profil reste visible, aucun nouveau paiement n'est bloqué |
| **Après 48h** | Désactivation définitive jusqu'au prochain paiement |

### 19.5 Compression des images (pipeline média)

```typescript
// media.service.ts — Pipeline de traitement avec Sharp
import * as sharp from 'sharp';

async processAndUpload(file: Express.Multer.File, bucket: string) {
  const optimized = await sharp(file.buffer)
    .resize(1200, 1200, { fit: 'inside', withoutEnlargement: true })
    .jpeg({ quality: 80, progressive: true })
    .toBuffer();

  const thumbnail = await sharp(file.buffer)
    .resize(300, 300, { fit: 'cover' })
    .jpeg({ quality: 70 })
    .toBuffer();

  // Upload original compressé + thumbnail vers MinIO
  await this.minioService.putObject(bucket, `${uuid}.jpg`, optimized);
  await this.minioService.putObject(bucket, `${uuid}_thumb.jpg`, thumbnail);

  // Retourner une signed URL via le backend (jamais l'URL MinIO directe)
  return this.generateSignedUrl(bucket, `${uuid}.jpg`);
}
```

### 19.6 Override Docker Compose pour développement local

```yaml
# docker-compose.dev.yml — Override LOCAL uniquement
# Usage : docker compose -f docker-compose.yml -f docker-compose.dev.yml up

services:
  minio:
    ports:
      - "9000:9000"   # API MinIO — accessible en local pour tester
      - "9001:9001"   # Console MinIO — accessible en local sur http://localhost:9001
```

> ⚠️ Ce fichier **ne doit jamais être utilisé en production**. En production, MinIO est entièrement interne au réseau Docker.

---

## 20. Mise à jour du Planning

| Phase | Durée estimée | Livrables — Mis à jour |
|-------|--------------|----------------------|
| **Phase 1 — Fondations** | 2 – 3 semaines | Docker Compose (dev + prod), PostgreSQL + MongoDB + Redis + MinIO interne, Auth OTP WhatsApp + fallback SMS feature flag |
| **Phase 2 — Core Features** | 3 – 4 semaines | Profils, Vérification, Catégories, Portfolio (MongoDB), Recherche géo (PostGIS), pipeline Sharp images |
| **Phase 3 — Monétisation** | 1 – 2 semaines | Abonnement Wave + webhook idempotent, activation compte, rappels expiration |
| **Phase 4 — Communication** | 2 – 3 semaines | Chat temps réel (MongoDB + WebSocket), Notifications push, contact WhatsApp |
| **Phase 5 — Mobile** | 4 – 6 semaines | App Flutter complète — parcours client + artisan, gestion offline gracieux |
| **Phase 6 — Admin & Launch** | 3 – 4 semaines | Panel Admin Next.js (sous-domaine séparé), tests complets, CI/CD GitHub Actions, déploiement VPS |
| **Phase 7 — HA** | Après lancement | Warm standby PostgreSQL + MongoDB Replica Set + Redis Sentinel sur VPS secondaire |
| **Phase 8 — Extensions** | Future | Orange Money, MTN MoMo, RDV, devis en ligne, migration Docker Swarm/K8s si nécessaire |