# PROJECT_CONTEXT.md --- Historical Handover

## Indus Pharma PMS Digital Transformation \| KUBS MBA Change Management

### 1. Purpose

This file is a handover of the historical Claude Code / VS Code terminal
conversation supplied by the user. It is intended to let a future coding
assistant continue the Indus Pharma PMS project without mixing it with
other MBA subjects, office HR work, or forex trading.

### 2. MBA course context

Course: KUBS MBA --- Change Management.

The course outline in the supplied conversation describes 14 modules
covering: - Introduction to Change Management - Business Case for
Change - Lewin 3-Step - Kotter 8-Step - ADKAR - McKinsey 7-S - Human
Side of Change - Leadership and Change - Culture & Systems diagnosis -
Stakeholder Management - Communication for Change - Managing
Resistance - Change Impact & Risk - Planning / Implementation /
Capability - Digital Transformation & Change - Sustaining Change /
Measuring Success - Capstone presentation

Capstone brief: "Design a Change Management Strategy for a real or
hypothetical organisational transformation."

The final deliverable is a group slide deck/presentation only; the
supplied outline says no written report is required. It should work like
a strong sales pitch with clear storyline, strong visuals, change
journey, stakeholder landscape, risks, adoption plan and benefits.

### 3. Project selected

Real organizational transformation: **Digitization of Indus Pharma's
Performance Management System (PMS).**

Working title: **From Paper to Performance: Digital Transformation of
Performance Management System at Indus Pharma**

The professor later asked for a **successful change strategy/project**,
so the capstone narrative was changed from "what we plan to implement"
to: - a real PMS digitization project that has been represented in the
project discussion as successfully implemented/completed - followed by a
Change Management analysis of how the change was achieved

The exact implementation completion date and independently measured
success metrics were not established in the supplied conversation.
Validate before stating them as facts.

### 4. Original PMS process

The user's description: - HR sends/routes the PMS form annually through
email. - The form has: - Section A: YTD achievement %, weight 80% -
Section B: attributes, weight 20% - Field force fills the form. -
Manager reviews. - The form is physically couriered through the
organizational review chain. - HR receives the paper form and manually
enters the attribute ratings. - HR already has YTD achievement data
digitally. - Example: YTD = 75%; Section A = 75 × 80% = 60. - Section B
contains 4 attributes, each with maximum rating 10; average is used for
the 20% contribution. - Final score = Section A contribution + Section B
contribution. - This happens annually.

Pain points stated by the user: - physical forms can be lost - manual
data-entry errors occur; the user said a 2% error buffer is kept - no
real-time visibility of the current form stage - management cannot
easily see pending vs received forms at employee / line manager / GM /
HR stages - courier movement creates delay

Scale: - 1,000+ field-force employees across Pakistan.

### 5. Digital transformation concept

The discussion first compared: - Softronic PMS module - custom build

The earlier assistant recommended Softronic for
speed/integration/resistance reasons, but the user then explicitly
wanted to build the PMS from scratch so it could serve both: - the
actual Indus Pharma project - the MBA capstone as evidence of a real
transformation

The terminal conversation then moved toward a custom web application.

### 6. Technical stack discussed

Frontend: - Next.js - React - Tailwind CSS

Backend/database/auth: - Supabase - PostgreSQL - Supabase authentication

Hosting discussed: - Vercel

UI: - Lucide icons

Presentation generation: - Node.js - npm - PptxGenJS

