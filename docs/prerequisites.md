<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# Prerequisites

## QNX free license

These instructions cover the free QNX Everywhere license for **non-commercial use by eligible participants**, not a commercial license. Check the [QNX Everywhere eligibility requirements and license terms](https://www.qnx.com/products/everywhere/) before requesting a license.

1. Visit [QNX Everywhere](https://www.qnx.com/products/everywhere/) and create a QNX account.
2. Request and register a free QNX license through QNX Everywhere.
3. After license registration, open [your QNX account's products page](https://www.qnx.com/account/index.html#products). Your license key is shown there.

Before running the Bazel commands below, add your QNX account credentials to `~/.netrc` under `machine qnx.com`. See [Getting Started: build-time credentials](getting-started.md#build-time-credentials-qnx_sdp) for the entry format.

From this repository's root, add the license key. Replace `KEY` with the key shown on the products page:

```sh
bazel run @qnx_softwarecentercli//:qnxsoftwarecenter/qnxsoftwarecenter_clt -- -addLicenseKey KEY
```

By default, this adds the license to `~/.qnx/license/licenses`.

Verify that the license is activated:

```sh
bazel run @qnx_softwarecentercli//:qnxsoftwarecenter/qnxsoftwarecenter_clt -- -listLicenseKeys
```

The output should list your license key and show that it is activated.

### Configure the S-CORE build toolchain

The S-CORE build toolchain expects the license file at `/opt/score_qnx/license/licenses`. As the final setup step, copy the activated license file there:

```sh
sudo mkdir -p /opt/score_qnx/license
sudo cp ~/.qnx/license/licenses /opt/score_qnx/license/licenses
```
