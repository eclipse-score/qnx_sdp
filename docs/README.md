<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0.

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# score_qnx_sdp documentation

Consumers and contributors can use this index to find setup, usage, reference,
maintenance, and troubleshooting information for `score_qnx_sdp`, which
installs the QNX Software Development Platform (SDP). These documents cover the
Bazel module; they do not explain QNX SDP internals or configure the S-CORE
C/C++ toolchain.

The following documents cover each task:

| Document | Audience | Content |
| --- | --- | --- |
| [license-and-credentials.md](license-and-credentials.md) | Consumers and developers | Set up a QNX account, license, `~/.netrc`, environment variables, and a license file for the toolchain. |
| [user-guide.md](user-guide.md) | Consumers | Add the module, define `qnx_sdp` targets, use the output, configure a proxy, and provide custom patchsets. |
| [reference.md](reference.md) | Consumers and developers | Look up `qnx_sdp` attributes, generated BUILD targets, the repository rule, the wrapper, and the credential helper. |
| [developer-guide.md](developer-guide.md) | Contributors | Explore the repository, build and format it, use CI, update the installer or patchsets, and review security notes. |
| [troubleshooting.md](troubleshooting.md) | Consumers and developers | Diagnose common symptoms, causes, and fixes. |

Choose a path based on your task:

- **Consumer:** Start with [license and credentials](license-and-credentials.md),
  then follow the [user guide](user-guide.md).
- **Developer:** Start with the consumer path, then read the
  [developer guide](developer-guide.md).

The module has these characteristics:

- Module name: `score_qnx_sdp` (see [MODULE.bazel](../MODULE.bazel)).
  Dependencies: `rules_pkg` and `rules_python`.
- Public application programming interface (API): the `qnx_sdp` rule in
  [`rules/qnx_sdp.bzl`](../rules/qnx_sdp.bzl).
- Internal repository: `@qnx_softwarecentercli`, declared by the module.
  Consumers do not declare it.
- Supported SDP versions: 8.0.5 (default) and 8.0.6, with patchsets in
  [`patchsets/`](../patchsets).
- Host platform: Linux x86_64. Fetching and building require network access to
  `qnx.com`.
- License: Apache-2.0.
