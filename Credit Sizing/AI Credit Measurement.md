# 1. Actual AI Credit Measurement Rules

## Objective

Estimated AI Credits support planning.

Actual AI Credits support:

- Calibration
- Forecast accuracy
- Capacity planning
- Cost governance
- AI ROI measurement

Actual Credits must be measured consistently across teams and tools.

---

# 2. Golden Rule

Estimate Credits ≠ Actual Credits

Actual Credits are measured only from executed AI work.

Do not use:

- Story Points
- Development hours
- Human effort
- Calendar duration

as proxies for Actual AI Credits.

Only count AI-assisted execution activity.

---

# 3. Credit Measurement Hierarchy

Priority order:

```text
Platform Reported Credits
        ↓
Model Token Consumption
        ↓
Agent Execution Units
        ↓
Proxy Formula
```

Use the highest fidelity source available.

---

# 4. Measurement Method 1 (Preferred)

## Direct Platform Credits

If the platform exposes credits consumed:

Examples:

- GitHub Copilot Enterprise
- Internal Agent Platform
- AI Gateway
- Bedrock
- Azure OpenAI Consumption Records

Use actual reported values.

Example

```text
Code Agent        : 120 credits
Review Agent      : 50 credits
Test Agent        : 75 credits

Total

245 AI Credits
```

No conversion required.

---

# 5. Measurement Method 2

## Token-Based Measurement

If credits are unavailable but token usage is available.

Normalize tokens to credits.

Recommended baseline:

```text
1 AI Credit

=

100,000 Tokens
```

Example

```text
Input Tokens

=
3,000,000

Output Tokens

=
2,000,000

Total

=
5,000,000 Tokens
```

Credits

```text
5,000,000

÷

100,000

=

50 Credits
```

---

# 6. Measurement Method 3

## Agent Execution Units

Used when token visibility is unavailable.

Each agent execution has a standardized credit value.

Examples

| Execution Type | Credits |
|----------------|----------|
| Story Analysis | 10 |
| Architecture Generation | 25 |
| API Generation | 20 |
| UI Generation | 20 |
| Test Generation | 20 |
| Code Review | 10 |
| Security Review | 15 |
| Documentation Generation | 10 |

Example

```text
Story Analysis         1 x 10
Architecture           1 x 25
API Generation         2 x 20
Testing                2 x 20
Review                 3 x 10

Total

125 Credits
```

---

# 7. Measurement Method 4

## Productivity Proxy Model

Use only if no platform telemetry exists.

Formula

```text
Credits

=

Artifacts Created
× Complexity Factor
```

Example

| Item | Count |
|--------|--------|
| APIs Generated | 4 |
| Screens Generated | 3 |
| Unit Tests Generated | 30 |

Complexity Factor

```text
Medium = 10 Credits
```

Calculation

```text
37

×

10

=

370 Credits
```

This method should be temporary.

---

# 8. Credit Attribution Rules

Credits must be attributed to a single story.

Example

```text
MYD-101

Architecture Agent
API Agent
Testing Agent
Review Agent
```

All credits roll up into:

```text
MYD-101
```

Avoid attributing credits only to the sprint.

Credits should always be traceable to:

```text
Epic
→ Story
→ Task
→ Agent Run
```

---

# 9. Rework Credits

Rework consumes credits and must be measured.

Examples:

- Failed generations
- Incorrect code generation
- Agent reruns
- Test regeneration
- Architecture redesign

Example

```text
Initial Run      100

Rework           35

Total Actual

135 Credits
```

Do not exclude rework.

Rework is valuable calibration data.

---

# 10. Human Override Rules

Human effort does not consume AI Credits.

Example

```text
Developer manually edits code
for 3 hours
```

Credits

```text
0
```

Example

```text
Agent generates code

Developer accepts output
```

Credits

```text
Count AI Credits
```

---

# 11. Shared Agent Rules

When one agent supports multiple stories.

Allocate proportionally.

Example

```text
Architecture Review

100 Credits
```

Supports:

```text
Story A = 50%
Story B = 30%
Story C = 20%
```

Allocation

