---
iip: <to be assigned>
title: <The IIP title is a few words, not a complete sentence>
description: <Description is one full (short) sentence>
author: <a comma separated list of the author's or authors' name + GitHub username (in parenthesis), or name and email (in angle brackets).  Example, FirstName LastName (@GitHubUsername), FirstName LastName <foo@bar.com>, FirstName (@GitHubUsername) and GitHubUsername (@GitHubUsername)>
discussions-to: <URL>
status: Draft
type: <Standards Track, Process, or Informational>
layer (*only required for Standards Track): <Core, Networking, Interface, IRC>
created: <date created on, in ISO 8601 (yyyy-mm-dd) format>
requires (*optional): <IIP number(s)>
replaces (*optional): <IIP number(s)>
superseded-by (*optional): <IIP number(s)>
---

This is the suggested template for new IIPs.

Note that an IIP number will be assigned by an editor. When opening a pull request to submit your IIP, please use an abbreviated title in the filename, `iip-draft_title_abbrev.md`.

The title should be 44 characters or less. It should not repeat the IIP number in title, irrespective of the category.

## Abstract
Abstract is a multi-sentence (short paragraph) technical summary. This should be a very terse and human-readable version of the specification section. Someone should be able to read only the abstract to get the gist of what this specification does.

## Motivation
The motivation section should describe the "why" of this IIP. What problem does it solve? Why should someone want to implement this standard? What benefit does it provide to the IOTA ecosystem? What use cases does this IIP address?

## Specification
The key words “MUST”, “MUST NOT”, “REQUIRED”, “SHALL”, “SHALL NOT”, “SHOULD”, “SHOULD NOT”, “RECOMMENDED”, “MAY”, and “OPTIONAL” in this document are to be interpreted as described in RFC 2119.

The technical specification should describe the syntax and semantics of any new feature. The specification should be detailed enough to allow competing, interoperable implementations for any of the current IOTA platforms (TODO: link to wiki).

## Rationale
The rationale fleshes out the specification by describing what motivated the design and why particular design decisions were made. It should describe alternate designs that were considered and related work, e.g. how the feature is supported in other languages.

## Backwards Compatibility
All IIPs that introduce backwards incompatibilities must include a section describing these incompatibilities and their severity. The IIP must explain how the author proposes to deal with these incompatibilities. IIP submissions without a sufficient backwards compatibility treatise may be rejected outright.

## Test Cases
Test cases for an implementation are mandatory for IIPs that are affecting consensus changes.  If the test suite is too large to reasonably be included inline, then consider adding it as one or more files in the IIPs directory.

## Reference Implementation
An optional section that contains a reference/example implementation that people can use to assist in understanding or implementing this specification.  If the implementation is too large to reasonably be included inline, then consider adding it as one or more files in the IIPs directory.

## Copyright
Copyright and related rights waived via [CC0](https://creativecommons.org/publicdomain/zero/1.0/).
