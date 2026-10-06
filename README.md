<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/LOGO_DM.png">
    <source media="(prefers-color-scheme: light)" srcset="assets/LOGO.png">
    <img alt="SirfBill Logo" src="assets/LOGO.png" width="300">
  </picture>
  <br/>
  <h1>SirfBill POS - Manju Medical Stores & Digital Clinic</h1>
</div>

Welcome to the **SirfBill POS** application for **Manju Medical Stores & Digital Clinic**! This is a comprehensive, multi-tenant Point of Sale (POS) and inventory management system designed specifically for pharmacies, medical stores, and digital clinics.

---

## 📋 Table of Contents

- [Project Overview](#project-overview)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Environment Configuration](#environment-configuration)
- [Project Structure](#project-structure)
- [Architecture Deep Dive](#architecture-deep-dive)
  - [Layered Architecture](#layered-architecture)
- [State Management (Riverpod)](#state-management-riverpod)
- [Models Layer](#models-layer)
- [Services Layer](#services-layer)
- [Routing (GoRouter)](#routing-gorouter)
- [Theming System](#theming-system)
- [Feature Modules](#feature-modules)
  - [Multi-Tenant POS & Billing](#multi-tenant-pos--billing)
  - [Inventory & Stock Management](#inventory--stock-management)
  - [Financial Accounts & History](#financial-accounts--history)
- [Backend API Contract](#backend-api-contract)
- [Key Design Decisions](#key-design-decisions)
- [Common Gotchas](#common-gotchas)
- [Adding a New Feature](#adding-a-new-feature)
- [Contributing](#contributing)
- [License](#license)

---

## 📖 Project Overview
**SirfBill POS** (Point of Sale) is a robust, cloud-ready accounting and inventory management platform tailored specifically for the medical and pharmacy sector. Designed to replace traditional, error-prone paper billing and isolated legacy software, SirfBill provides a seamless, real-time digital solution for modern storefronts and digital clinics.

At its core, SirfBill is built with a **Multi-Tenant SaaS Architecture**. This means a single deployment of the application can securely host multiple independent shops, pharmacies, or clinics. Each tenant experiences complete data isolation—meaning their inventory, customers, financial accounts, and transaction histories are strictly segregated and protected.

### The Problem It Solves
Medical stores face unique challenges compared to standard retail:
- **Strict Compliance**: Tracking Drug Licenses, HSN codes, and GSTINs on every invoice.
- **Granular Inventory**: Managing medicines not just by name, but by specific **Batch Numbers**, **Expiry Dates**, and **Loose vs. Bulk** quantities (e.g., selling 2 tablets out of a strip of 10).
- **Invoice Formatting**: Accommodating different hardware setups, from standard A4/A5 laser printers to thermal receipt printers, with dynamic terms and conditions.

SirfBill solves these challenges by providing an intuitive, lightning-fast web interface (built with Flutter) backed by a highly secure and scalable backend (FastAPI + PostgreSQL). It empowers store owners to focus on their customers while the software handles the heavy lifting of inventory alerts, financial summaries, and professional PDF generation.

## 🛠️ Tech Stack

### Frontend Architecture
| Technology | Role | Why We Chose It |
|------------|------|-----------------|
| **Flutter Web** | Core UI Framework | Provides a unified codebase capable of compiling to a high-performance web application with a desktop-class layout. |
| **Riverpod** | State Management | Ensures compile-safe, robust state management. Crucial for handling real-time POS cart updates and caching authentication states securely. |
| **GoRouter** | Routing | Manages complex web navigation, URL parameters, and auth-guard redirects (kicking unauthenticated users back to login). |
| **Dio** | Networking | Advanced HTTP client that handles global interceptors (for Bearer tokens) and centralized error logging across the app. |
| **pdf & printing** | Invoice Generation | Allows the frontend to dynamically construct and render complex A4, A5, and Thermal PDF invoices purely in Dart, offloading computation from the backend. |

### Backend Architecture
| Technology | Role | Why We Chose It |
|------------|------|-----------------|
| **Python & FastAPI** | Core API Framework | Delivers lightning-fast RESTful APIs with automatic OpenAPI (Swagger) documentation and high async concurrency. |
| **SQLAlchemy** | ORM | Provides strict database schemas and handles complex relational joins, which is vital for maintaining complete data isolation in a multi-tenant environment. |
| **PostgreSQL** | Database | A highly reliable, ACID-compliant relational database perfect for handling transactional accounting and granular inventory tracking. |
| **JWT** | Authentication | Secures API endpoints via stateless JSON Web Tokens, ensuring users can only access their specific shop's data. |

## 📋 Prerequisites

Before you begin, ensure you have the following installed on your machine:

### Frontend
- **Flutter SDK** (`>=3.19.0` recommended): [Install Flutter](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (Bundled with Flutter)
- **Web Browser**: Google Chrome (for local testing of the web build)

### Backend & Database
- **Python** (`3.10+`): [Install Python](https://www.python.org/downloads/)
- **PostgreSQL**: [Install PostgreSQL](https://www.postgresql.org/download/) (or use a cloud provider like Supabase/Neon)

### Recommended Tools
- **IDE**: [Visual Studio Code](https://code.visualstudio.com/) or [Android Studio](https://developer.android.com/studio)
- **Extensions**: Flutter & Dart plugins for your IDE
- **API Tester**: [Postman](https://www.postman.com/) or [Insomnia](https://insomnia.rest/) (for testing FastAPI endpoints)

## 🚀 Getting Started

Follow these instructions to get a local copy up and running for development and testing.

### 1. Clone the repository
First, clone the frontend repository to your local machine:
```bash
git clone https://github.com/your-username/sirfbill-pos.git
cd sirfbill-pos
```

### 2. Set up Environment Variables
Create a `.env` file in the root of the Flutter project to point to your backend API.
```bash
touch .env
```
Add the following line to the `.env` file (replace with your local or live backend URL):
```env
API_BASE_URL=http://127.0.0.1:8000
```

### 3. Install Dependencies
Run the following command to download all required Flutter and Dart packages:
```bash
flutter pub get
```

### 4. Run the Application
Since this application is heavily optimized for web and desktop layouts, it is best tested on Chrome:
```bash
flutter run -d chrome
```

## ⚙️ Environment Configuration

The application intelligently switches between environment variables based on whether it is running in local development or deployed to production. 

### Local Development (The `.env` Fallback)
For local development, the app reads from a `.env` file using the `flutter_dotenv` package.
1. Create a `.env` file in the root directory.
2. Add your development URL: `API_BASE_URL=http://127.0.0.1:8000`.
3. Add the `.env` file to your `pubspec.yaml` assets so Flutter can read it.

### Production Deployment (The `--dart-define` Approach)
**⚠️ CRITICAL WARNING FOR FLUTTER WEB:** Web browsers aggressively cache `.env` files. If you deploy an update using a `.env` file, your users will still hit the old backend URL because their browser has cached the old text file.

To bypass this caching issue entirely, we inject the API URL directly into the compiled JavaScript at build time using the `--dart-define` flag:

```bash
# Build the web app for production
flutter build web --dart-define=API_BASE_URL=https://sirfapi.yourdomain.com
```

### How the Code Handles It
The `ApiConstants` class is set up to automatically prioritize the compile-time variable, and gracefully fall back to the `.env` file if it doesn't exist:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl {
    // 1. Try to get it from compile-time variables (Best for Production Web)
    const dartDefineUrl = String.fromEnvironment('API_BASE_URL');
    if (dartDefineUrl.isNotEmpty) {
      return dartDefineUrl;
    }
    
    // 2. Fallback to .env file (Best for Local Development)
    return dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';
  }
}
```

## 📂 Project Structure

The codebase is meticulously organized into domain-specific folders to keep the presentation (UI) cleanly separated from the business logic and API layer. Here is the comprehensive file tree:

```text
lib/
├── config/                  # Core App Configurations
│   ├── api_client.dart      # Singleton Dio instance, auth headers, and logging
│   └── api_constants.dart   # Centralized environment variables and base URLs
│
├── models/                  # Data Transfer Objects (DTOs)
│   ├── counter_models.dart  # Core POS data schemas
│   ├── crm_models.dart      # Customer and User schemas
│   ├── lab_models.dart      # Lab, bookings, and pathology models
│   └── settings_models.dart # ShopSettings (Drug License, GSTIN, Bank details)
│
├── notifiers/               # Riverpod State Notifiers (Business Logic)
│   ├── accounts_notifier.dart
│   ├── billing_notifier.dart
│   ├── category_notifier.dart
│   ├── counter_notifier.dart
│   ├── crm_notifier.dart
│   ├── customer_notifier.dart
│   ├── doctor_notifier.dart
│   ├── history_notifier.dart
│   ├── inventory_notifier.dart
│   ├── lab_notifier.dart
│   ├── rack_notifier.dart
│   └── settings_notifier.dart
│
├── providers/               # Global Riverpod Providers (Dependency Injection)
│   ├── billing_provider.dart
│   ├── counter_providers.dart
│   ├── crm_provider.dart
│   ├── crm_providers.dart
│   ├── distributor_provider.dart
│   ├── lab_providers.dart
│   └── theme_provider.dart
│
├── router/                  # Navigation & Routing
│   └── app_router.dart      # GoRouter implementation and auth guards
│
├── screens/                 # Presentation Layer (UI Pages)
│   ├── auth/                
│   │   ├── login_screen.dart
│   │   └── role_login_screen.dart
│   ├── counter/             # POS & Pharmacy Modules
│   │   ├── accounts_screen.dart
│   │   ├── add_purchase_bill_screen.dart
│   │   ├── bill_customization_screen.dart
│   │   ├── billing_history_screen.dart
│   │   ├── billing_screen.dart
│   │   ├── counter_dashboard.dart
│   │   ├── customers_screen.dart
│   │   ├── distributor_detail_screen.dart
│   │   ├── distributors_screen.dart
│   │   ├── history_screen.dart
│   │   ├── inventory_screen.dart
│   │   ├── shop_management_screen.dart
│   │   └── upload_management_screen.dart
│   │   └── widgets/         # Component-level subfolders for counter modules
│   │       ├── accounts/
│   │       ├── billing/
│   │       ├── customers/
│   │       ├── distributors/
│   │       ├── inventory/
│   │       └── shop/
│   ├── crm/                 # Digital Clinic & CRM Modules
│   │   ├── crm_appointments_screen.dart
│   │   ├── crm_dashboard.dart
│   │   ├── crm_dashboard_home.dart
│   │   ├── crm_doctors_screen.dart
│   │   ├── crm_orders_screen.dart
│   │   ├── crm_patients_screen.dart
│   │   ├── crm_payment_receipt_screen.dart
│   │   ├── crm_placeholder_screens.dart
│   │   ├── crm_prescriptions_screen.dart
│   │   └── crm_send_to_lab_screen.dart
│   ├── home/                
│   │   └── dashboard_screen.dart
│   ├── lab/                 # Pathology & Lab Modules
│   │   ├── lab_accounts_screen.dart
│   │   ├── lab_bookings_screen.dart
│   │   ├── lab_create_template_screen.dart
│   │   ├── lab_dashboard.dart
│   │   ├── lab_dashboard_home.dart
│   │   ├── lab_history_screen.dart
│   │   ├── lab_packages_screen.dart
│   │   ├── lab_reports_screen.dart
│   │   ├── lab_sample_tracking_screen.dart
│   │   ├── lab_send_reports_screen.dart
│   │   ├── lab_settings_screen.dart
│   │   ├── lab_templates_screen.dart
│   │   ├── lab_tests_screen.dart
│   │   └── widgets/
│   │       └── new_booking_modal.dart
│   └── splash/              
│       └── splash_screen.dart
│
├── services/                # API and Backend Integrations
│   ├── account_service.dart
│   ├── accounting_extended_service.dart
│   ├── auth_service.dart
│   ├── billing_history_service.dart
│   ├── billing_service.dart
│   ├── category_service.dart
│   ├── crm_data_service.dart
│   ├── customer_service.dart
│   ├── distributor_service.dart
│   ├── doctor_service.dart
│   ├── draft_service.dart
│   ├── export_service.dart
│   ├── global_search_service.dart
│   ├── inventory_service.dart
│   ├── lab_data_service.dart
│   ├── pdf_generator_service.dart
│   ├── purchase_service.dart
│   ├── rack_service.dart
│   ├── shop_service.dart
│   ├── shop_settings_service.dart
│   └── transaction_service.dart
│
├── themes/                  # Design System
│   ├── app_colors.dart      # Centralized hex color constants
│   └── app_theme.dart       # Material 3 typography and component styles
│
├── utils/                   # Helpers and Utilities
│   ├── format_utils.dart    # Currency and date formatters
│   ├── pdf_generator.dart   # Main interface for invoice creation
│   ├── pdf_a4_generator.dart# Full-page A4 format implementation
│   ├── pdf_a5_generator.dart# Half-page A5 format implementation
│   ├── pdf_thermal_generator.dart # 3-inch thermal printer implementation
│   └── responsive.dart      # Breakpoints for desktop/tablet scaling
│
├── widgets/                 # Global Reusable UI Components
│   ├── category_dropdown.dart
│   ├── custom_date_range_picker.dart
│   ├── custom_pagination.dart
│   ├── distributor_dropdown.dart
│   └── rack_dropdown.dart
│
└── main.dart                # Application entry point, initializing dotenv and ProviderScope
```

## 🏗️ Architecture Deep Dive

The application is built on a strict **Clean Layered Architecture**. This ensures that the user interface is completely decoupled from the API fetching logic and business rules, making the app highly scalable and testable.

### Data Flow Diagram

```mermaid
graph TD
    UI[🖥️ Presentation Layer<br/>(Screens, Widgets)] -->|User Action / Watch| State[🔄 State Layer<br/>(Riverpod Notifiers)]
    State -->|Calls API| Service[🌐 Service Layer<br/>(Dio API Services)]
    Service -->|Network Request| Backend[(FastAPI Backend)]
    Backend -->|JSON Response| Service
    Service -->|Parses via DTO| Models[📦 Models Layer<br/>(Dart Data Classes)]
    Models -->|Returns Typed Data| State
    State -->|Updates State| UI
```

### Layered Architecture Explained
- **Presentation Layer (`/screens`, `/widgets`)**: Contains all UI elements. It handles user inputs (like scanning a barcode) and passes the action to the Riverpod Notifiers. It has *zero* knowledge of APIs or HTTP requests.
- **State Layer (`/notifiers`, `/providers`)**: Built entirely on Riverpod. It holds the active state (e.g., current items in the billing cart). When it needs new data, it calls the Service layer, waits for the response, updates itself, and triggers a UI rebuild automatically.
- **Service Layer (`/services`)**: The only layer allowed to communicate with the outside world. All classes here use the centralized `ApiClient` (Dio) to perform HTTP GET/POST requests and handle 401/500 status codes globally.
- **Data Layer (`/models`)**: Acts as the strict contract between the frontend and the FastAPI backend. Every JSON response from the Service layer is mapped tightly to a strongly-typed Dart class to prevent runtime crashes caused by typos or missing keys.

## 🔄 State Management (Riverpod)
We use **Riverpod** for robust, compile-safe state management across the entire application. It eliminates the need for `StatefulWidget` in most cases and guarantees UI consistency.

### Provider ↔ Notifier Pattern
To keep business logic strictly separated from the UI, we implement the `NotifierProvider` pattern:
1. **State Class**: A class defining the data (e.g., `BillingState`).
2. **Notifier**: A class containing the actual business logic functions (`addItemToCart()`). It mutates the state.
3. **Provider**: The global entry point that the UI listens to using `ref.watch()`.

### Code Example:
```dart
// 1. The State
class CartState {
  final List<CartItem> items;
  final bool isLoading;
  CartState({required this.items, this.isLoading = false});
}

// 2. The Notifier (Business Logic)
class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(CartState(items: []));

  void addItem(CartItem item) {
    state = CartState(items: [...state.items, item]); // Triggers UI Rebuild
  }
}

// 3. The Global Provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
```

**Key areas Riverpod manages:**
- Caching the JWT Authentication Token securely.
- Maintaining the globally selected `tenant_id` so the user doesn't have to select their shop on every screen.
- Real-time updates for cart items during POS checkout without freezing the main thread.

## 📦 Models Layer
Models act as the single source of truth for JSON serialization and deserialization. By keeping this logic strictly in the `/models` directory, the rest of the application (like UI and Services) never has to touch raw JSON Maps.

- **FastAPI Sync**: They strictly map to the backend Pydantic schemas to prevent typing errors. If a field is `Optional` in Python, it must be `?` (nullable) in Dart.
- **Strict Factories**: We use Dart factory constructors to safely parse data coming from the API, preventing null-reference crashes.

### Code Example:
```dart
class TransactionModel {
  final int id;
  final double amount;
  final String? description; // Maps to Optional[str] in FastAPI

  TransactionModel({
    required this.id,
    required this.amount,
    this.description,
  });

  // Safely parse from backend JSON
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] ?? 0,
      amount: (json['amount'] ?? 0.0).toDouble(),
      description: json['description'], // Can be null
    );
  }

  // Convert to JSON for POST requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'description': description,
    };
  }
}
```

## 🔌 Services Layer

### API Service (`Dio`)
The backbone of our network layer is the custom `ApiClient` singleton. It configures `Dio` with:
- **Base URLs**: Fetched dynamically via `ApiConstants`.
- **Global Timeouts**: Prevents the UI from hanging if the backend server is asleep.
- **Auth Interceptors**: Automatically injects the `Authorization: Bearer <token>` header into every outbound request.
- **Global Error Handling**: Catches 401 Unauthorized errors globally and kicks the user back to the login screen if their token expires.

Specific domain services (e.g., `TransactionService`, `InventoryService`) simply call `apiClient.dio.get(...)` and map the raw JSON lists into strict Dart `Models`.

### Code Example:
```dart
import 'package:dio/dio.dart';
import '../config/api_client.dart';
import '../models/inventory_models.dart';

class InventoryService {
  final ApiClient _apiClient = ApiClient(); // Singleton instance

  Future<List<InventoryItem>> fetchInventory(String shopId) async {
    try {
      // 1. Make the network call (Auth headers are injected automatically by ApiClient)
      final response = await _apiClient.dio.get('/inventory', queryParameters: {
        'shop_id': shopId,
      });
      
      // 2. Parse the JSON list into strictly typed Dart Models
      if (response.data is List) {
        return (response.data as List)
            .map((item) => InventoryItem.fromJson(item))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      // 3. Centralized error handling
      throw Exception('Failed to load inventory: ${e.message}');
    }
  }
}
```

## 🛣️ Routing (GoRouter)
Routing is managed by the official **`GoRouter`** package. Since SirfBill is a web-first platform, handling URLs correctly is critical.

### Why GoRouter?
- **Web Deep Linking**: Users can bookmark specific pages (e.g., `https://bill.naiyo24.com/dashboard/billing`) and GoRouter instantly resolves the correct screen.
- **Auth Guards**: GoRouter acts as our bouncer. If a user tries to access a protected route (like `/inventory`) without a valid JWT token, the router intercepts the request and instantly redirects them to the `/login` screen.

### Code Example:
```dart
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      // 1. Check Auth State via Riverpod
      final isAuthenticated = ref.read(authProvider).token != null;
      final isGoingToLogin = state.matchedLocation == '/login';

      // 2. Auth Guards
      if (!isAuthenticated && !isGoingToLogin) {
        return '/login'; // Kick to login if not authenticated
      }
      if (isAuthenticated && isGoingToLogin) {
        return '/dashboard'; // Skip login if already authenticated
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      // Nested Routes...
    ],
  );
});
```

## 🎨 Theming System
The app uses a unified, centralized **Material 3** `ThemeData` configuration located in `lib/themes/`. 

To maintain a consistent, medical-appropriate aesthetic across the entire platform, we strictly enforce the following patterns:
- **`AppColors`**: A dedicated class holding all hex values (Primary Greens, Secondary Blues, Error Reds, and Surface grays). Developers should *never* hardcode hex values directly into UI widgets.
- **`AppTheme`**: Defines the global `ThemeData`. This automatically styles all `ElevatedButton`, `TextFormField`, and `Card` widgets across the app so they look identical without needing custom styling on every page.
- **Typography**: We heavily rely on **Google Fonts** (specifically clean sans-serif fonts) implemented directly within the `AppTheme` text themes.

### Code Example:
```dart
// lib/themes/app_colors.dart
class AppColors {
  static const Color primary = Color(0xFF2E7D32); // Medical Green
  static const Color surface = Color(0xFFFFFFFF);
  static const Color error = Color(0xFFD32F2F);
}

// Accessing the theme in UI
Container(
  color: Theme.of(context).colorScheme.primary, // Do this!
  // color: Colors.green, // DON'T DO THIS!
)
```

## 🧩 Feature Modules

### 🛒 Multi-Tenant POS & Billing
The billing screen is the highest-traffic module in the application. It provides a lightning-fast checkout experience optimized specifically for pharmacy and clinic workflows.

#### Tenant Isolation
To support the SaaS model, the frontend NEVER assumes the shop context. Instead:
- The currently active `shop_id` and `tenant_id` are stored globally in Riverpod (`authProvider`).
- Every single API call (fetching inventory, saving a bill) forcefully injects this `shop_id` into the query parameters.
- The FastAPI backend validates this ID against the user's JWT token to ensure they cannot read or write data to another tenant's shop.

#### Dynamic Invoice Generation
We generate rich PDF invoices (A4, A5, and Thermal) entirely on the client-side using the `pdf` and `printing` packages. This offloads expensive PDF generation from the backend server.

**Code Example:**
```dart
// Fetch shop settings (Bank details, Drug License, Logo)
final settings = ref.read(settingsProvider);

// Generate an A5 PDF dynamically in Dart
final pdfBytes = await PdfA5Generator.generateA5Bill(
  bill: currentBill,
  shopSettings: settings,
  drugLicence: settings.drugLicense,
  bankName: settings.bankName,
  acNumber: settings.acNumber,
  ifsc: settings.ifsc,
);

// Preview or Print directly from the browser
await Printing.layoutPdf(
  onLayout: (PdfPageFormat format) async => pdfBytes,
);
```

### 📦 Inventory & Stock Management
A granular stock tracking system that moves far beyond simple retail inventory, handling the exact complexities required by pharmacies.

- **Medical Specifics**: Detailed tracking of **Batch Numbers**, **Expiry Dates**, HSN Codes, and MRP.
- **Loose Items Mathematics**: Supports selling 2 tablets out of a 10-tablet strip without breaking the inventory math. The system calculates base prices per unit and aggregates them accurately in the cart.
- **Duplicate Name Handling**: The backend database deliberately avoids `unique=True` constraints on medicine names. This allows a pharmacy to stock the exact same medicine "Paracetamol 500mg" but with different batch numbers, expiry dates, or distributors.
- **Real-time Search & Alerts**: The `InventoryScreen` uses a `TextEditingController` combined with a Riverpod provider to instantly filter thousands of items locally on the client-side, while visually flagging items that are running out of stock.

**Code Example:**
```dart
// Filtering inventory based on search query dynamically
final filteredInventoryProvider = Provider<List<InventoryItem>>((ref) {
  final allItems = ref.watch(inventoryProvider).items;
  final searchQuery = ref.watch(inventorySearchQueryProvider).toLowerCase();

  if (searchQuery.isEmpty) return allItems;

  return allItems.where((item) {
    return item.name.toLowerCase().contains(searchQuery) ||
           item.batchNumber.toLowerCase().contains(searchQuery);
  }).toList();
});
```

### 💰 Financial Accounts & History
The financial module replaces the physical ledger book with automated, real-time calculations. It acts as the single source of truth for the shop's financial health.

- **Immutable Transaction Ledger**: Every single sale, expense, supplier payment, or customer refund generates an immutable transaction record. These records are strictly linked to the `tenant_id` and categorized (e.g., 'SALE', 'PURCHASE', 'EXPENSE').
- **Live Aggregation**: The frontend dynamically aggregates these transaction records to instantly calculate `Cash in Hand`, `Total Income`, `Total Expenses`, and `Net Profit` for the active day or month.
- **Data Integrity**: By relying on an append-only transaction ledger, the system prevents silent data manipulation and guarantees that the "Cash in Drawer" value is always mathematically provable.

**Code Example:**
```dart
// Aggregating transaction history locally to build the financial summary
final accountSummaryProvider = Provider<AccountSummary>((ref) {
  final transactions = ref.watch(transactionListProvider).data ?? [];
  
  double totalIncome = 0;
  double totalExpense = 0;

  for (var tx in transactions) {
    if (tx.type == TransactionType.income) {
      totalIncome += tx.amount;
    } else if (tx.type == TransactionType.expense) {
      totalExpense += tx.amount;
    }
  }

  return AccountSummary(
    totalIncome: totalIncome,
    totalExpense: totalExpense,
    netProfit: totalIncome - totalExpense,
  );
});
```

### 🏥 Digital Clinic (CRM)
A dedicated module for managing patient and doctor relationships.
- **Doctor Management**: Track visiting doctors and their schedules.
- **Prescription Uploads**: Digitize and store patient prescriptions.
- **Appointments**: Schedule and track patient visits.

### 🔬 Pathology & Lab Management
An integrated solution for managing diagnostic tests.
- **Test Booking**: Book lab tests directly from the POS.
- **Sample Tracking**: Track the status of diagnostic samples.
- **Report Generation**: Deliver final pathology reports to the patient digitally.

## 🔌 Backend API Contract
The Flutter app interacts with a Python **FastAPI** backend via standard RESTful JSON endpoints. 

### Core Principles
- **Stateless Authentication**: The backend does not maintain sessions. The frontend must pass the JWT token (acquired during login) in the `Authorization: Bearer <token>` header for every protected request.
- **Strict Multi-Tenancy**: The backend heavily utilizes SQLAlchemy. Before executing any `SELECT`, `INSERT`, or `UPDATE` query, the backend filters the operation by the `tenant_id` associated with the JWT token. If a user attempts to fetch a `shop_id` that does not belong to their `tenant_id`, the backend immediately rejects the request.

### Common HTTP Status Codes
The Flutter `ApiClient` is designed to handle these specific backend responses:
- `200 OK` / `201 Created`: Request succeeded. Data is parsed into Dart Models.
- `400 Bad Request`: Usually indicates a validation error (e.g., missing a required field like Batch Number).
- `401 Unauthorized`: The JWT token has expired or is invalid. The `ApiClient` interceptor catches this and instantly kicks the user back to the `/login` screen.
- `404 Not Found`: The requested resource (e.g., a specific transaction ID) does not exist or belongs to a different tenant.
- `500 Internal Server Error`: An unhandled exception occurred on the FastAPI server.

## 🧠 Key Design Decisions

Throughout the development of SirfBill, several architectural choices were made to prioritize speed, scalability, and developer experience.

### 1. Client-Side PDF Generation
Rather than pushing JSON to the backend, rendering a PDF via Python, and downloading it (which requires heavy server CPU and causes latency), **all invoice PDFs are generated directly in Dart on the user's device**. 
- **Benefit**: Zero server cost for PDF rendering, instant generation for the user, and full offline preview capabilities using the `printing` package.

### 2. Singleton `ApiClient`
Instead of passing HTTP clients into every service constructor or relying on complex dependency injection for network calls, `ApiClient` is implemented as a Dart Singleton.
- **Benefit**: It guarantees that Auth Interceptors (which attach the JWT token) and global error catchers (which kick users out on 401 Unauthorized) are initialized exactly once and applied universally across the app.

### 3. Separation of Models and Logic
Dart classes inside `/models` are strictly data classes (DTOs) with `fromJson` and `toJson` methods. They contain absolutely zero business logic.
- **Benefit**: If the backend API changes a field name, the developer only has to update one file in `/models`, rather than hunting down UI bugs across a dozen different screens.

### 4. Banning `StatefulWidget` (Mostly)
By relying heavily on Riverpod `ConsumerWidget`, we have virtually eliminated `StatefulWidget` from the codebase (except for complex local animations).
- **Benefit**: No more `setState()` spaghetti code. UI strictly reacts to the State Layer, meaning it is impossible for the UI to show out-of-sync data.

## ⚠️ Common Gotchas (Troubleshooting)

If you run into bugs while developing or deploying SirfBill, check these common pitfalls first:

### 1. Flutter Web Deployment & Caching (`.env` issues)
Browsers heavily cache Flutter Web `main.dart.js` and static asset files (like `.env`). If you deploy an update but the live site (`bill.naiyo24.com`) is still trying to hit an old API IP address:
- **Do not** rely solely on `.env` files for production URLs.
- **Fix**: You must pass the API URL at compile time using Dart Defines. This forces the Flutter engine to bake the URL into the binary, bypassing the browser's static asset cache.
```bash
# Correct way to build for production web
flutter build web --dart-define=API_BASE_URL=https://sirfapi.vwings247.me
```

### 2. "Already Exists" Database Errors
If you try to add an item or category and get a `400 Bad Request` saying it already exists, remember that **multi-tenancy applies to names too**. 
- Previously, the backend had a global `unique=True` constraint on names. This was removed so multiple tenants could use the same names. 
- However, if you get this error *within* the same `tenant_id`, you must differentiate the item by giving it a unique **Batch Number** or **Category Name**.

### 3. Account Summary Shows "0"
If the `AccountSummaryModel` is returning `0.0` for `total_income` despite there being transactions:
- **Fix**: Check if the backend SQL query is accidentally filtering by `shop_id` when it should be aggregating across all shops for a given `tenant_id`, or vice versa. Always double check which ID the Service layer is passing.

## ➕ Adding a New Feature

Because of the strict Clean Architecture, adding a new feature (like an "Employee Attendance" module) requires following a specific sequence. Do not skip steps or mix layers!

### Step 1: The Model (`/models`)
Always start with the data contract. Create a new Dart file (e.g., `attendance_model.dart`). Define your fields, ensuring they exactly match the FastAPI Pydantic schema. Write the `fromJson` factory and `toJson` method.

### Step 2: The Service (`/services`)
Create the network layer (e.g., `AttendanceService`). Instantiate the `ApiClient` singleton. Write your `Future` methods to handle GET, POST, PUT, and DELETE operations. Map the `response.data` directly into the Model you built in Step 1.

### Step 3: The Notifier/Provider (`/notifiers` or `/providers`)
Create the State layer (e.g., `AttendanceNotifier`). It should take the Service from Step 2 as a dependency. Write functions that call the service and mutate the local state (e.g., `markPresent()`). Finally, expose it globally using a `StateNotifierProvider`.

### Step 4: The UI (`/screens` and `/widgets`)
Build your UI using `ConsumerWidget` instead of `StatefulWidget`. Use `ref.watch(attendanceProvider)` to read the data, and `ref.read(attendanceProvider.notifier).markPresent()` to trigger actions. Ensure you use colors from `AppTheme`!

### Step 5: The Route (`router.dart`)
Finally, map your new screen in `GoRouter`. If the screen requires the user to be logged in, make sure it sits behind the Auth Guard redirect logic.

## 🤝 Contributing
Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make to SirfBill are **greatly appreciated**.

### Coding Standards
Before submitting a pull request, please ensure:
- Your code follows the **Clean Layered Architecture** detailed above (no business logic in the UI!).
- You have not added any `StatefulWidget` unless absolutely necessary (use `ConsumerWidget`).
- You have run `flutter format .` to format your Dart code.
- You have checked for linter warnings using `flutter analyze`.

### Contribution Steps
1. Fork the Project.
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`).
3. Commit your Changes using descriptive commit messages (`git commit -m 'feat: Add Awesome Feature'`).
4. Push to the Branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request detailing what you changed and why.

## 📄 License

This software is developed exclusively for **Manju Medical Stores & Digital Clinic**. 

- **Proprietary Software**: The codebase, UI designs, and architectural patterns within this repository are proprietary. Unauthorized copying, distribution, or modification of this software without explicit permission is strictly prohibited.
- **Third-Party Libraries**: SirfBill utilizes several open-source packages (e.g., Riverpod, Dio, GoRouter, pdf). These packages remain under their respective licenses (MIT, Apache, etc.). Please see the `pubspec.yaml` file for a full list of dependencies.

---
<div align="center">
  <p>Built with ❤️ for pharmacies and digital clinics everywhere.</p>
</div>
