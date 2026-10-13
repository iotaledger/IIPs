---
iip: 
title: Score-based Reward Distribution
description: New reward distribution algorithms based on validator scores.
author: Olivia Saa (@oliviasaa) <olivia.saa@iota.org>
discussions-to: 
status: Draft
type: 
layer: 
created: 
requires: 
---


# Motivation

We proposed in IIP ADD LINK an **automated and standardized system** for monitoring validator behavior, that woulnd culminate in a commonly agreed score that reflects each validator’s performance during an epoch. In the current IIP, we propose how these scores are calculated to directly influence the rewards distributed at the epoch’s end.

Distributed protocols frequently depend on validator-reported metrics that cannot be objectively verified. These *unprovable metrics* introduce a significant vulnerability: malicious validators may strategically distort their reports to influence the aggregated scores used for rewards or penalties.

Under a standard Byzantine model with $3f+1$ validators and up to $f$ byzantine participants, adversaries may attempt to:

- deflate the scores of honest peers,
- inflate the scores of malicious peers,
- create conflicting views among honest reporters.

Because reports come from both honest and malicious sources, the protocol must aggregate subjective views into a stable, manipulation-resistant score. A feasible mechanism must:

1. Tolerate arbitrary malicious inputs.
2. Preserve accuracy for honest validators.
3. Detect and isolate malicious reporters and malicious targets.
4. Ensure that reward calculations remain fair and robust.

This proposal introduces an order-statistic-based scoring algorithm that meets these requirements and provides formal guarantees under the $3f+1$ model.

# Specification

### Metrics

During an epoch, each validator will monitor its peers throughout an epoch, collecting performance metrics for every other validator. Regardless of the exact set of metrics used, they are divided into two categories: **provable** and **unprovable** metrics.

While provable metrics allow for objective verification and the submission of proofs for misbehavior, unprovable metrics naturally lack such formal accountability mechanisms. At the end of the epoch, validators will share a common view of provable metrics. Based on IIP ADD LINK, validators will also share a common view of the metrics that all validators report about each other. We begin by defining how such reports can be deterministically aggregated.


Validator scoring proceeds in **four phases**:

1. Aggregation of reports using order statistic.  
2. Identification of malicious reporters and malicious peers using ε-bounded deviation checks.  
3. Re-computation of scores using only trusted data.  
4. Penalization of malicious validators.

Next section defines the normative behavior of each phase.

### Calculating scores - algorithm overview

#### Step 1: Aggregation of metrics

Let $m$ be a metric of interest. Let $m(i, j)$ denote validator $i$’s subjective report about validator $j$'s metric $m$. For each validator $j$ and metric $m$, collect all received reports:

$R(j) = \{ m(i, j) | \text{ for all validators } i \text{ who sent reports}\}$

The aggregated score for validator $j$ is computed using the **stake weighted k_th order statistics** of the report set:

$m_a(j) = \text{stake weighted k-os}( R(j) )$

for $k\in [f,r-f]$ and $r$ is the number of received reports. This order-statistic-based aggregation is the base for the entirety of the scoring pipeline.

#### Step 2: Misbehavior Detection

The protocol defines a tolerance parameter $\varepsilon$, representing the maximum acceptable deviation between honest reports.
- A validator $i$ **MUST** be flagged as malicious if
$|m(i, j)-m_a(j) | > \varepsilon$ for more than $2f + 1$ distinct validators $j$.

    This indicates that reporter $i$ is inconsistent with the honest cluster on more validators than possible under the Byzantine bound.

- A validator $j$ **MUST** be flagged as malicious if:
$|m(i, j)-m_a(j) | > \varepsilon$ for more than $f + 1$ distinct reporters $i$.

    This indicates that $j$ elicits inconsistencies from more than the maximum allowed number of malicious reporters.

#### Step 3. Final Scoring of Honest Validators

After removing all flagged reporters and flagged peers, the protocol computes a refined score defined in the next section.

#### Step 4. Penalization of Malicious Validators

All validators flagged as malicious via step 1 or 2 should be penalized by reducing their scores. Penalties **MUST** be deterministic and verifiable from the set of published reports and aggregated computations.

### Computing the score - proposed formula

- **Step 1:** For all unprovable metrics, we perform the order statistics-based aggregation defined above, resulting on a single value $m_a(j)$ for each metric and validator.

    Each value $m_a(j)$ is then normalized into a value $m_\text{score}$ between 0 and 1, reflecting how close a validator’s behavior remains to the acceptable range. Note that this normalization is not directly suitable for fixed-point arithmetic and must be appropriately scaled in the implementation.

    - If $m(i) ≤ m_{\text{allowance}}$, then $m_{\text{score}}(i) = 1$,
    - If $m(i) ≥ m_{\text{max}}$, then  $m_{\text{score}}(i) = 0$,
    - Otherwise, $m_{\text{score}}(i) = (m_{\text{max}} - m(i))/(m_{\text{max}} - m_{\text{allowance}})$

    where:
    - $m(i)$ is the measured count for validator $i$,
    - $m_{\text{allowance}}$ defines the tolerated number of occurrences without penalty,
    - $m_{\text{max}}$ is the threshold beyond which the score for that metric becomes zero.


