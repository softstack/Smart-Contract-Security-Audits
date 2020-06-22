import logging
import sys
from typing import List, Optional, Tuple

import click
from mythx_models.response import AnalysisInputResponse, DetectedIssuesResponse

from mythx_cli.formatter import FORMAT_RESOLVER, util
from mythx_cli.formatter.base import BaseFormatter
from mythx_cli.util import write_or_print

LOGGER = logging.getLogger("mythx-cli")


@click.command("report")
@click.argument("uuids", default=None, nargs=-1)
@click.option(
    "--min-severity",
    type=click.Choice(["low", "medium", "high"]),
    help="Ignore SWC IDs below the designated level",
    default=None,
)
@click.option(
    "--swc-blacklist",
    type=click.STRING,
    help="A comma-separated list of SWC IDs to ignore",
    default=None,
)
@click.option(
    "--swc-whitelist",
    type=click.STRING,
    help="A comma-separated list of SWC IDs to include",
    default=None,
)
@click.pass_obj
def analysis_report(
    ctx,
    uuids: List[str],
    min_severity: Optional[str],
    swc_blacklist: Optional[List[str]],
    swc_whitelist: Optional[List[str]],
) -> None:
    """Fetch the report for a single or multiple job UUIDs.

    \f

    :param ctx: Click context holding group-level parameters
    :param uuids: List of UUIDs to display the report for
    :param min_severity: Ignore SWC IDs below the designated level
    :param swc_blacklist: A comma-separated list of SWC IDs to ignore
    :param swc_whitelist: A comma-separated list of SWC IDs to include
    :return:
    """

    issues_list: List[
        Tuple[DetectedIssuesResponse, Optional[AnalysisInputResponse]]
    ] = []
    formatter: BaseFormatter = FORMAT_RESOLVER[ctx["fmt"]]
    for uuid in uuids:
        LOGGER.debug(f"{uuid}: Fetching report")
        resp = ctx["client"].report(uuid)
        LOGGER.debug(f"{uuid}: Fetching input")
        inp = (
            ctx["client"].request_by_uuid(uuid)
            if formatter.report_requires_input
            else None
        )

        LOGGER.debug(f"{uuid}: Applying SWC filters")
        util.filter_report(
            resp,
            min_severity=min_severity,
            swc_blacklist=swc_blacklist,
            swc_whitelist=swc_whitelist,
        )
        resp.uuid = uuid
        issues_list.append((resp, inp))

    LOGGER.debug(f"{uuid}: Printing report for {len(issues_list)} issue items")
    write_or_print(formatter.format_detected_issues(issues_list))
    sys.exit(ctx["retval"])
