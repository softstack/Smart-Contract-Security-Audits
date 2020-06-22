"""Utility functions for handling API requests and responses."""

from typing import List, Union

import click
from mythx_models.response import DetectedIssuesResponse, Severity

SEVERITY_ORDER = (
    Severity.UNKNOWN,
    Severity.NONE,
    Severity.LOW,
    Severity.MEDIUM,
    Severity.HIGH,
)


def get_source_location_by_offset(source: str, offset: int) -> int:
    """Retrieve the Solidity source code location based on the source map
    offset.

    :param source: The Solidity source to analyze
    :param offset: The source map's offset
    :return: The offset's source line number equivalent
    """

    return source.encode("utf-8")[0:offset].count("\n".encode("utf-8")) + 1


def generate_dashboard_link(uuid: str) -> str:
    """Generate a MythX dashboard link for an analysis job.

    This method will generate a link to an analysis job on the official
    MythX dashboard production setup. Custom deployment locations are currently
    not supported by this function (but available at mythx.io).
    :param uuid: The analysis job's UUID
    :return: The analysis job's dashboard link
    """
    return "https://dashboard.mythx.io/#/console/analyses/{}".format(uuid)


def normalize_swc_list(swc_list: Union[str, List[str], None]) -> List[str]:
    """Normalize a list of SWC IDs.

    This method normalizes a list of SWC ID definitions, making SWC-101, swc-101,
    and 101 equivalent.
    :param swc_list: The list of SWC IDs as strings
    :return: The normalized SWC ID list as SWC-XXX
    """
    if not swc_list:
        return []
    if type(swc_list) == str:
        swc_list = swc_list.split(",")
    swc_list = [str(x).strip().upper() for x in swc_list]
    swc_list = ["SWC-{}".format(x) if not x.startswith("SWC") else x for x in swc_list]

    return swc_list


def set_ci_failure() -> None:
    """Based on the current context, set the return code to 1.

    This method sets the return code to 1. It is called by the
    respective subcommands (analyze and report) in case a severe issue
    has been found (as specified by the user) if the CI flag is passed.
    This will make the MythX CLI fail when running on a CI server. If no
    context is available, this function assumes that it is running
    outside a CLI scenario (e.g. a test setup) and will not do anything.
    """
    try:
        ctx = click.get_current_context()
        if ctx.obj["ci"]:
            ctx.obj["retval"] = 1
    except RuntimeError:
        # skip failure when there is no active click context
        # i.e. the method has been called outside the click
        # application.
        pass


def filter_report(
    resp: DetectedIssuesResponse,
    min_severity: Union[str, Severity] = None,
    swc_blacklist: Union[str, List[str]] = None,
    swc_whitelist: Union[str, List[str]] = None,
) -> DetectedIssuesResponse:
    """Filter issues based on an SWC blacklist and minimum severity.

    This will remove issues of a specific SWC ID or with a too low
    severity from the issue reports of the passed
    :code:`DetectedIssuesResponse` object. The SWC blacklist can be a
    list of strings in the format "SWC-000" or a comma-separated string.
    "SWC" is case-insensitive and normalized. The SWC whitelist works in
    a similar way, just including selected SWCs into the resulting
    response object.

    :param resp: The issue report of an analysis job
    :param min_severity: Ignore SWC IDs below the designated level
    :param swc_blacklist: A comma-separated list of SWC IDs to ignore
    :param swc_whitelist: A comma-separated list of SWC IDs to include
    :return: The filtered issue report
    """

    min_severity = Severity(min_severity.title()) if min_severity else Severity.UNKNOWN
    swc_blacklist = normalize_swc_list(swc_blacklist)
    swc_whitelist = normalize_swc_list(swc_whitelist)

    new_issues = []
    for report in resp.issue_reports:
        for issue in report.issues:
            is_severe = SEVERITY_ORDER.index(issue.severity) >= SEVERITY_ORDER.index(
                min_severity
            )
            not_blacklisted = issue.swc_id not in swc_blacklist
            is_whitelisted = issue.swc_id in swc_whitelist if swc_whitelist else True

            if all((is_severe, is_whitelisted, not_blacklisted)):
                new_issues.append(issue)
                set_ci_failure()

        report.issues = new_issues

    return resp
