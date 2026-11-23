<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0.

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# License and credentials

Consumers and contributors can use this guide to prepare a machine to build
QNX Software Development Platform (SDP) artifacts with `score_qnx_sdp` or the
S-CORE QNX toolchain. You need a QNX license and myQNX credentials. This guide
does not cover adding the module to a Bazel project; see the
[user guide](user-guide.md).

## Request a QNX Everywhere license

These steps apply to eligible participants using the free QNX Everywhere license
for non-commercial use. Check the [eligibility requirements and
terms](https://www.qnx.com/products/everywhere/) first. If you have a
commercial license, use your license key in [Activate the license key](#activate-the-license-key).

1. Create a QNX account at [QNX Everywhere](https://www.qnx.com/products/everywhere/).
2. Request a free license there.
3. Register the license.
4. Open [your account's products page](https://www.qnx.com/account/index.html#products).
5. Copy the license key.

## Set up myQNX credentials

The QNX Software Center command-line interface (CLI) uses myQNX credentials to
download packages. To set up the credentials:

1. Add your credentials to `~/.netrc`:

   ```text
   machine qnx.com
   login LOGIN
   password PASSWORD
   ```

   Replace `LOGIN` and `PASSWORD` with your myQNX credentials.

2. Restrict access to the file:

   ```sh
   chmod 600 ~/.netrc
   ```

Using `~/.netrc` is the recommended method. Environment variables are also
available, with trade-offs described in [Credential sources](#credential-sources).

## Activate the license key

Run the following steps from a checkout of this repository:

1. Add the license key:

   ```sh
   bazel run \
     @qnx_softwarecentercli//:qnxsoftwarecenter/qnxsoftwarecenter_clt -- \
     -addLicenseKey LICENSE_KEY
   ```

   Replace `LICENSE_KEY` with the key you copied or received from QNX.

2. Confirm that the CLI lists your key as activated:

   ```sh
   bazel run \
     @qnx_softwarecentercli//:qnxsoftwarecenter/qnxsoftwarecenter_clt -- \
     -listLicenseKeys
   ```

The CLI stores the license in `~/.qnx/license/licenses`.

## Configure the S-CORE toolchain license file

This step applies when you compile with the QNX C/C++ toolchain configured by
[`bazel_cpp_toolchains`](https://github.com/eclipse-score/bazel_cpp_toolchains).
It does not apply when you only produce SDP artifacts with this module.

The toolchain defaults to `/opt/score_qnx/license/licenses` for its license
file. If you do not configure a different `license_path`, copy the activated
license file there:

1. Create the license directory:

   ```sh
   sudo mkdir -p /opt/score_qnx/license
   ```

2. Copy the activated license file:

   ```sh
   sudo cp ~/.qnx/license/licenses /opt/score_qnx/license/licenses
   ```

For toolchain setup and license configuration, see its
[QNX integration guide](https://github.com/eclipse-score/bazel_cpp_toolchains/blob/main/docs/qnx_integration.md).

## Credential sources

The module uses two independent credential mechanisms:

| Purpose | Used by | Sources, in priority order |
| --- | --- | --- |
| Install the SDP (`qnxsoftwarecenter_clt`) | `qnx_sdp` rule through the wrapper | `MYQNX_USER` and `MYQNX_PASSWORD` forwarded with `--action_env`; otherwise `~/.netrc` |
| Authenticate Bazel downloads from `qnx.com` | Bazel credential helper | `SCORE_QNX_USER` and `SCORE_QNX_PASSWORD`; otherwise `~/.netrc` |

Keep these details in mind when choosing a credential source:

- Set both variables in a pair, or set neither. Supplying only one variable is
  an error in the wrapper and is ignored by the helper.
- With `MYQNX_*`, the password becomes part of the Bazel action command line.
  Prefer `~/.netrc`. See the developer guide's
  [security notes](developer-guide.md#review-security-sensitive-behavior).
- To avoid retyping flags, add them to an untracked `user.bazelrc` or to
  `~/.bazelrc`:

  ```text
  build --action_env=MYQNX_USER
  build --action_env=MYQNX_PASSWORD
  ```

- Never commit credentials, `.netrc`, or `user.bazelrc` files that contain
  credentials.
