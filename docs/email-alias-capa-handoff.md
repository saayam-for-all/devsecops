# Organizational Email Alias & CAPA Operational Handoff

**Issue:** #78  
**Purpose:** Provide a repeatable process for organizational email alias management and CAPA communication handoff.

> **Note:** Email alias configuration is managed through the organization's approved external administration system (Nettigritty). This repository documents the operational process and handoff guidance but does not directly configure email aliases.

---

## 1. Organizational Email Alias Structure

Organizational aliases should follow a consistent, function-based naming approach.

| Function | Proposed Alias | Purpose |
|---|---|---|
| SWAT | `swat@<organization-domain>` | Incident and urgent operational communication |
| Communications | `communications@<organization-domain>` | Organizational communication |
| DevSecOps | `devsecops@<organization-domain>` | Security, infrastructure, and technical communication |
| CAPA | `capa@<organization-domain>` | Corrective and Preventive Action communication |
| Project Management | `pm@<organization-domain>` | Project coordination and management |

Actual aliases and ownership should be confirmed by the authorized email administrator.

---

## 2. Alias Ownership

Each organizational alias should have a clearly identified primary owner and backup owner.

| Function | Primary Owner | Backup Owner | Responsibility |
|---|---|---|---|
| SWAT | Assigned owner | Assigned backup | Incident communication |
| Communications | Assigned owner | Assigned backup | Organizational communication |
| DevSecOps | Assigned owner | Assigned backup | Technical and security communication |
| CAPA | Assigned owner | Assigned backup | CAPA notifications |
| Project Management | Assigned owner | Assigned backup | Project coordination |

Ownership information should be maintained by the appropriate organizational administrator.

---

## 3. Alias Change Request Procedure

Use the following process when creating, modifying, or retiring an organizational email alias.

### Step 1 – Identify the requirement

Document:

- Business or operational purpose
- Requested alias
- Intended recipients
- Communication type
- Whether the alias supports incident response or CAPA communication

### Step 2 – Identify ownership

Define:

- Primary owner
- Backup owner
- Responsible organizational team

### Step 3 – Submit the request

Submit the request to the authorized Nettigritty/email administrator.

The repository should document the process but must not contain administrative credentials, passwords, or authentication tokens.

### Step 4 – Configure the alias

The authorized administrator creates or modifies the alias in the external email administration system.

### Step 5 – Validate the configuration

Send a controlled test message and confirm that the intended recipients receive the communication.

### Step 6 – Document the change

Record:

- Alias/function
- Purpose
- Primary owner
- Backup owner
- Date of change
- Validation status

---

## 4. CAPA Communication Flow

CAPA-related communication should follow a defined process so that alerts reach the appropriate stakeholders.

```text
CAPA / Operational Trigger
          |
          v
Identify Communication Type
          |
          v
Select Appropriate Organizational Alias
          |
          v
Send Notification
          |
          v
Relevant Stakeholders Receive Communication
          |
          v
CAPA Owner Coordinates Response
          |
          v
Corrective / Preventive Action
          |
          v
Resolution and Follow-up
          |
          v
Document Outcome

