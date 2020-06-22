"""This module contains a simple text formatter class printing a subset of the
response data."""

from typing import List, Optional, Tuple

from mythx_models.response import (
    AnalysisInputResponse,
    AnalysisListResponse,
    AnalysisStatusResponse,
    DetectedIssuesResponse,
    GroupListResponse,
    GroupStatusResponse,
    VersionResponse,
)

from .base import BaseFormatter
from .util import generate_dashboard_link, get_source_location_by_offset


class SimpleFormatter(BaseFormatter):
    """The simple text formatter.

    This formatter generates simplified text output. It also displays
    the source locations of issues by line in the Solidity source code
    if given. Therefore, this formatter requires the analysis input to
    be given.
    """

    report_requires_input = True

    @staticmethod
    def format_analysis_list(resp: AnalysisListResponse) -> str:
        """Format an analysis list response to a simple text representation."""

        res = []
        for analysis in resp:
            res.append("UUID: {}".format(analysis.uuid))
            res.append("Submitted at: {}".format(analysis.submitted_at))
            res.append("Status: {}".format(analysis.status))
            res.append("")

        return "\n".join(res)

    @staticmethod
    def format_group_status(resp: GroupStatusResponse) -> str:
        """Format a group status response to a simple text representation."""

        res = [
            "ID: {}".format(resp.group.identifier),
            "Name: {}".format(resp.group.name or "<unnamed>"),
            "Created on: {}".format(resp.group.created_at),
            "Status: {}".format(resp.group.status),
            "",
        ]
        return "\n".join(res)

    @staticmethod
    def format_group_list(resp: GroupListResponse) -> str:
        """Format an analysis group response to a simple text
        representation."""

        res = []
        for group in resp:
            res.append("ID: {}".format(group.identifier))
            res.append("Name: {}".format(group.name or "<unnamed>"))
            res.append("Created on: {}".format(group.created_at))
            res.append("Status: {}".format(group.status))
            res.append("")

        return "\n".join(res)

    @staticmethod
    def format_analysis_status(resp: AnalysisStatusResponse) -> str:
        """Format an analysis status response to a simple text
        representation."""

        res = [
            "UUID: {}".format(resp.uuid),
            "Submitted at: {}".format(resp.submitted_at),
            "Status: {}".format(resp.status),
            "",
        ]
        return "\n".join(res)

    @staticmethod
    def format_detected_issues(
        issues_list: List[
            Tuple[DetectedIssuesResponse, Optional[AnalysisInputResponse]]
        ]
    ) -> str:
        """Format an issue report to a simple text representation."""

        # TODO: Sort by file
        for resp, inp in issues_list:
            res = []
            for report in resp.issue_reports:
                for issue in report.issues:
                    res.append(generate_dashboard_link(resp.uuid))
                    res.append(
                        "Title: {} ({})".format(issue.swc_title or "-", issue.severity)
                    )
                    res.append("Description: {}".format(issue.description_long.strip()))

                    for loc in issue.locations:
                        comp = loc.source_map.components[0]
                        source_list = loc.source_list or report.source_list
                        if source_list and 0 >= comp.file_id < len(source_list):
                            filename = source_list[comp.file_id]
                            if not inp.sources or filename not in inp.sources:
                                # Skip files we don't have source for
                                # (e.g. with unresolved bytecode hashes)
                                res.append("")
                                continue
                            line = get_source_location_by_offset(
                                inp.sources[filename]["source"], comp.offset
                            )
                            snippet = inp.sources[filename]["source"].split("\n")[
                                line - 1
                            ]
                            res.append("{}:{}".format(filename, line))
                            res.append("\t" + snippet.strip())

                        res.append("")

        return "\n".join(res)

    @staticmethod
    def format_version(resp: VersionResponse) -> str:
        """Format a version response to a simple text representation."""

        return "\n".join(
            [
                "API: {}".format(resp.api_version),
                "Harvey: {}".format(resp.harvey_version),
                "Maru: {}".format(resp.maru_version),
                "Mythril: {}".format(resp.mythril_version),
                "Hashed: {}".format(resp.hashed_version),
            ]
        )
