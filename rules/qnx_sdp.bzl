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

def _impl(ctx):
    """ Implementation of the qnx_sdp rule.
    """
    qnx_sdp_dir = ctx.actions.declare_directory(ctx.label.name)
    args = ctx.actions.args()
    args.add("--installer", ctx.executable._installer)
    user = ctx.configuration.default_shell_env.get("MYQNX_USER")
    password = ctx.configuration.default_shell_env.get("MYQNX_PASSWORD")
    if user:
        args.add("-u", user)
    if password:
        args.add("-p", password)
    args.add("--")
    if ctx.attr.clean_install:
        args.add("-cleanInstall")
    args.add("-mirrorBaseline", ctx.attr.baseline)
    if ctx.attr.use_proxy:
        args.add("-proxy.host", ctx.attr.proxy_host)
        args.add("-proxy.port", ctx.attr.proxy_port)
    args.add("-importAndInstall", ctx.file.patchset)
    args.add("-destination", qnx_sdp_dir.path)
    ctx.actions.run(
        inputs = [ctx.file.patchset],
        outputs = [qnx_sdp_dir],
        executable = ctx.executable._wrapper,
        tools = [
            ctx.attr._wrapper[DefaultInfo].files_to_run,
            ctx.attr._installer[DefaultInfo].files_to_run,
        ] + ctx.attr._installer[DefaultInfo].default_runfiles.files.to_list(),
        arguments = [args],
    )
    return DefaultInfo(files = depset([qnx_sdp_dir]))

qnx_sdp = rule(
    implementation = _impl,
    attrs = {
        "use_proxy": attr.bool(
            mandatory = False,
            default = False,
            doc = "Whether to use a proxy for the QNX SDP installer.",
        ),
        "proxy_host": attr.string(
            mandatory = False,
            default = "localhost",
            doc = "The proxy host for the QNX SDP installer.",
        ),
        "proxy_port": attr.string(
            mandatory = False,
            default = "8080",
            doc = "The proxy port for the QNX SDP installer.",
        ),
        "baseline": attr.string(
            mandatory = False,
            default = "qnx800",
            doc = "The baseline which QNX Software Center will use for generating QNX SDP package.",
        ),
        "clean_install": attr.bool(
            mandatory = False,
            default = False,
            doc = "Remove the active baseline installation, if one exists",
        ),
        "patchset": attr.label(
            allow_single_file = True,
            doc = "The patchset file to be applied to the QNX SDP installer.",
        ),
        "_wrapper": attr.label(
            default = Label("//tools:qnx_software_center_wrapper"),
            executable = True,
            cfg = "exec",
            doc = "Wrapper which supplies the myQNX credentials to the QNX Software Center CLI.",
        ),
        "_installer": attr.label(
            default = Label("@qnx_softwarecentercli//:installer"),
            allow_files = True,
            executable = True,
            cfg = "exec",
            doc = "The QNX SDP installer executable.",
        ),
    },
)
