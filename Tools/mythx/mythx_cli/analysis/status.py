import logging
from typing import List

import click

from mythx_cli.formatter import FORMAT_RESOLVER
from mythx_cli.util import write_or_print

LOGGER = logging.getLogger("mythx-cli")


@click.command("status")
@click.argument("uuids", default=None, nargs=-1)
@click.pass_obj
def analysis_status(ctx, uuids: List[str]) -> None:
    """Get the status of an already submitted analysis.

    \f

    :param ctx: Click context holding group-level parameters
    :param uuids: A list of job UUIDs to fetch the status for
    """
    for uuid in uuids:
        LOGGER.debug(f"{uuid}: Fetching status")
        resp = ctx["client"].status(uuid)
        LOGGER.debug(f"{uuid}: Printing status information")
        write_or_print(FORMAT_RESOLVER[ctx["fmt"]].format_analysis_status(resp))
