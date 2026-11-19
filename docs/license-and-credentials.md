<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# License and credentials

Required by both consumers and developers. Do these steps once per machine.

## 1. QNX account and license

The steps below cover the free QNX Everywhere license for **non-commercial use by eligible participants**. Check the [eligibility requirements and terms](https://www.qnx.com/products/everywhere/) first. With a commercial license, skip to step 2 and use your own license key.

1. Create a QNX account at [QNX Everywhere](https://www.qnx.com/products/everywhere/).
2. Request and register a free license there.
3. Open [your account's products page](https://www.qnx.com/account/index.html#products) and copy the license key.

## 2. myQNX credentials

The build logs in to myQNX to download packages. Put your credentials in `~/.netrc` and restrict it:

```
machine qnx.com
login <user>
password <password>
```

```sh
chmod 600 ~/.netrc
```

This is the recommended method. Environment variables work too, with downsides; see [Credential sources](#credential-sources).

## 3. Activate the license key

Run from a checkout of this repository, with the key from step 1 in place of `KEY`:

```sh
bazel run @qnx_softwarecentercli//:qnxsoftwarecenter/qnxsoftwarecenter_clt -- -addLicenseKey KEY
bazel run @qnx_softwarecentercli//:qnxsoftwarecenter/qnxsoftwarecenter_clt -- -listLicenseKeys
```

The license is stored in `~/.qnx/license/licenses`. The second command must list your key as activated.

## 4. License file for the S-CORE toolchain

This step applies when compiling with the QNX C/C++ toolchain configured by [`bazel_cpp_toolchains`](https://github.com/eclipse-score/bazel_cpp_toolchains) (Bazel module `score_bazel_cpp_toolchains`), not when only producing SDP artifacts with this module.

That toolchain defaults to `/opt/score_qnx/license/licenses` for its license file. Unless you configure a different `license_path`, copy the activated file there:

```sh
sudo mkdir -p /opt/score_qnx/license
sudo cp ~/.qnx/license/licenses /opt/score_qnx/license/licenses
```

For toolchain setup and license configuration, see its [QNX integration guide](https://github.com/eclipse-score/bazel_cpp_toolchains/blob/main/docs/qnx_integration.md).

## Credential sources

Two independent mechanisms use credentials.

| Purpose | Used by | Sources, in priority order |
| --- | --- | --- |
| Install the SDP (`qnxsoftwarecenter_clt`) | `qnx_sdp` rule via the wrapper | `MYQNX_USER` + `MYQNX_PASSWORD` forwarded with `--action_env`; otherwise `~/.netrc` |
| Authenticate Bazel downloads from `qnx.com` | Bazel credential helper | `SCORE_QNX_USER` + `SCORE_QNX_PASSWORD`; otherwise `~/.netrc` |

Details:

- Set both variables of a pair, or neither. A single one is an error in the wrapper and is ignored by the helper.
- With `MYQNX_*`, the password becomes part of the Bazel action command line. Prefer `~/.netrc`. See [security notes](developer-guide.md#security-notes).
- To avoid retyping flags, put them in an untracked `user.bazelrc` or your `~/.bazelrc`:

  ```
  build --action_env=MYQNX_USER
  build --action_env=MYQNX_PASSWORD
  ```

- Never commit credentials, `.netrc` or `user.bazelrc` files containing them.
