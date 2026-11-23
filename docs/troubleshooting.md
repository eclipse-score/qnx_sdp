<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0.

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# Troubleshooting

Consumers and contributors can use this guide to diagnose common errors while
setting up credentials, building QNX Software Development Platform (SDP)
artifacts, or maintaining this repository. It covers common symptoms and does
not replace the [user guide](user-guide.md) or
[developer guide](developer-guide.md). The QNX Software Center
command-line interface (CLI) handles SDP installation.

## Troubleshoot consumer builds

The following table maps consumer symptoms to likely causes and fixes:

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `No myQNX credentials: ...` | No complete `machine qnx.com` entry in `~/.netrc` and no `MYQNX_*` variables forwarded. | Set up [credentials](license-and-credentials.md#set-up-myqnx-credentials). |
| `--user and --password must be given together` | Only one of `MYQNX_USER` or `MYQNX_PASSWORD` is forwarded. | Set both variables or neither. |
| `No patchset found for SDP version` | `sdp_version` has no directory in `patchsets/`. | Use a supported version or set `patchset`. |
| Action fails with an authentication or license error. | The account lacks a license for the baseline or packages. | Check the license in your [QNX account](https://www.qnx.com/account/index.html#products) and [activate it](license-and-credentials.md#activate-the-license-key). |
| Download fails with 401/403, or a checksum mismatch occurs because the download is an HTML login page. | `qnx.com` requires authentication. | Configure [authenticated downloads](user-guide.md#authenticate-downloads). |
| Fetch or CLI cannot reach the network. | Your network requires a proxy. | Set `use_proxy`, `proxy_host`, and `proxy_port`. |
| The QNX toolchain configured by [`bazel_cpp_toolchains`](https://github.com/eclipse-score/bazel_cpp_toolchains) reports a missing license. | The license file is not at the configured `license_path`. | Check `license_path`. Its default is `/opt/score_qnx/license/licenses`; see [toolchain license setup](license-and-credentials.md#configure-the-s-core-toolchain-license-file). |
| Module resolution fails. | The registry is unreachable or not configured. | Add the `--registry` flags from [Add the module](user-guide.md#add-the-module). |

## Troubleshoot contributor builds

The following table maps contributor symptoms to likely causes and fixes:

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `Failed to extract QNX Software Center: ...` during fetch. | The installer exited with a nonzero status. | Read the printed output. Check disk space and confirm that the file is the Linux `.run` installer. |
| Installer fetch reaches the 300-second timeout. | Disk or network access is slow. | Retry, or raise `timeout` in [rules/qnx_softwarecentercli.bzl](../rules/qnx_softwarecentercli.bzl). |
| Download checksum does not match. | `sha256` is wrong in [MODULE.bazel](../MODULE.bazel), or `qnx.com` returned a login or authorization page instead of the installer. Bazel hashes that response as a downloaded file, so an authentication failure can look like a checksum mismatch. | Check [download authentication](user-guide.md#authenticate-downloads). Confirm that the downloaded file is the installer before checking its checksum with `sha256sum`. Do not replace the expected checksum with the checksum of an error page. |
| Wrapper reports `failed to run` for the installer. | The installer path is wrong or the file is not executable. | Fetch the installer again with the command in [Maintain the installer](developer-guide.md#maintain-the-installer). |
| Helper reports `URI must use HTTPS`. | The URI uses HTTP instead of HTTPS. | Use an HTTPS URL on `qnx.com` or one of its subdomains. |
| Helper reports `Unsupported domain`. | The URI host is not `qnx.com` or a subdomain. | This is expected for non-QNX domains. The helper accepts HTTPS `qnx.com` and subdomains only. |
| `Failed getting credentials from environment or .netrc` | No `SCORE_QNX_*` pair or `.netrc` entry is available. | Provide a complete credential pair as described in [Credential sources](license-and-credentials.md#credential-sources). |
| `Failed to get myQNX cookie from login page` | QNX rejected the credentials. | Verify your credentials on qnx.com. |
| The `bzlmod-lock` CI check fails. | `MODULE.bazel.lock` is stale. | Run `bazel mod deps --lockfile_mode=update` and commit the updated lockfile. |

## Force a refetch

To fetch the installer again, run:

```sh
bazel fetch --force @qnx_softwarecentercli//:installer
```

As a last resort, `bazel clean --expunge` removes the entire Bazel output base,
including cached downloads and build outputs. You must rebuild affected targets
after running it.
