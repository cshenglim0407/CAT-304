# Cashlytics - Smart Financial Tracking Application

A localised mobile financial management application integrating OCR and AI to simplify expense tracking and provide intelligent spending insights.

## Quick Start

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK (included with Flutter)
- Android Studio / Xcode (for emulator/device)
- Git

### Running the Application

#### 1. Setup Environment Variables (First Time Only)
Follow the [Environment Configuration](#environment-configuration) section below to set up all required credentials and configuration files.

#### 2. Install Dependencies
```bash
cd mobile
flutter pub get
```

#### 3. Run on Emulator or Device
```bash
# Run on connected device or emulator
flutter run

# Run with a specific device
flutter run -d <device_id>

# Run in release mode (optimized)
flutter run --release
```

#### 4. Build APK (Android)
```bash
# Build APK in debug mode
flutter build apk --debug

# Build APK in release mode
flutter build apk --release

# Build split APKs by ABI (smaller file sizes)
flutter build apk --split-per-abi --release
```

#### 5. Build for iOS
```bash
# Build iOS app (Xcode is required)
flutter build ipa
```

#### 6. Code Analysis
```bash
flutter analyze
```

---

## Environment Configuration

Refer to [mobile/assets/env/.env.example](mobile/assets/env/.env.example), create 4 files:
- [mobile/assets/env/.env](mobile/assets/env/.env)
- [mobile/assets/env/.env.local](mobile/assets/env/.env.local)
- [mobile/assets/env/.env.development](mobile/assets/env/.env.development)
- [mobile/assets/env/.env.production](mobile/assets/env/.env.production)

Append this to [mobile/android/local.properties](mobile/android/local.properties):
```
# Facebook OAuth
FACEBOOK_APP_ID=xxx
FACEBOOK_CLIENT_TOKEN=xxx
FACEBOOK_DISPLAY_NAME=Cashlytics
```

Create [mobile/ios/Flutter/Secrets.xcconfig](mobile/ios/Flutter/Secrets.xcconfig) and paste this:
```
# Google Client ID
GOOGLE_CLIENT_ID=com.googleusercontent.apps.xxx

# Facebook OAuth
FACEBOOK_APP_ID=xxx
FACEBOOK_CLIENT_TOKEN=xxx
FACEBOOK_DISPLAY_NAME=Cashlytics
```

---

## Project Overview

### Abstract
Managing personal finances has become increasingly challenging in today's cashless and fast-paced lifestyle. Many existing budgeting applications provide only basic features and often lack automation, intuitive design, and local relevance, leading to poor user engagement and limited financial awareness. To address this, Cashlytics is proposed as a localised smart financial tracking application that integrates Optical Character Recognition (OCR) and Artificial Intelligence (AI) to simplify expense recording, provide spending insights, and promote better budgeting habits. Cashlytics aims to encourage responsible spending behaviour aligned with Sustainable Development Goal (SDG) 12: Responsible Consumption and Production, ultimately helping users build long-term financial discipline through smarter, data-driven decision-making.

### Introduction

#### Project Background
In today's fast-paced digital world, financial management has become an essential life skill for individuals of all backgrounds, especially young adults and university students who are beginning to handle their own finances. However, despite the availability of numerous budgeting applications, many users still find it difficult to effectively track their expenses and maintain financial discipline. Most existing financial tracking applications are either overly complex, lack user-friendly interfaces, or do not provide meaningful insights that can help users make informed spending decisions.

To address these issues, the Cashlytics mobile application is proposed as a localised innovative solution that combines simplicity, automation, and intelligence in financial management. Cashlytics enables users to record their income and expenses efficiently while leveraging modern technologies such as OCR and AI to provide more engaging and personalized budgeting insights such as financial health score and advice. Through visual analytics such as pie charts, line charts, and summary dashboards, users can better understand their spending patterns and financial health.

Furthermore, the application supports the goals of United Nations SDG 12: Responsible Consumption and Production, which emphasises sustainable and mindful use of resources. By encouraging users to monitor and control their spending, Cashlytics promotes responsible financial behaviour that aligns with sustainable lifestyle practices. Ultimately, this project aims to develop an intuitive, data-driven, and impactful mobile application that helps individuals achieve greater financial awareness and stability in their daily lives.

#### Problem Statement
Effective personal financial management remains a significant challenge in Malaysia, especially among young adults. A recent survey by UCSI University revealed that 73% of Malaysians aged 18 to 40 are currently in debt, while data from the Ministry of Finance reported that over 53,000 individuals under 30 collectively owe nearly RM1.9 billion. In addition, Malaysia's household debt has reached 84.3% of GDP as of March 2025, totalling approximately RM1.65 trillion, one of the highest ratios in the region. These figures highlight an urgent need for improved financial literacy and better personal budgeting tools to help individuals make informed spending decisions.

These figures have pointed to two critical issues. First, low financial literacy and awareness—only 36% of Malaysians reportedly understand basic financial concepts, putting them at risk of financial mismanagement. Second, inadequate tools for budget tracking and financial insight—many existing apps require manual entry, are not culturally localised, or don't provide actionable insights. This leads to disengagement, abandoned usage, and missed opportunities for financial improvement.

Despite the availability of various financial management applications such as Spendee, Wallet by BudgetBakers, and Frollo, many users still struggle to develop consistent budgeting habits. Existing apps often suffer from complex user interfaces, slow performance, and a lack of localisation for Malaysian users. Moreover, most rely heavily on manual data entry, which discourages long-term engagement. Many also fail to offer intelligent insights or real-time analysis, causing users to lose interest quickly or fail to act on their spending data.

As a result, young Malaysians often find themselves unaware of how small, frequent expenses accumulate into significant financial strain. This leads to overspending, difficulty saving, and eventually, unsustainable consumption patterns. These issues contradict the principles of SDG 12: Responsible Consumption and Production, which emphasises the need for individuals to use resources efficiently and sustainably. Therefore, there is a clear need for a smart, user-friendly, and locally adapted financial application that not only tracks expenses but also provides AI-driven insights and behavioural feedback to encourage responsible financial management among Malaysians.

### Description
Cashlytics is a mobile application designed to help users take control of their personal finances with ease. It offers essential features such as account and wallet management, income and expense tracking, and customizable budget and threshold settings.

Beyond the basics, Cashlytics stands out by integrating advanced technologies, including AI-driven financial insights and OCR-based automatic transaction recording, to simplify financial planning and provide smarter, data-driven recommendations for better money management.

The app is developed around five main modules: User Authentication and Profile Management Module, Income and Expense Management Module, Budget and Threshold Module, Expense Entry and OCR Module, and AI Financial Health Score and Insights Module.

#### Core Modules

**User Authentication and Profile Management Module**

  This module consists of three sub-modules: User Registration, User Authentication, and Profile Management. User Registration sub-module enables users to securely create and access their accounts using email and phone number verification combined with password-based authentication.

  To enhance security and usability, the system also supports Open Authentication (OAuth), OAuth-based authentication through trusted third-party providers such as Google and Facebook, ensuring secure access while safeguarding sensitive financial records. The Profile Management sub-module allows users to update personal information, manage account credentials, and change passwords, ensuring that user data remains accurate, secure, and up to date.

**Income and Expenses Management Module**

  This module is responsible for managing users' financial transactions and account records. It consists of three sub-modules: Wallet and Account Management, View and Filter Transactions, and Transaction Database Integration.

  Through the Wallet and Account Management sub-module, users can manage multiple financial sources such as bank accounts, e-wallets, cash-on-hand, and credit or debit cards. The View and Filter Transactions sub-module enables users to browse, search, and filter transaction records based on criteria such as date, category, or account type, providing clear visibility into income and spending activities. All transaction data is handled through the Transaction Database Integration sub-module, ensuring secure storage, efficient retrieval, and consistency across the system. This structured integration supports accurate financial tracking and forms the foundation for budgeting and AI-driven analysis.

**Budget and Threshold Module**

  The Budget and Threshold Module helps users plan and monitor their spending behavior effectively. It consists of two sub-modules: Set Monthly Budget and View Budget Tracking Status.

  The Set Monthly Budget sub-module allows users to define personalized monthly spending limits based on their financial goals and preferences. These budgets can be assigned across different spending categories to encourage better allocation of resources. The View Budget Tracking Status sub-module provides real-time insights into budget utilization, allowing users to monitor remaining balances and spending progress throughout the month. This module promotes financial awareness and supports disciplined spending habits by giving users a clear overview of their budget performance.

**Expense Entry and OCR Module**

  The Expense Entry and OCR Module facilitates efficient and accurate expense recording. It consists of three sub-modules: Camera Capture and Image Storage, Text Extraction and Categorization, and Expense Entry Management.

  Users can manually record expenses through the Expense Entry Management sub-module by entering transaction details and assigning appropriate categories such as food, transportation, or entertainment. In addition, users may capture receipt images using their device camera via the Camera Capture and Image Storage sub-module. The captured receipts are processed using OCR in the Text Extraction and Categorization sub-module, which automatically extracts relevant transaction details such as date, amount, and merchant name. The system then categorizes the expense accordingly, reducing manual input and improving data accuracy. This module serves as a key differentiating feature of Cashlytics.

**AI Financial Health Score and Insights Module**

  This module provides intelligent financial analysis and personalized insights. It comprises three sub-modules: Health Score Calculation, Personalized Suggestions, and Monthly Report Generation.

  The Health Score Calculation sub-module analyzes user income patterns, spending behavior, and expense distribution to generate a comprehensive Financial Health Score that reflects overall financial stability. Based on this score and observed trends, the Personalized Suggestions sub-module offers tailored recommendations to help users improve saving habits and optimize spending. The Monthly Report Generation sub-module produces periodic summaries highlighting key financial trends, budget performance, and improvement areas. Together, these sub-modules empower users with actionable insights to make informed and sustainable financial decisions.

### Key Unique Aspects

  Cashlytics distinguishes itself from existing financial budgeting applications through a combination of local adaptation, AI integration, and interactive data visualisation. Unlike many global apps that focus on generic financial management, Cashlytics is designed with Malaysian users and lifestyle patterns in mind.

  - **Localised AI-Driven Financial Insights and Health Scoring**: Cashlytics introduces a personal Financial Health Score that evaluates spending patterns and offers smart, human-like recommendations. For example, if you spend too much on e-hailing, reminders like "You could have saved RM200 on transport by taking public transit" could be shown. This approach makes financial tracking more engaging and action-oriented rather than merely observational.

  - **OCR-Based Expense Entry**: Users can scan receipts or bills using OCR technology to automatically record expense details, significantly reducing manual data entry and potential errors. The integration of the Gemini API enhances text detection and extraction accuracy, enabling more reliable identification of transaction information—an advanced capability that differentiates Cashlytics from many existing budgeting applications.

  - **Multiview Data Visualisation**: Beyond standard charts, Cashlytics presents expenses through calendar, list, and pie chart views, giving users the freedom to visualise data from different perspectives. This variety enhances understanding of both daily spending and long-term financial trends.

---

## Team & Responsibilities

| Name | Role | Modules | Key Tasks |
|------|------|---------|-----------|
| **[Lim Wen Hao](https://github.com/WenHao1223)** | Team Lead & Tech Lead | Income and Expenses Management; AI Financial Health Score and Insights | System architecture design, database schema, Supabase setup, CRUD operations, data visualization, Gemini API integration, backend deployment |
| **[Lim Cong Sheng](https://github.com/cshenglim0407)** | Mobile Frontend Developer | User Authentication and Profile Management | Authentication logic, Firebase setup, Flutter environment, UI components, OAuth integration, profile management |
| **[Oong Xian Ming](https://github.com/Oong-Xian-Ming)** | Backend Developer | Expense Entry and OCR | Supabase Storage, OCR pipeline, FastAPI backend, receipt upload, OCR deployment |
| **[Tan Jun Cheng](https://github.com/Jccc03)** | Database Designer | Budget and Threshold | Database schema, ERD diagram, budget logic, budget UI implementation |

---

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: FastAPI (Python)
- **Database**: Supabase (PostgreSQL)
- **Storage**: Supabase Storage
- **Authentication**: Supabase Auth + OAuth (Google, Facebook)
- **OCR**: Gemini API, Python OCR pipeline
- **Deployment**: Render (Docker)
- **Email**: SMTP service

---

## Project Structure

```
CAT-304/
├── mobile/             # Flutter mobile application
│   ├── lib/            # Dart source code
│   ├── android/        # Android-specific configuration
│   ├── ios/            # iOS-specific configuration
│   ├── assets/         # Images, env files
│   └── pubspec.yaml    # Flutter dependencies
├── backend/            # Python backend services
│   └── ocr/           # OCR service
├── database/          # SQL scripts and database setup
└── README.md          # This file
```

---

## Additional Resources

For detailed configuration instructions, see:
- [Mobile Environment Setup](mobile/assets/env/.env.example)
- [Backend OCR Service](backend/ocr/README.md)
- [Database Schema](database/)