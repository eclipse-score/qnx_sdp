<!-- ----------------------------------------------------------------------------
  Copyright (c) 2026 Contributors to the Eclipse Foundation

  See the NOTICE file(s) distributed with this work for additional
  information regarding copyright ownership.

  This program and the accompanying materials are made available under the
  terms of the Apache License Version 2.0 which is available at
  https://www.apache.org/licenses/LICENSE-2.0.

  SPDX-License-Identifier: Apache-2.0
----------------------------------------------------------------------------- -->

# Reference

Consumers and contributors can use this reference to look up the module's rule
attributes, generated labels, repository rule, and helper tools for QNX
Software Development Platform (SDP) artifacts. For setup and procedures, see
the [user guide](user-guide.md) and [developer guide](developer-guide.md).

## `qnx_sdp` rule

Load the rule in a BUILD file with:

```starlark
load("@score_qnx_sdp//rules:qnx_sdp.bzl", "qnx_sdp")
```

The rule declares a directory output named after its target. Its source is
[`rules/qnx_sdp.bzl`](../rules/qnx_sdp.bzl). The following attributes are
available:

| Attribute | Type | Default | Description |
| --- | --- | --- | --- |
| `sdp_version` | string | `"8.0.5"` | SDP version. Selects the newest `patchset_N.plist` under `patchsets/SDP_VERSION/` unless `patchset` is set. Always exposed in package metadata. |
| `patchset` | label (single file) | none | Patchset file to use instead of the bundled one. |
| `baseline` | string | `"qnx800"` | Baseline passed to `-mirrorBaseline`. |
| `clean_install` | bool | `True` | Passes `-cleanInstall` to remove an existing baseline installation. |
| `use_proxy` | bool | `False` | Passes proxy options to the QNX Software Center command-line interface (CLI). |
| `proxy_host` | string | `"localhost"` | Proxy host, used when `use_proxy` is true. |
| `proxy_port` | string | `"8080"` | Proxy port, used when `use_proxy` is true. |
| `set_build_file` | bool | `True` | Copies [templates/sdp/BUILD.template](../templates/sdp/BUILD.template) to `BUILD.bazel` in the SDP root. |

Private attributes (`_wrapper`, `_installer`, `_build_template`, and
`_patchsets`) are implementation details. The rule fails with
`No patchset found for SDP version ...` if no bundled patchset matches.

The rule returns `DefaultInfo` with the SDP directory and `PackageVariablesInfo`
for `rules_pkg`. The package variables are:

| Variable | Value |
| --- | --- |
| `sdp_version` | Configured version, even when you supply an explicit `patchset`. |
| `patchset` | Resolved patchset file's basename without `.plist`, whether bundled or explicit (for example, `patchset_1`). |

Set `package_variables = ":qnx_sdp"` on a `pkg_tar` target to use these values
in `package_file_name`. For example, use
`"qnx-sdp-{sdp_version}-{patchset}.tar.gz"` with `extension = "tar.gz"`.

The action invokes the wrapper with this argument structure:

```text
qnx_software_center_wrapper --installer INSTALLER --destination OUT \
  [--user USER --password PASSWORD] [--template TEMPLATE] -- \
  [-cleanInstall] -mirrorBaseline BASELINE \
  [-proxy.host PROXY_HOST -proxy.port PROXY_PORT] \
  -importAndInstall PATCHSET
```

`INSTALLER` is the CLI path, and `OUT` is the output directory. The rule
supplies `USER` and `PASSWORD` from the configured credentials, `TEMPLATE` from
the template file, and the remaining values from the rule attributes and
resolved patchset.

## Bundled patchsets

Patchsets are stored at `patchsets/SDP_VERSION/patchset_N.plist`. Replace
`SDP_VERSION` with the SDP version. Each file lists the QNX packages
(`id/version//package`) to import and install, one per line. The rule uses the
highest `N` for each SDP version.

## Generated SDP BUILD file

The rule copies [templates/sdp/BUILD.template](../templates/sdp/BUILD.template)
to `BUILD.bazel` in the SDP directory. The template defines these public
filegroups:

| Group | Targets (suffix `_x86_64` or `_aarch64` where applicable) |
| --- | --- |
| Whole tree | `all_files`, `empty`, `host_all`, `host_dir`, `target_all`, `target_dir`, `sysroot_dir` |
| Binutils | `ar`, `as`, `gcov`, `ld`, `strip`, `objdump`, `readelf`, `mkifs` |
| Compiler and linker | `cc`, `cxx`, `qcc_target_config`, `compiler_pieces`, `linker_pieces`, `compiler_files`, `linker_files`, `cxx_builtin_include_directories` |
| Target content | `target_libraries`, `target_headers`, `pci_solibs`, `ssl_solibs` |
| File sets | `ar_files`, `as_files`, `strip_files`, `coverage_files`, `dwp_files`, `objcopy_files` |
| Utilities | `qchecksec`, `mkifs`, `elfnote`, `dumpifs`, `traceprinter`, `use`, `secpolcompile` |

