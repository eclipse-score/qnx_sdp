<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# User guide

For people who use `score_qnx_sdp` to get QNX SDP artifacts. Before starting, complete [License and credentials](license-and-credentials.md).

## Requirements

- Linux x86_64 host.
- Bazel with Bzlmod (the repository uses the version in [.bazelversion](../.bazelversion)).
- Network access to `qnx.com`, `bcr.bazel.build` and `raw.githubusercontent.com`.
- A myQNX account with a license that covers the packages in the patchset.

## Add the module

In your `MODULE.bazel`:

```starlark
bazel_dep(name = "score_qnx_sdp", version = "0.0.1")

# Only for local development against a checkout:
local_path_override(
    module_name = "score_qnx_sdp",
    path = "../qnx_sdp",
)
```

Resolve the module from the Eclipse S-CORE registry by adding to your `.bazelrc`:

```
common --registry=https://raw.githubusercontent.com/eclipse-score/bazel_registry/main/
common --registry=https://bcr.bazel.build
```

You do not declare `@qnx_softwarecentercli`; the module does that itself.

## Define an SDP target

```starlark
load("@score_qnx_sdp//rules:qnx_sdp.bzl", "qnx_sdp")

qnx_sdp(name = "qnx_sdp")                          # SDP 8.0.5 (default)
qnx_sdp(name = "qnx_sdp_806", sdp_version = "8.0.6")
```

The rule picks the newest bundled patchset for `sdp_version` from [patchsets/](../patchsets). All attributes are in the [reference](reference.md#qnx_sdp-rule).

Build it:

```sh
bazel build //:qnx_sdp
```

The first build downloads and installs the QNX Software Center CLI (up to 5 minutes), then installs the SDP. The output is a directory at `bazel-bin/qnx_sdp/`. Later builds are cached until the patchset, SDP version, baseline or installer changes.

## Use the output

Depend on the target in any rule that accepts files; it yields the SDP directory as a single tree artifact.

To compile C/C++ code for QNX in S-CORE builds, use the separate [`bazel_cpp_toolchains`](https://github.com/eclipse-score/bazel_cpp_toolchains) repository (Bazel module `score_bazel_cpp_toolchains`). Its [QNX integration guide](https://github.com/eclipse-score/bazel_cpp_toolchains/blob/main/docs/qnx_integration.md) explains how to declare an SDP package and configure and register a toolchain. This module only produces the SDP artifacts; building a `qnx_sdp` target does not register a toolchain.

Unless `set_build_file = False`, the rule also copies a `BUILD.bazel` into the SDP root. It defines filegroups for toolchain wiring (`:cc`, `:cxx`, `:host_all`, `:sysroot_dir`, and per-architecture `*_x86_64` / `*_aarch64` groups). These labels become usable when the SDP root is a Bazel package of its own, for example when you publish the packaged tarball and consume it as an external repository. The list is in the [reference](reference.md#generated-sdp-build-file).

To package the SDP:

```starlark
load("@rules_pkg//pkg:tar.bzl", "pkg_tar")

pkg_tar(
    name = "qnx_sdp_pkg",
    srcs = ["qnx_sdp"],
    remap_paths = {"qnx_sdp": ""},  # drop the "qnx_sdp/" prefix in the tarball
)
```

## Common options

| Need | Setting |
| --- | --- |
| Build behind a proxy | `use_proxy = True`, `proxy_host = "..."`, `proxy_port = "..."` |
| Keep an existing installation instead of wiping it | `clean_install = False` |
| Use your own package selection | `patchset = "my_patchset.plist"` (a QNX Software Center patchset file) |
| Skip the generated `BUILD.bazel` inside the SDP | `set_build_file = False` |
| Use environment variables instead of `~/.netrc` | `--action_env=MYQNX_USER --action_env=MYQNX_PASSWORD`, see [credentials](license-and-credentials.md#credential-sources) |

## Authenticated downloads

If downloading the installer from `qnx.com` needs a login, enable the credential helper in your `.bazelrc`:

```
common --credential_helper=*.qnx.com=%workspace%/path/to/qnx_credential_helper.py
```

Copy [tools/qnx_credential_helper.py](../tools/qnx_credential_helper.py) into your repository and point the flag at it. The helper uses `SCORE_QNX_USER` / `SCORE_QNX_PASSWORD` or `~/.netrc`.

Problems? See [troubleshooting](troubleshooting.md#for-users).
