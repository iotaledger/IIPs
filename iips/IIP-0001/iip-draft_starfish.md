---
iip: 1
title: IIP Process
description:  Purpose and guidelines of the contribution framework
author: Levente Pap (@lzpap) <levente.pap@iota.org>
discussions-to: https://github.com/iotaledger/iips/discussions
status: Active
type: Process
created: 2025-02-12
---

## Abstract

This IIP proposes Starfish, a new DAG-based consensus protocol that can be seen as improvement over Mysticeti.
Starfish combines two ideas: first, we decouple in the block structure transaction data from the block headers, allowing
dissemination of block headers without data; second, we encode the transaction data using Reed-Solomon codes into encoded shards, 
enabling reconstruction of transaction data from a few shards. Since the block headers are of small size, we can push to a peer all block 
headers that might be not known by the peer. This allows peers to include in the local DAG a received block upon its
reception, and drive the DAG construction and the commit rule in time. This brings more liveness compared to Mysticeti. Sharding
allows to control the communication complexity and potentially storage complexity and keep it low even in the Byzantine environment.

## Motivation

The motivation for this IIP comes from our theoretical discussion and practical observation in the Testnet around Mysticeti.
Because of Byzantine behaviour, slow or deadlocked network connection and/or slow computational capability, some 
validators, later called bad validators, can share its own block to only a few selected peers in time. Blocks of good validators that reference 
blocks of bad validators can stay suspended in the block managers of validators depending on the depth of the missing 
causal history.


## Design / Specification

### IIP Types

There are 3 types of IIPs:
 - A **Standards Track IIP** describes any change that affects most or all IOTA node implementations, such as a change to the network protocol, a change in transaction validity rules, or any change or addition that affects the interoperability of applications using IOTA. Standards Track IIPs consist of two parts, a design document and a reference implementation. Standards Track IIPs can be broken down into following layers:
   1. **Core**: Changes or additions to core features of IOTA, including consensus, execution, storage, and account signatures
   2. **Networking**: Changes or additions to IOTA's mempool or network protocols
   3. **Interface**: Changes or additions to RPC or API specifications or lower-level naming conventions
   4. **Framework**: Changes or additions to IOTA Move contracts and primitives included within the codebase, such as within the IOTA Framework
   5. **Application**: Proposals of new IOTA Move standards or primitives that would not be included within the IOTA codebase but are of significant interest to the developer community
 - An **Informational IIP** describes an IOTA design issue, or provides general guidelines or information to the IOTA community, but does not propose a new feature. Informational IIPs do not necessarily represent an IOTA community consensus or recommendation, so users and implementors are free to ignore Informational IIPs or follow their advice.
 - A **Process IIP** describes a process surrounding IOTA, or proposes a change to (or an event in) a process. Process IIPs are like Standards Track IIPs but apply to areas other than the IOTA protocol itself. They may propose an implementation, but not to IOTA's codebase; they often require community consensus; unlike Informational IIPs, they are more than recommendations, and users are typically not free to ignore them. Examples include procedures, guidelines, changes to the decision-making process, and changes to the tools or environment used in IOTA development.

It is highly recommended that an IIP outlines a single key proposal, idea or feature; the narrower the scope of the IIP is, the easier it becomes to reach consensus on the proposed feature and incorporate it into the protocol. Several IIPs can form a bundle of changes when linked to each other.

### IIP Format and Structure