- **Step 2:** Once all individual metric scores are obtained, they are combined into a final single score for each validator. We do that by first dividing the metrics into "hard punishable" misbehaviors or not.

    Given our set of hard punishable metrics $m^1, ..., m^N$ and our set of not hard punishable metrics $m^{N+1}, ..., m^{N+n}$ we combine $m_{scores}$ as:

    $\text{score}(i) = \text{max score} * \prod_{j=1}^{N} m^j_{scores}(i) * (a + \sum_{j=N+1}^{N+n} w_j * m^j_{scores}(i)) / (a + \sum_{j=N+1}^{N+n} w_j)$

where
- $w_j$ are weights for the not hardly punishable metrics.
- $\text{max score}$ is another normalization factor determining the upper bound of the score,
- $a$ is a baseline term ensuring the score remains positive even when all metrics (except equivocations) are degraded.

The use of the separate formulas in the metric normalization ensures that no metric can contribute a negative value, effectively capping penalties once the threshold is exceeded. This formulation provides a flexible and deterministic scoring system, where all validators can independently compute identical scores given the same inputs. The weighting and allowance parameters can be tuned through protocol updates to maintain desired game-theoretical properties, balancing fairness, robustness, and network performance incentives.


## Rationale

### Order Statistic Choice

The $(r - f)$-th order statistic is selected because:

- Malicious validators can contribute at most $f$ extreme high values.
- Trimming these values guarantees robustness against inflating attacks.
- The statistic lies within the bounded interval defined by honest reports.
- Monotonicity is preserved by construction.

Using means or weighted averages is insecure because a single malicious outlier can arbitrarily shift results.

### Misbehavior Detection Thresholds

The thresholds used in steps 1 and 2 derive directly from the $3f+1$ Byzantine model (at most $f$ malicious validadors among $3f+1$).

Thus:
- A reporter deviating from more than $2f+1$ peers **cannot** be honest.
- A peer causing more than $f+1$ large deviations **cannot** be honest.

These thresholds reflect the maximum number of disagreements possible under honest conditions.

### Two-Phase Aggregation

The first aggregation phase ensures robustness against adversarial inputs.  
The second phase, executed only on trusted validators, ensures accuracy:

- Honest reports cluster tightly around the fair value.
- Using the median guarantees stability and resistance to noise.
- Removing flagged nodes prevents residual influence by borderline manipulators.

This two-layer structure combines *resilience* and *precision*.

### Penalization

Penalizing malicious validators is necessary to ensure that dishonest reporting incurs economic cost, pushing rational actors to prefer honest behavior. Without penalties, validators might repeatedly attempt manipulation at no risk.

### Justification for the scoring formula

- Penalizing part of misbehaviors through multiplicative scoring: By structuring the score as a multiplicative function, where part of the metrics acts as a scaling factor on the auxiliary score, we ensure that any hardly penalizable incident proportionally suppresses all other positive contributions.
For example, a validator that equivocates repeatedly should not compensate for this behavior through otherwise good performance—its overall score should be significantly reduced regardless of other metrics. This design introduces non-linear penalties, discouraging validators from engaging in behavior that could compromise network integrity, even if other performance aspects remain satisfactory.
- Linearly Weighted Auxiliary Components: the second term in the formula aggregates less severe but still important aspects of validator behavior through a weighted linear combination.
Each component contributes proportionally to the total, with penalties that increase smoothly as the corresponding count grows beyond its allowance threshold.
This linear design simplifies interpretation and configuration, allowing us to tune the sensitivity of each metric independently.
- Allowance Parameters: Each metric includes an allowance term, defining the level of deviation tolerated before a penalty applies. This mechanism acknowledges the realities of distributed operation—temporary network issues, minor configuration errors, or maintenance downtime—and ensures validators are not unduly penalized for rare, non-malicious events. It also makes the system adaptable: as the network matures or validator requirements evolve, allowances can be adjusted to reflect new reliability expectations.
- Tunable Weights: Finally, the weighting parameters $w_i$ provide a straightforward method for the protocol to rebalance incentives over time. By adjusting these values, we can emphasize specific aspects of validator performance—such as uptime, accuracy, or consensus integrity—based on empirical observations and evolving network priorities.

# Reference Implementation

An initial set of metrics has already been implemented in the iota repository, along with a simple scoring function that serves as a placeholder for a more complete version. This reference implementation is available in the (already merged) [PR#7604](https://github.com/iotaledger/iota/pull/7604) and [PR#7921](https://github.com/iotaledger/iota/pull/7921). A more complex scoring formula following this IIP is implementated in this (still not merged) [PR#8521](https://github.com/iotaledger/iota/pull/8521).

# Backwards Compatibility
