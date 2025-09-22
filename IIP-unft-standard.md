---
iip: <to be assigned>
title: Unified NFT Collection Standard
description: Defines a reusable Move module for initializing and operating NFT collections on Iota with pausable supply, capability-based access control, and optional max-supply limits.
author: fabw222
discussions-to: https://github.com/iotaledger/iips/issues
status: Draft
type: Standards Track
layer: Interface
created: 2024-05-27
requires:
replaces:
superseded-by:
---

## Abstract

`unft_standard` specifies a reusable Move module that streamlines the creation
and management of NFT collections on Iota. It standardizes the metadata layout,
capabilities for minting/burning, optional supply ceilings, and lifecycle
controls such as pausing, while emitting baseline events for indexing.

## Motivation

Projects launching NFTs currently implement bespoke collection logic, leading to
duplicated effort and inconsistent behavior across the ecosystem. This proposal
introduces a canonical module for initializing shared collection metadata,
tracking supply, and exposing mint/burn capabilities to downstream contracts.
Adopting a unified interface simplifies wallet support, analytics, and reuse of
composable primitives (e.g., launchpads, royalty services).

## Specification

### Module Overview

The module is published under `unft_standard::unft_standard`. Collections are
parameterized by a phantom type `T` supplied by the integrator.

Key structs:

- `NftMetadata<T>` – shared object storing human-readable attributes plus a
  `pausable` flag and optional `max_supply_hint`.
- `NftCollection<T>` – shared object tracking `max_supply`, `minted`, `burned`,
  and `paused` counters.
- `NftMintCap<T>` / `NftBurnCap<T>` / `NftMetadataCap<T>` – linear capabilities
  governing mint, burn, and metadata controls.

Initialization entry points:

```move
public fun create_collection<T>(
    publisher: &Publisher,
    name: String,
    description: String,
    image_url: String,
    external_url: option::Option<String>,
    decimals: u8,
    max_supply: option::Option<u64>,
    pausable: bool,
    make_burn_cap: bool,
    ctx: &mut TxContext
): (NftMintCap<T>, option::Option<NftBurnCap<T>>, NftMetadataCap<T>);

public fun create_unbounded_collection<T>(
    publisher: &Publisher,
    name: String,
    description: String,
    image_url: String,
    external_url: option::Option<String>,
    decimals: u8,
    initial_max_supply_hint: option::Option<u64>,
    pausable: bool,
    make_burn_cap: bool,
    ctx: &mut TxContext
): (NftMintCap<T>, option::Option<NftBurnCap<T>>, NftMetadataCap<T>);
```

Both functions share the metadata and collection objects and return the
capabilities for the caller to manage.

Supply registration helpers:

- `register_mint` – increments supply for a single object.
- `register_batch_mint` – accepts a vector of object IDs, ensures the batch does
  not exceed remaining capacity, and emits per-object events.
- `register_burn_with_cap` / `register_burn_owner` – record burn activity.

Lifecycle controls:

- `pause_collection` and `resume_collection` require `NftMetadataCap<T>` and a
  `NftMetadata<T>` reference. They abort with `ECollectionNotPausable` if the
  collection opted out via `pausable = false`.
- `assert_can_mint` enforces both `max_supply` (when provided) and `paused`
  status before any mint registration.

Metadata updates:

`update_metadata` accepts optional arguments per field. `image_url` and non-empty
`external_url` must include a `://` scheme or the call aborts with
`EInvalidImageUrl` / `EInvalidExternalUrl`.

### Events and Errors

Events: `CapsInitializedEvent`, `MintedEvent`, `BurnedEvent`,
`MetadataUpdatedEvent`.

Error codes: `ENotAuthorizedPublisher`, `EMaxSupplyExceeded`,
`EInvalidMintAmount`, `EInvalidImageUrl`, `EInvalidExternalUrl`,
`ECollectionPaused`, `ECollectionNotPausable`.

## Rationale

Returning capabilities rather than auto-transferring them avoids the composability
warnings in the Move linter and gives integrators explicit control of capability
storage. Batch minting minimizes transaction overhead for large drops. The
`pausable` metadata flag exposes collection policy to indexers, while
`ECollectionNotPausable` prevents accidental pausing when minting must stay
always-on. URL validation enforces a minimum quality bar for media references.

## Backwards Compatibility

