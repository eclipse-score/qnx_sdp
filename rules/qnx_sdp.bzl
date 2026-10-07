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
    user = ctx.configuration.default_shell_env["MYQNX_USER"]
    password = ctx.configuration.default_shell_env["MYQNX_PASSWORD"]
    args = ctx.actions.args()
    args.add("-myqnx.user", user)
    args.add("-myqnx.password", password)
    args.add("-importAndInstall", ctx.file.patchset)
    args.add("-destination", qnx_sdp_dir.path)
    ctx.actions.run(
        inputs = [ctx.file.patchset],
        outputs = [qnx_sdp_dir],
        executable = ctx.executable._installer,
        tools = ctx.attr._installer[DefaultInfo].default_runfiles.files,
        arguments = [args],
    )
    return DefaultInfo(files = depset([qnx_sdp_dir]))

qnx_sdp = rule(
    implementation = _impl,
    attrs = {
        "patchset": attr.label(
            allow_single_file = True,
            doc = "The patchset file to be applied to the QNX SDP installer.",
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
