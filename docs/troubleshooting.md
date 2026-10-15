<!--
# *******************************************************************************
# Copyright (c) 2026 Contributors to the Eclipse Foundation
#
# See the NOTICE file(s) distributed with this work for additional
# information regarding copyright ownership.
#
# This program and the accompanying materials are made available under the
# terms of the Apache License Version 2.0 which is available at
# https://www.apache.org/licenses/LICENSE-2.0
#
# SPDX-License-Identifier: Apache-2.0
# *******************************************************************************
-->

# Troubleshooting

## Common failures

| Symptom | Likely cause | Fix |
| --- | --- | --- |
| Analysis error about key `MYQNX_USER` or `MYQNX_PASSWORD` | Variables not forwarded to Bazel's action environment | Export both variables and pass `--action_env=MYQNX_USER --action_env=MYQNX_PASSWORD`. |
| Analysis error about `patchset` being `None` | `patchset` attribute not set | Set `patchset` on the `qnx_sdp` target. |
| `Failed to extract QNX Software Center: ...` during fetch | Installer exited non-zero | Read the printed stdout and stderr. Check disk space, that the file is a Linux `.run` installer, and that it can run on the host. |
| Checksum mismatch on download | Wrong `sha256`, or the download returned an HTML login page | Verify `sha256` against the file. If the page requires login, configure the credential helper. |
| Download fails with 401/403 | No authentication for `qnx.com` | Configure `--credential_helper` and credentials. See [getting-started.md](getting-started.md#authenticated-downloads-credential-helper). |
| `Unsupported domain` from the helper | URL is not `https` on `qnx.com` or a subdomain | Intended behavior. Use the helper only for `*.qnx.com`. |
| `Failed getting credentials from .netrc` | Neither `SCORE_QNX_*` variables nor a `qnx.com` entry in `~/.netrc` | Set both `SCORE_QNX_USER` and `SCORE_QNX_PASSWORD`, or add a `machine qnx.com` entry. |
| `Failed to get myQNX cookie from login page` | Login did not succeed (bad credentials) | Check the user name and password by logging in on qnx.com. |
| Installer fetch hits the 300 second timeout | Slow network or disk | Retry, or raise `timeout` in [rules/qnx_softwarecentercli.bzl](../rules/qnx_softwarecentercli.bzl). |
| Module `rules_pkg` not found when building in `tests/` | Network or registry access problem | `tests/` uses the default registry. Check connectivity to `bcr.bazel.build`. |
| `qnx_sdp` action fails with an authentication or license error | Account lacks entitlement for the baseline or packages | Confirm the myQNX account has the required licenses for the patchset. |

## Forcing a refetch

If the installer repository is in a bad state:

```sh
bazel clean --expunge        # or: bazel fetch --force @qnx_softwarecentercli//:installer
```

Use `--expunge` only if you accept re-downloading everything in the output base.

## Security notes

- The `qnx_sdp` rule passes the myQNX password as the command-line argument `-myqnx.password`. It can therefore be seen in the process list on the build host, and it is part of the action's command line. Avoid remote caches or execution services that record action command lines, and treat build logs from `--subcommands` or `--verbose_failures` as sensitive.
- The installer is run with `agree-to-license-terms`. Make sure the people running the build are entitled to accept the QNX license terms.
- The credential helper only sends credentials to `https://*.qnx.com` hosts. Keep that check when modifying it.
- Do not commit credentials, `.netrc`, or `user.bazelrc` files that contain them.
- The installer is verified by SHA-256, so any URL or checksum change should be reviewed.
