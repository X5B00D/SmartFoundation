# Multi-Department Ticketing System - Workflow Analysis

---

## 1. Architecture Layers

```mermaid
graph TB
    subgraph P["Presentation Layer (Out of Scope V1)"]
        UI[UI / API Layer]
    end

    subgraph R["Read Models Layer"]
        V1[V_TicketFullDetails]
        V2[V_TicketInboxByScope]
        V3[V_TicketCurrentSLA]
        DL1[TicketDL]
        DL2[ServiceDL]
        DL3[ArbitrationDL]
        DL4[DashboardDL]
    end

    subgraph B["Business Logic Layer"]
        SP1[TicketSP]
        SP2[ArbitrationSP]
        SP3[ClarificationSP]
        SP4[QualityReviewSP]
        SP5[ServiceSP]
        SP6[TicketSLASP]
    end

    subgraph D["Data Model Layer"]
        subgraph M["Master Tables"]
            MT1[Service]
            MT2[ServiceRoutingRule]
            MT3[ServiceSLAPolicy]
            MT4[ServiceCatalogSuggestion]
        end

        subgraph T["Transaction Tables"]
            TT1[Ticket]
            TT2[ArbitrationCase]
            TT3[ClarificationRequest]
            TT4[QualityReview]
            TT5[TicketPauseSession]
            TT6[TicketSLA]
        end

        subgraph H["History Tables"]
            HT1[TicketHistory]
            HT2[TicketSLAHistory]
            HT3[CatalogRoutingChangeLog]
        end

        subgraph L["Lookup Tables"]
            L1[TicketStatus]
            L2[TicketClass]
            L3[Priority]
            L4[RequesterType]
            L5[PauseReason]
            L6[ArbitrationReason]
            L7[ClarificationReason]
            L8[QualityReviewResult]
        end
    end

    subgraph E["Existing Enterprise Systems"]
        EU1[User]
        EU2[Distributor]
        EU3[UserDistributor]
        EU4[Idara/Dept/Div/Section]
        EU5[DSDID Routing]
        EU6[dbo.AuditLog]
    end

    UI --> R
    R --> B
    B --> D
    B --> E
    D --> E

    classDef clearFont fill:#e1f5ff,stroke:#000000,stroke-width:1px,color:#000000;
    class P clearFont;

    classDef readFont fill:#fff4e1,stroke:#000000,stroke-width:1px,color:#000000;
    class R readFont;

    classDef businessFont fill:#ffe1f5,stroke:#000000,stroke-width:1px,color:#000000;
    class B businessFont;

    classDef dataFont fill:#e1ffe1,stroke:#000000,stroke-width:1px,color:#000000;
    class D dataFont;

    classDef existingFont fill:#f0f0f0,stroke:#000000,stroke-width:1px,color:#000000;
    class E existingFont;
```

---

## 2. Spec-Level Dependencies

