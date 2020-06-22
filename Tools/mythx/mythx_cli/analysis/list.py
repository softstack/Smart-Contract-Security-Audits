import logging

import click
from mythx_models.response import AnalysisListResponse

from mythx_cli.formatter import FORMAT_RESOLVER
from mythx_cli.util import write_or_print

LOGGER = logging.getLogger("mythx-cli")


@click.command("list")
@click.option(
    "--number",
    default=5,
    type=click.IntRange(min=1, max=100),  # ~ 5 requests à 20 entries
    show_default=True,
    help="The number of most recent analysis jobs to display",
)
@click.pass_obj
def analysis_list(ctx, number: int) -> None:
    """Get a list of submitted analyses.

    \f

    :param ctx: Click context holding group-level parameters
    :param number: The number of analysis jobs to display
    :return:
    """

    result = AnalysisListResponse(analyses=[], total=0)
    offset = 0
    while True:
        LOGGER.debug(f"Fetching analyses with offset {offset}")
        resp = ctx["client"].analysis_list(offset=offset)
        if not resp.analyses:
            LOGGER.debug("Received empty analysis list response")
            break
        offset += len(resp.analyses)
        result.analyses.extend(resp.analyses)
        if len(result.analyses) >= number:
            LOGGER.debug(f"Received {len(result.analyses)} analyses")
            break

    # trim result to desired result number
    LOGGER.debug(f"Got {len(result.analyses)} analyses, trimming to {number}")
    result = AnalysisListResponse(analyses=result[:number], total=resp.total)
    write_or_print(FORMAT_RESOLVER[ctx["fmt"]].format_analysis_list(result))