```text
A = 50 Credits

B = 30 Credits

C = 20 Credits
```

---

# 12. Calibration Dataset

For every story capture:

| Field | Description |
|---------|-------------|
| Story ID | Traceability |
| Estimated Credits | Planning Value |
| Actual Credits | Measured Value |
| Variance % | Forecast Quality |
| Rework Credits | Waste Indicator |
| Credits per Sprint | Capacity Signal |
| Credits per Release | Cost Analysis |

---

# 13. Calibration Formula

Variance

```text
Variance %

=

(Actual Credits - Estimated Credits)

/

Estimated Credits

× 100
```

---

# 14. Rework Ratio

Formula

```text
Rework Ratio

=

Rework Credits

/

Actual Credits
```

Example

```text
Rework

=
150

Actual

=
600
```

Result

```text
25%
```

Target

```text
<15%
```

---

# 15. Sprint Calibration Process

At sprint closure:

Step 1

Collect:

```text
Estimated Credits
```

Step 2

Collect:

```text
Actual Credits
```

Step 3

Calculate:

```text
Variance
```

Step 4

Determine:

```text
Calibration Factor
```

Formula

```text
Actual

/

Estimated
```

Example

```text
Actual

=
12,500

Estimated

=
10,000
```

Calibration Factor

```text
1.25
```

Future estimates become:

```text
Estimated Credits

×

1.25
```

until additional sprint data becomes available.

---
# 16.1.1 Worked Example - Sprint Credit Calibration

## Sprint 15 Overview

Team delivers four stories during the sprint.

### Planned Stories

| Story ID | Story Name | Estimated Credits |
|-----------|------------|------------------:|
| MYD-101 | Leave Approval Workflow | 500 |
| MYD-102 | Attendance Regularization | 300 |
| MYD-103 | Delegation Management | 450 |
| MYD-104 | Notification Framework | 750 |
| | **Total** | **2,000** |

---

# Story-Level Actual Consumption

## MYD-101 Leave Approval Workflow

### Agent Activity

| Activity | Credits |
|------------|---------:|
| Requirements Analysis | 10 |
| Architecture Generation | 25 |
| API Generation | 40 |
| UI Generation | 20 |
| Unit Testing | 20 |
| E2E Test Generation | 50 |
| Code Review Agent | 20 |
| Rework | 35 |
| **Total Actual** | **220** |

Variance

```text
220 - 500

=
-280
```

Variance %

```text
-56%
```

Story was significantly over-estimated.

---

## MYD-102 Attendance Regularization

### Agent Activity

| Activity | Credits |
|------------|---------:|
| Analysis | 10 |
| Architecture | 25 |
| API Generation | 60 |
| UI Generation | 40 |
| Integration Tests | 50 |
| Reviews | 20 |
| Rework | 45 |
| **Total Actual** | **250** |

Variance %

```text
(250 - 300)

/ 300

=
-16.7%
```

---

## MYD-103 Delegation Management

### Agent Activity

| Activity | Credits |
|------------|---------:|
| Analysis | 10 |
| Architecture | 25 |
| API Generation | 80 |
| UI Generation | 40 |
| Testing | 70 |
| Reviews | 25 |
| Rework | 70 |
| **Total Actual** | **320** |

Variance %

```text
(320 - 450)

/ 450

=
-28.9%
```

---

## MYD-104 Notification Framework

### Agent Activity

| Activity | Credits |
|------------|---------:|
| Analysis | 10 |
| Architecture | 50 |
| API Generation | 120 |
| Event Processing Logic | 150 |
| Testing | 150 |
| Reviews | 50 |
| Security Review | 50 |
| Rework | 120 |
| **Total Actual** | **700** |

Variance %

```text
(700 - 750)

/ 750

=
-6.7%
```

---

# Sprint Summary

| Story | Estimated | Actual |
|---------|---------:|---------:|
| MYD-101 | 500 | 220 |
| MYD-102 | 300 | 250 |
| MYD-103 | 450 | 320 |
| MYD-104 | 750 | 700 |
| **Total** | **2,000** | **1,490** |

---

# Forecast Accuracy

