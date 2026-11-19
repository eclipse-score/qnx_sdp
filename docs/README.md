<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# score_qnx_sdp documentation

`score_qnx_sdp` downloads the QNX Software Center CLI and uses it to install a QNX SDP, described by a patchset file, into a Bazel-managed directory.

## Documents

| Document | Audience | Content |
| --- | --- | --- |
| [license-and-credentials.md](license-and-credentials.md) | everyone | QNX account, free license, `~/.netrc`, environment variables, license file for the toolchain |
| [user-guide.md](user-guide.md) | consumers | Adding the module, defining `qnx_sdp` targets, using the output, proxy, custom patchsets |
| [reference.md](reference.md) | everyone | `qnx_sdp` attributes, generated BUILD targets, repository rule, wrapper, credential helper |
| [developer-guide.md](developer-guide.md) | contributors | Repository layout, how the build works, local builds, CI, updating the installer or patchsets, security |
| [troubleshooting.md](troubleshooting.md) | everyone | Symptom, cause and fix tables, split by audience |

## Which path are you on?

- **Consumer**: [license-and-credentials.md](license-and-credentials.md), then [user-guide.md](user-guide.md).
- **Developer**: the consumer path first, then [developer-guide.md](developer-guide.md).

## Facts at a glance

- Module name: `score_qnx_sdp` (see [MODULE.bazel](../MODULE.bazel)). Dependencies: `rules_pkg`, `rules_python`.
- Public API: the `qnx_sdp` rule in `@score_qnx_sdp//rules:qnx_sdp.bzl`.
- Internal: the `@qnx_softwarecentercli` repository, declared by the module itself. Consumers do not declare it.
- Supported SDPs: 8.0.5 (default) and 8.0.6, with patchsets in [patchsets/](../patchsets).
- Host: Linux x86_64. Network access to `qnx.com` is required at fetch and build time.
- License: Apache-2.0.
