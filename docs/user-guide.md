<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0.

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# User guide

Consumers can use this guide to add `score_qnx_sdp` to a Bazel project, build a
QNX Software Development Platform (SDP) directory, and package or consume its
output. It does not configure or register a QNX C/C++ toolchain. Before you
begin, complete
[license and credential setup](license-and-credentials.md).

## Requirements

Before adding the module, make sure your build environment meets these
requirements:

- Linux x86_64 host.
- Bazel with Bzlmod, using the version in [.bazelversion](../.bazelversion).
- Network access to `qnx.com`, `bcr.bazel.build`, and `raw.githubusercontent.com`.
- A myQNX account with a license that covers the packages in the patchset.

## Add the module

To add the published module and configure its registry, follow these steps:

1. Add the module to your `MODULE.bazel`:

   ```starlark
   bazel_dep(name = "score_qnx_sdp", version = "0.0.1")
   ```

2. Optional: To test the module against a local checkout, add a
   `local_path_override` to `MODULE.bazel`:

   ```starlark
   local_path_override(
       module_name = "score_qnx_sdp",
       path = "../qnx_sdp",
   )
   ```

3. To resolve the module from the Eclipse S-CORE registry, add these lines to
   your `.bazelrc`:

   ```text
   common --registry=https://raw.githubusercontent.com/eclipse-score/bazel_registry/main/
   common --registry=https://bcr.bazel.build
   ```

You do not declare `@qnx_softwarecentercli`; the module declares it.

## Define and build an SDP target

To declare and build an SDP target, follow these steps:

1. Load the rule and declare one or more SDP targets in a BUILD file:

   ```starlark
   load("@score_qnx_sdp//rules:qnx_sdp.bzl", "qnx_sdp")

   qnx_sdp(name = "qnx_sdp")  # SDP 8.0.5 (default)
   qnx_sdp(name = "qnx_sdp_806", sdp_version = "8.0.6")
   ```

   The rule selects the newest bundled patchset for `sdp_version` from
   [patchsets/](../patchsets). See the [reference](reference.md#qnx_sdp-rule)
   for all attributes.

2. Build the default target:

   ```sh
   bazel build //:qnx_sdp
   ```

   The first build downloads and installs the QNX Software Center command-line
   interface (CLI), which can take up to five minutes. It then installs the
   SDP. The output is a directory at
   `bazel-bin/qnx_sdp/`. Later builds use the cache until the patchset, SDP
   version, baseline, or installer changes.

## Use or package the output

The `qnx_sdp` target produces an SDP directory as a single tree artifact. Depend
on the target from any rule that accepts files.

To compile C/C++ code for QNX in S-CORE builds, use the separate
[`bazel_cpp_toolchains`](https://github.com/eclipse-score/bazel_cpp_toolchains)
repository (Bazel module `score_bazel_cpp_toolchains`). Its
[QNX integration guide](https://github.com/eclipse-score/bazel_cpp_toolchains/blob/main/docs/qnx_integration.md)
explains how to declare an SDP package and configure and register a toolchain.
Building a `qnx_sdp` target produces SDP artifacts; it does not register a
toolchain.

Unless you set `set_build_file = False`, the rule also copies a `BUILD.bazel`
file into the SDP root. It defines filegroups for toolchain wiring, including
`:cc`, `:cxx`, `:host_all`, `:sysroot_dir`, and per-architecture
`*_x86_64` and `*_aarch64` groups. These labels are usable when the SDP root is
a Bazel package, for example when you publish a packaged tarball and consume it
as an external repository. See the [generated BUILD file reference](reference.md#generated-sdp-build-file)
for the full list.

- Optional: To package the SDP with `rules_pkg`, add a `pkg_tar` target:

  ```starlark
  load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

  pkg_tar(
      name = "qnx_sdp_pkg",
      srcs = ["qnx_sdp"],
      remap_paths = {"qnx_sdp": ""},  # Remove the "qnx_sdp/" prefix in the archive.
  )
  ```

## Configure common options

Use the following settings for common requirements:

| Need | Setting |
| --- | --- |
| Build behind a proxy | `use_proxy = True`, `proxy_host = "PROXY_HOST"`, `proxy_port = "PROXY_PORT"` |
| Keep an existing installation instead of removing it | `clean_install = False` |
| Use your own package selection | `patchset = "my_patchset.plist"` (a QNX Software Center patchset file) |
| Skip the generated `BUILD.bazel` inside the SDP | `set_build_file = False` |
| Use environment variables instead of `~/.netrc` | `--action_env=MYQNX_USER --action_env=MYQNX_PASSWORD`; see [credential sources](license-and-credentials.md#credential-sources) |

Replace `PROXY_HOST` and `PROXY_PORT` with your proxy's hostname and port when
you use the proxy setting.

## Authenticate downloads

If downloading the installer from `qnx.com` requires a login, configure the
credential helper with these steps:

1. Copy [`tools/qnx_credential_helper.py`](../tools/qnx_credential_helper.py)
   into your repository.
2. Add the credential helper setting to your `.bazelrc`:

   ```text
   common --credential_helper=*.qnx.com=%workspace%/PATH/TO/HELPER
   ```

   Replace `PATH/TO/HELPER` with the helper's path in your repository. The
   helper uses `SCORE_QNX_USER` and `SCORE_QNX_PASSWORD`, or `~/.netrc`.

If you encounter an error, see [Troubleshooting](troubleshooting.md).
