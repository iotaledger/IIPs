---
iip: 2
title: Starfish Consensus Protocol
description: A DAG-based consensus protocol improving liveness and efficiency
author: Nikita Polianskii (@polinikita) <nikita.polianskii@iota.org>
discussions-to: https://github.com/iotaledger/IIPs/discussions/10
status: Draft
type: Standards Track
layer: Core
created: 2025-04-16
requires: None
---

## Abstract

This IIP proposes Starfish, a DAG-based consensus protocol enhancing Mysticeti. Starfish decouples block headers from transaction data, enabling push-based header dissemination, and encodes transaction data into Reed-Solomon shards for efficient reconstruction. These mechanisms improve liveness, reduce communication complexity to linear, and lower storage overhead, even in Byzantine environments.

## Motivation

Starfish addresses three limitations in Mysticeti:

**Liveness.** Because of Byzantine behaviour, slow or deadlocked network connection and/or slow computational capability, some 
validators, hereafter called _slow_ validators, can share its own block to only a few selected peers in time. Blocks that reference 
blocks of slow validators can stay suspended in the block managers for a long time depending on the depth of the missing 
causal history. In Mysticeti, the blocks of the recent DAG are fetched by explicit requesting the missing parents of a given suspended block.
This slow synchronization of the recent DAG can trigger liveness issues in Mysticeti. Starfish allows for faster synchronization 
of the recent DAG.

**Communication complexity.** For n=3f+1, we can observe in the network with f slow validators situations when each block of a slow validator, while being disseminated to f not-slow validators, will be requested from these validators by other validators.
This may lead to impractical quadratic communication complexity O(n^2). Starfish keeps the communication complexity linear
for all circumstances by using Reed-Solomon codes and using shards in dissemination of other blocks.

**Storage overhead.** Now each validator store the whole transaction data associated with a block. With Starfish, we can
store block headers with only one shard of transaction data, reducing the size of the consensus database.

## Specification
Starfish requires implementation of a new crate as it contains many new components in consensus and modifies existing modules.
Below, we sum up the most important changes compared to the current version of Mysticeti:
 - Block Structure: 
   - Separation of Header and Data: Blocks are split into headers (containing metadata) and body optionally containing transaction data or shard. Only headers are signed, and the block digest is calculated solely from the header.
   - Data Commitment: Blocks include a Merkle root commitment to encoded transaction data. 
   - Data Acknowledgment: Once the transaction data of a block is available by a validator, it should acknowledge that in next block. 
   - Sharding with Reed-Solomon Codes: Transaction data is encoded into shards using Reed-Solomon codes, allowing reconstruction from a subset of shards. 
   The commitment could be a Merkle tree on the encoded shards. For own blocks, send full transaction data; for blocks of other validators, send shards together with proofs. 
 - Encoder/Decoder: block verifier, core and data manager should be equipped by [n,f+1] Reed-Solomon encoders and decoders to a) ensure the correctness
of the computed transaction commitment, b) be able to decode the transaction data from locally available shards, c) create 
new blocks
 - Block Verifier:
   Validates incoming block headers independently. If transaction data is received, verifies its commitment against the header to ensure correctness.
- Data Manager:
 Handles transaction data retrieval and reconstruction. Requests missing data from the block author first (full data with sharding) or from nodes acknowledging the data (shards). Once reconstructed, data is forwarded to the DagState for storage and future serving.
 - Block Creation:
 Generates blocks with separate headers and transaction data. The data commitment should be computed based on the encoded transaction data by using some commitment scheme that allow for proofs, e.g. Merkle tree. Includes in a block header pending data acknowledgments.
 - Dag State:
   In addition, it should track for which blocks, a validator has transaction data (pending acknowledgments). Another important structure should provide information about who knows which block headers to disseminate only those block headers
that are indeed needed.
 - Linearizer:
   Tracks data acknowledgments for past blocks, including only quorum-acknowledged data in new commits. 
 - Streaming own blocks:
   Broadcast own blocks with their transaction data and block headers potentially missing by peers. 
 - Storage:
   Separates storage for headers and shards and own transaction data. Triggers data storage upon availability to minimize overhead.
 - Commit Structure:
   Includes references to headers traversed by the Linearizer for data acknowledgment collection. Lists data blocks with a quorum of acknowledgments with optional bitmaps of acknowledging nodes to optimize data retrieval.

Starfish can be enabled via protocol parameters. 

For theoretical details, see [eprint.iacr.org/2025/567](https://eprint.iacr.org/2025/567). 

## Rationale

Starfish’s design is driven by the need to enhance Mysticeti’s performance in bad network conditions and/or adversarial environment. Key decisions include:

- **Header-Data Decoupling**: Since the constructed DAG in Mysticeti is uncertified, the block propogation is one of the key issues. We decouple the header from data in the block structure to ensure that we can push all the required block headers. Only block headers are needed for driving the consensus. The transaction data can be retrieved once sequenced.
- **Data Acknowledgments**: Since we decouple headers from data, we can't simply sequence the data associated with a block by a vanilla Mysticeti commit rule as it might be unavailable by a majority of the network. Thereby, one needs to include in block headers acknowledgments about transaction data availability for past blocks. In addition, for sequencing transactions one needs to get a quorum of acknowledgments.
- **Reed-Solomon Sharding**: Chosen for its ability to reconstruct data from any f+1 shards, ensuring linear communication complexity. Reed-Solomon codes are optimal in terms of recoverability and this is a primary reason why we stick with them. In addition, there are libraries (e.g. https://crates.io/crates/reed-solomon-simd) that are very CPU efficient and consume little memory.
- **Merkle Tree Commitments**: Preferred for their simple proof generation, enabling shard verification without full data.
- **Data Manager**: To ensure live consensus decisions, it is enough to have available all block headers in the causal history of blocks. Data manager is needed to fetch potentially missing transaction data from peers once it is sequenced and available to a quorum of the network.

## Backwards Compatibility

Starfish introduces backwards incompatibilities with Mysticeti consensus crate:

- **Block Structure**: The new header-data split and sharding are incompatible with Mysticeti’s monolithic blocks. 
- **Storage**: Mysticeti’s full-data storage is replaced by header-shard storage. This storage is not replacable across validators.
- **Protocol Logic**: Components like block verifier and linearizer require updates, breaking compatibility with Mysticeti’s logic.

**Mitigation**:
- Use crate `iotaledger/iota/crates/starfish` and enable Starfish with protocol parameters.
- Test compatibility in a public testnet to ensure node upgrades are seamless.
- Remove `iotaledger/iota/consensus` at a later point

## Test Cases
The new consensus crate will need to be extensively tested. In particular, all exising modules, e.g. block verifier, will require modifications in existing tests.
All new modules (e.g. encoder/decoder) will require testing of typical possible scenarios.
To ensure that the new consensus serves its purposes, there should be tests mimicking slow validators that fail to properly disseminate their blocks and this behaviour should not affect the liveness of the consensus.



## Reference Implementation

A prototype implementation is available at [github.com/iotaledger/starfish](https://github.com/iotaledger/starfish). It includes:

- A new crate with core Starfish-specific components (tracking who knows which block headers, encoding/decoding, data fetcher, Starfish linearizer sequencer, etc.).
- Modified Mysticeti modules (Block store, Linearizer, Block Verifier).
- Simulation scripts to test latency, throughput and bandwidth efficiency locally and in a geo-distributed network.

This draft aids consensus developers and will be refined for production.

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
