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

"""Wrapper for the QNX Software Center CLI (qnxsoftwarecenter_clt).

Adds the myQNX credentials to the CLI invocation so that they do not have to
appear in the caller's (e.g. Bazel action) command line.

Credentials are resolved in this order:
  1. --user and --password options of this wrapper (must be given together)
  2. the entry for machine "qnx.com" in the netrc file

Usage:
  qnx_software_center_wrapper.py --installer PATH [--user U] [--password P]
      [--netrc FILE] -- <qnxsoftwarecenter_clt arguments>
"""

import argparse
import netrc
import os
import sys
from typing import List, Optional, Sequence, Tuple

_QNX_DOMAIN = "qnx.com"


class WrapperError(Exception):
    """Raised when the wrapper cannot obtain valid credentials or read the netrc file."""


def eprint(*args, **kwargs):
    """Print to stderr; accepts the same arguments as print()."""
    print(*args, file=sys.stderr, **kwargs)


def read_netrc(path: Optional[str] = None) -> Tuple[Optional[str], Optional[str]]:
    """Read the myQNX credentials from a netrc file.

    Args:
        path: Path to the netrc file. Defaults to ~/.netrc.

    Returns:
        A tuple (login, password) for machine "qnx.com". Each element is None
        if the file or the entry does not exist, or the value is empty.

    Raises:
        WrapperError: If the file exists but cannot be read or parsed.
    """
    path = path or os.path.expanduser("~/.netrc")
    try:
        auth = netrc.netrc(path).authenticators(_QNX_DOMAIN)
    except FileNotFoundError:
        return None, None
    except (OSError, netrc.NetrcParseError) as exc:
        raise WrapperError(f"Failed reading {path}: {exc}") from exc
    if auth is None:
        return None, None
    login, _, password = auth
    return login or None, password or None


def resolve_credentials(
    user: Optional[str], password: Optional[str], netrc_path: Optional[str] = None
) -> Tuple[str, str]:
    """Determine the myQNX credentials to use.

    Credentials given on the command line take precedence over the netrc file;
    the two sources are never mixed.

    Args:
        user: myQNX user name from the command line, if any.
        password: myQNX password from the command line, if any.
        netrc_path: Path to the netrc file. Defaults to ~/.netrc.

    Returns:
        A tuple (user, password).

    Raises:
        WrapperError: If no complete credentials are available.
    """
    if user and password:
        return user, password

    netrc_user, netrc_password = read_netrc(netrc_path)
    if not (netrc_user and netrc_password):
        raise WrapperError(
            f"No myQNX credentials: pass --user and --password or add a "
            f"'machine {_QNX_DOMAIN}' entry with login and password to the netrc file"
        )
    return netrc_user, netrc_password


def build_command(
    installer: str, user: str, password: str, cli_args: Sequence[str]
) -> List[str]:
    """Build the qnxsoftwarecenter_clt command line.

    Args:
        installer: Path to the qnxsoftwarecenter_clt executable.
        user: myQNX user name.
        password: myQNX password.
        cli_args: Additional arguments passed to the CLI unchanged.

    Returns:
        The full argument vector, starting with the executable.
    """
    return [installer, "-myqnx.user", user, "-myqnx.password", password, *cli_args]


def parse_args(argv: Sequence[str]) -> Tuple[argparse.Namespace, List[str]]:
    """Parse the wrapper's command line.

    Everything after the first "--" is not parsed and is returned as the
    arguments for qnxsoftwarecenter_clt. Exits via parser.error() if only one
    of --user and --password is given.

    Args:
        argv: Command line arguments without the program name.

    Returns:
        A tuple (parsed wrapper arguments, arguments for qnxsoftwarecenter_clt).
    """
    parser = argparse.ArgumentParser(
        description="Wrapper for the QNX Software Center CLI (qnxsoftwarecenter_clt).",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        allow_abbrev=False,
    )
    parser.add_argument(
        "-i", "--installer", required=True, help="Path to qnxsoftwarecenter_clt"
    )
    parser.add_argument(
        "-u",
        "--user",
        help="myQNX user name (overrides netrc, requires --password)",
        default=None,
    )
    parser.add_argument(
        "-p",
        "--password",
        help="myQNX password (overrides netrc, requires --user)",
        default=None,
    )
    parser.add_argument("--netrc", help="Path to netrc file (default: ~/.netrc)")

    argv = list(argv)
    if "--" in argv:
        index = argv.index("--")
        own, cli_args = argv[:index], argv[index + 1 :]
    else:
        own, cli_args = argv, []

    args = parser.parse_args(own)
    if bool(args.user) != bool(args.password):
        parser.error("--user and --password must be given together!")
    return args, cli_args


def main(argv: Optional[Sequence[str]] = None) -> int:
    """Resolve credentials and run qnxsoftwarecenter_clt with them.

    Args:
        argv: Command line arguments without the program name. Defaults to sys.argv[1:].

    Returns:
        The exit code of the wrapper.
    """
    args, cli_args = parse_args(argv if argv is not None else sys.argv[1:])
    try:
        user, password = resolve_credentials(args.user, args.password, args.netrc)
        command = build_command(args.installer, user, password, cli_args)
        os.execvp(command[0], command)
    except WrapperError as exc:
        eprint(f"qnx_software_center_wrapper: {exc}")
        return 1
    except OSError as exc:
        eprint(f"qnx_software_center_wrapper: failed to run {args.installer}: {exc}")
        return 1
    return 0  # unreachable: execvp replaces the process on success


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
