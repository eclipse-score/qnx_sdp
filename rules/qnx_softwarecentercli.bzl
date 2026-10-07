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

"""Rule for downloading and setting up the QNX Software Center CLI installer."""

def _impl(rctx):
    """ Implementation of the qnx_softwarecentercli repository rule.
    """
    rctx.download(
        url = rctx.attr.url,
        output = "qnx-swc-setup.run",
        sha256 = rctx.attr.sha256,
        executable = True,
    )

    # Make installer executable
    rctx.execute(["chmod", "+x", "./qnx-swc-setup.run"], quiet = True)

    # Run the installer
    result = rctx.execute(
        [
            "./qnx-swc-setup.run",
            "--nox11",
            "force-override",
            "disable-auto-start",
            "agree-to-license-terms",
            ".",
        ],
        timeout = 300,
        quiet = False,
    )

    if result.return_code != 0:
        fail("Failed to extract QNX Software Center: %s\nStderr: %s" % (result.stdout, result.stderr))

    rctx.file(
        "BUILD.bazel",
        content = """
package(default_visibility = ["//visibility:public"])
filegroup(
    name = "installer",
    srcs = ["qnxsoftwarecenter/qnxsoftwarecenter_clt"],
    data = glob(["**"]),
)
""",
    )

qnx_softwarecentercli = repository_rule(
    implementation = _impl,
    attrs = {
        "url": attr.string(
            mandatory = True,
            doc = "URL pointing to the QNX Software Center installer script.",
        ),
        "sha256": attr.string(
            mandatory = True,
            doc = "SHA-256 checksum of the QNX Software Center installer script.",
        ),
    },
)