```mermaid
graph TB
    subgraph M0["Milestone 0: Prerequisites"]
        PREREQ[Document existing schemas<br/>Define state machine<br/>Establish test data]
    end

    subgraph M1["Milestone 1: Foundation Layer"]
        S01[Spec 01<br/>Lookup Foundations]
        S02[Spec 02<br/>Service Catalogue]
        S03[Spec 03<br/>Core Ticket Backbone]
    end

    subgraph M2["Milestone 2: Assignment Layer"]
        S04[Spec 04<br/>Assignment & Work Start]
    end

    subgraph M3["Milestone 3: Exception Handling"]
        S05[Spec 05<br/>Clarification Flow]
        S06[Spec 06<br/>Arbitration Flow]
    end

    subgraph M4["Milestone 4: Dependency Layer"]
        S07[Spec 07<br/>Parent-Child Ticketing]
        S08[Spec 08<br/>Blocking & Pause Sessions]
    end

    subgraph M5["Milestone 5: Completion Layer"]
        S09[Spec 09<br/>SLA Engine]
        S10[Spec 10<br/>Quality Review]
        S11[Spec 11<br/>Catalogue Learning]
    end

    subgraph M6["Milestone 6: Visibility Layer"]
        S12[Spec 12<br/>Reporting & Dashboards]
    end

    PREREQ --> S01
    S01 --> S02
    S01 --> S03
    S01 -.-> S12
    S02 --> S04
    S03 --> S04
    S04 --> S05
    S04 --> S06
    S05 --> S07
    S05 --> S08
    S06 --> S08
    S07 --> S09
    S08 --> S09
    S09 --> S10
    S09 --> S11
    S10 --> S12
    S11 --> S12

    classDef m0Font fill:#fff0f0,stroke:#000000,stroke-width:2px,color:#000000;
    class M0 m0Font;

    classDef m1Font fill:#f0fff0,stroke:#000000,stroke-width:1px,color:#000000;
    class M1 m1Font;

    classDef m2Font fill:#f0f0ff,stroke:#000000,stroke-width:1px,color:#000000;
    class M2 m2Font;

    classDef m3Font fill:#fff0ff,stroke:#000000,stroke-width:1px,color:#000000;
    class M3 m3Font;

    classDef m4Font fill:#f0fff0,stroke:#000000,stroke-width:1px,color:#000000;
    class M4 m4Font;

    classDef m5Font fill:#f0f0ff,stroke:#000000,stroke-width:1px,color:#000000;
    class M5 m5Font;

    classDef m6Font fill:#fff0f0,stroke:#000000,stroke-width:1px,color:#000000;
    class M6 m6Font;
```

---

## 3. Table Creation Order

```mermaid
graph LR
    subgraph P1["Phase 1: Lookup Tables (Spec 01)"]
        L1[TicketStatus]
        L2[TicketClass]
        L3[Priority]
        L4[RequesterType]
        L5[PauseReason]
        L6[ArbitrationReason]
        L7[ClarificationReason]
        L8[QualityReviewResult]
    end

    subgraph P2["Phase 2: Master Tables (Spec 02)"]
        M1[Service]
        M2[ServiceRoutingRule]
        M3[ServiceSLAPolicy]
        M4[ServiceCatalogSuggestion]
    end

    subgraph P3["Phase 3: Transaction Tables"]
        T1[Ticket<br/>Spec 03]
        T5[ClarificationRequest<br/>Spec 05]
        T2[ArbitrationCase<br/>Spec 06]
        T6[QualityReview<br/>Spec 10]
        T3[TicketPauseSession<br/>Spec 08]
        T4[TicketSLA<br/>Spec 09]
        T7[CatalogRoutingChangeLog<br/>Spec 11]
    end

    subgraph P4["Phase 4: History Tables"]
        H1[TicketHistory<br/>Spec 03]
        H2[TicketSLAHistory<br/>Spec 09]
        H3[CatalogRoutingChangeLog<br/>Spec 11]
    end

    P1 --> P2
    P2 --> P3
    P3 --> P4

    classDef p1Font fill:#e1f5ff,stroke:#000000,stroke-width:1px,color:#000000;
    class P1 p1Font;

    classDef p2Font fill:#fff4e1,stroke:#000000,stroke-width:1px,color:#000000;
    class P2 p2Font;

    classDef p3Font fill:#ffe1f5,stroke:#000000,stroke-width:1px,color:#000000;
    class P3 p3Font;

    classDef p4Font fill:#e1ffe1,stroke:#000000,stroke-width:1px,color:#000000;
    class P4 p4Font;
```

---

## 4. Ticket State Machine (Inferred - Needs Definition)

