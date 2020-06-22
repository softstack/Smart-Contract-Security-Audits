import logging
from typing import List

import click
from mythx_models.response import GroupCreationResponse

from mythx_cli.util import write_or_print

LOGGER = logging.getLogger("mythx-cli")


@click.command("close")
@click.argument("identifiers", nargs=-1, required=True)
@click.pass_obj
def group_close(ctx, identifiers: List[str]) -> None:
    """Close/seal an existing group.

    \f

    :param ctx: Click context holding group-level parameters
    :param identifiers: The group ID(s) to seal
    """

    for identifier in identifiers:
        LOGGER.debug(f"Closing group for ID {identifier}")
        resp: GroupCreationResponse = ctx["client"].seal_group(group_id=identifier)
        write_or_print(
            "Closed group with ID {} and name '{}'".format(
                resp.group.identifier, resp.group.name
            )
        )