Variance

```text
Actual - Estimated

=
1490 - 2000

=
-510
```

Variance %

```text
(-510 / 2000)

× 100

=
-25.5%
```

Interpretation:

```text
The team is systematically
overestimating AI Credits.
```

---

# Calibration Factor

Formula

```text
Actual Credits

/

Estimated Credits
```

Calculation

```text
1490

/

2000

=
0.745
```

Calibration Factor

```text
0.75
```

Meaning:

Future estimates should initially be adjusted by:

```text
Estimated Credits

×

0.75
```

until more sprint data becomes available.

---

# Rework Analysis

## Total Rework

| Story | Rework Credits |
|----------|---------:|
| MYD-101 | 35 |
| MYD-102 | 45 |
| MYD-103 | 70 |
| MYD-104 | 120 |
| **Total** | **270** |

---

## Rework Ratio

Formula

```text
Rework Credits

/

Actual Credits
```

Calculation

```text
270

/

1490

=
18.1%
```

Interpretation

```text
18.1% of all AI consumption
was spent regenerating,
fixing or repeating outputs.
```

Target

```text
<15%
```

Action

```text
Improve prompts
Improve architecture context
Increase specification quality
```

---

# Credit Velocity

Formula

```text
Actual Credits Delivered
per Sprint
```

Result

```text
1490 Credits
```

Historical Example

| Sprint | Credits Delivered |
|----------|----------:|
| Sprint 13 | 1,100 |
| Sprint 14 | 1,350 |
| Sprint 15 | 1,490 |

Trend

```text
35.4% growth in AI-assisted
delivery capacity over
three sprints.
```

---

# AI Productivity Metrics

## Credits per Story

Formula

```text
Actual Credits

/

Stories Delivered
```

Calculation

```text
1490

/

4

=
372.5 Credits
```

---

## Credits per Story Point

Assume total delivered:

```text
34 Story Points
```

Calculation

```text
1490

/

34

=
43.8 Credits
per Story Point
```

This becomes the team's baseline conversion factor.

---

# Future Estimation Baseline

After three to five sprints establish:

```text
1 Story Point

≈

44 AI Credits
```

Examples

| Story Points | Predicted Credits |
|-------------|------------------:|
| 2 | 88 |
| 3 | 132 |
| 5 | 220 |
| 8 | 352 |
| 13 | 572 |

This provides a bridge between traditional Agile planning and AI-native planning.

---

# Executive Dashboard Example

## Sprint 15

| KPI | Value |
|--------|--------|
| Stories Delivered | 4 |
| Planned Credits | 2,000 |
| Actual Credits | 1,490 |
| Forecast Accuracy | 74.5% |
| Rework Ratio | 18.1% |
| Credits per Story Point | 43.8 |
| Credit Velocity | 1,490 |
| Calibration Factor | 0.75 |

## Key Insight

The team over-estimated AI effort by approximately 25%, while maintaining a healthy delivery velocity. Future planning should reduce baseline estimates by 25% and focus on reducing rework through better story specifications and reusable agent context.
---
# 16. Maturity Progression Model

Level 1

```text
Manual Estimation
```

Level 2

```text
Story-Based Credits
```

Level 3

```text
Agent Execution Tracking
```

Level 4

```text
Token-Based Tracking
```

Level 5

```text
Real-Time Credit Accounting
```

---

# 17. Recommended Enterprise KPI Set

Planning Metrics

- Estimated Credits
- Actual Credits
- Credit Velocity
- Calibration Accuracy

Efficiency Metrics

- Credits per Story
- Credits per Release
- Credits per Team

Quality Metrics

- Rework Ratio
- Credits Lost to Regeneration
- Review Credits

Business Metrics

- Cost per Credit
- Business Value per 100 Credits
- Features Delivered per 1000 Credits

Strategic Metrics

- AI Credit Capacity
- AI Credit Consumption
- AI Credit Forecast Accuracy
- AI Engineering ROI

  Introducing a derived metric called VHEC (Value per Hundred Engineering Credits)
  VHEC
=
Business Value Delivered
/
(Actual AI Credits / 100)