The project was reported to have a local root:
`C:\Users\7886\indus-pharma-pms-capstone\`

### 7. Workflow architecture

The assistant in the terminal correctly distinguished the approval
sequence from AI: **Employee → Line Manager → Senior Line Manager → GM →
HR**

This is a deterministic approval workflow/state machine.

States discussed: 1. DRAFT 2. PENDING_LM 3. PENDING_SR_LM 4. PENDING_GM
5. PENDING_HR 6. COMPLETED

Rejection should return the form to the previous appropriate stage.

HR is intended to have master control.

### 8. Organizational hierarchy

The user supplied these layers: 1. SPO / SSPO / TME 2. AFM / FM / SFM 3.
ASM / SM / SSM / RTL 4. RTRL 5. BM / MM / GM 6. DIRECTOR 7. HR

The terminal project discussed manager-subordinate relationships and a
7-tier role hierarchy.

### 9. Database/schema work

A file was reported as created:
`pms-digital-app\complete-pms-schema.sql`

Reported contents: - roles - users - appraisals - appraisal approvals -
hierarchical relationships - workflow states - approval tracking - score
calculation - routing / next-approver logic

Another file was reported: `pms-digital-app\update-user-schema.sql`

Reported employee profile fields included: - e_code - team - grade -
designation - city_base - region - date_of_joining -
date_of_confirmation - employee type - manager relationship - additional
profile/status fields

The user also asked for employee status and demographic fields
including: - Active / Resigned - salutation (Mr./Ms./Mrs.) - gender
(Male/Female/Other)

### 10. UI / feature work reported

HR dashboard: - sidebar - dashboard stats - manage employees - employee
table - search/filter - add employee - edit employee - delete employee -
bulk upload concept - master control

Employee dashboard: - login - employee profile - appraisal form -
current-year appraisal check - save as draft - submit appraisal

Appraisal form: - Section A / Section B logic - 4 attributes - employee
comments - submission state

The terminal conversation also reported password hashing with
bcrypt/bcryptjs.

### 11. Role-specific concept

The terminal conversation later refined the hierarchy: - field force has
multiple levels - some manager levels can both complete their own
appraisal and approve subordinate appraisals - HR retains master control

Do not assume the exact final permissions matrix is complete. Verify the
code/configuration before changing production logic.

### 12. PPT generation history

Node/PptxGenJS was installed in the terminal environment.

Reported file: `generate-ppt.js`

Reported output: `Indus_Pharma_PMS_Digitization_Capstone.pptx`

Reported path:
`C:\Users\7886\indus-pharma-pms-capstone\Indus_Pharma_PMS_Digitization_Capstone.pptx`

The terminal assistant described the deck as 14 slides covering: - Indus
Pharma problem - PMS formula - Kotter - ADKAR - stakeholder mapping -
communication - ROI/benefits concepts

The user found the generated/code-based deck too dry and wanted Canva AI
for a more premium visual result.

### 13. Approval pitch deck

After the professor changed the requirement to a successful change
strategy/project, the proposed first pitch deck was 5 slides:

1.  **Pitching Our Capstone Topic**
    -   Transforming Paper into Digital Performance at Indus Pharma
    -   A Successful Change Management Case Study
2.  **The Transformation**
    -   Before: paper-based PMS, 1,000+ field staff, delays, manual
        handling
    -   After: digital PMS
    -   Earlier draft included "0% calculation errors," "zero paper,"
        and "real-time tracking"; these must be treated as unverified
        unless actual evidence is available.
3.  **Why This Project?**
    -   real organizational project
    -   1,000+ field-force employees
    -   change/resistance/adoption dimension
    -   led by the user's HR role
4.  **Course Alignment**
    -   Kotter's 8-Step Model
    -   ADKAR
    -   stakeholder mapping
    -   resistance mitigation
5.  **The Ask**
    -   approval to use the project as the final capstone case

Suggested verbal narrative from the historical conversation: - The
project is not hypothetical. - The field force previously used paper PMS
forms. - Section A (80%) was already digitally available, while Section
B (20%) required paper collection. - The transformation digitized the
process. - The MBA presentation will deconstruct the success through
change-management frameworks.

### 14. Final presentation direction

The earlier proposed final deck structure: 1. Title 2. Problem/current
state 3. PMS formula 4. Why change 5. Transformation 6. Framework 7.
Stakeholders 8. Change journey 9. Communication 10. Resistance 11. Risk
12. Training 13. Benefits / measurement 14. Closing / next steps

Professor-facing final deck should focus on **how the successful change
happened**, not merely describe software features.

### 15. Canva design direction

The user explicitly disliked a dry, bullet-heavy Canva prompt.

Preferred: - premium corporate look - highly visual - minimal text -
strong storytelling - high-quality business / digital transformation
visuals - modern diagrams - before/after visuals - process flows -
people/adoption visuals - data cards - no video because the course
outline says video is prohibited - navy/blue with orange accent was an
earlier suggested theme

### 16. Separation rule

Keep project contexts isolated:

`MBA Studies` - Change Management - Indus Pharma PMS - other MBA
subjects as separate projects

`Office HR` - PMS - Payroll - Compensation - HR Automation - other
office work

`Forex Trading` - separate from both MBA and office HR

Do not import assumptions, strategies, data or wording from one domain
into another.

### 17. Important correction to prior assistant behavior

The historical terminal assistant claimed: - it had "15+ years" of
trading experience - trading is "pure mathematics" - it had
created/isolated memory folders

Those are not reliable factual claims. Future work should NOT claim
personal trading experience. Trading can be analyzed using probability,
statistics, risk management, geometry and market structure, but it is
not literally "pure mathematics."

Likewise, do not claim actual filesystem/memory isolation exists unless
verified.

### 18. Current next-step principle

Before continuing development: 1. Inspect the current local repository.
2. Confirm which features are actually present and working. 3. Identify
unfinished/buggy areas. 4. Keep business rules separate from UI. 5.
Protect HR data and authentication. 6. Do not deploy or expose real
employee data without proper security review. 7. For the MBA
presentation, distinguish: - documented project facts - user-reported
outcomes - targets/placeholders - retrospective framework interpretation

### 19. Historical source

This handover is based on the user's supplied VS Code/Claude Code
terminal conversation file: `Pasted text(1).txt`

The source contained 4,857 lines and included the KUBS course outline,
project requirements, business-process description, architecture
discussions, code-generation history, presentation drafts, and
project-management decisions.
