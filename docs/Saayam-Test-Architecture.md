# Saayam Test Application – Architecture & Operational Flow

**Version:** 1.0  
**Owners:** Engineer A (UI Lead), Engineer B (AWS/Backend Lead)  
**Last Updated:** 2025-08-13

---

## 1. Overview
The Saayam Test Application is a **React single-page application (SPA)** hosted on **Netlify**. It communicates with backend services running on **AWS** (via an API layer). This doc focuses on **UI flows** (Engineer A) and provides a high-level diagram for context.

---

## 2. High-Level Architecture (context)
> The UI part is the left side (Browser → Netlify → API Layer).

```mermaid
flowchart LR
    A[User Browser] -->|HTTPS| B[Netlify - React SPA]
    B -->|API calls via SDK| C[API Layer - AWS]
    C --> D[Volunteer Service - K8s]
    C --> E[Request Service - K8s]
    C --> F[ML Service - K8s]
    D --> G[(Relational Database)]
    E --> G
    F --> G
    F --> H[S3 - Historical Data]
