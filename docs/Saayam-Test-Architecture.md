# Saayam Test Application – Architecture & Operational Flow (UI-Focused)

 **Version:** 1.0  
 **Owners:** Engineer A (UI Lead), Engineer B (AWS/Backend Lead)  
 **Scope:** This document focuses **only on the UI architecture and flows**. Backend, AWS infrastructure, and API layer design are documented separately by Engineer B.  

 **Last Updated:** 2025-08-13  

---

 ## 1. Overview
-The Saayam Test Application is a **React single-page application (SPA)** hosted on **Netlify**. It communicates with backend services running on **AWS** (via an API layer). This doc focuses on **UI flows** (Engineer A) and provides a high-level diagram for context.
+The Saayam Test Application is a **React single-page application (SPA)** hosted on **Netlify**. It communicates with backend services running on **AWS** (via an API layer). This doc focuses on **UI flows** (Engineer A) and includes a high-level diagram for context.
+
+This document covers:
+- **UI flows** (Engineer A’s ownership).
+- **How the UI communicates** with backend APIs.
+- **High-level diagram** showing UI context in the full system.

---

-## 2. High-Level Architecture (context)
-> The UI part is the left side (Browser → Netlify → API Layer).
+## 2. High-Level Architecture (UI Context)
+> The UI portion is: **Browser → Netlify (React SPA) → API Layer**.

 ```mermaid
 flowchart LR
-    A[User Browser] -->|HTTPS| B[Netlify - React SPA]
-    B -->|API calls via SDK| C[API Layer - AWS]
+    A[User Browser] -->|HTTPS| B[Netlify - React SPA]
     B -->|API calls - SDK| C[API Layer - AWS]
     C --> D[Volunteer Service - K8s]
     C --> E[Request Service - K8s]
     C --> F[ML Service - K8s]
-    D --> G[(Relational Database)]
+    D --> G[(Relational Database - Aurora)]
     E --> G
-    F --> G
-    F --> H[S3 - Historical Data]
+    F --> H[S3 - History Data]
+
+---

+## 3. Dependencies & Environments
+
+| Item           | Detail                                  |
+|----------------|-----------------------------------------|
+| Hosting        | Netlify (test environment)              |
+| API Base URL   | https://<api-base>/v1                    |
+| Auth Provider  | TBD (handled by backend)                 |
+| Auth Storage   | Access token in localStorage/session     |
+| Roles          | Volunteer, Beneficiary                  |
+| Env Vars Used  | VITE_API_URL, VITE_ENV                   |
+
+---

+## 4. UI ↔ API Touchpoints
+
+| UI Page/Flow         | Action                          | API Endpoint (example) |
+|----------------------|---------------------------------|-------------------------|
+| Login                | Authenticate user               | POST /auth/login        |
+| Volunteer Dashboard  | Fetch “My Requests”             | GET /requests?me        |
+| Create Help Request  | Submit new request               | POST /requests          |
+| Notifications        | Fetch latest updates            | GET /notifications      |
+| Donate               | Process payment                  | POST /donate            |
+
+---

+## 5. UI Flow: Login → Dashboard
+
+```mermaid
+flowchart LR
+    A[User] --> B[Login Form]
+    B -->|POST /auth/login| C{Auth OK?}
+    C -- No --> B
+    C -- Yes --> D{Role}
+    D -- Volunteer --> E[Volunteer Dashboard]
+    D -- Beneficiary --> F[Beneficiary Dashboard]
+    E -->|API calls| G[Request Service]
+    F -->|API calls| G
+```

---

-## 3. UI Component Flows (Engineer A)
-
-The UI is a React SPA with the following main flows:
+## 6. UI Component Flows (Engineer A)
+
+The UI is a React SPA with the following main flows:

 ### Landing Page (Home)
 - Components: Hero banner, carousel, mission statement, call-to-action buttons.
 - No authentication required.

 ### About Us
 - Static information page describing mission, values, and team.

 ### Volunteer Services
 - Lists available support categories: Food, Housing, Clothing, Education, Healthcare, etc.
 - Links to “Become a Volunteer” registration form (requires login).

 ### Login / Sign Up
 - Auth handled via API calls to backend.
 - Post-login redirects to Volunteer Dashboard or Beneficiary Dashboard depending on role.

 ### Volunteer Dashboard
 - Shows My Requests table with filters and search.
 - Requests displayed with ID, Type, Subject, Status, Category, Priority, and Calamity.
 - Options to update status or close requests (calls backend APIs).

 ### Create Help Request (Beneficiary flow)
 - Form to submit new help requests.
 - Sends data via API to Request Service.

 ### Notifications
 - Shows updates on request progress and volunteer assignments.

 ### Donate
 - External or integrated payment gateway.
 - Links to backend for transaction logging.
+
+---

+## 7. Deployment Notes (UI)
+- **Build Command:** `npm run build`  
+- **Output Directory:** `dist/`  
+- **Deployment:** Auto-deployed via GitHub → Netlify integration.  
+- **Environments:**  
+  - Test: `https://test-saayam.netlify.app`  
+  - Prod: TBD  
+
+---
+
+**End of UI Architecture Document**