```mermaid
stateDiagram-v2
    [*] --> New: INSERT_TICKET
    New --> Queue: ASSIGN_TICKET
    Queue --> InProgress: MOVE_TO_IN_PROGRESS
    InProgress --> OperationalResolved: RESOLVE_OPERATIONALLY
    InProgress --> Clarification: OPEN_CLARIFICATION
    InProgress --> Arbitration: OPEN_ARBITRATION
    InProgress --> Paused: PAUSE_TICKET
    Queue --> Rejected: REJECT_TO_SUPERVISOR
    Rejected --> Queue: REASSIGN

    Clarification --> InProgress: RESPOND/RESUME
    Arbitration --> Redirected: DECIDE_REDIRECT
    Arbitration --> InProgress: DECIDE_OVERRULE
    Arbitration --> Cancelled: CANCEL_ARBITRATION
    Redirected --> Queue

    Paused --> InProgress: RESUME_TICKET

    OperationalResolved --> QualityReview: OPEN_QUALITY_REVIEW
    QualityReview --> FinallyClosed: APPROVE_FINAL_CLOSURE
    QualityReview --> InProgress: RETURN_FOR_CORRECTION
    QualityReview --> OperationalResolved: REJECT_CLOSURE

    FinallyClosed --> [*]

    note right of OperationalResolved
        Ready for quality review
        Cannot be reopened without
        special authorization
    end note

    note right of Paused
        SLA clock paused
        Parent may be blocked
    end note
```

---

## 5. Stored Procedure Dependencies

```mermaid
graph TB
    subgraph SPs["Stored Procedures"]
        TicketSP[TicketSP]
        ServiceSP[ServiceSP]
        ArbitrationSP[ArbitrationSP]
        ClarificationSP[ClarificationSP]
        QualityReviewSP[QualityReviewSP]
        TicketSLASP[TicketSLASP]
    end

    subgraph Tables["Table Dependencies"]
        Lkp[Lookup Tables<br/>Spec 01]
        Svc[Service Tables<br/>Spec 02]
        Tkt[Ticket Table<br/>Spec 03]
    end

    TicketSP --> Lkp
    TicketSP --> Svc
    TicketSP --> Tkt

    ServiceSP --> Lkp

    ArbitrationSP --> Tkt
    ArbitrationSP --> Lkp

    ClarificationSP --> Tkt
    ClarificationSP --> Lkp

    QualityReviewSP --> Tkt
    QualityReviewSP --> Lkp

    TicketSLASP --> Svc
    TicketSLASP --> Lkp

    classDef spFont fill:#ffe1f5,stroke:#000000,stroke-width:1px,color:#000000;
    class SPs spFont;

    classDef tableFont fill:#e1ffe1,stroke:#000000,stroke-width:1px,color:#000000;
    class Tables tableFont;
```

---

## 6. Milestone Execution Flow

