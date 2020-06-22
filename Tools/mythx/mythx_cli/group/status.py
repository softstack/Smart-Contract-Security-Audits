import logging
from typing import List

import click

from mythx_cli.formatter import FORMAT_RESOLVER
from mythx_cli.util import write_or_print

LOGGER = logging.getLogger("mythx-cli")


@click.command("status")
@click.argument("gids", default=None, nargs=-1)
@click.pass_obj
def group_status(ctx, gids: List[str]) -> None:
    """Get the status of an analysis group.

    \f

    :param ctx: Click context holding group-level parameters
    :param gids: A list of group IDs to fetch the status for
    """

    for gid in gids:
        LOGGER.debug(f"Fetching group status for ID {gid}")
        resp = ctx["client"].group_status(group_id=gid)
        write_or_print(FORMAT_RESOLVER[ctx["fmt"]].format_group_status(resp))
