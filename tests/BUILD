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

load("@rules_pkg//pkg:tar.bzl", "pkg_tar")
load("@score_qnx_sdp//rules:qnx_sdp.bzl", "qnx_sdp")

qnx_sdp(
    name = "qnx_sdp",
    patchset = ":patchsets/0.0.1/patchset.plist",
)

pkg_tar(
    name = "qnx_sdp_pkg",
    srcs = [
        "qnx_sdp",
    ],
    remap_paths = {"qnx_sdp": ""},
)