```mermaid
graph LR
    subgraph M0["Milestone 0: Prerequisites"]
        TASK0[Document schemas<br/>Define state machine<br/>Create test data]
    end

    subgraph M1["Milestone 1: Foundation"]
        TASK1[Create lookups<br/>Build service catalogue<br/>Core ticket creation]
        CHECK1[Checkpoint:<br/>Can create ticket?]
    end

    subgraph M2["Milestone 2: Assignment"]
        TASK2[Queue handling<br/>User assignment<br/>Work start]
        CHECK2[Checkpoint:<br/>Can assign & start work?]
    end

    subgraph M3["Milestone 3: Exceptions"]
        TASK3[Clarification workflow<br/>Arbitration workflow<br/>Scope disputes]
        CHECK3[Checkpoint:<br/>Can handle exceptions?]
    end

    subgraph M4["Milestone 4: Dependencies"]
        TASK4[Parent-child tickets<br/>Blocking logic<br/>Pause sessions]
        CHECK4[Checkpoint:<br/>Can model dependencies?]
    end

    subgraph M5["Milestone 5: Completion"]
        TASK5[SLA engine<br/>Quality review<br/>Catalogue learning]
        CHECK5[Checkpoint:<br/>Full lifecycle works?]
    end

    subgraph M6["Milestone 6: Visibility"]
        TASK6[Dashboard views<br/>Reporting DL<br/>Leadership metrics]
        CHECK6[Checkpoint:<br/>Full system ready?]
    end

    TASK0 --> TASK1 --> CHECK1
    CHECK1 --> TASK2 --> CHECK2
    CHECK2 --> TASK3 --> CHECK3
    CHECK3 --> TASK4 --> CHECK4
    CHECK4 --> TASK5 --> CHECK5
    CHECK5 --> TASK6 --> CHECK6

    classDef task0Font fill:#fff0f0,stroke:#000000,stroke-width:1px,color:#000000;
    class TASK0 task0Font;

    classDef task1Font fill:#f0fff0,stroke:#000000,stroke-width:1px,color:#000000;
    class TASK1 task1Font;

    classDef task2Font fill:#f0f0ff,stroke:#000000,stroke-width:1px,color:#000000;
    class TASK2 task2Font;

    classDef task3Font fill:#fff0ff,stroke:#000000,stroke-width:1px,color:#000000;
    class TASK3 task3Font;

    classDef task4Font fill:#f0fff0,stroke:#000000,stroke-width:1px,color:#000000;
    class TASK4 task4Font;

    classDef task5Font fill:#f0f0ff,stroke:#000000,stroke-width:1px,color:#000000;
    class TASK5 task5Font;

    classDef task6Font fill:#fff0f0,stroke:#000000,stroke-width:1px,color:#000000;
    class TASK6 task6Font;

    classDef checkFont fill:#ffd700,stroke:#000000,stroke-width:2px,color:#000000;
    class CHECK1,CHECK2,CHECK3,CHECK4,CHECK5,CHECK6 checkFont;
```

---

## 7. Critical Gaps Summary

```mermaid
mindmap
  root((Critical Gaps))
    Schema Integration
      G1 Distributor structure undefined
      G2 AuditLog JSON format undefined
      G3 UserDistributor validation pattern
      G1 Resident identity table location
    Business Logic
      G4 SLA time unit (min vs hours)
      G5 Ticket status codes & transitions
      G6 Quality reviewer identity logic
      G7 Arbitrator selection algorithm
      D5 Reopen ticket conditions
    Data Design
      D1 Ticket tree depth limit
      D4 Pause session overlap handling
      D6 Service suggestion sources
    Integration
      I2 Notification dependencies
      I3 Attachment storage location
      I4 Authorization layer pattern
    Testing
      T1 Test data strategy
      T2 Performance criteria
      T3 Concurrency handling
```

---

## 8. Priority-Based Execution Matrix

```mermaid
graph TB
    subgraph P0["Priority P0: Core Foundation"]
        S01[Spec 01<br/>Lookup Foundations]
        S02[Spec 02<br/>Service Catalogue]
        S03[Spec 03<br/>Core Ticket Backbone]
    end

    subgraph P1["Priority P1: Primary Use Case"]
        S04[Spec 04<br/>Assignment & Work Start]
    end

    subgraph P2["Priority P2: Exception Handling"]
        S05[Spec 05<br/>Clarification Flow]
        S06[Spec 06<br/>Arbitration Flow]
    end

    subgraph P3["Priority P3: Time Tracking"]
        S09[Spec 09<br/>SLA Engine]
    end

    subgraph P4["Priority P4: Advanced Features"]
        S07[Spec 07<br/>Parent-Child Ticketing]
        S08[Spec 08<br/>Blocking & Pause Sessions]
    end

    subgraph P5["Priority P5: Maturity Features"]
        S10[Spec 10<br/>Quality Review]
        S11[Spec 11<br/>Catalogue Learning]
    end

    subgraph P6["Priority P6: Visibility"]
        S12[Spec 12<br/>Reporting & Dashboards]
    end

    P0 --> P1 --> P2 --> P3 --> P4 --> P5 --> P6

    classDef p0Font fill:#ffcccc,stroke:#000000,stroke-width:1px,color:#000000;
    class P0 p0Font;

    classDef p1Font fill:#ffddcc,stroke:#000000,stroke-width:1px,color:#000000;
    class P1 p1Font;

    classDef p2Font fill:#ffeecc,stroke:#000000,stroke-width:1px,color:#000000;
    class P2 p2Font;

    classDef p3Font fill:#ffffcc,stroke:#000000,stroke-width:1px,color:#000000;
    class P3 p3Font;

    classDef p4Font fill:#ffffdd,stroke:#000000,stroke-width:1px,color:#000000;
    class P4 p4Font;

    classDef p5Font fill:#ffffee,stroke:#000000,stroke-width:1px,color:#000000;
    class P5 p5Font;

    classDef p6Font fill:#f0f0f0,stroke:#000000,stroke-width:1px,color:#000000;
    class P6 p6Font;
```

