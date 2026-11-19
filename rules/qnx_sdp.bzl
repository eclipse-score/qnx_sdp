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

"""Rule for applying a patchset to the QNX SDP installer."""

load("@rules_pkg//pkg:providers.bzl", "PackageVariablesInfo")

_sdp_attrs = {
    "baseline": attr.string(
        default = "qnx800",
        doc = "The baseline which QNX Software Center will use for generating QNX SDP package.",
    ),
    "clean_install": attr.bool(
        default = True,
        doc = "Remove the active baseline installation, if one exists",
    ),
    "patchset": attr.label(
        allow_single_file = True,
        doc = "The patchset file to be applied to the QNX SDP installer.",
    ),
    "proxy_host": attr.string(
        default = "localhost",
        doc = "The proxy host for the QNX SDP installer.",
    ),
    "proxy_port": attr.string(
        default = "8080",
        doc = "The proxy port for the QNX SDP installer.",
    ),
    "sdp_version": attr.string(
        default = "8.0.5",
        doc = "The version of the QNX SDP to install.",
    ),
    "set_build_file": attr.bool(
        default = True,
        doc = "Whether to set the build template file, default is True.",
    ),
    "use_proxy": attr.bool(
        default = False,
        doc = "Whether to use a proxy for the QNX SDP installer.",
    ),
    "_build_template": attr.label(
        allow_single_file = True,
        default = Label("@score_qnx_sdp//templates/sdp:BUILD.template"),
        doc = "Optional BUILD.bazel template file to copy into the package root.",
    ),
    "_installer": attr.label(
        default = Label("@qnx_softwarecentercli//:installer"),
        allow_files = True,
        executable = True,
        cfg = "exec",
        doc = "The QNX SDP installer executable.",
    ),
    "_patchsets": attr.label_list(
        allow_files = True,
        default = ["@score_qnx_sdp//patchsets"],
        doc = "The list of patchset files to be applied to the QNX SDP installer.",
    ),
    "_wrapper": attr.label(
        default = Label("//tools:qnx_software_center_wrapper"),
        executable = True,
        cfg = "exec",
        doc = "Wrapper which supplies the myQNX credentials to the QNX Software Center CLI.",
    ),
}

def _resolve_patchset(ctx):
    """Resolve the patchset file to be used for the QNX SDP installer."""
    if ctx.file.patchset:
        return ctx.file.patchset
    selected = None
    highest_number = -1
    for patchset in ctx.files._patchsets:
        if ctx.attr.sdp_version not in patchset.dirname.split("/"):
            continue
        number = int(patchset.basename.removeprefix("patchset_").removesuffix(".plist"))
        if number > highest_number:
            selected = patchset
            highest_number = number
    if selected == None:
        fail("No patchset found for SDP version {}".format(ctx.attr.sdp_version))
    return selected

def _qnx_sdp_impl(ctx):
    """Register the SDP installation action and expose its package metadata."""
    patchset = _resolve_patchset(ctx)
    inputs = [patchset]
    qnx_sdp_dir = ctx.actions.declare_directory(ctx.label.name)
    args = ctx.actions.args()
    args.add("--installer", ctx.executable._installer)
    args.add("--destination", qnx_sdp_dir.path)
    user = ctx.configuration.default_shell_env.get("MYQNX_USER")
    password = ctx.configuration.default_shell_env.get("MYQNX_PASSWORD")
    if user:
        args.add("-u", user)
    if password:
        args.add("-p", password)
    if ctx.attr.set_build_file:
        args.add("-t", ctx.file._build_template)
        inputs.append(ctx.file._build_template)
    args.add("--")
    if ctx.attr.clean_install:
        args.add("-cleanInstall")
    args.add("-mirrorBaseline", ctx.attr.baseline)
    if ctx.attr.use_proxy:
        args.add("-proxy.host", ctx.attr.proxy_host)
        args.add("-proxy.port", ctx.attr.proxy_port)
    args.add("-importAndInstall", patchset)
    ctx.actions.run(
        inputs = inputs,
        outputs = [qnx_sdp_dir],
        executable = ctx.executable._wrapper,
        tools = [
            ctx.attr._wrapper[DefaultInfo].files_to_run,
            ctx.attr._installer[DefaultInfo].files_to_run,
        ] + ctx.attr._installer[DefaultInfo].default_runfiles.files.to_list(),
        arguments = [args],
    )
    return [
        DefaultInfo(files = depset([qnx_sdp_dir])),
        PackageVariablesInfo(values = {
            "sdp_version": ctx.attr.sdp_version,
            "patchset": patchset.basename.removesuffix(".plist"),
        }),
    ]

qnx_sdp = rule(
    implementation = _qnx_sdp_impl,
    attrs = _sdp_attrs,
)
