# 🛍️ Mehal Gebeya — Premium Ethiopian E-Commerce

Mehal Gebeya is a high-performance, modern e-commerce application designed specifically for the Ethiopian market. Built with **Flutter** and powered by **Supabase**, it delivers a seamless shopping experience for local users, featuring professional product displays, secure authentication, and a robust administrative backend.

---

## ✨ Key Features

### 🛒 For Customers
*   **Dual Authentication**: Secure login via Supabase Auth and Firebase integration.
*   **Discovery**: Browse diverse categories such as Traditional Clothing, Food, Jewelry, and Handcrafts.
*   **Personalization**: Persistent favorites/wishlist, dark/light mode preferences, and multi-address management.
*   **Smart Cart & Orders**: Real-time cart updates and detailed order tracking with PDF receipt generation.
*   **Localized Payments**: Integrated support for local payment methods (CBE, Telebirr, Chapa).

### 🛡️ For Admins
*   **Modern Dashboard**: Comprehensive analytics and management tools.
*   **Resource Management**: Full CRUD operations for products and categories.
*   **Auditability**: Complete audit logging for critical administrative actions.
*   **Order Fulfillment**: Real-time order management and status tracking.

---

## 🛠️ Technology Stack

| Layer | Technology |
| :--- | :--- |
| **Frontend** | [Flutter 3.x](https://flutter.dev) (Responsive Web & Mobile) |
| **Backend** | [Supabase](https://supabase.com) (Auth, Database, Storage) |
| **State Management** | [Provider](https://pub.dev/packages/provider) |
| **Storage** | Supabase Storage (Avatars, Product Images) |
| **Security** | PostgreSQL Row Level Security (RLS) |
| **Reports** | [PDF Package](https://pub.dev/packages/pdf) for Receipts |

---

## 🏛️ Database Schema

Mehal Gebeya uses a highly relational PostgreSQL schema optimized for e-commerce performance and security.

### 📊 Entity Relationship Diagram

```mermaid
erDiagram
    AUTH_USERS ||--|| USERS : "synced by trigger"
    USERS ||--o{ ORDERS : "places"
    USERS ||--o{ USER_ADDRESSES : "has"
    USERS ||--o{ NOTIFICATIONS : "receives"
    USERS ||--o{ PRODUCT_REVIEWS : "writes"
    USERS ||--o{ WISHLIST : "saves"
    USERS ||--o| CARTS : "owns"

    CATEGORIES ||--o{ PRODUCTS : "contains"
    PRODUCTS ||--o{ ORDER_ITEMS : "included in"
    PRODUCTS ||--o{ WISHLIST : "added to"
    PRODUCTS ||--o{ PRODUCT_REVIEWS : "reviewed in"

    ORDERS ||--|{ ORDER_ITEMS : "consists of"
    ORDERS ||--o| PAYMENTS : "paid by"
    ORDERS ||--o{ NOTIFICATIONS : "triggers"
    USER_ADDRESSES ||--o{ ORDERS : "shipping destination"

    USERS ||--o{ AUDIT_LOGS : "acts as"
    ORDERS ||--o{ AUDIT_LOGS : "logged for"

    AUTH_USERS {
        uuid id PK
        text email
        jsonb raw_user_meta_data
        timestamp created_at
    }

    USERS {
        uuid id PK "FK to auth.users"
        text email
        text full_name
        bool is_admin
        text role
        text avatar_url
        timestamp created_at
    }

    PRODUCTS {
        uuid id PK
        text name
        text description
        numeric price
        uuid category_id FK
        bool is_sold
        int stock
        jsonb image_urls
    }

    CATEGORIES {
        uuid id PK
        text name
        text icon
        timestamp created_at
    }

    ORDERS {
        uuid id PK
        uuid user_id FK
        text status
        numeric total
        uuid address_id FK
        jsonb shipping_address
        timestamp created_at
    }

    ORDER_ITEMS {
        uuid id PK
        uuid order_id FK
        uuid product_id FK
        integer quantity
        numeric price
    }

    USER_ADDRESSES {
        uuid id PK
        uuid user_id FK
        text label
        text address_line1
        text city
        text state
        text phone
    }

    NOTIFICATIONS {
        uuid id PK
        uuid user_id FK
        uuid order_id FK
        text type
        text message
        bool is_read
    }

    PRODUCT_REVIEWS {
        uuid id PK
        uuid product_id FK
        uuid user_id FK
        integer rating
        text review
    }

    WISHLIST {
        uuid id PK
        uuid user_id FK
        uuid product_id FK
    }

    PAYMENTS {
        uuid id PK
        uuid order_id FK
        uuid user_id FK
        text method
        numeric amount
        text status
    }

    CARTS {
        uuid user_id PK
        jsonb items
        timestamp updated_at
    }

    AUDIT_LOGS {
        uuid id PK
        text action
        uuid actor_id FK
        uuid order_id FK
        text details
        timestamp timestamp
    }
```

### 🔄 Auto-Sync Trigger: `auth.users` → `public.users`

Every signup (email/password **or** Google OAuth) automatically creates a matching row in `public.users` via a PostgreSQL trigger:

```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.users (id, email, full_name, avatar_url, created_at, is_admin)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', ''),
    NOW(),
    FALSE
  )
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();
```

> **One-time backfill** — to sync existing auth users who predate the trigger:
> ```sql
> INSERT INTO public.users (id, email, full_name, avatar_url, created_at, is_admin)
> SELECT id, email,
>   COALESCE(raw_user_meta_data->>'full_name', raw_user_meta_data->>'name', ''),
>   COALESCE(raw_user_meta_data->>'avatar_url', raw_user_meta_data->>'picture', ''),
>   created_at, FALSE
> FROM auth.users
> WHERE id NOT IN (SELECT id FROM public.users);
> ```

### ⚡ Instant Login (Without Email Confirmation Link)

To allow users to register and sign in immediately without needing to click an email confirmation link:

**Method 1: Supabase Dashboard Toggle (Recommended)**
1. In the [Supabase Dashboard](https://supabase.com/dashboard), go to **Authentication** -> **Providers** -> **Email**.
2. Turn **OFF** the toggle for **Confirm email**.
3. Click **Save**.

**Method 2: Auto-Confirm SQL Trigger**
Run this in the **Supabase SQL Editor**:
```sql
-- 1. Confirm all existing users immediately
UPDATE auth.users
SET email_confirmed_at = NOW()
WHERE email_confirmed_at IS NULL;

-- 2. Automatically mark future signups as confirmed
CREATE OR REPLACE FUNCTION public.auto_confirm_user()
RETURNS trigger AS $$
BEGIN
  NEW.email_confirmed_at = COALESCE(NEW.email_confirmed_at, NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_auto_confirm ON auth.users;
CREATE TRIGGER on_auth_user_auto_confirm
  BEFORE INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.auto_confirm_user();
```

---

## 🚀 Getting Started

### Prerequisites
*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (>= 3.0.0)
*   [Supabase Account](https://supabase.com/)

### Installation

1.  **Clone & Fetch Dependencies**
    ```bash
    git clone [repository-url]
    cd mehal_gebeya
    flutter pub get
    ```

2.  **Configure Environment Variables**
    Create a file at `assets/.env` and add your credentials:
    ```env
    SUPABASE_URL=https://your-project-ref.supabase.co
    SUPABASE_ANON_KEY=your-anon-key
    ```
    *Ensure `assets/.env` is included in your `pubspec.yaml`.*

3.  **Database Setup**
    *   Run the provided `supabase_setup.sql` in your Supabase SQL Editor to create tables.
    *   **CRITICAL**: Run `policy.sql` to apply the secure Row Level Security rules.

4.  **Run the Application**
    ```bash
    flutter run
    ```

---

## 📦 Build & Release

### 📱 Android (APK)
To generate a release build for Android devices:
```bash
flutter build apk --release
```
The output file can be found at: `build/app/outputs/flutter-apk/app-release.apk`

### 🌐 Web
To build the application for hosting on a web server:
```bash
flutter build web --release --base-href "/"
```
The production-ready files will be located in the `build/web/` directory.

---

## 🔒 Database & Security (RLS)

This project uses **PostgreSQL Row Level Security** to ensure data integrity. 
*   **User Privacy**: Users can only access their own profiles, addresses, and orders.
*   **Content Safety**: Only authenticated admins have permission to update products or categories.
*   **Public Access**: Product catalogs and reviews are publicly viewable for maximum conversion.

To re-apply or update security rules, refer to [policy.sql](policy.sql).

---

## 📁 Folder Structure

```text
lib/
├── models/         # Data structures (Order, Product, User)
├── providers/      # State management (Cart, Theme, Auth)
├── screens/        # UI Layers (Auth, Profile, Admin, Shop)
├── services/       # External APIs (Supabase, PDF Export)
├── widgets/        # Reusable UI components
└── main.dart       # App entry & Routing
```

---

## 🔧 Troubleshooting

### ☕ JAVA_HOME / Gradle Errors
If you encounter `JAVA_HOME is set to an invalid directory` when running on Android:
1.  **Direct Flutter Config** (Recommended):
    ```powershell
    flutter config --jdk-dir "C:\Program Files\Eclipse Adoptium\jdk-17.x.x-hotspot"
    ```
2.  **System Environment**:
    Ensure your `JAVA_HOME` environment variable points to a valid JDK path and restart your terminal.

### 🛠️ Persistent Build Errors (Exit 1)
If the build fails unexpectedly after environment changes:
1.  **Clean the project**: `flutter clean`
2.  **Fetch dependencies**: `flutter pub get`
3.  **Run again**: `flutter run`
4.  **Run on web**: flutter run -d chrome --web-port=3000

*Note: If errors persist, try closing any programs that might be locking files (like Antivirus or indexing tools).*

---

## 🎨 Theming

The app supports a premium Dark Mode. Preferences are automatically saved using `SharedPreferences`. Toggle the theme in **Settings > Appearance**.

---

## 📄 License

This project is licensed under the MIT License.
