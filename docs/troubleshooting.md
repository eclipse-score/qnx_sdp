<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# Troubleshooting

## For users

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `No myQNX credentials: ...` | No complete `machine qnx.com` entry in `~/.netrc` and no `MYQNX_*` variables forwarded | Set up [credentials](license-and-credentials.md#2-myqnx-credentials). |
| `--user and --password must be given together` | Only one of `MYQNX_USER` / `MYQNX_PASSWORD` is forwarded | Set both or neither. |
| `No patchset found for SDP version X` | `sdp_version` has no directory in `patchsets/` | Use a supported version or set `patchset`. |
| Action fails with an authentication or license error | Account lacks a license for the baseline or packages | Check the license in your [account](https://www.qnx.com/account/index.html#products) and [activate it](license-and-credentials.md#3-activate-the-license-key). |
| Download fails with 401/403, or checksum mismatch because an HTML login page was returned | `qnx.com` needs authentication | Enable the [credential helper](user-guide.md#authenticated-downloads). |
| Fetch or CLI cannot reach the network | Proxy required | Set `use_proxy`, `proxy_host`, `proxy_port`. |
| QNX toolchain configured by [`bazel_cpp_toolchains`](https://github.com/eclipse-score/bazel_cpp_toolchains) complains about a missing license | License file not at the configured `license_path` | Check `license_path`; the default is `/opt/score_qnx/license/licenses` ([steps](license-and-credentials.md#4-license-file-for-the-s-core-toolchain)). |
| Module resolution fails | Registry not reachable or not configured | Add the `--registry` flags from the [user guide](user-guide.md#add-the-module). |

## For developers

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| `Failed to extract QNX Software Center: ...` during fetch | Installer exited non-zero | Read the printed output. Check disk space and that the file is the Linux `.run` installer. |
| Installer fetch hits the 300 s timeout | Slow disk or network | Retry, or raise `timeout` in [rules/qnx_softwarecentercli.bzl](../rules/qnx_softwarecentercli.bzl). |
| Checksum mismatch on download | Wrong `sha256` in [MODULE.bazel](../MODULE.bazel), or `qnx.com` returned a login/authorization error page instead of the installer. Bazel hashes that response as a downloaded file, so an authentication failure can misleadingly appear as a checksum mismatch. | Check [download authentication](user-guide.md#authenticated-downloads) and confirm the downloaded file is the actual installer before verifying its checksum with `sha256sum`. Do not replace the expected checksum with the checksum of an error page. |
| `failed to run <installer>` from the wrapper | Installer path wrong or not executable | Refetch (below). |
| `Unsupported domain` from the helper | URI is not `https` on `qnx.com` | Intended. The helper is only for `*.qnx.com`. |
| `Failed getting credentials from environment or .netrc` | No `SCORE_QNX_*` pair and no `.netrc` entry | Provide one. |
| `Failed to get myQNX cookie from login page` | Login rejected | Verify the credentials on qnx.com. |
| `bzlmod-lock` CI check fails | `MODULE.bazel.lock` stale | `bazel mod deps --lockfile_mode=update`, commit the lockfile. |

## Forcing a refetch

```sh
bazel fetch --force @qnx_softwarecentercli//:installer
```

As a last resort, `bazel clean --expunge` re-downloads everything in the output base.