The proposal does not modify existing on-chain resources; it introduces a new
module. Integrators must update their initialization calls to handle the
returned capability tuple and to supply the `pausable` argument. No consensus
rules are affected.

## Test Cases

Representative unit tests are supplied under `tests/unft_standard_tests.move`
covering initialization, batch minting, URL validation, pausing, and metadata
updates.

## Reference Implementation

```move
module unft_standard::unft_standard;

use std::option;
use std::vector;
use std::string::String;
use iota::event;
use iota::package::Publisher;

// ----------------------------
// Error codes
// ----------------------------
const ENotAuthorizedPublisher: u64 = 1;
const EMaxSupplyExceeded: u64 = 2;
const EInvalidMintAmount: u64 = 3;
const EInvalidImageUrl: u64 = 4;
const EInvalidExternalUrl: u64 = 5;
const ECollectionPaused: u64 = 6;
const ECollectionNotPausable: u64 = 7;

// ----------------------------
// IPX-style collection capabilities
// ----------------------------
public struct NftMintCap<phantom T> has key, store { id: object::UID }
public struct NftBurnCap<phantom T> has key, store { id: object::UID }
public struct NftMetadataCap<phantom T> has key, store { id: object::UID }

// ----------------------------
// Collection singletons and supply ledger
// ----------------------------
public struct NftMetadata<phantom T> has key, store {
    id: object::UID,
    name: String,
    description: String,
    image_url: String,
    external_url: option::Option<String>,
    decimals: u8 // Defaults to 0 for fractional display without affecting uniqueness
    max_supply_hint: option::Option<u64>,
    pausable: bool
}

public struct NftCollection<phantom T> has key, store {
    id: object::UID,
    max_supply: option::Option<u64>, // None represents an unlimited max supply
    minted: u64,
    burned: u64,
    paused: bool,
}

// ----------------------------
// Unified events (for indexing and aggregation)
// ----------------------------
public struct CapsInitializedEvent<phantom T> has copy, drop {
    burn_cap_minted: bool,
}
public struct MintedEvent<phantom T> has copy, drop { object: object::ID }
public struct BurnedEvent<phantom T> has copy, drop { object: object::ID }
public struct MetadataUpdatedEvent<phantom T> has copy, drop {}

// ----------------------------
// Collection initialization (requires Publisher authority)
// ----------------------------
/// Only the publisher of *T* may initialize the collection singletons and capabilities; pass `option::none` for an unlimited max supply. The newly created capability objects are returned for use in programmable transactions.
public fun create_collection<T>(
    publisher: &Publisher,
    name: String,
    description: String,
    image_url: String,
    external_url: option::Option<String>,
    decimals: u8,
    max_supply: option::Option<u64>,
    pausable: bool,
    make_burn_cap: bool,
    ctx: &mut TxContext
) : (
    NftMintCap<T>,
    option::Option<NftBurnCap<T>>,
    NftMetadataCap<T>
) {
    create_collection_internal<T>(
        publisher,
        name,
        description,
        image_url,
        external_url,
        decimals,
        max_supply,
        max_supply,
        pausable,
        make_burn_cap,
        ctx
    )
}

/// Convenience helper for creating a collection with no max supply cap while retaining an optional display hint. Returns the minted capability objects.
public fun create_unbounded_collection<T>(
    publisher: &Publisher,
    name: String,
    description: String,
    image_url: String,
    external_url: option::Option<String>,
    decimals: u8,
    initial_max_supply_hint: option::Option<u64>,
    pausable: bool,
    make_burn_cap: bool,
    ctx: &mut TxContext
) : (
    NftMintCap<T>,
    option::Option<NftBurnCap<T>>,
    NftMetadataCap<T>
) {
    create_collection_internal<T>(
        publisher,
        name,
        description,
        image_url,
        external_url,
        decimals,
        option::none<u64>(),
        initial_max_supply_hint,
        pausable,
        make_burn_cap,
        ctx
    )
}

fun create_collection_internal<T>(
    publisher: &Publisher,
    name: String,
    description: String,
    image_url: String,
    external_url: option::Option<String>,
    decimals: u8,
    max_supply: option::Option<u64>,
    supply_hint: option::Option<u64>,
    pausable: bool,
    make_burn_cap: bool,
    ctx: &mut TxContext
) : (
    NftMintCap<T>,
    option::Option<NftBurnCap<T>>,
    NftMetadataCap<T>
) {
    // Publisher check: must match the package/module that defines T
    assert!(publisher.from_package<T>(), ENotAuthorizedPublisher);

    let (
        md,
        col,
        mint,
        burn_opt,
        meta
    ) = new_collection_components<T>(name, description, image_url, external_url, decimals, max_supply, supply_hint, pausable, make_burn_cap, ctx);

    // Share the collection-level singletons so everyone can borrow them as shared objects
    transfer::share_object(md);
    transfer::share_object(col); // Share the supply ledger for O(1) reads/writes

    event::emit(CapsInitializedEvent<T>{ burn_cap_minted: make_burn_cap });

    (mint, burn_opt, meta)
}

fun validate_urls(image_url: &String, external_url: &option::Option<String>) {
    validate_single_url(image_url, EInvalidImageUrl);
    if (external_url.is_some()) {
        let url_ref = option::borrow(external_url);
        validate_single_url(url_ref, EInvalidExternalUrl);
    };
}

fun validate_single_url(url: &String, error: u64) {
    if (!has_scheme_or_empty(url)) {
        abort error
    };
}

fun has_scheme_or_empty(value: &String): bool {
    if (std::string::is_empty(value)) {
        return true
    };
    let separator = std::string::utf8(b"://");
    std::string::index_of(value, &separator) < std::string::length(value)
}

public(package) fun new_collection_components<T>(
    name: String,
    description: String,
    image_url: String,
    external_url: option::Option<String>,
    decimals: u8,
    max_supply: option::Option<u64>,
    supply_hint: option::Option<u64>,
    pausable: bool,
    make_burn_cap: bool,
    ctx: &mut TxContext
): (
    NftMetadata<T>,
    NftCollection<T>,
    NftMintCap<T>,
    option::Option<NftBurnCap<T>>,
    NftMetadataCap<T>
) {
    validate_urls(&image_url, &external_url);
    let md = NftMetadata<T>{
        id: object::new(ctx),
        name,
        description,
        image_url,
        external_url,
        decimals,
        max_supply_hint: supply_hint,
        pausable
    };
    let col = NftCollection<T>{
        id: object::new(ctx),
        max_supply,
        minted: 0,
        burned: 0,
        paused: false
    };
    let mint = NftMintCap<T>{ id: object::new(ctx) };
    let meta = NftMetadataCap<T>{ id: object::new(ctx) };
    let burn_opt = if (make_burn_cap) {
        option::some(NftBurnCap<T>{ id: object::new(ctx) })
    } else {
        option::none<NftBurnCap<T>>()
    };
    (md, col, mint, burn_opt, meta)
}

// ----------------------------
// Metadata updates (requires NftMetadataCap)
// ----------------------------
public fun update_metadata<T>(
    _cap: &NftMetadataCap<T>,
    md: &mut NftMetadata<T>,
    name: option::Option<String>,
    description: option::Option<String>,
    image_url: option::Option<String>,
    external_url: option::Option<String>,
    decimals: option::Option<u8>,
    max_supply_hint: option::Option<option::Option<u64>>
) {
    if (name.is_some()) { md.name = name.destroy_some(); };
    if (description.is_some()) { md.description = description.destroy_some(); };
    if (image_url.is_some()) {
        let new_image = image_url.destroy_some();
        validate_single_url(&new_image, EInvalidImageUrl);
        md.image_url = new_image;
    };
    if (external_url.is_some()) {
        let new_external = external_url.destroy_some();
        validate_single_url(&new_external, EInvalidExternalUrl);
        md.external_url = option::some(new_external);
    };
    if (decimals.is_some()) { md.decimals = decimals.destroy_some(); };
    if (max_supply_hint.is_some()) { md.max_supply_hint = max_supply_hint.destroy_some(); };
    event::emit(MetadataUpdatedEvent<T>{});
}

// ----------------------------
// Supply tracking (minimal intrusion: called after external mint/burn)
// ----------------------------
/// Record a mint driven by the publisher-held NftMintCap; pass the minted object's ID (via `object::id(&obj)`)
public fun register_mint<T>(
    _mint: &NftMintCap<T>,
    col: &mut NftCollection<T>,
    minted_obj: object::ID
) {
    assert_can_mint(col, 1);
    col.minted = col.minted + 1;
    event::emit(MintedEvent<T>{ object: minted_obj });
}

/// Record multiple mints in a single call.
public fun register_batch_mint<T>(
    _mint: &NftMintCap<T>,
    col: &mut NftCollection<T>,
    minted_ids: vector<object::ID>
) {
    let count = vector::length(&minted_ids);
    if (count == 0) {
        return
    };
    assert_can_mint(col, count);
    col.minted = col.minted + count;

    let mut ids = minted_ids;
    while (!vector::is_empty(&ids)) {
        let id = vector::pop_back(&mut ids);
        event::emit(MintedEvent<T>{ object: id });
    };
}

/// Record a burn that uses the burn capability path
public fun register_burn_with_cap<T>(
    _burn: &NftBurnCap<T>,
    col: &mut NftCollection<T>,
    burned_obj: object::ID
) {
    col.burned = col.burned + 1;
    event::emit(BurnedEvent<T>{ object: burned_obj });
}

/// Record a burn without a burn capability—used when holders burn directly and an external module deletes the object
public fun register_burn_owner<T>(
    col: &mut NftCollection<T>,
    burned_obj: object::ID
) {
    col.burned = col.burned + 1;
    event::emit(BurnedEvent<T>{ object: burned_obj });
}

/// Pause minting-related operations for the collection.
public fun pause_collection<T>(
    _cap: &NftMetadataCap<T>,
    metadata: &NftMetadata<T>,
    col: &mut NftCollection<T>
) {
    assert!(metadata.pausable, ECollectionNotPausable);
    col.paused = true;
}

/// Resume minting-related operations for the collection.
public fun resume_collection<T>(
    _cap: &NftMetadataCap<T>,
    metadata: &NftMetadata<T>,
    col: &mut NftCollection<T>
) {
    assert!(metadata.pausable, ECollectionNotPausable);
    col.paused = false;
}

// ----------------------------
// Convenience accessors
// ----------------------------
public fun supply<T>(col: &NftCollection<T>): (u64, u64, option::Option<u64>) {
    (col.minted, col.burned, col.max_supply)
}

fun assert_can_mint<T>(col: &NftCollection<T>, amount: u64) {
    assert!(amount > 0, EInvalidMintAmount);
    assert!(!col.paused, ECollectionPaused);
    if (col.max_supply.is_some()) {
        let max_supply_ref = col.max_supply.borrow();
        assert!(col.minted + amount <= *max_supply_ref, EMaxSupplyExceeded);
    };
}

#[test_only]
public(package) fun metadata_refs<T>(
    metadata: &NftMetadata<T>
): (
    &String,
    &String,
    &String,
    &option::Option<String>,
    u8,
    &option::Option<u64>,
    bool
) {
    (
        &metadata.name,
        &metadata.description,
        &metadata.image_url,
        &metadata.external_url,
        metadata.decimals,
        &metadata.max_supply_hint,
        metadata.pausable
    )
}

#[test_only]
public(package) fun collection_snapshot<T>(
    col: &NftCollection<T>
): (&option::Option<u64>, u64, u64, bool) {
    (&col.max_supply, col.minted, col.burned, col.paused)
}

#[test_only]
public(package) fun destroy_components_for_tests<T>(
    metadata: NftMetadata<T>,
    collection: NftCollection<T>,
    mint: NftMintCap<T>,
    burn_opt: option::Option<NftBurnCap<T>>,
    meta_cap: NftMetadataCap<T>
) {
    let NftMetadata { id, .. } = metadata;
    object::delete(id);

    let NftCollection { id, .. } = collection;
    object::delete(id);

    let NftMintCap { id } = mint;
    object::delete(id);

    if (burn_opt.is_some()) {
        let burn = burn_opt.destroy_some();
        let NftBurnCap { id } = burn;
        object::delete(id);
    } else {
        burn_opt.destroy_none();
    };

    let NftMetadataCap { id } = meta_cap;
    object::delete(id);
}

#[test_only]
public(package) fun destroy_caps_for_tests<T>(
    mint: NftMintCap<T>,
    burn_opt: option::Option<NftBurnCap<T>>,
    meta_cap: NftMetadataCap<T>
) {
    let NftMintCap { id } = mint;
    object::delete(id);

    if (burn_opt.is_some()) {
        let burn = burn_opt.destroy_some();
        let NftBurnCap { id } = burn;
        object::delete(id);
    } else {
        burn_opt.destroy_none();
    };

    let NftMetadataCap { id } = meta_cap;
    object::delete(id);
}
```

## Acknowledgements
[IPX Coin Standard](https://github.com/interest-protocol/ipx-coin-standard)

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
