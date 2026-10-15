#!/usr/bin/env python3

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

import enum
import http.cookiejar
import json
import netrc
import os
import sys
import urllib.error
import urllib.parse
import urllib.request
from typing import Optional, Tuple

_QNX_DOMAIN = "qnx.com"
_QNX_URL = "https://www.qnx.com/account/login.html"
_QNX_SCORE_MARKERS = ("SCORE_QNX_USER", "SCORE_QNX_PASSWORD")


class Error(enum.IntEnum):
    NO_ERROR = 0
    GENERAL_ERROR = 1
    URI_ERROR = 2
    DOMAIN_ERROR = 3
    CREDENTIALS_ERROR = 4
    AUTHENTICATION_ERROR = 5
    JSON_ERROR = 6


def eprint(*args, **kwargs):
    print(*args, file=sys.stderr, **kwargs)


def is_https(scheme: str) -> bool:
    if scheme != "https":
        eprint(f"URI must use HTTPS")
        return False
    return True


def is_qnx_domain(hostname: str) -> bool:
    if not (hostname == _QNX_DOMAIN or hostname.endswith("." + _QNX_DOMAIN)):
        eprint(f"Unsupported domain: {hostname}")
        return False
    return True


def get_credentials(domain: str = _QNX_DOMAIN) -> Optional[Tuple[str, str]]:
    if all(name in os.environ for name in _QNX_SCORE_MARKERS):
        return (
            os.environ[_QNX_SCORE_MARKERS[0]],
            os.environ[_QNX_SCORE_MARKERS[1]],
        )

    try:
        auth = netrc.netrc().authenticators(domain)
    except (OSError, netrc.NetrcParseError) as exc:
        eprint(f"Failed reading .netrc: {exc}")
        return None
    if auth is None:
        eprint(f"No credentials found for {domain} in .netrc")
        return None

    login, _, password = auth
    if login is None or password is None:
        eprint(f"Incomplete credentials for {domain} in .netrc")
        return None

    return login, password


def login_for_cookie(login: str, password: str) -> Optional[str]:
    form_data = urllib.parse.urlencode(
        {"userlogin": login, "password": password, "UseCookie": "1"}
    ).encode("ascii")

    cookie_jar = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(
        urllib.request.HTTPCookieProcessor(cookie_jar)
    )
    try:
        with opener.open(_QNX_URL, data=form_data) as response:
            if response.status != 200:
                eprint(f"Failed to login to QNX (HTTP {response.status})")
                return None
    except (OSError, urllib.error.URLError) as exc:
        eprint(f"Failed to login to QNX: {exc}")
        return None

    for cookie in cookie_jar:
        if cookie.name == "myQNX":
            return cookie.value

    eprint(f"Failed to get myQNX cookie from login page")
    return None


def main() -> int:
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, OSError) as exc:
        eprint(f"Invalid JSON input: {exc}")
        return Error.JSON_ERROR

    try:
        parsed_uri = urllib.parse.urlparse(data["uri"])
        hostname = (parsed_uri.hostname or "").lower().rstrip(".")
    except (KeyError, TypeError, ValueError) as exc:
        eprint(f"Invalid URI: {exc}")
        return Error.GENERAL_ERROR

    if not is_https(parsed_uri.scheme):
        return Error.URI_ERROR

    if not is_qnx_domain(hostname):
        return Error.DOMAIN_ERROR

    credentials = get_credentials()
    if credentials is None:
        eprint(f"Failed getting credentials from environment or .netrc")
        return Error.CREDENTIALS_ERROR
    login, password = credentials

    my_qnx_cookie = login_for_cookie(login, password)
    if my_qnx_cookie is None:
        return Error.AUTHENTICATION_ERROR

    print(json.dumps({"headers": {"Cookie": [f"myQNX={my_qnx_cookie}"]}}))
    return Error.NO_ERROR


if __name__ == "__main__":
    sys.exit(main())