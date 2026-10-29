<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# score_qnx_sdp Documentation

`score_qnx_sdp` is a Bazel module (Bzlmod) that produces a QNX Software Development Platform (SDP) from Bazel. It downloads the QNX Software Center command-line tool, then uses it to install a QNX SDP described by a patchset file into a Bazel-managed directory. That directory can be packaged (for example into a tarball) or consumed by a toolchain.

## Contents

| Document | Description |
| --- | --- |
| [architecture.md](architecture.md) | Repository layout, components, and the end-to-end build flow |
| [getting-started.md](getting-started.md) | Prerequisites, credentials, and how to consume the module |
| [reference.md](reference.md) | Reference for the rules, repository rule, credential helper, and module configuration |
| [testing.md](testing.md) | The `tests/` module, how to run it, and what it does and does not verify |
| [troubleshooting.md](troubleshooting.md) | Common failures and security notes |

## At a glance

- Module name: `score_qnx_sdp` (declared in [MODULE.bazel](../MODULE.bazel)).
- Public API:
  - `qnx_sdp` rule, from `@score_qnx_sdp//rules:qnx_sdp.bzl`.
  - `qnx_softwarecentercli` repository rule, from `@score_qnx_sdp//rules:qnx_softwarecentercli.bzl`. It is used internally by the module.
  - `tools/qnx_credential_helper.py`, a Bazel credential helper for authenticated downloads from `qnx.com`.
- Dependency: `rules_pkg` 1.2.0.
- License: Apache-2.0, copyright Eclipse Foundation contributors (see the headers in each source file).

## Quick example

```starlark
# BUILD
load("@score_qnx_sdp//rules:qnx_sdp.bzl", "qnx_sdp")

qnx_sdp(
    name = "qnx_sdp",
    patchset = ":patchsets/0.0.1/patchset.plist",
)
```

```sh
export MYQNX_USER=<myQNX user>
export MYQNX_PASSWORD=<myQNX password>
bazel build //:qnx_sdp --action_env=MYQNX_USER --action_env=MYQNX_PASSWORD
```

See [getting-started.md](getting-started.md) for the full setup.
