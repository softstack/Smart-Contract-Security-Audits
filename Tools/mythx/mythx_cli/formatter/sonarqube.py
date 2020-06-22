"""This module contains the SonarQube formatter class ."""

import json
from typing import List, Optional, Tuple

from mythx_models.response import AnalysisInputResponse, DetectedIssuesResponse
from mythx_models.response.issue import Severity, SourceType

from mythx_cli.formatter.json import JSONFormatter


class SonarQubeFormatter(JSONFormatter):
    """The SonarQube issue formatter.

    The goal of this formatter is to deliver JSON output that allows MythX issue reports
    to be fed into the SonarQube QA system. It does not require the analysis input.

    This is an ongoing project and currently not
    displayed in the official documentation. Please let me know if you have access to a
    SonarQube instance and want to try it out!
    """

    report_requires_input = False

    @staticmethod
    def format_detected_issues(
        issues_list: List[
            Tuple[DetectedIssuesResponse, Optional[AnalysisInputResponse]]
        ]
    ) -> str:
        """Format an issue report to a SonarQube JSON representation."""
        new_reports = []
        for resp, _ in issues_list:
            for report in resp.issue_reports:
                for issue in report:
                    new_issue = {}
                    for loc in issue.decoded_locations:
                        for raw_loc in issue.locations:
                            if raw_loc.source_type != SourceType.SOLIDITY_FILE:
                                continue
                            new_issue["onInputFile"] = raw_loc.source_list[
                                raw_loc.source_map.components[0].file_id
                            ]
                            new_issue["atLineNr"] = loc.start_line

                    new_issue.update(
                        {
                            "linterName": "mythx",
                            "forRule": issue.swc_id,
                            "ruleType": issue.severity.name,
                            "remediationEffortMinutes": 0,
                            "severity": "vulnerability"
                            if issue.severity == Severity.HIGH
                            else issue.severity.name,
                            "message": issue.description_long,
                        }
                    )
                    new_reports.append(new_issue)

        return json.dumps(new_reports)
