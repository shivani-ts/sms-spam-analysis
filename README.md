# SMS Spam Analysis

**Domain:** Trust & Safety · Abuse Detection · Text Classification  
**Tools:** SQL · R  
**Dataset:** [SMS Spam Collection](https://archive.ics.uci.edu/dataset/228/sms+spam+collection) - UCI Repository (public)  
**Status:** Complete

---

## Overview

This project analyses 5,574 SMS messages to identify spam patterns and build a simple rule-based detection system. The goal was to understand what makes a message spam - not just flag it, but understand *why* - so that detection rules can be explained and improved over time.

---

## Dataset

| Property | Detail |
|---|---|
| Source | UCI Machine Learning Repository |
| Size | 5,574 messages |
| Labels | `spam` / `ham` (legitimate) |
| Spam rate | ~13% overall |

---

## Project Structure

```
sms-spam-analysis/
├── data/
│   └── SMSSpamCollection          # Source dataset (from UCI, tab-separated)
├── spam_analysis.sql              # Pattern queries and spam signals
├── spam_analysis.R                # Statistical analysis and visualisation
└── README.md
```

---

## Key Findings

**Spam messages are significantly longer** than legitimate ones on average - they tend to pack in promotional content, URLs, and calls to action. The median spam message was 149 characters vs 62 for legitimate messages.

**Three signals reliably identify spam:**
- Contains a phone number (e.g. "Call 07946...") — present in 38% of spam, under 1% of legitimate
- Contains a URL - present in 29% of spam, 3% of legitimate
- Contains prize/win keywords ("winner", "free", "prize", "claim") - /present in 41% of spam

**Rule-based detection results:**

| Rule | Precision | Coverage |
|---|---|---|
| Contains phone number | 94% | 38% of spam |
| Contains URL | 88% | 29% of spam |
| Prize/win keywords | 91% | 41% of spam |
| Any one of the above | 83% | 63% of spam |

A simple combination of these three rules catches **63% of spam** at **83% precision** - with no model required.

---

## How to Reproduce

### SQL
```sql
-- Load SMSSpamCollection as a tab-separated file into a table called messages
-- columns: label (spam/ham), content (text)
-- Then run spam_analysis.sql
```

### R
```r
install.packages(c("tidyverse", "ggplot2", "scales"))
# Then run spam_analysis.R
# Update the file path on line 12 to point to your local dataset
```

---

## Skills Demonstrated

| Skill | Where |
|---|---|
| SQL pattern detection | `spam_analysis.sql` |
| Statistical analysis in R | `spam_analysis.R` |
| Rule-based classifier evaluation | Both files |
| Findings into actionable insight | This README |

---

*Project by D. Shivani*
