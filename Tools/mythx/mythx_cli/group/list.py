import logging

import click
from mythx_models.response import GroupListResponse
from pythx import Client

from mythx_cli.formatter import FORMAT_RESOLVER
from mythx_cli.util import write_or_print

LOGGER = logging.getLogger("mythx-cli")


@click.command("list")
@click.option(
    "--number",
    default=5,
    type=click.IntRange(min=1, max=100),  # ~ 5 requests à 20 entries
    show_default=True,
    help="The number of most recent groups to display",
)
@click.pass_obj
def group_list(ctx, number: int) -> None:
    """Get a list of analysis groups.

    \f

    :param ctx: Click context holding group-level parameters
    :param number: The number of analysis groups to display
    :return:
    """

    client: Client = ctx["client"]
    result = GroupListResponse(groups=[], total=0)
    offset = 0
    while True:
        LOGGER.debug(f"Fetching groups with offset {offset}")
        resp = client.group_list(offset=offset)
        if not resp.groups:
            LOGGER.debug("Received empty group list response")
            break
        offset += len(resp.groups)
        result.groups.extend(resp.groups)
        if len(result.groups) >= number:
            LOGGER.debug(f"Received {len(result.groups)} groups")
            break

    # trim result to desired result number
    LOGGER.debug(f"Got {len(result.groups)} analyses, trimming to {number}")
    result = GroupListResponse(groups=result[:number], total=resp.total)
    write_or_print(FORMAT_RESOLVER[ctx["fmt"]].format_group_list(result))
