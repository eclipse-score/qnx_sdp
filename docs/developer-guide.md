<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0.

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# Developer guide

If you contribute to `score_qnx_sdp`, use this guide to build or maintain the
module, update its installer or patchsets, and review its security-sensitive
behavior. The module installs a QNX Software Development Platform (SDP) with
the QNX Software Center command-line interface (CLI). This guide assumes you
have completed [license and credential setup](license-and-credentials.md);
consumer setup is outside this guide's scope. See the
[reference](reference.md) for rule and tool details.

## Repository layout

The repository contains the module definition, rule implementations, helper
tools, patchsets, and generated SDP BUILD template:

```
.
├── MODULE.bazel            Module definition and pinned CLI installer
├── BUILD.bazel             Format and copyright checks; SDP targets
├── .bazelrc                Registries and credential helper (root module only)
├── rules/
│   ├── qnx_sdp.bzl                  qnx_sdp rule
│   └── qnx_softwarecentercli.bzl    repository rule installing the CLI
├── tools/
│   ├── qnx_software_center_wrapper.py   Credential and template wrapper
│   └── qnx_credential_helper.py         Bazel credential helper
├── patchsets/8.0.5/patchset_1.plist   bundled package selections
├── templates/sdp/BUILD.template     BUILD file copied into the generated SDP
└── docs/
```

## Build flow

This flowchart shows how Bazel fetches the CLI and creates the SDP directory:

```mermaid
flowchart TD
    A[bazel build //:qnx_sdp_805] --> B{@qnx_softwarecentercli fetched?}
    B -- no --> C[Download .run installer, verify SHA-256]
    C --> D[Run installer into repository dir]
    D --> E[Generate BUILD.bazel with :installer]
    B -- yes --> F
    E --> F[qnx_sdp action]
    F --> G[Wrapper resolves credentials]
    G --> H["Run qnxsoftwarecenter_clt"]
    H --> I["Mirror baseline and install patchset"]
    I --> J[Wrapper copies template if requested]
    J --> K[Tree artifact: SDP directory]
```

The build has three stages:

1. **Fetch:** The repository rule downloads the pinned installer and runs it
   non-interactively. The installer accepts QNX Software Center license terms
   on behalf of the person running the build.
2. **Build:** The `qnx_sdp` action runs the wrapper. The wrapper reads
   credentials from forwarded `MYQNX_*` variables or `~/.netrc`, then launches
   the CLI to mirror the baseline, import the patchset, and install into the
   output directory. The wrapper copies the BUILD template when requested.
3. **Package:** The consumer packages the resulting SDP directory, for example
   with `pkg_tar`.

The implementation has these design properties:

- The installer is pinned by URL and SHA-256. SDP content is not hermetic
  because it depends on what QNX serves at build time.
- The patchset is an action input, so changing it invalidates the action.
  Credentials are not rule attributes and do not appear in BUILD files.
- This module declares `@qnx_softwarecentercli` and references it from its
  `.bzl` file, so consumers do not declare it.
- The wrapper and installer are execution-configuration tools for the action.

## Build and format

To build both SDP targets and format the Python, Starlark, and YAML files, run:

```sh
bazel build //:qnx_sdp_805 //:qnx_sdp_806
bazel run //:format.fix
```

To check formatting, run:

```sh
bazel test //:format.check
```

Builds need network access and valid myQNX credentials. For consumer examples,
including packaging the SDP with `pkg_tar`, see the [user guide](user-guide.md).

The root [.bazelrc](../.bazelrc) disables implicit Python `__init__.py`
creation, including for dependencies. Python packages must supply any required
`__init__.py` files explicitly.

The [tests/](../tests/) directory supports manual verification by module
owners; it is not an automated test suite.

## Continuous integration (CI)

The [checks workflow](../.github/workflows/checks.yml) runs the S-CORE copyright
check, formatting check, and Bzlmod lockfile check on pull requests and pushes
to `main`. Run the build and formatting commands in [Build and format](#build-and-format)
locally before opening a pull request.

If you change dependencies, update `MODULE.bazel.lock` with:

```sh
bazel mod deps --lockfile_mode=update
```

## Maintain the installer

To update the QNX Software Center CLI:

1. Get the new Linux `.run` URL from qnx.com.
2. Compute its SHA-256 checksum with `sha256sum`.
3. Update `url` and `sha256` in [MODULE.bazel](../MODULE.bazel).
4. Fetch the installer:

   ```sh
   bazel fetch --force @qnx_softwarecentercli//:installer
   ```

5. Rebuild both root SDP targets:

   ```sh
   bazel build //:qnx_sdp_805 //:qnx_sdp_806
   ```

## Add or update a patchset

To add or update a patchset:

1. Use a patchset number `N` greater than the existing files for that SDP
   version. The rule selects the highest number, so older files remain for
   reference.
2. Export a patchset from QNX Software Center to
   `patchsets/SDP_VERSION/patchset_N.plist`, or copy the previous file to that
   path. Replace `SDP_VERSION` with the SDP version.
3. If you copied an existing patchset, update its package versions.
4. If you add an SDP version, add a `qnx_sdp` target to the root
   [BUILD.bazel](../BUILD.bazel) and set `sdp_version`.
5. Build the target and check that its output contains the expected toolchain
   files.

## Change the generated BUILD file

Edit [templates/sdp/BUILD.template](../templates/sdp/BUILD.template). Its paths
are relative to the SDP root, and it hard-codes the QNX target triple (for
example, `x86_64-pc-nto-qnx8.0.0`). Check those paths after each SDP version
update.

## Debug the CLI manually

To display the CLI help, run:

```sh
bazel run \
  @qnx_softwarecentercli//:qnxsoftwarecenter/qnxsoftwarecenter_clt -- -help
```

## Review security-sensitive behavior

Keep these security properties in mind when changing the module:

- Passwords from `~/.netrc` are not in the Bazel action command line, so they do
  not appear in `--subcommands` output, build logs, or remote execution records.
- The wrapper passes `-myqnx.password` to the CLI as an argument. The password
  is visible in the host process list while the CLI runs.
- With `MYQNX_*` and `--action_env`, the rule adds `-u` and `-p` values to the
  action command line. Avoid remote caches or execution services that record
  command lines, and treat `--subcommands` and `--verbose_failures` output as
  sensitive.
- The installer runs with `agree-to-license-terms`. Builders must be entitled
  to accept QNX's license terms.
- The credential helper must only send credentials to `https://*.qnx.com`.
  Preserve that check when changing the helper.
- Review every change to the installer URL or checksum.
- Never commit credentials.
