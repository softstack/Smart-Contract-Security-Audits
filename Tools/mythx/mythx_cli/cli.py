"""The main runtime of the MythX CLI."""
import logging
import sys
from pathlib import Path

import click
import yaml
from pythx import Client, MythXAPIError
from pythx.middleware.toolname import ClientToolNameMiddleware

from mythx_cli import __version__
from mythx_cli.analysis.list import analysis_list
from mythx_cli.analysis.report import analysis_report
from mythx_cli.analysis.status import analysis_status
from mythx_cli.analyze.command import analyze
from mythx_cli.formatter import FORMAT_RESOLVER
from mythx_cli.group.close import group_close
from mythx_cli.group.list import group_list
from mythx_cli.group.open import group_open
from mythx_cli.group.status import group_status
from mythx_cli.render.command import render
from mythx_cli.util import update_context
from mythx_cli.version.command import version

LOGGER = logging.getLogger("mythx-cli")
logging.basicConfig(level=logging.WARNING)


class APIErrorCatcherGroup(click.Group):
    """A custom click group to catch API-related errors.

    This custom Group implementation catches :code:`MythXAPIError`
    exceptions, which get raised when the API returns a non-200
    status code. It is used to notify the user about the error that
    happened instead of triggering an uncaught exception traceback.

    It is given to the main CLI entrypoint and propagated to all
    subcommands.
    """

    def __call__(self, *args, **kwargs):
        try:
            return self.main(*args, **kwargs)
        except MythXAPIError as exc:
            LOGGER.debug("Caught API error")
            click.echo("The API returned an error:\n{}".format(exc))
            sys.exit(1)


# noinspection PyIncorrectDocstring
@click.group(cls=APIErrorCatcherGroup)
@click.option(
    "--debug",
    is_flag=True,
    default=False,
    envvar="MYTHX_DEBUG",
    help="Provide additional debug output",
)
@click.option(
    "--api-key", envvar="MYTHX_API_KEY", help="Your MythX API key from the dashboard"
)
@click.option(
    "--username", envvar="MYTHX_USERNAME", help="Your MythX account's username"
)
@click.option(
    "--password", envvar="MYTHX_PASSWORD", help="Your MythX account's password"
)
@click.option(
    "--format",
    "fmt",
    default=None,
    type=click.Choice(FORMAT_RESOLVER.keys()),
    help="The format to display the results in",
)
@click.option(
    "--ci",
    is_flag=True,
    default=None,
    help="Return exit code 1 if high-severity issue is found",
)
@click.option(
    "-y",
    "--yes",
    is_flag=True,
    default=None,
    help="Do not prompt for any confirmations",
)
@click.option(
    "-o", "--output", default=None, help="Output file to write the results into"
)
@click.option(
    "-c",
    "--config",
    type=click.Path(exists=True),
    help="YAML config file for default parameters",
)
@click.pass_context
def cli(
    ctx,
    debug: bool,
    api_key: str,
    username: str,
    password: str,
    fmt: str,
    ci: bool,
    output: str,
    yes: bool,
    config: str,
) -> None:
    """Your CLI for interacting with https://mythx.io/

    \f

    :param ctx: Click context holding group-level parameters
    :param debug: Boolean to enable the `logging` debug mode
    :param api_key: User JWT api token from the MythX dashboard
    :param username: The MythX account ETH address/username
    :param password: The account password from the MythX dashboard
    :param fmt: The formatter to use for the subcommand output
    :param ci: Boolean to return exit code 1 on medium/high-sev issues
    :param output: Output file to write the results into
    :param config: YAML config file to read default parameters from
    """

    # set loggers to debug mode
    if debug:
        for name in logging.root.manager.loggerDict:
            logging.getLogger(name).setLevel(logging.DEBUG)

    ctx.obj = {
        "debug": debug,
        "api_key": api_key,
        "username": username,
        "password": password,
        "fmt": fmt,
        "ci": ci,
        "output": output,
        "yes": yes,
        "config": config,
    }

    LOGGER.debug("Initializing configuration context")
    config_file = config or ".mythx.yml"
    if Path(config_file).is_file():
        LOGGER.debug(f"Parsing config at {config_file}")
        with open(config_file) as config_f:
            parsed_config = yaml.safe_load(config_f.read())
    else:
        parsed_config = {"analyze": {}}

    # The analyze context is updated separately in the command
    # implementation
    ctx.obj["analyze"] = parsed_config.get("analyze", {})

    # overwrite context with top-level YAML config keys if necessary
    update_context(ctx.obj, "ci", parsed_config, "ci", False)
    update_context(ctx.obj, "output", parsed_config, "output", None)
    update_context(ctx.obj, "fmt", parsed_config, "format", "table")
    update_context(ctx.obj, "yes", parsed_config, "confirm", False)

    # set return value - used for CI failures
    ctx.obj["retval"] = 0

    LOGGER.debug(f"Initializing tool name middleware with {__version__}")
    toolname_mw = ClientToolNameMiddleware(name="mythx-cli-{}".format(__version__))

    if api_key is not None:
        LOGGER.debug("Initializing client with API key")
        ctx.obj["client"] = Client(api_key=api_key, middlewares=[toolname_mw])
    elif username and password:
        LOGGER.debug("Initializing client with username and password")
        ctx.obj["client"] = Client(
            username=username, password=password, middlewares=[toolname_mw]
        )
    else:
        raise click.UsageError(
            (
                "The trial user has been deprecated. You can still use the MythX CLI for free "
                "by signing up for a free account at https://mythx.io/ and entering your access "
                "credentials."
            )
        )


LOGGER.debug("Registering main commands")
cli.add_command(analyze)
cli.add_command(render)
cli.add_command(version)


@cli.group()
def group() -> None:
    """Create, modify, and view analysis groups.

    \f

    This subcommand holds all group-related actions, such as creating,
    listing, closing groups, as well as fetching the status of one
    or more group IDs.
    """
    pass


LOGGER.debug("Registering group commands")
group.add_command(group_list)
group.add_command(group_status)
group.add_command(group_open)
group.add_command(group_close)


@cli.group()
def analysis() -> None:
    """Get information on running and finished analyses.

    \f

    This subcommand holds all analysis-related actions, such as submitting new
    analyses, listing existing ones, fetching their status, as well as fetching
    the reports of one or more finished analysis jobs.
    """
    pass


LOGGER.debug("Registering analysis commands")
analysis.add_command(analysis_status)
analysis.add_command(analysis_list)
analysis.add_command(analysis_report)


if __name__ == "__main__":
    sys.exit(cli())  # pragma: no cover
