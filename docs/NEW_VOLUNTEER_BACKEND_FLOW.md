# Backend Architecture & Flow for Saayam Volunteers

## Overview
This document explains how the main AWS components interact in the Saayam system.
It is meant to help new volunteers quickly understand the flow.

## Key Components
- **API Gateway** → Entry point for all client requests.
- **Cognito** → Handles user authentication (signup, login, OTP).
- **Lambda** → Serverless functions for business logic.
- **Aurora (Postgres)** → Main relational database.
- **DynamoDB** → Used for quick lookups and caching scenarios.
- **Redis (ElastiCache)** → Session caching and faster data retrieval.
- **S3** → Stores files, media, backups.
- **Route 53** → DNS service to route requests to correct endpoints.
- **CloudWatch** → Monitoring, logs, and alerts.

## Sample Workflow
1. User opens app and logs in → API Gateway forwards request.
2. API Gateway authenticates with Cognito.
3. Request is processed by a Lambda function.
4. Lambda pulls/stores data in Aurora or DynamoDB depending on need.
5. If large files → stored in S3.
6. CloudWatch records logs & metrics for every step.

## Flowchart
(Flowchart PNG will be added later here)
