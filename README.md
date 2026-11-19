<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# score_qnx_sdp

Bazel module (Bzlmod) that installs a QNX Software Development Platform (SDP) with the QNX Software Center CLI and exposes it as a Bazel directory artifact. The result can be packaged, or used as the sysroot and tool source of a QNX toolchain.

For S-CORE builds, QNX C/C++ toolchain configuration is provided by the separate [`bazel_cpp_toolchains`](https://github.com/eclipse-score/bazel_cpp_toolchains) repository (Bazel module `score_bazel_cpp_toolchains`). This module produces SDP artifacts; it does not configure or register a C/C++ toolchain.

The module ships patchsets for QNX SDP 8.0.5 and 8.0.6, so a minimal consumer needs only a `qnx_sdp` target and a QNX account.

## Documentation

| I want to... | Read |
| --- | --- |
| Get a QNX account, license and credentials set up | [License and credentials](docs/license-and-credentials.md) |
| Use the module to get QNX SDP artifacts | [User guide](docs/user-guide.md) |
| Look up rule attributes, tools and environment variables | [Reference](docs/reference.md) |
| Change this module or add an SDP version | [Developer guide](docs/developer-guide.md) |
| Fix an error | [Troubleshooting](docs/troubleshooting.md) |

See [docs/README.md](docs/README.md) for the full index.
