# AI Credit Estimation Framework
## Planning Artifact for Agentic SDLC

Version: 1.0
Owner: Product Management

Purpose: Replace or augment Story Points with a measurable AI consumption model for planning, budgeting, forecasting, and governance.

---

# 1. Why AI Credits?

Traditional Story Points estimate:

- Human effort
- Complexity
- Uncertainty

AI-assisted development introduces additional dimensions:

- Agent execution cost
- LLM consumption
- Code generation volume
- Testing generation effort
- Review and rework loops
- Context window utilization

AI Credits (AIC) estimate expected AI resource consumption and become the common unit for:

- Sprint planning
- Budget forecasting
- Cost tracking
- Productivity analysis
- AI ROI measurement

---

# 2. AI Credit Definition

1 AI Credit represents a normalized unit of AI engineering work.

Credits may be consumed through:

- Requirements analysis
- Architecture generation
- Code generation
- Refactoring
- Test generation
- Documentation generation
- Security reviews
- Agent collaboration

---

# 3. Estimation Dimensions

Total AI Credits are derived from four independent drivers:

```text
AI Credits
=
Story Size
+
Requirements Complexity
+
Technical Scope
+
Testing Scope
```

---

# 4. Story Size Credits

Represents overall business object size.

| Story Size | Story Points | Base AI Credits |
|------------|-------------|----------------|
| XS | 1 | 25 |
| S | 2 | 50 |
| M | 3-5 | 100 |
| L | 8 | 250 |
| XL | 13 | 500 |
| Epic | 21+ | 1000 |

Example:

```text
Leave Approval Workflow
Size = L

Credits = 250
```

---

# 5. Requirements Complexity Credits

Measures business-rule complexity.

## Level 1 - Simple

Characteristics:

- Single workflow
- Few validations
- Minimal business rules

Examples:

- Profile update
- CRUD screen

Credits:

```text
+20
```

---

## Level 2 - Moderate

Characteristics:

- Multiple validation paths
- Business rules
- Approval logic

Examples:

- Leave request
- Expense submission

Credits:

```text
+50
```

---

## Level 3 - Complex

Characteristics:

- Multiple personas
- Dynamic workflow
- Configurable rules

Examples:

- Attendance regularization
- Goal management

Credits:

```text
+100
```

---

## Level 4 - Enterprise

Characteristics:

- Cross-functional process
- Regulatory requirements
- Exception handling

Examples:

- Performance management
- Travel approvals

Credits:

```text
+200
```

---

## Level 5 - Strategic Platform

Characteristics:

- Organization-wide capability
- Workflow engine
- Platform abstraction

Examples:

- MyDay Workflow Engine
- Product Intelligence Framework

Credits:

```text
+500
```

---

# 6. Technical Scope Credits

Measures implementation breadth.

## Single Component

Characteristics:

- Few files changed
- Single repository

Credits:

```text
+10
```

---

## Feature Component

Characteristics:

- 5-15 files
- UI + API

Credits:

```text
+30
```

---

## Multi-Service Feature

Characteristics:

- Multiple APIs
- Integration layer

Credits:

```text
+100
```

---

## Cross Platform

Characteristics:

- Frontend
- Backend
- Integration

Credits:

```text
+250
```

---

## Enterprise Platform Change

Characteristics:

- Multiple domains
- Shared services
- Reusable framework

Credits:

```text
+500
```

---

# 7. Testing Scope Credits

Measures testing effort generated and validated by agents.

## Unit Testing

- Positive scenarios
- Negative scenarios

Credits

```text
+20
```

---

## Integration Testing

- API Chains
- Service Interactions

Credits

```text
+50
```

---

## End-to-End Testing

- Workflow Testing
- Persona Validation

Credits

```text
+100
```

---

## Performance Testing

Credits

```text
+100
```

---

## Security Testing

Credits

```text
+100
```

---

## Compliance Validation

Credits

```text
+150
```

---

# 8. Complete Estimation Example

Story:

```text
Leave Approval Workflow
```

Assessment:

| Driver | Estimate |
|----------|-----------|
| Story Size | L |
| Requirements | Moderate |
| Technical Scope | Multi-Service |
| Testing Scope | E2E |

Calculation:

```text
Story Size        = 250

Requirements      = 50

Technical Scope   = 100

Testing           = 100

-----------------------

Total AIC         = 500
```

Estimated Cost:

```text
500 AI Credits
```

---

# 9. Sprint Planning Capacity

Instead of:

```text
Sprint Capacity = 40 Story Points
```

Use:

```text
Sprint Capacity = 10,000 AI Credits
```

Example:

| Story | Credits |
|----------|----------|
| MYD-101 | 500 |
| MYD-102 | 300 |
| MYD-103 | 800 |
| MYD-104 | 1200 |

Total:

```text
2800 Credits
```

Remaining:

```text
7200 Credits
```

---

# 10. Credit Calibration Model

Initial estimates will be inaccurate.

The model should self-calibrate every sprint.

---

## Step 1 - Capture Estimated Credits

Example

| Story | Estimated Credits |
|----------|----------|
| MYD-101 | 500 |
| MYD-102 | 250 |
| MYD-103 | 750 |

Total

```text
1500
```

---

## Step 2 - Capture Actual Credits

Collect from:

- Copilot usage
- Coding agent executions
- PR review agent runs
- Test generation agent runs

Example

| Story | Actual Credits |
|----------|----------|
| MYD-101 | 650 |
| MYD-102 | 230 |
| MYD-103 | 900 |

Total

```text
1780
```

---

## Step 3 - Measure Variance

Formula

```text
Variance %

=
(Actual - Estimate)
/ Estimate
```

Example

```text
(1780 - 1500)

÷ 1500

=
18.66%
```

---

# 11. Calibration Factor

Formula

```text
Calibration Factor

=
Actual Credits
/
Estimated Credits
```

Example

```text
1780 / 1500

=
1.19
```

Future estimates become:

```text
Estimated Credits
×
1.19
```

---

# 12. Confidence Bands

| Variance | Confidence |
|------------|------------|
| 0-10% | High |
| 10-20% | Medium |
| 20-35% | Low |
| >35% | Re-estimate Model |

---

# 13. AI Budgeting Model

Quarter Capacity

```text
100,000 AI Credits
```

Allocation

| Track | Credits |
|---------|----------|
| New Features | 50,000 |
| Enhancements | 20,000 |
| Tech Debt | 15,000 |
| Testing | 10,000 |
| Innovation | 5,000 |

---

# 14. Portfolio Reporting

Track monthly:

| Metric | Description |
|----------|-------------|
| Planned Credits | Forecasted |
| Actual Credits | Consumed |
| Credit Variance | Forecast Accuracy |
| Credit Velocity | Credits Delivered |
| Cost per Credit | Financial Efficiency |
| Credits per Story Point | Legacy Comparison |
| Credits per Release | Release Economics |

---

# 15. Future State

Traditional

```text
Epic
→ Story
→ Story Points
→ Sprint
```

AI-Native SDLC

```text
Epic
→ Story
→ AI Credits
→ Agent Execution Plan
→ Sprint
→ Cost Forecast
→ ROI Tracking
```

The end goal is to make AI Credits the primary planning, capacity, budgeting, and delivery metric while Story Points remain only a transition metric for teams moving from human-centric to agent-assisted development.
