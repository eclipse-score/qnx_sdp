<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

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
| `clean_install` | bool | no | `False` | Passes `-cleanInstall`, which removes the active baseline installation if one exists. |
| `use_proxy` | bool | no | `False` | Pass the proxy settings below to the CLI. |
| `proxy_host` | string | no | `"localhost"` | Proxy host, passed as `-proxy.host`. Only used if `use_proxy` is set. |
| `proxy_port` | string | no | `"8080"` | Proxy port, passed as `-proxy.port`. Only used if `use_proxy` is set. |
| `patchset` | label (single file) | effectively yes | none | Patchset file passed to `-importAndInstall`. |
| `_wrapper` | label | private | `//tools:qnx_software_center_wrapper` | The [wrapper](#qnx-software-center-wrapper) that runs the CLI, built for `exec`. Not intended to be overridden. |
| `_installer` | label | private | `@qnx_softwarecentercli//:installer` | The CLI executable, built for `exec`. Not intended to be overridden. |

`patchset` is not marked `mandatory`. If it is omitted, `ctx.file.patchset` is `None` and the rule fails during analysis, so treat it as required.

Example with a proxy:

```starlark
qnx_sdp(
    name = "qnx_sdp",
    patchset = ":patchsets/0.0.1/patchset.plist",
    use_proxy = True,
    proxy_host = "127.0.0.1",
    proxy_port = "48159",
)
```

### Action

Executable: the wrapper `//tools:qnx_software_center_wrapper`. The wrapper runs the CLI `@qnx_softwarecentercli//:installer` (`qnxsoftwarecenter/qnxsoftwarecenter_clt`).

| Argument | Value |
| --- | --- |
| `--installer` | path of the CLI executable |
| `-u` | `MYQNX_USER` from `ctx.configuration.default_shell_env`, only if set |
| `-p` | `MYQNX_PASSWORD` from `ctx.configuration.default_shell_env`, only if set |
| `--` | separator, everything after it goes to the CLI |
| `-cleanInstall` | only if `clean_install` is set |
| `-mirrorBaseline` | `baseline` |
| `-proxy.host`, `-proxy.port` | `proxy_host`, `proxy_port`, only if `use_proxy` is set |
| `-importAndInstall` | path of `patchset` |
| `-destination` | path of the declared output directory |

The wrapper adds `-myqnx.user` and `-myqnx.password` to the CLI call itself.

Inputs: the patchset. Tools: the wrapper and the installer, including the installer's runfiles. Outputs: one tree artifact.

### Outputs

- `DefaultInfo.files`: a depset containing the SDP directory, named `<name>`.
- No custom providers are returned.

### Credentials

The myQNX credentials are optional in the build invocation:

- If both `MYQNX_USER` and `MYQNX_PASSWORD` are in the action environment (`--action_env=MYQNX_USER --action_env=MYQNX_PASSWORD`), the rule passes them to the wrapper as `-u` and `-p`. In this case the password is part of the action command line.
- Otherwise the wrapper reads the `qnx.com` entry from `~/.netrc`. The credentials then never appear in the action command line.

## QNX Software Center wrapper

File: [tools/qnx_software_center_wrapper.py](../tools/qnx_software_center_wrapper.py). Exposed as the `py_binary` `//tools:qnx_software_center_wrapper` in [tools/BUILD.bazel](../tools/BUILD.bazel). It uses only the Python standard library and shares no code with the credential helper.

It supplies the myQNX credentials to `qnxsoftwarecenter_clt`, so that the caller does not have to put them on a command line.

### Usage

```
qnx_software_center_wrapper.py -i|--installer PATH [-u|--user USER -p|--password PASSWORD]
    [--netrc FILE] -- <qnxsoftwarecenter_clt arguments>
```

| Option | Required | Description |
| --- | --- | --- |
| `-i`, `--installer` | yes | Path to `qnxsoftwarecenter_clt`. |
| `-u`, `--user` | with `-p` | myQNX user name. Overrides `.netrc`. |
| `-p`, `--password` | with `-u` | myQNX password. Overrides `.netrc`. |
| `--netrc` | no | Path to the netrc file. Default: `~/.netrc`. |

Everything after the first `--` is passed to the CLI unchanged.

### Behavior

1. `--user` and `--password` must be given together, or not at all. Giving only one is an argument error (exit code 2).
2. If both are given, they are used. Otherwise the wrapper reads the login and password of machine `qnx.com` from the netrc file. The two sources are never mixed.
3. If no complete credentials are found (including a missing netrc file or entry), the wrapper prints an error and exits with code 1.
4. The wrapper builds `<installer> -myqnx.user <user> -myqnx.password <password> <CLI arguments>` and replaces itself with it (`execvp`). The CLI's output and exit code therefore pass straight through.
5. If the installer cannot be started, the wrapper prints an error and exits with code 1.

Example `~/.netrc` entry (use `chmod 600`):

```
machine qnx.com
login <user>
password <password>
```

The wrapper still has to pass the credentials to the CLI as arguments, so they can be visible in the process list on the build host while the CLI runs.

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