---

## 9. Data Flow: Known Service Ticket

```mermaid
sequenceDiagram
    participant R as Requester
    participant UI as UI Layer
    participant SP as TicketSP
    participant T as Ticket Table
    participant S as Service Tables
    participant H as TicketHistory
    participant A as AuditLog

    R->>UI: Select Service (e.g., Water Faucet Repair)
    UI->>S: Lookup Service Routing Rule
    S-->>UI: Return TargetDSDID
    UI->>SP: INSERT_TICKET (with ServiceID)
    SP->>SP: Validate requester type
    SP->>SP: Get default routing
    SP->>SP: Initialize rootTicketID_FK
    SP->>T: Insert ticket record
    SP->>H: Write creation history
    SP->>A: Write JSON audit entry
    SP-->>UI: Ticket created
    UI-->>R: Confirmation with TicketNo

    Note over R,A: Ticket now in appropriate queue
```

---

## 10. Data Flow: Arbitration Case

```mermaid
sequenceDiagram
    participant U as Unit User
    participant S as Supervisor
    participant A as ArbitratorSP
    participant AC as ArbitrationCase
    participant T as Ticket
    participant H as TicketHistory

    U->>S: Reject ticket (wrong scope)
    S->>A: OPEN_ARBITRATION_CASE
    A->>AC: Insert case record
    A->>T: Update ticket status
    A->>H: Write arbitration history
    A-->>S: Case opened

    Note over A: Arbitrator reviews...

    A->>A: DECIDE_REDIRECT
    A->>T: Update TargetDSDID_FK
    A->>T: Update QueueDistributorID_FK
    A->>AC: Update case status & decision
    A->>H: Write redirect history
    A-->>S: Redirected to new queue
```

---

## 11. Parent-Child Blocking Flow

```mermaid
graph LR
    subgraph Parent["Parent Ticket"]
        P1[Ticket ID: 100]
        P2[Status: In Progress]
        P3[isParentBlocked: true]
    end

    subgraph Child["Child Ticket"]
        C1[Ticket ID: 101]
        C2[parentTicketID_FK: 100]
        C3[Status: In Progress]
    end

    subgraph Pause["Pause Session"]
        PS1[ticketID_FK: 100]
        PS2[pauseReason: Dependency]
        PS3[relatedChildTicketID_FK: 101]
    end

    P3 -.->|blocked by| PS3
    PS3 -.->|waiting for| C3

    C3 -->|Complete| Done[Child Done]
    Done -->|Resume| Resume[Parent Resumes]
    Resume --> P3b[isParentBlocked: false]

    classDef parentFont fill:#ffe1f5,stroke:#000000,stroke-width:1px,color:#000000;
    class Parent parentFont;

    classDef childFont fill:#e1f5ff,stroke:#000000,stroke-width:1px,color:#000000;
    class Child childFont;

    classDef pauseFont fill:#fff4e1,stroke:#000000,stroke-width:1px,color:#000000;
    class Pause pauseFont;

    classDef doneFont fill:#e1ffe1,stroke:#000000,stroke-width:2px,color:#000000;
    class Done doneFont;
```

---

## 12: Quick Reference - Spec Deliverables

