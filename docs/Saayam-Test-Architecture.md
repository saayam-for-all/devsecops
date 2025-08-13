# Saayam Test Application – Architecture & Operational Flow (UI-Focused)

**Version:** 1.0  
**Owners:** Engineer A (UI Lead), Engineer B (AWS/Backend Lead)  
**Scope:** This document focuses **only on the UI architecture and flows**. Backend, AWS infrastructure, and API layer design are documented separately by Engineer B.  

**Last Updated:** 2025-08-13  

---

## 1. Overview
The Saayam Test Application is a **React single-page application (SPA)** hosted on **Netlify**. It communicates with backend services running on **AWS** (via an API layer). This doc focuses on **UI flows** (Engineer A) and includes a high-level diagram for context.

This document covers:
- **UI flows** (Engineer A’s ownership).
- **How the UI communicates** with backend APIs.
- **High-level diagram** showing UI context in the full system.

---

## 2. High-Level Architecture (UI Context)
> The UI portion is: **Browser → Netlify (React SPA) → API Layer**.

```mermaid
flowchart LR
    A[User Browser] -->|HTTPS| B[Netlify - React SPA]
    B -->|API calls - SDK| C[API Layer - AWS]
    C --> D[Volunteer Service - K8s]
    C --> E[Request Service - K8s]
    C --> F[ML Service - K8s]
    D --> G[(Relational Database - Aurora)]
    E --> G
    F --> H[S3 - History Data]

---

## 3. Dependencies & Environments
| Item          | Detail                               |
| ------------- | ------------------------------------ |
| Hosting       | Netlify (test environment)           |
| API Base URL  | https\://<api-base>/v1               |
| Auth Provider | TBD (handled by backend)             |
| Auth Storage  | Access token in localStorage/session |
| Roles         | Volunteer, Beneficiary               |
| Env Vars Used | VITE\_API\_URL, VITE\_ENV            |
