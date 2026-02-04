---
iip: <to be assigned>
title: Dynamic Minimum Commission based on the Validator's Voting Power per Epoch
description: A dynamic minimum validator commission rate set to the validator's voting power percentage to prevent stake hoarding and promote decentralization.
author: DLT.GREEN (@dlt_green)
discussions-to: https://github.com/iotaledger/IIPs/discussions/29
status: Draft
type: Standards Track
layer: Core
created: 2026-01-16
---

## Abstract

This IIP introduces a dynamic minimum validator commission rate that is automatically set to the validator's effective voting power percentage (VP%) at the start of each epoch. Implemented as a simple `max(validator_set_commission, VP%)` enforcement, it prevents large validators from using persistently low or zero commissions to hoard stake, thereby reducing centralization risks and improving the sustainability and competitiveness of smaller validators.

Due to the existing protocol cap on individual validator voting power at 10%, the enforced minimum commission will never exceed 10%.

## Motivation

In the current IOTA staking system, validators are free to set any commission rate, including 0%. Large validators (or those with significant self-stake) can leverage low commissions to attract a disproportionate share of delegations, leading to concentration of voting power. This creates a feedback loop where dominant validators become increasingly attractive to delegators seeking maximum rewards, marginalizing mid-sized and smaller validators and threatening long-term network decentralization.

The protocol already caps individual validator voting power at 10% (with excess stake redistributed to promote balance). However, low/zero-commission strategies still incentivize stake hoarding up to this cap. Tying the minimum commission to VP% provides a proportional economic disincentive without introducing new caps or complexity.

A recent snapshot (January 2026) showed that only ~6 out of 73 active validators would be immediately affected by this rule, indicating minimal short-term disruption while providing a meaningful guardrail against further centralization. Community discussions highlighted broad concern about stake hoarding and strong preference for a lightweight, proportional solution.

## Specification

At the start of each epoch, during committee selection and staking reward calculations:

1. Use the validator's **effective voting power percentage (VP%)** as determined by the protocol (already capped at a maximum of 10%).

2. Enforce the effective minimum commission for the epoch:

`effective_commission = max(validator_set_commission, VP%)`

The validator's publicly set commission remains unchanged for display and future epochs; only the effective rate applied to rewards in the current epoch is adjusted upward if necessary.

No other changes to delegation, reward distribution, or committee selection mechanics are required.

## Rationale

- **Proportionality**: Tying the minimum commission directly to influence (effective voting power) creates a natural economic incentive for stake distribution without arbitrary thresholds.
- **Bounded Impact**: With the protocol's 10% voting power cap per validator, the maximum enforced minimum commission under this rule is 10%, ensuring predictability and preventing excessive commission forcing.
- **Simplicity**: The change requires only a minor adjustment in epoch-boundary logic and imposes negligible computational overhead.
- **Non-punitive**: Validators can always set a higher commission proactively; the rule only corrects excessively low rates that contribute to centralization.
- **Community consensus**: Extensive discussion showed strong validator support (~45% of surveyed stake weight fully supported this VP%-based model). The IOTA Foundation/Protocol Research team has expressed support for this lightweight approach as an effective initial guardrail.

This design preserves delegator choice while gently nudging the system toward healthier stake distribution.

## Backwards Compatibility

The proposal is fully backwards compatible. No existing functionality is removed, and all current validator configurations remain valid. Validators with set commissions already ≥ their effective VP% are unaffected. Those with lower commissions will see their effective rate increased for the epoch (up to a maximum of 10%), but delegators are not penalized retroactively, and validators retain full control over future settings.

No hard fork is required.

## Test Cases

Test cases should verify:

- A validator with 8% effective VP and 0% set commission has effective commission forced to 8%.
- A validator with 10% effective VP (at cap) and 5% set commission has effective commission forced to 10%.
- A validator with 10% effective VP and 12% set commission retains 12% effective commission.
- A validator with potential uncapped stake >10% but effective VP capped at 10% has minimum commission enforced at most 10%.
- VP% calculations correctly handle edge cases (e.g., very small validators with VP% < 0.01%).

## Reference Implementation

No full implementation is provided yet, as the change is minimal. It consists of adding the `max()` enforcement in the epoch transition logic where staking rewards and performance factors are computed, using the already-capped effective voting power values.

## Security Considerations

The change introduces no new attack vectors. All calculations use existing, audited stake accounting and voting power capping mechanisms. By reducing incentives for voting power concentration, it strengthens resistance to centralization-based attacks. No new privileges or state mutations are added.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