The template is the source of truth for exact target names.

## `qnx_softwarecentercli` repository rule

The source for this rule is
[`rules/qnx_softwarecentercli.bzl`](../rules/qnx_softwarecentercli.bzl).
[`MODULE.bazel`](../MODULE.bazel) instantiates it as
`@qnx_softwarecentercli`; consumers do not use it directly.

The rule accepts these attributes:

| Attribute | Description |
| --- | --- |
| `url` | Location of the Linux `.run` installer. |
| `sha256` | SHA-256 checksum that the downloaded installer must match. |

The rule downloads and runs the installer with
`--nox11 force-override disable-auto-start agree-to-license-terms .` and a
300-second timeout. It writes a `BUILD.bazel` file that exposes `:installer`
for `qnxsoftwarecenter/qnxsoftwarecenter_clt` and includes the
`qnxsoftwarecenter/**` tree as data.

## Wrapper

[`tools/qnx_software_center_wrapper.py`](../tools/qnx_software_center_wrapper.py)
defines the `//tools:qnx_software_center_wrapper` target. It adds
`-myqnx.user` and `-myqnx.password` to a CLI call, appends `-destination`, and
can copy a BUILD template into the destination after the CLI succeeds.

The wrapper accepts this command-line syntax:

```text
qnx_software_center_wrapper.py --installer INSTALLER \
  [--destination DESTINATION] [--user USER --password PASSWORD] \
  [--netrc NETRC_FILE] [--template TEMPLATE] -- CLI_ARGUMENTS...
```

Replace each uppercase name with its corresponding path, credential, or CLI
argument. `CLI_ARGUMENTS...` represents the arguments passed to
`qnxsoftwarecenter_clt`.

The following options configure the wrapper:

| Option | Description |
| --- | --- |
| `-i`, `--installer` | Required path to `qnxsoftwarecenter_clt`. |
| `-d`, `--destination` | Destination passed to the CLI as `-destination`. |
| `-u`, `--user` / `-p`, `--password` | Credentials. Supply both to override `.netrc`. |
| `--netrc` | netrc file. Defaults to `~/.netrc` (entry for machine `qnx.com`). |
| `-t`, `--template` | File copied to `DESTINATION/BUILD.bazel` after a successful run. |

Arguments after `--` go to the CLI unchanged. The wrapper returns the CLI's exit
code.

## Credential helper

[`tools/qnx_credential_helper.py`](../tools/qnx_credential_helper.py)
implements the [Bazel credential helper
protocol](https://github.com/bazelbuild/proposals/blob/main/designs/2022-06-07-bazel-credential-helpers.md).
It reads a JSON request from standard input. For `https://qnx.com` and
`https://*.qnx.com` URIs, it logs in at
`https://www.qnx.com/account/login.html` and writes a JSON response containing
a `Cookie: myQNX=...` header. Credentials come from `SCORE_QNX_USER` and
`SCORE_QNX_PASSWORD`, or from `~/.netrc`.

The helper uses these exit codes:

| Code | Meaning |
| --- | --- |
| `0` | Success. |
| `1` | General error. |
| `2` | URI does not use HTTPS. |
| `3` | URI is not on a QNX domain. |
| `4` | Credentials are unavailable. |
| `5` | Login failed. |
| `6` | JSON input is invalid. |

To check the helper manually, send it a JSON request:

```sh
printf '%s\n' '{"uri":"https://www.qnx.com/download/"}' |
  SCORE_QNX_USER=LOGIN SCORE_QNX_PASSWORD=PASSWORD \
  python3 tools/qnx_credential_helper.py
```

Replace `LOGIN` and `PASSWORD` with your myQNX credentials. On success, the
helper prints a JSON response with a `Cookie` header.

## Environment variables

The module uses these environment variables:

| Variable | Used by | Meaning |
| --- | --- | --- |
| `MYQNX_USER`, `MYQNX_PASSWORD` | `qnx_sdp` through `--action_env` | Credentials for SDP installation. Overrides `.netrc`. |
| `SCORE_QNX_USER`, `SCORE_QNX_PASSWORD` | Credential helper | Credentials for Bazel downloads from `qnx.com`. |