```mermaid
graph TB
    subgraph Legend["Legend"]
        LDB[Database Tasks]
        LSP[Stored Procedures]
        LV[Views / DL]
        LUI[UI Tasks]
    end

    subgraph Spec01["Spec 01: Lookup Foundations"]
        S01DB[8 Lookup Tables<br/>Seed Scripts]
        S01T[Uniqueness Tests]
    end

    subgraph Spec02["Spec 02: Service Catalogue"]
        S02DB[4 Master Tables]
        S02SP[ServiceSP - 8 Actions]
        S02R[V_ServiceFullDefinition<br/>ServiceDL]
        S02UI[5 Admin Screens]
    end

    subgraph Spec03["Spec 03: Core Ticket"]
        S03DB[Ticket + TicketHistory]
        S03SP[TicketSP - INSERT_TICKET]
        S03R[V_TicketFullDetails<br/>V_TicketLastAction<br/>TicketDL]
        S03UI[Creation + Details + List]
    end

    subgraph Spec04["Spec 04: Assignment"]
        S04SP[TicketSP - 4 Actions]
        S04R[Inbox Extensions]
        S04UI[4 Assignment Screens]
    end

    subgraph Spec05["Spec 05: Clarification"]
        S05DB[ClarificationRequest]
        S05SP[ClarificationSP - 3 Actions]
        S05UI[2 Clarification Screens]
    end

    subgraph Spec06["Spec 06: Arbitration"]
        S06DB[ArbitrationCase]
        S06SP[ArbitrationSP - 4 Actions]
        S06R[ArbitrationDL]
        S06UI[2 Arbitration Screens]
    end

    subgraph Spec07["Spec 07: Parent-Child"]
        S07SP[TicketSP - CREATE_CHILD]
        S07R[Tree Loading Extension]
        S07UI[2 Parent-Child Screens]
    end

    subgraph Spec08["Spec 08: Blocking"]
        S08DB[TicketPauseSession]
        S08SP[TicketSP - 2 Actions]
        S08UI[3 Pause/Resume Screens]
    end

    subgraph Spec09["Spec 09: SLA"]
        S09DB[TicketSLA + History]
        S09SP[TicketSLASP]
        S09R[V_TicketCurrentSLA]
        S09UI[SLA Badges + Lists]
    end

    subgraph Spec10["Spec 10: Quality"]
        S10DB[QualityReview]
        S10SP[QualityReviewSP - 4 Actions]
        S10UI[3 Quality Screens]
    end

    subgraph Spec11["Spec 11: Learning"]
        S11DB[CatalogRoutingChangeLog]
        S11SP[ServiceSP - 2 Actions]
        S11UI[3 Learning Screens]
    end

    subgraph Spec12["Spec 12: Reporting"]
        S12R[3 Inbox Views<br/>DashboardDL]
        S12UI[4 Dashboard Screens]
    end

    classDef dbFont fill:#e1ffe1,stroke:#000000,stroke-width:1px,color:#000000;
    class LDB,S01DB,S03DB,S05DB,S06DB,S08DB,S09DB,S10DB,S11DB dbFont;

    classDef spFont fill:#ffe1f5,stroke:#000000,stroke-width:1px,color:#000000;
    class LSP,S02SP,S03SP,S04SP,S05SP,S06SP,S07SP,S08SP,S09SP,S10SP,S11SP spFont;

    classDef viewFont fill:#fff4e1,stroke:#000000,stroke-width:1px,color:#000000;
    class LV,S02R,S03R,S04R,S06R,S07R,S09R,S12R viewFont;

    classDef uiFont fill:#e1f5ff,stroke:#000000,stroke-width:1px,color:#000000;
    class LUI,S01T,S02UI,S03UI,S04UI,S05UI,S06UI,S07UI,S08UI,S09UI,S10UI,S11UI,S12UI uiFont;
```

---

*Generated from plan.md analysis*
*Last Updated: 2026-03-30*
