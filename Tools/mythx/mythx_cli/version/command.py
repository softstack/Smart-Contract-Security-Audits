import logging

import click

from mythx_cli import __version__
from mythx_cli.formatter import FORMAT_RESOLVER
from mythx_cli.util import write_or_print

LOGGER = logging.getLogger("mythx-cli")


@click.command()
@click.option(
    "--api/--self",
    "remote_flag",
    is_flag=True,
    default=False,
    help="Switch between local CLI and remote API version",
)
@click.pass_obj
def version(ctx, remote_flag) -> None:
    """Display API version information.

    \f

    :param ctx: Click context holding group-level parameters
    :param remote_flag: Boolean to switch between local CLI and remote API version
    :return:
    """

    if remote_flag:
        LOGGER.debug("Fetching version information")
        resp = ctx["client"].version()
        write_or_print(FORMAT_RESOLVER[ctx["fmt"]].format_version(resp))
    else:
        click.echo(f"MythX CLI v{__version__}: https://github.com/dmuhs/mythx-cli")