IIPs must adhere to the format and structure requirements that are outlined in this document. A IIP is written in [Markdown](https://docs.github.com/en/github/writing-on-github/getting-started-with-writing-and-formatting-on-github/basic-writing-and-formatting-syntax) format and should have the following parts (optional parts are marked with a *):

| Name                      | Description                                                                                                                                                                                                                                                                                                                                                                                                                   |
|---------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Preamble                  | [RFC 822](https://www.ietf.org/rfc/rfc822.txt) style headers containing metadata about the IIP, including the IIP number, a short descriptive title (limited to a maximum of 44 characters), a description (limited to a maximum of 140 characters), and the author details. Irrespective of the category, the title and description should not include IIP number. [See below](#iip-header-preamble) for details.            |
| Abstract                  | A short summary of the technical issue being addressed by the IIP.                                                                                                                                                                                                                                                                                                                                                            |
| Motivation                | A motivation section is critical for IIPs that want to change the IOTA protocol. It should clearly explain why the existing protocol specification is inadequate to address the problem that the IIP solves. IIP submissions without sufficient motivation may be rejected outright.                                                                                                                                          |
| Specification             | The technical specification should provide a concise, high level design of the change or feature, without going deep into implementation details. It should also describe the syntax and semantics of any new feature.                                                                                                                                                                                                        |
| Rationale                 | The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages. The rationale may also provide evidence of consensus within the community, and should discuss important objections or concerns raised during discussion. |
| Backwards Compatibility*  | All IIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The IIP must explain how the author proposes to deal with these incompatibilities. IIP submissions without a sufficient backwards compatibility treatise may be rejected outright.                                                                                                          |
| Test Cases*               | Test cases for an implementation are mandatory for IIPs that are affecting consensus changes. Tests should either be inlined in the IIP as data or placed in the IIP folder.                                                                                                                                                                                                                                                  |
| Reference Implementation* | An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification.                                                                                                                                                                                                                                                                       |
| Copyright                 | All IIPs must be in the public domain. See the bottom of this IIP for an example copyright waiver.                                                                                                                                                                                                                                                                                                                            |

### IIP Template

The template to follow for new IIPs is located in the [repository](https://github.com/iotaledger/iips/blob/main/TEMPLATE.md).

### IIP Process

Parties involved in the process are:
 - _IIP author_: you, the champion who proposes a new IIP. **It is the responsibility of the _IIP author_ to drive the progression of the IIP to `Active` status. This includes initiating public discussion and implementing the proposal as well.**
 - _IIP editor_: they deal with administering the IIP process and ensure process requirements are fulfilled.
 - _Core contributors_: technical experts of IOTA who evaluate new IIPs, provide feedback and ensure that only sound and secure features are added to the protocol.
 
#### IIP Statuses

The status of the IIP describes its current stage in the IIP process.

| Status    | Description                                                                                                   |
|-----------|---------------------------------------------------------------------------------------------------------------|
| Idea      | An idea for an improvement to the IOTA technology. Not yet tracked as an official IIP.                        |
| Draft     | The idea has been formally accepted in the repository, and is being worked on by its authors.                 |
| Proposed  | The IIP has a working implementation and has clear plans on how to progress to `Active` status.               |
| Active    | The IIP is deployed to the main network or some IIP specific adoption criteria has been met.                  |
| Deferred  | The _IIP author(s)_ are not working on the IIP currently, but plan to continue in the future. IIP is on hold. |
| Rejected  | The IIP is rejected.                                                                                          |
| Withdrawn | The IIP has been withdrawn by the _IIP author(s)_.                                                            |
| Replaced  | The IIP is replaced by a newer IIP. Must point to the new IIP in the header.                                  |
| Obsolete  | The IIP is rendered obsolete by some future change.                                                           |

#### IIP Workflow

##### How are new proposal get added to the protocol?

1. All IIPs begin life as an `Idea` proposed in the public [IOTA discussion forum, that is the GitHub Discussion page of the IIP repository](https://github.com/iotaledger/iips/discussions). A public, open discussion should predate any formal IIP submission. If you want to propel your proposal to acceptance, you should make sure to build consensus and support in the community around your proposed changes already in the idea stage.


2. Once the idea has been vetted, your next task is to submit a `Draft` IIP to the IIP repository as a pull request. Do not assign a IIP number yet to the draft, but make sure that the proposal is technically sound and follows the format and style guides of the IIP Process. Create a sub-folder under `iips` folder with the title of the draft (`iips/title_of_draft/`) and put all assets in this folder.


3. A _IIP editor_ reviews your PR and assigns a IIP number to the draft.


4. _Core contributors_ as well as the broader public evaluate the draft proposal and might ask for modifications or clarifications. The proposal can only be merged into the repository as a draft if it represents a net improvement and does not complicate the protocol unduly.


5. The IIP is merged into the repo with `Draft` status by _IIP editor/author_.


6. When a working implementation is presented and there are clear plans on how to progress the IIP to  completion, the _IIP author_ submits a subsequent PR that links its implementation to the IIP and progresses it to `Proposed` stage. The IIP is ready to be deployed on testnet.


7. When a `Proposed` IIP is deemed to have met all appropriate criteria and its implementation has been demonstrated to work reliably in testnet environment, it is ready to be moved to the main network. Upon deployment, the IIP status must change to `Active`.

##### How can a IIP transition from one status to another?

![image](./process.svg)

A `Draft` IIP might be moved to `Deferred` status by the _IIP author(s)_ when they are no longer working on the proposal, but plan to continue it in the future. _IIP editors_ might also move any IIPs to  `Deferred` if the proposal is not making progress.

A `Draft` IIP might be moved to `Withdrawn` status by the _IIP author(s)_.

A `Draft` IIP might be moved to `Rejected` status by _IIP editor(s)_ or _Core contributors_ if it does not meet the appropriate IIP criteria, or no relevant progress has been demonstrated on the IIP for at least 3 years.

A `Draft` IIP might be moved to `Proposed` status by IIP author(s) if it is considered complete, has a working implementation and clear plans on how to progress it to `Active` status.

A `Proposed` IIP might be moved to `Active` status if a IIP specific adoption criteria has been met. For Core IIPs this means deployment on the main network.

A `Proposed` IIP might be moved to `Rejected` status by _IIP editor(s)_ or _Core contributors_ if its implementation puts unduly burden and complexity on the protocol, or other significant problems are discovered during testing.

An `Active` IIP might be moved to `Replaced` status by a newer IIP. The replaced IIP must point to the IIP that replaces it.

An `Active` IIP might be moved to `Obsolete` status when the feature is deprecated.

##### How to champion the IIP Process as a IIP author?

 - Browse the [idea discussion forum](https://github.com/iotaledger/iips/discussions) before posting a new IIP idea. Someone else might already have proposed your idea, or a similar one. Take inspiration from previous ideas and discussions.
 - It is your responsibility as a _IIP author_ to build community consensus around your idea. Involve as many people in the discussion as you can. Use social media platforms, Discord or Reddit to raise awareness of your idea.
 - Submit a draft IIP as a PR to the IIP repository. Put extra care into following IIP guidelines and formats. IIPs must contain a link to previous discussions on the topic, otherwise your submissions might be rejected. IIPs that do not present convincing motivation, demonstrate lack of understanding of the design's impact, or are disingenuous about the drawbacks or alternatives tend to be poorly-received.
 - Your draft IIP gets a IIP number assigned by a _IIP editor_ and receives review and feedback from the larger community as well as from _Core contributors_. Be prepared to revise your draft based on this input.
 - IIPs that have broad support are much more likely to make progress than those that don't receive any comments. Feel free to reach out to the _IIP editors_ in particular to get help to identify stakeholders and obstacles.
 - Submitted draft IIPs rarely go through the process unchanged, especially as alternatives and drawbacks are shown. You can make edits, big and small, to the draft IIP to clarify or change the design, but make changes as new commits to the pull request, and leave a comment on the pull request explaining your changes. Specifically, do not squash or rebase commits after they are visible on the pull request.
 - When your draft IIP PR gets enough approvals from _IIP editors_ and _Core contributors_, it can be merged into the repository, however, your job is far from complete! To move the draft into the next status (proposed), you have to demonstrate a working implementation of your IIP. For Core IIPs, seek help from protocol developers and/or client teams to coordinate the feature implementation. For IRCs for example you need to provide their implementation yourself.
 - You also need to present a clear plan on how the IIP will be moved to the `Active` status, by for example agreeing on a IIP deployment strategy with _Core contributors_.
 - To move your `Draft` IIP to the `Proposed` phase, submit a subsequent PR that links its implementation and devises its route to become `Active`. The latter might be an additional document in the IIP's folder, a link to a public discussion or a short description or comment on the PR itself.
 - To move your `Proposed` IIP to `Active` status you need to demonstrate that it has met its specific adoption criteria. For Core IIPs, this means that majority of network nodes support it. For other IIPs, especially for IRCs, adoption might mean that the standard is publicly available, well documented and there are applications building on it.

### IIP Header Preamble

Each IIPs must have an RFC 822 style header preamble preceded and followed by three hyphens (---). The headers must appear in the following order. Headers marked with "*" are optional and are described below. All other headers are required.

| Field                | Description                                                                                                                                                                                                                                                                          |
|----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `iip`                | IIP number, or "?" before being assigned (assigned by _IIP editor_)                                                                                                                                                                                                                  |
| `title`              | Few words describing the IIP, maximum 44 characters                                                                                                                                                                                                                                  |
| `description*`       | One full short sentence                                                                                                                                                                                                                                                              |
| `author`             | A comma separated list of the author's or authors' name + GitHub username (in parenthesis), or name and email (in angle brackets). Example, FirstName LastName (@GitHubUsername), FirstName LastName <foo@bar.com>, FirstName (@GitHubUsername) and GitHubUsername (@GitHubUsername) |
| `discussions-to*`    | The url pointing to the official discussion thread                                                                                                                                                                                                                                   |
| `status`             | Current status of the IIP. One of: `Draft`, `Proposed`, `Active`, `Deferred`, `Rejected`, `Withdrawn`, `Obsolete` or `Replaced`                                                                                                                                                      |
| `type`               | IIP type, one of: `Standards Track`, `Process` or `Informational`                                                                                                                                                                                                                    |
| `layer*`             | Only for Standards Track, defines layer: `Core`, `Networking`, `Interface`, `Framework` or `Application`                                                                                                                                                                             |
| `created`            | Date created on, in ISO 8601 (yyyy-mm-dd) format                                                                                                                                                                                                                                     |
| `requires*`          | Link dependent IIPs by number                                                                                                                                                                                                                                                        |
| `replaces*`          | Older IIP being replaced by this IIP                                                                                                                                                                                                                                                 |
| `superseded-by*`     | Newer IIP replaces this IIP                                                                                                                                                                                                                                                          |
| `withdrawal-reason*` | A sentence explaining why the IIP was withdrawn. (Optional field, only needed when status is `Withdrawn`)                                                                                                                                                                            |
| `rejection-reason*`  | A sentence explaining why the IIP was rejected. (Optional field, only needed when status is `Rejected`)                                                                                                                                                                              |

### Linking IIPs
References to other IIPs should follow the format IIP-N where N is the IIP number you are referring to. Each IIP that is referenced in an IIP MUST be accompanied by a relative Markdown link the first time it is referenced, and MAY be accompanied by a link on subsequent references. The link MUST always be done via relative paths so that the links work in this GitHub repository or forks of this repository. For example, you would link to this IIP with `[IIP-1](../IIP-0001/iip-0001.md)`.

### Auxiliary Files
Images, diagrams and auxiliary files should be included in the subdirectory of the IIP.  When linking to an image in the IIP, use relative links such as `[IIP Process Diagram](../IIP-0001/process.png)`.

### Linking to external resources
External links should not be included, except to the IOTA repository.

### Transferring IIP Ownership

It occasionally becomes necessary to transfer ownership of IIPs to a new champion. In general, we'd like to retain the original author as a co-author of the transferred IIP, but that's really up to the original author. A good reason to transfer ownership is because the original author no longer has the time or interest in updating it or following through with the IIP process, or has fallen off the face of the 'net (i.e. is unreachable or isn't responding to email). A bad reason to transfer ownership is because you don't agree with the direction of the IIP. We try to build consensus around a IIP, but if that's not possible, you can always submit a competing IIP.

If you are interested in assuming ownership of a IIP, send a message asking to take over, addressed to both the original author and the _IIP editors_. If the original author doesn't respond to the email in a timely manner, the _IIP editors_ will make a unilateral decision (it's not like such decisions can't be reversed :)).

### IIP Editors

| Name               | GitHub username   | Email address               | Affiliation     |
|:-------------------|:------------------|:----------------------------|:----------------|
| Kevin Mayrhofer    | Dr-Electron       | kevin.mayrhofer@iota.org    | IOTA Foundation |
| Gino Osahon        | Ginowine          | gino.osahon@iota.org        | IOTA Foundation |
| Lucas Tortora      | lucas-tortora     | lucas.tortora@iota.org      | IOTA Foundation |
| Salaheldin Soliman | salaheldinsoliman | salaheldin.soliman@iota.org | IOTA Foundation |
| Vivek Jain         | vivekjain23       | vivek.jain@iota.org         | IOTA Foundation |
| Levente Pap        | lzpap             | levente.pap@iota.org        | IOTA Foundation |

### IIP Editor Responsibilities

IIP editors' essential role is to assist and guard the process of contributing to the IOTA ecosystem, provide help and directions to community members as well as to external contributors. If you have a question regarding the IIP process, reach out to them, they will point you to the right direction.

They ensure that only quality contributions are added as IIPs, provide support for IIP authors, furthermore monitor that the IIP process is fair, objective and well documented.

For each new IIP that comes in, an editor does the following:
 - Read the IIP to check if it is ready: sound and complete. The ideas must make technical sense, even if they don't seem likely to get to `Active` status.
 - The title should accurately describe the content.
 - Check the IIP for language (spelling, grammar, sentence structure, etc.), markup (GitHub flavored Markdown), code style.

If the IIP isn't ready, the editor will send it back to the author for revision, with specific instructions.

Once the IIP is ready to be merged as a draft, the editor will:
 - Assign a IIP number that does not conflict with other IIP numbers. It might be the PR number, but might also be selected as the next unused IIP number in line.
 - Merge the corresponding pull request.
 - Send a message back to the IIP author with the next step.

The editors don't pass judgment on IIPs. We merely do the administrative & editorial part.

### Core Contributors

_Core contributors_ consists of several core developers of the IOTA ecosystem. Their job is to evaluate technical details of IIPs, judge their technical feasibility and safeguard the evolution of the protocol. Core improvement ideas must be carefully thought through and their benefits must outweigh their drawbacks.

In order for a draft IIP to be accepted into the repo, it must be signed-off by _Core contributors_. It is also this group that gives the green light for drafts to become proposed or active.

## Rationale

The IIP process is intended to replace the formerly adopted Tangle Improvement Proposal (TIP) process due the underlying technological shift.

TIPs refer to the previous generation of IOTA technology and hence are outdated. In order not to confuse contributors, IIP is introduced as a new process to propose, discuss and implement new ideas for the IOTA technology stack.

In order not to reinvent the wheel, the IIP Process draws heavily on the [BIP](https://github.com/bitcoin/bips/blob/master/bip-0002.mediawiki) and [EIP](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md) processes.

## Backwards Compatibility
 - The current `iotaledger/tips` repository will be archived.
 - All TIPs become `Obsolete` and are no longer in use.

## References
 - [BIP-1](https://github.com/bitcoin/bips/blob/master/bip-0001.mediawiki) and[ BIP-2](https://github.com/bitcoin/bips/blob/master/bip-0002.mediawiki), Bitcoin Improvement Proposal Purpose and Guidelines
 - [EIP-1](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1.md), Ethereum Improvement Proposal Purpose and Guidelines
 - [CIP-1](https://github.com/cardano-foundation/CIPs/tree/master/CIP-0001), Cardano Improvement Proposal Process

## Copyright

Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
