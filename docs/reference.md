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

```starlark
load("@score_qnx_sdp//rules:qnx_sdp.bzl", "qnx_sdp")
```

Declares one directory output named after the target. Source: [rules/qnx_sdp.bzl](../rules/qnx_sdp.bzl).

| Attribute | Type | Default | Description |
| --- | --- | --- | --- |
| `sdp_version` | string | `"8.0.5"` | SDP version. Selects the newest `patchset_N.plist` under `patchsets/<version>/` unless `patchset` is set. Always exposed in package metadata. |
| `patchset` | label (single file) | none | Own patchset file. Overrides the bundled one. |
| `baseline` | string | `"qnx800"` | Baseline passed to `-mirrorBaseline`. |
| `clean_install` | bool | `True` | Pass `-cleanInstall` to remove an existing baseline installation. |
| `use_proxy` | bool | `False` | Pass the proxy options to the CLI. |
| `proxy_host` | string | `"localhost"` | Proxy host, used if `use_proxy`. |
| `proxy_port` | string | `"8080"` | Proxy port, used if `use_proxy`. |
| `set_build_file` | bool | `True` | Copy [templates/sdp/BUILD.template](../templates/sdp/BUILD.template) to `BUILD.bazel` in the SDP root. |

Private attributes (`_wrapper`, `_installer`, `_build_template`, `_patchsets`) are implementation details. The rule fails with `No patchset found for SDP version ...` if no bundled patchset matches.

The rule returns `DefaultInfo` with the SDP directory and `PackageVariablesInfo`
for `rules_pkg`, containing:

| Variable | Value |
| --- | --- |
| `sdp_version` | The configured version, even when an explicit `patchset` is supplied. |
| `patchset` | The resolved patchset file's basename with a trailing `.plist` removed, whether bundled or explicitly supplied (for example `patchset_1`). |

Set `package_variables = ":qnx_sdp"` on a `pkg_tar` target to use these values in
`package_file_name`, for example `"qnx-sdp-{sdp_version}-{patchset}.tar.gz"`
with `extension = "tar.gz"`.

The action runs:

```
qnx_software_center_wrapper --installer <clt> --destination <out> [-u .. -p ..] [-t <template>] --
    [-cleanInstall] -mirrorBaseline <baseline> [-proxy.host .. -proxy.port ..] -importAndInstall <patchset>
```

## Bundled patchsets

Located at `patchsets/<sdp_version>/patchset_<N>.plist`. Each lists the QNX packages (`id/version//package`) to import and install, one per line. The highest `N` for a version is used.

## Generated SDP BUILD file

[templates/sdp/BUILD.template](../templates/sdp/BUILD.template) becomes `BUILD.bazel` inside the SDP directory. It contains public filegroups, grouped as:

| Group | Targets (suffix `_x86_64` or `_aarch64` where applicable) |
| --- | --- |
| Whole tree | `all_files`, `empty`, `host_all`, `host_dir`, `target_all`, `target_dir`, `sysroot_dir` |
| Binutils | `ar`, `as`, `gcov`, `ld`, `strip`, `objdump`, `readelf`, `mkifs` |
| Compiler and linker | `cc`, `cxx`, `qcc_target_config`, `compiler_pieces`, `linker_pieces`, `compiler_files`, `linker_files`, `cxx_builtin_include_directories` |
| Target content | `target_libraries`, `target_headers`, `pci_solibs`, `ssl_solibs` |
| File sets | `ar_files`, `as_files`, `strip_files`, `coverage_files`, `dwp_files`, `objcopy_files` |
| Utilities | `qchecksec`, `mkifs`, `elfnote`, `dumpifs`, `traceprinter`, `use`, `secpolcompile` |

The template is the source of truth for exact names.

## `qnx_softwarecentercli` repository rule

Source: [rules/qnx_softwarecentercli.bzl](../rules/qnx_softwarecentercli.bzl). Instantiated in [MODULE.bazel](../MODULE.bazel) as `@qnx_softwarecentercli`; not meant for direct use by consumers.

| Attribute | Description |
| --- | --- |
| `url` | Location of the Linux `.run` installer. |
| `sha256` | Checksum the download must match. |

It downloads and runs the installer with `--nox11 force-override disable-auto-start agree-to-license-terms .` (300 s timeout) and writes a `BUILD.bazel` exposing `:installer` (the `qnxsoftwarecenter/qnxsoftwarecenter_clt` binary, with the `qnxsoftwarecenter/**` tree as data).

## Wrapper

[tools/qnx_software_center_wrapper.py](../tools/qnx_software_center_wrapper.py), target `//tools:qnx_software_center_wrapper`. Adds `-myqnx.user` / `-myqnx.password` to a `qnxsoftwarecenter_clt` call so callers do not need them in their own command line, appends `-destination`, and optionally copies a BUILD template into the destination after success.

```
qnx_software_center_wrapper.py --installer PATH [-d DEST] [-u USER -p PASSWORD] [--netrc FILE] [-t TEMPLATE] -- <clt arguments>
```

| Option | Description |
| --- | --- |
| `-i`, `--installer` | Required. Path to `qnxsoftwarecenter_clt`. |
| `-d`, `--destination` | Passed to the CLI as `-destination`. |
| `-u`, `--user` / `-p`, `--password` | Credentials. Must be given together. Override `.netrc`. |
| `--netrc` | netrc file. Default `~/.netrc` (entry for machine `qnx.com`). |
| `-t`, `--template` | File copied to `<destination>/BUILD.bazel` after a successful run. |

Arguments after `--` go to the CLI unchanged. The wrapper exits with the CLI's exit code.

## Credential helper

[tools/qnx_credential_helper.py](../tools/qnx_credential_helper.py) implements the [Bazel credential helper protocol](https://github.com/bazelbuild/proposals/blob/main/designs/2022-06-07-bazel-credential-helpers.md). It reads a JSON request on stdin, and for `https://qnx.com` or `https://*.qnx.com` URIs logs in at `https://www.qnx.com/account/login.html` and prints a `Cookie: myQNX=...` header. Credentials come from `SCORE_QNX_USER` + `SCORE_QNX_PASSWORD`, else `~/.netrc`.

Exit codes: `0` ok, `1` general error, `2` non-HTTPS URI, `3` non-QNX domain, `4` no credentials, `5` login failed, `6` invalid JSON.

Manual check:

```sh
echo '{"uri":"https://www.qnx.com/download/"}' | SCORE_QNX_USER=<user> SCORE_QNX_PASSWORD=<pass> python3 tools/qnx_credential_helper.py
```

## Environment variables

| Variable | Used by | Meaning |
| --- | --- | --- |
| `MYQNX_USER`, `MYQNX_PASSWORD` | `qnx_sdp` (via `--action_env`) | Credentials for the SDP installation. Overrides `.netrc`. |
| `SCORE_QNX_USER`, `SCORE_QNX_PASSWORD` | credential helper | Credentials for Bazel downloads from `qnx.com`. |
