---
iip: 
title: Validator Scoring Mechanism
description: An automated and standardized system for monitoring validator behavior and scores
author: Olivia Saa (@oliviasaa) <olivia.saa@iota.org>
discussions-to: 
status: Draft
type: 
layer: 
created: 
requires: 
---

# Motivation

Validators are the backbone of the IOTA network. The performance of each validator directly influences the network’s overall efficiency and usability. Therefore, it is essential to incentivize validators to operate reliably and effectively by tying their rewards to their observed performance.

Currently, the only mechanism for penalizing underperforming validators is a manual reporting system. This system requires a quorum of validators to explicitly report a misbehaving peer in order to reduce their rewards. Such an approach is impractical, as it demands continuous manual monitoring, which is an unreasonable burden for most operators. Moreover, no standard criteria exist to guide reporting decisions, resulting in inconsistent and arbitrary thresholds set independently by each validator.

We propose an **automated and standardized system** for monitoring validator behavior, culminating in a commonly agreed score that reflects each validator’s performance during an epoch. These scores would directly influence the rewards distributed at the epoch’s end.

# Specification

## Performance Metrics and Proofs

Each validator will monitor its peers throughout an epoch, collecting performance metrics for every other validator. Regardless of the exact set of metrics used, they are divided into two categories: **provable** and **unprovable** metrics:

- **Unprovable metrics**: These represent misbehaviours for which a validator cannot produce a proof. Examples include malformed blocks or the dissemination of invalid blocks. Validators will collect and disseminate counts for those unprovable metrics. 
- **Provable metrics**: These include signed but invalid blocks and equivocations. Validators should produce *proofs* of these behaviours throughout the epoch and disseminate them.

For that, we introduce a new `ConsensusTransactionKind` specific to propagate both proofs of misbehaviors and the unprovable counts relative to metrics collected throguth the epoch. Whenever a block containing a transaction of this type is committed, validators update their counts for provable misbehaviours and also store the sender's view of the unprovable metrics. This type of transaction should be sent with a reasonable periodicity, so proofs don't accumulate too much, but at the same time, without taking unnecessary block space. We propose to follow the same periodicity of the checkpoint creation.

## Aggregating Metrics and calculating Scores

At the end of each epoch, validators should aggregate the different perceptions of the committee about all unprovable metrics in a deterministic way. With this aggregation and the provable counts, they calculate a score for each validator.

Scores can be updated during the epoch according to a partial  count of the validators' misbehaviours for monitoring purposes. Furthermore, metric counts and the score itself are used by the protocol at the epoch end to adjust rewards. Thus we calculate scores also with the same periodicity as checkpoint creation.

When the very last checkpoint of the epoch is created, all validators share the same view of the included transactions of the whole epoch, thus a validator can safely and deterministically calculate the scores based on his perception of the committed consensus transactions.

## Adjusting Rewards

The aggregated scores are passed to the advance_epoch function, where they are used to adjust validator rewards using the following formula:

`adjusted_rewards[i] = unadjusted_rewards[i] * aggregated_scores[i] / max_score`

Where `max_score` is the maximum achievable score. As in the current protocol, the difference between adjusted and unadjusted rewards is burned. 

# Rationale

## Performance Metrics

The categorization of metrics as provable or unprovable allows them to be treated differently. Unprovable metrics are highly gameable and should not lead to severe penalties. Provable metrics, if correctly designed, offer a reliable estimation of validator performance and potential malicious behaviour, and can therefore be used as part of a strong  incentivization mechanism.

Since proofs are embedded in committed blocks, validators already have a common view of all provable metrics. Thus, there is no need to report any count or score relative to provable metrics at the epoch end.

Unprovable metrics, on the other hand, remain entirely local to each validator. Therefore, they must be shared and agreed upon through the consensus mechanism.

## Aggregating Scores

The use of the checkpoint periodicity to create such transactions and to calculate scores is ideal, since the epoch end is naturally syncronized with a checkpoint creation. This timing ensures that the latest score data is captured for reward adjustment at the epoch’s end, without delays on the epoch advancement.

## Adjusting Rewards

Once consensus is reached on the score, adjusting rewards becomes straightforward. The score incorporates all locally computed metrics and is designed to ensure incentive compatibility. As such, it can be directly applied as a multiplicative factor to the unadjusted rewards.

# Reference Implementation

An initial set of metrics has already been implemented in the iota repository, along with a simple scoring function that serves as a placeholder for a more complete version. This reference implementation is available in the (already merged) [PR#7604](https://github.com/iotaledger/iota/pull/7604) and [PR#7921](https://github.com/iotaledger/iota/pull/7921) The remaining components required to achieve consensus on an aggregated score and to adjust rewards are implementated in this (still not merged) [PR#8521](https://github.com/iotaledger/iota/pull/8521).

# Backwards Compatibility

The introduction of a new type of consensus message is not backward compatible and must be implemented as a protocol upgrade enabling the new functionality. Additionally, since scores are passed to the `advance_epoch` function a new version of `ChangeEpoch` transaction should be created, together with a new version of the `iota-framework` package. All other changes are either local to the node (as storing and counting metrics). Those local changes should not cause any node behaviour or agreement problems.
