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

# Testing

## Overview

The repository has no unit-test framework and no `*_test` targets. Verification is an integration build: [tests/](../tests) is a separate Bazel module (`score_qnx_sdp_test`) that depends on the root module and builds the real targets end to end.

## The `tests` module

### [tests/MODULE.bazel](../tests/MODULE.bazel)

```starlark
module(name = "score_qnx_sdp_test")
bazel_dep(name = "rules_pkg", version = "1.2.0")
bazel_dep(name = "score_qnx_sdp", version = "0.0.1")
local_path_override(module_name = "score_qnx_sdp", path = "../")
```

`local_path_override` makes the test module build against the working tree one directory up, so local changes to the rules are exercised directly. The `version = "0.0.1"` in `bazel_dep` is only a label here. The root module does not declare a version, and the override bypasses version resolution.

### [tests/BUILD](../tests/BUILD)

| Target | Rule | Purpose |
| --- | --- | --- |
| `//:qnx_sdp` | `qnx_sdp` | Builds the SDP directory from `patchsets/0.0.1/patchset.plist`. Uses the default `baseline` (`qnx800`). |
| `//:qnx_sdp_pkg` | `pkg_tar` | Packs the SDP directory into a tarball. `remap_paths = {"qnx_sdp": ""}` removes the top-level directory prefix. |

### Patchsets

[tests/patchsets/0.0.1/patchset.plist](../tests/patchsets/0.0.1/patchset.plist) is currently empty. Replace it with a real QNX Software Center patchset to get a meaningful SDP. The directory name (`0.0.1`) follows the module version and is only a convention.

## Running the tests

Work from the `tests/` directory:

```sh
cd tests
export MYQNX_USER=<user>
export MYQNX_PASSWORD=<password>

bazel build //:qnx_sdp --action_env=MYQNX_USER --action_env=MYQNX_PASSWORD
bazel build //:qnx_sdp_pkg --action_env=MYQNX_USER --action_env=MYQNX_PASSWORD
```

Results:

- `bazel-bin/qnx_sdp/` holds the installed SDP.
- `bazel-bin/qnx_sdp_pkg.tar` holds the package.
- `bazel-tests`, `bazel-out`, `bazel-bin`, `bazel-testlogs` are the standard Bazel convenience symlinks. They are not source files and are ignored by `.gitignore` through `bazel-*`.

Notes:

- `tests/` has no `.bazelrc`, so the root registry configuration does not apply. `rules_pkg` and the other dependencies come from the default Bazel Central Registry.
- The first run downloads and installs the QNX Software Center CLI during the fetch step. The step fails on checksum mismatch or a non-zero installer exit code.
- Network access and valid myQNX credentials are required. This makes the test unsuitable for offline CI. Run it in an environment that provides secrets.

## What a pass means

A successful `bazel build //:qnx_sdp_pkg` shows that:

1. The module and its dependencies resolve.
2. The installer download matches the pinned SHA-256 and runs to completion.
3. The `:installer` filegroup resolves to the CLI binary, and its runfiles are available to the action.
4. The CLI accepts the arguments the rule generates, authenticates, and installs into the declared directory.
5. `pkg_tar` can consume the tree artifact.

It does not verify:

- The contents of the installed SDP. There are no assertions on files, versions, or toolchain behavior.
- The credential helper. It has no automated tests. Use the manual check in [reference.md](reference.md#manual-check).
- Behavior with a non-default `baseline`, or with failure paths such as missing credentials or a bad patchset.

## Suggested additions

These are not implemented. They are listed to indicate where coverage is missing.

- A `sh_test` or `py_test` that runs against the built SDP, checking that expected files exist, for example the toolchain compilers.
- A unit test for `qnx_credential_helper.py` that mocks `urllib` to cover domain filtering, credential selection, and the missing-cookie case.
- A CI job that provides `MYQNX_USER` and `MYQNX_PASSWORD` as secrets and builds `//:qnx_sdp_pkg` in `tests/`.
