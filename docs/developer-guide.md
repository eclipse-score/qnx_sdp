<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# Developer guide

For contributors to this module. Set up your account first: [License and credentials](license-and-credentials.md). Rule and tool details are in the [reference](reference.md).

## Repository layout

```
.
├── MODULE.bazel            Module definition, pinned installer (@qnx_softwarecentercli)
├── BUILD.bazel             Format/copyright checks; qnx_sdp_805 and qnx_sdp_806 targets
├── .bazelrc                Registries and credential helper (root module only)
├── rules/
│   ├── qnx_sdp.bzl                  qnx_sdp rule
│   └── qnx_softwarecentercli.bzl    repository rule installing the CLI
├── tools/
│   ├── qnx_software_center_wrapper.py   supplies credentials, copies BUILD template
│   └── qnx_credential_helper.py         Bazel credential helper for qnx.com
├── patchsets/<version>/patchset_<N>.plist   bundled package selections
├── templates/sdp/BUILD.template     BUILD file copied into the generated SDP
└── docs/
```

## How it works

```mermaid
flowchart TD
    A[bazel build //:qnx_sdp_805] --> B{@qnx_softwarecentercli fetched?}
    B -- no --> C[Download .run installer, verify SHA-256]
    C --> D[Run installer into repository dir]
    D --> E[Generate BUILD.bazel with :installer]
    B -- yes --> F
    E --> F[qnx_sdp action]
    F --> G[Wrapper resolves credentials]
    G --> H["qnxsoftwarecenter_clt -mirrorBaseline ... -importAndInstall patchset -destination out"]
    H --> I[Wrapper copies BUILD.template to out/BUILD.bazel]
    I --> J[Tree artifact: SDP directory]
```

1. **Fetch** (repository rule): downloads the pinned installer and runs it non-interactively. This accepts the QNX Software Center license terms on behalf of whoever runs the build.
2. **Build** (`qnx_sdp` action): the wrapper reads credentials (`MYQNX_*` forwarded by the rule, else `~/.netrc`), then launches the CLI which mirrors the baseline, imports the patchset and installs into the output directory. The wrapper then copies the BUILD template.
3. **Packaging** is left to the consumer (for example `pkg_tar`).

Design notes:

- The installer is pinned by URL and SHA-256. The SDP content is not hermetic: it depends on what QNX serves at build time.
- The patchset is a plain input, so changing it invalidates the action. Credentials are not attributes, so they never appear in BUILD files.
- `@qnx_softwarecentercli` is declared in this module and referenced by a label in this module's `.bzl`, so consumers need no declaration.
- Wrapper and installer are `exec` configuration tools of the action.

## Build and format

Root module:

```sh
bazel build //:qnx_sdp_805 //:qnx_sdp_806
bazel run //:format.fix       # format Python, Starlark, YAML
bazel run //:copyright-check     # copyright headers (//:copyright-fix to repair)
```

Builds need network access and valid myQNX credentials. For consumer examples, including packaging the SDP with `pkg_tar`, see the [user guide](user-guide.md).

The root [.bazelrc](../.bazelrc) disables implicit Python `__init__.py` creation, including for dependencies. Python packages must supply any required `__init__.py` files explicitly.

The [tests/](../tests/) directory is not yet ready as an automated test suite. Its current setup is mainly for manual verification by module owners.

## CI

[.github/workflows/checks.yml](../.github/workflows/checks.yml) runs the S-CORE copyright check, the formatting check and the Bzlmod lockfile check on pull requests and pushes to `main`. Run the equivalents locally before opening a PR. If you change dependencies, update `MODULE.bazel.lock` (`bazel mod deps --lockfile_mode=update`).

## Common maintenance tasks

### Update the QNX Software Center CLI

1. Get the new Linux `.run` URL from qnx.com and compute its SHA-256 (`sha256sum`).
2. Update `url` and `sha256` in [MODULE.bazel](../MODULE.bazel).
3. Fetch the installer again (`bazel fetch --force @qnx_softwarecentercli//:installer`) and rebuild the root SDP targets with `bazel build //:qnx_sdp_805 //:qnx_sdp_806`.

### Add or update a patchset

1. Create `patchsets/<sdp_version>/patchset_<N>.plist` with `N` higher than the existing files. The rule takes the highest `N`, so older ones stay for reference only. Export it from QNX Software Center or copy the previous file and change the package versions.
2. For a new SDP version, add a `qnx_sdp` target to the root [BUILD.bazel](../BUILD.bazel) with `sdp_version` set and build it.
3. Run a build and check the result contains the expected toolchain files.

### Change the generated BUILD file

Edit [templates/sdp/BUILD.template](../templates/sdp/BUILD.template). Paths in it are relative to the SDP root and hard-code the QNX target triple (for example `x86_64-pc-nto-qnx8.0.0`), so check them after every SDP version bump.

### Debug the CLI manually

```sh
bazel run @qnx_softwarecentercli//:qnxsoftwarecenter/qnxsoftwarecenter_clt -- -help
```

## Security notes

- Passwords from `~/.netrc` are not in the Bazel action command line, so they do not appear in `--subcommands` output, build logs or remote execution records.
- The wrapper passes `-myqnx.password` to the CLI as an argument, so it is visible in the host process list while the CLI runs.
- With `MYQNX_*` and `--action_env`, the rule adds `-u`/`-p` to the action command line. Avoid remote caches or execution services that record command lines, and treat `--subcommands` and `--verbose_failures` output as sensitive.
- The installer runs with `agree-to-license-terms`. Builders must be entitled to accept QNX's license terms.
- The credential helper must only send credentials to `https://*.qnx.com`. Keep that check when changing it.
- Review any change of installer URL or checksum.
- Never commit credentials.
