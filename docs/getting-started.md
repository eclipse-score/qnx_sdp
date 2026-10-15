<!--
# *******************************************************************************
# Copyright (c) 2026 Contributors to the Eclipse Foundation
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available under the
# terms of the Apache License Version 2.0 which is available at
# https://www.apache.org/licenses/LICENSE-2.0
#
# SPDX-License-Identifier: Apache-2.0
# *******************************************************************************
-->

# Getting Started

## Prerequisites

- Linux x86_64 host. The pinned installer is the Linux `.run` build, and the test outputs use the `k8` platform.
- Bazel with Bzlmod support. The repository was last built with Bazel 9.3.0. No `.bazelversion` is checked in.
- Network access to `qnx.com` and, for module resolution, to `bcr.bazel.build` and `raw.githubusercontent.com`.
- A myQNX account with the licenses required for the SDP baseline you request.

## Consuming the module

In your `MODULE.bazel`:

```starlark
bazel_dep(name = "score_qnx_sdp", version = "0.0.1")

# Only for local development against a checkout:
local_path_override(
    module_name = "score_qnx_sdp",
    path = "../qnx_sdp",
)
```

`score_qnx_sdp` is resolved from the registries configured in [.bazelrc](../.bazelrc) (the Eclipse S-CORE registry and the Bazel Central Registry). Add the same `--registry` flags to your own `.bazelrc` if you consume it from a registry. `rules_pkg` is only needed if you package the output.

You do not need to declare `@qnx_softwarecentercli`. The module does this itself.

## Defining an SDP target

```starlark
load("@score_qnx_sdp//rules:qnx_sdp.bzl", "qnx_sdp")

qnx_sdp(
    name = "qnx_sdp",
    baseline = "qnx800",                               # optional, default "qnx800"
    patchset = ":patchsets/0.0.1/patchset.plist",
)
```

The `patchset` is a QNX Software Center patchset `.plist` file. It describes the packages to import and install. Create and export one with QNX Software Center. The file in [tests/patchsets/0.0.1/patchset.plist](../tests/patchsets/0.0.1/patchset.plist) is empty and serves only as a placeholder.

To package the result:

```starlark
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

pkg_tar(
    name = "qnx_sdp_pkg",
    srcs = ["qnx_sdp"],
    remap_paths = {"qnx_sdp": ""},   # drop the "qnx_sdp/" prefix inside the tarball
)
```

## Credentials

Two separate mechanisms exist, and they use different variable names.

| Purpose | Used by | Source |
| --- | --- | --- |
| Run `qnxsoftwarecenter_clt` to import and install the patchset | `qnx_sdp` rule | Environment variables `MYQNX_USER` and `MYQNX_PASSWORD`, forwarded with `--action_env` |
| Authenticate Bazel downloads from `qnx.com` | `tools/qnx_credential_helper.py` | `SCORE_QNX_USER` and `SCORE_QNX_PASSWORD`, or `~/.netrc` entry for machine `qnx.com` |

### Build-time credentials (`qnx_sdp`)

The rule reads `MYQNX_USER` and `MYQNX_PASSWORD` from the action environment. Pass them through without writing the values on the command line:

```sh
export MYQNX_USER=<user>
export MYQNX_PASSWORD=<password>
bazel build //:qnx_sdp --action_env=MYQNX_USER --action_env=MYQNX_PASSWORD
```

If either variable is missing from the action environment, analysis fails with a missing-key error from `default_shell_env`.

To avoid retyping the flags, put them in a user-level `~/.bazelrc` or an untracked `user.bazelrc`:

```
build --action_env=MYQNX_USER
build --action_env=MYQNX_PASSWORD
```

### Authenticated downloads (credential helper)

If the installer download from `qnx.com` requires a login, configure Bazel to use the helper:

```
# .bazelrc
common --credential_helper=*.qnx.com=%workspace%/path/to/qnx_credential_helper.py
```

Provide credentials in one of two ways:

```sh
export SCORE_QNX_USER=<user>
export SCORE_QNX_PASSWORD=<password>
```

or in `~/.netrc`:

```
machine qnx.com
login <user>
password <password>
```

Both `SCORE_QNX_USER` and `SCORE_QNX_PASSWORD` must be set for the environment variables to be used. Otherwise the helper falls back to `~/.netrc`.

The checked-in `.bazelrc` does not set `--credential_helper`, so this must be configured by the consumer. Inside a consumer workspace the script is available as `@score_qnx_sdp//tools:qnx_credential_helper.py`. Bazel needs a filesystem path for the flag, for example one under the external repository directory. Copying the script into your own repository is the simplest option.

## Building

```sh
bazel build //:qnx_sdp        # SDP directory
bazel build //:qnx_sdp_pkg    # tarball of the SDP
```

The first build fetches and runs the QNX Software Center installer (up to 300 seconds), then runs the SDP installation. Subsequent builds reuse the cached repository and action outputs unless the patchset, baseline, or installer change.

Output locations (from the directory you built in):

- `bazel-bin/qnx_sdp/` for the SDP directory.
- `bazel-bin/qnx_sdp_pkg.tar` for the package.
