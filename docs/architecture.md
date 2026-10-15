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

# Architecture

## Repository layout

```
qnx_sdp/
├── .bazelrc                         Registry configuration (root module only)
├── .gitignore                       Ignores bazel-* output symlinks
├── BUILD                            Empty; marks the root package
├── MODULE.bazel                     Module definition and installer repository
├── MODULE.bazel.lock                Bzlmod lockfile
├── README.md                        One-line project description
├── rules/
│   ├── BUILD.bazel                  Empty; makes `//rules` a package
│   ├── qnx_sdp.bzl                  `qnx_sdp` rule (builds the SDP)
│   └── qnx_softwarecentercli.bzl    `qnx_softwarecentercli` repository rule
├── tools/
│   ├── BUILD.bazel                  Exports the credential helper
│   └── qnx_credential_helper.py     Bazel credential helper for qnx.com
├── tests/                           Separate Bazel module that exercises the rules
│   ├── BUILD                        `qnx_sdp` and `pkg_tar` targets
│   ├── MODULE.bazel                 Depends on `score_qnx_sdp` via local_path_override
│   ├── MODULE.bazel.lock
│   └── patchsets/0.0.1/patchset.plist   Patchset input (currently an empty file)
└── docs/                            This documentation
```

The `tests/bazel-*` entries are symlinks created by Bazel when building inside `tests/`. They are build output, not source.

## Components

### 1. Module definition ([MODULE.bazel](../MODULE.bazel))

- Declares the module `score_qnx_sdp`. No `version` is set.
- Depends on `rules_pkg` 1.2.0.
- Instantiates the `qnx_softwarecentercli` repository rule under the repository name `qnx_softwarecentercli`, pinned to a specific installer URL and SHA-256:
  - URL: `https://www.qnx.com/download/download/79441/qnx-setup-2.0.4-202501021438-linux.run`
  - SHA-256: `5695a0ec8a1fd91840753b2cba86a9325f6052d4f69c757166cc61b09bcbe507`

The repository is declared in this module, so consumers do not need to declare it. The `qnx_sdp` rule refers to `@qnx_softwarecentercli` by a label written in this module's own `.bzl` file. Bazel resolves that label in the context of `score_qnx_sdp`, not the consumer.

### 2. Repository rule: `qnx_softwarecentercli` ([rules/qnx_softwarecentercli.bzl](../rules/qnx_softwarecentercli.bzl))

Runs at repository-fetch time, once per Bazel output base (and again when the rule's inputs change). Steps:

1. Download the installer `.run` script to `qnx-swc-setup.run`, verifying the SHA-256 and marking it executable.
2. Run `chmod +x ./qnx-swc-setup.run`.
3. Execute the installer non-interactively, with a 300 second timeout:
   ```
   ./qnx-swc-setup.run --nox11 force-override disable-auto-start agree-to-license-terms .
   ```
   The trailing `.` installs into the repository directory. Note that `agree-to-license-terms` accepts the QNX Software Center license on behalf of whoever runs the build.
4. Fail the fetch with stdout and stderr if the installer exits non-zero.
5. Generate a `BUILD.bazel` in the repository:
   ```starlark
   package(default_visibility = ["//visibility:public"])
   filegroup(
       name = "installer",
       srcs = ["qnxsoftwarecenter/qnxsoftwarecenter_clt"],
       data = glob(["**"]),
   )
   ```
   `:installer` is the CLI binary (`qnxsoftwarecenter_clt`), and `data` carries the whole installation as runfiles so the binary can find its libraries and resources.

### 3. Rule: `qnx_sdp` ([rules/qnx_sdp.bzl](../rules/qnx_sdp.bzl))

Declares a directory output (a tree artifact) named after the target, and runs one action that invokes the QNX Software Center CLI:

```
qnxsoftwarecenter_clt \
    -mirrorBaseline <baseline> \
    -myqnx.user <MYQNX_USER> \
    -myqnx.password <MYQNX_PASSWORD> \
    -importAndInstall <patchset> \
    -destination <output directory>
```

- `baseline` defaults to `qnx800`.
- `patchset` is the single input file.
- The credentials are read from `ctx.configuration.default_shell_env`, which contains the variables passed through `--action_env`.
- The installer is an implicit attribute (`_installer`) pointing at `@qnx_softwarecentercli//:installer`, built for the `exec` configuration. Its runfiles are passed as the action's `tools`.
- The rule returns `DefaultInfo(files = depset([<output directory>]))`.

### 4. Credential helper ([tools/qnx_credential_helper.py](../tools/qnx_credential_helper.py))

A standalone script implementing the [Bazel credential helper protocol](https://github.com/bazelbuild/proposals/blob/main/designs/2022-06-07-bazel-credential-helpers.md). It lets Bazel authenticate downloads from `qnx.com`. Details are in [reference.md](reference.md#credential-helper).

The helper is exported from [tools/BUILD.bazel](../tools/BUILD.bazel) via `exports_files`, but nothing in the repository configures Bazel to use it. See [getting-started.md](getting-started.md#authenticated-downloads-credential-helper).

### 5. Registry configuration ([.bazelrc](../.bazelrc))

```
common --registry=https://raw.githubusercontent.com/eclipse-score/bazel_registry/main/
common --registry=https://bcr.bazel.build
```

Module resolution first consults the Eclipse S-CORE registry, then the Bazel Central Registry. This file only applies when Bazel is run from the repository root. It does not apply to builds started from `tests/`.

## End-to-end flow

```mermaid
flowchart TD
    A[bazel build //:qnx_sdp_pkg] --> B[Resolve modules: score_qnx_sdp, rules_pkg]
    B --> C{@qnx_softwarecentercli fetched?}
    C -- no --> D[Download .run installer, verify SHA-256]
    D --> E[Run installer into repo dir]
    E --> F[Generate BUILD.bazel with :installer]
    C -- yes --> G
    F --> G[qnx_sdp action]
    G --> H["qnxsoftwarecenter_clt -mirrorBaseline ... -importAndInstall patchset -destination out"]
    H --> I[Tree artifact: SDP directory]
    I --> J[pkg_tar: qnx_sdp_pkg.tar]
```

1. Fetch phase (repository rule): the QNX Software Center CLI is downloaded and installed locally. This needs network access to `qnx.com`.
2. Build phase (`qnx_sdp` action): the CLI logs in to myQNX with the supplied credentials, mirrors the selected baseline, imports the patchset, and installs the resulting SDP into the declared output directory.
3. Packaging (consumer-defined): for example `pkg_tar` from `rules_pkg`, as in [tests/BUILD](../tests/BUILD).

## Design notes

- The installer version is pinned by URL and checksum, so the fetch is reproducible for a given installer. The SDP content is not hermetic: it depends on what QNX serves for the baseline and patchset at build time.
- The patchset (a `.plist` file) selects what is installed. It is a plain input file, so changing it invalidates the action.
- Credentials are not rule attributes. They come from the environment, so they are not written to any `BUILD` file. See [troubleshooting.md](troubleshooting.md#security-notes) for the caveats.
