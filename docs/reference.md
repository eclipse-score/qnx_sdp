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

# Reference

## `qnx_sdp` rule

Defined in [rules/qnx_sdp.bzl](../rules/qnx_sdp.bzl).

```starlark
load("@score_qnx_sdp//rules:qnx_sdp.bzl", "qnx_sdp")
```

Runs the QNX Software Center CLI to import a patchset and install the resulting SDP into a directory.

### Attributes

| Attribute | Type | Required | Default | Description |
| --- | --- | --- | --- | --- |
| `name` | name | yes | | Target name. Also the name of the output directory. |
| `baseline` | string | no | `"qnx800"` | Baseline passed to `-mirrorBaseline`. |
| `patchset` | label (single file) | effectively yes | none | Patchset file passed to `-importAndInstall`. |
| `_installer` | label | private | `@qnx_softwarecentercli//:installer` | The CLI executable, built for `exec`. Not intended to be overridden. |

`patchset` is not marked `mandatory`. If it is omitted, `ctx.file.patchset` is `None` and the rule fails during analysis, so treat it as required.

### Action

Executable: `@qnx_softwarecentercli//:installer` (`qnxsoftwarecenter/qnxsoftwarecenter_clt`).

| Argument | Value |
| --- | --- |
| `-mirrorBaseline` | `baseline` |
| `-myqnx.user` | `MYQNX_USER` from `ctx.configuration.default_shell_env` |
| `-myqnx.password` | `MYQNX_PASSWORD` from `ctx.configuration.default_shell_env` |
| `-importAndInstall` | path of `patchset` |
| `-destination` | path of the declared output directory |

Inputs: the patchset. Tools: the runfiles of the installer. Outputs: one tree artifact.

### Outputs

- `DefaultInfo.files`: a depset containing the SDP directory, named `<name>`.
- No custom providers are returned.

### Required environment

`MYQNX_USER` and `MYQNX_PASSWORD` must be present in the action environment. Use `--action_env=MYQNX_USER --action_env=MYQNX_PASSWORD`.

## `qnx_softwarecentercli` repository rule

Defined in [rules/qnx_softwarecentercli.bzl](../rules/qnx_softwarecentercli.bzl). Loaded in [MODULE.bazel](../MODULE.bazel) with `use_repo_rule`.

### Attributes

| Attribute | Type | Required | Description |
| --- | --- | --- | --- |
| `name` | string | yes | Repository name (`qnx_softwarecentercli` in this module). |
| `url` | string | yes | URL of the QNX Software Center installer `.run` script. |
| `sha256` | string | yes | SHA-256 of the installer. Download fails on mismatch. |

### Generated targets

| Target | Description |
| --- | --- |
| `@qnx_softwarecentercli//:installer` | `filegroup` whose single source is `qnxsoftwarecenter/qnxsoftwarecenter_clt`, with the whole installation (`glob(["**"])`) as `data`. Public visibility. |

### Installer invocation

```
./qnx-swc-setup.run --nox11 force-override disable-auto-start agree-to-license-terms .
```

- Timeout: 300 seconds.
- A non-zero exit code fails the fetch with the installer's stdout and stderr.

### Upgrading the installer

1. Obtain the new installer URL.
2. Compute its checksum: `sha256sum qnx-setup-*.run`.
3. Update `url` and `sha256` in [MODULE.bazel](../MODULE.bazel).
4. Rebuild, and refresh the lockfile if Bazel asks for it.

## Credential helper

File: [tools/qnx_credential_helper.py](../tools/qnx_credential_helper.py). Exported through `exports_files` in [tools/BUILD.bazel](../tools/BUILD.bazel).

### Protocol

- Input (stdin): JSON such as `{"uri": "https://www.qnx.com/..."}`.
- Output (stdout): JSON `{"headers": {"Cookie": ["myQNX=<token>"]}}`.
- Errors are written to stderr, and the exit code is 1.

### Logic

1. Parse `uri`. Exit with `Invalid URI` if it is missing or malformed.
2. Accept only the `https` scheme and host `qnx.com` or any `*.qnx.com` subdomain (case-insensitive, trailing dot ignored). Otherwise exit with `Unsupported domain`. This stops credentials being sent to other hosts.
3. Resolve credentials:
   - If both `SCORE_QNX_USER` and `SCORE_QNX_PASSWORD` are set, use them.
   - Otherwise read the `qnx.com` entry from `~/.netrc`. A missing file or entry exits with `Failed getting credentials from .netrc`.
4. POST `userlogin`, `password`, `UseCookie=1` (form-encoded) to `https://www.qnx.com/account/login.html`, using a cookie jar.
5. Fail if the response status is not 200, or if no `myQNX` cookie was set.
6. Print the `Cookie: myQNX=<value>` header for Bazel to attach to the download.

HTTP error responses raise `urllib.error.HTTPError`, which is not caught, so the script exits with a traceback. The script sets no network timeout.

### Manual check

```sh
echo '{"uri":"https://www.qnx.com/download/"}' | SCORE_QNX_USER=<user> SCORE_QNX_PASSWORD=<pass> python3 tools/qnx_credential_helper.py
```

A rejected domain, for example `{"uri":"https://example.com/"}`, must print `Unsupported domain` and exit with 1 without any network access.

## Module configuration summary

| File | Setting | Value |
| --- | --- | --- |
| [MODULE.bazel](../MODULE.bazel) | `module(name)` | `score_qnx_sdp` |
| [MODULE.bazel](../MODULE.bazel) | `bazel_dep` | `rules_pkg` 1.2.0 |
| [MODULE.bazel](../MODULE.bazel) | installer repository | `qnx_softwarecentercli`, QNX Software Center 2.0.4 (Linux) |
| [.bazelrc](../.bazelrc) | registries | Eclipse S-CORE registry, then `bcr.bazel.build` |
| [tests/MODULE.bazel](../tests/MODULE.bazel) | module | `score_qnx_sdp_test`, with `local_path_override` to `../` |
