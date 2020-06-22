"""This module contains the compressed and pretty-printing JSON formatters."""

import json
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

from mythx_cli.formatter.base import BaseFormatter


class JSONFormatter(BaseFormatter):
    """The JSON formatter.

    It returns string-encoded JSON objects and does not require the
    analysis input to generate payloads.
    """

    report_requires_input = False

    @staticmethod
    def format_group_status(resp: GroupStatusResponse) -> str:
        """Format a group status response as compressed JSON."""

        return resp.to_json()

    @staticmethod
    def format_group_list(resp: GroupListResponse) -> str:
        """Format a group list response as compressed JSON."""

        return resp.to_json()

    @staticmethod
    def format_analysis_list(resp: AnalysisListResponse) -> str:
        """Format an analysis list response as compressed JSON."""

        return resp.to_json()

    @staticmethod
    def format_analysis_status(resp: AnalysisStatusResponse) -> str:
        """Format an analysis status response as compressed JSON."""

        return resp.to_json()

    @staticmethod
    def format_detected_issues(
        issues_list: List[
            Tuple[DetectedIssuesResponse, Optional[AnalysisInputResponse]]
        ]
    ) -> str:
        """Format an issue report response as compressed JSON."""

        output = [resp.to_dict(as_list=True) for resp, _ in issues_list]
        return json.dumps(output)

    @staticmethod
    def format_version(resp: VersionResponse) -> str:
        """Format a version response as compressed JSON."""

        return resp.to_json()


class PrettyJSONFormatter(BaseFormatter):
    """The pretty-printing JSON formatter.

    It works exactly as the JSON formatter, with the difference that the
    string-encoded JSON object is indented with two spaces for each
    level, and the keys are sorted in alphabetical order.
    """

    report_requires_input = False

    @staticmethod
    def _print_as_json(obj, report_mode=False) -> str:
        """Pretty-print the given object's JSON representation."""

        json_args = {"indent": 2, "sort_keys": True}
        if report_mode:
            return json.dumps(
                [resp.to_dict(as_list=True) for resp, _ in obj], **json_args
            )
        return json.dumps(obj.to_dict(), **json_args)

    @staticmethod
    def format_group_status(resp: GroupStatusResponse) -> str:
        """Format a group status response as pretty-printed JSON."""

        return PrettyJSONFormatter._print_as_json(resp)

    @staticmethod
    def format_group_list(resp: GroupListResponse) -> str:
        """Format a group list response as pretty-printed JSON."""

        return PrettyJSONFormatter._print_as_json(resp)

    @staticmethod
    def format_analysis_list(obj: AnalysisListResponse) -> str:
        """Format an analysis list response as pretty-printed JSON."""

        return PrettyJSONFormatter._print_as_json(obj)

    @staticmethod
    def format_analysis_status(obj: AnalysisStatusResponse) -> str:
        """Format an analysis status response as pretty-printed JSON."""

        return PrettyJSONFormatter._print_as_json(obj)

    @staticmethod
    def format_detected_issues(
        issues_list: List[
            Tuple[DetectedIssuesResponse, Optional[AnalysisInputResponse]]
        ]
    ) -> str:
        """Format an issue report response as pretty-printed JSON."""

        return PrettyJSONFormatter._print_as_json(issues_list, report_mode=True)

    @staticmethod
    def format_version(obj: VersionResponse) -> str:
        """Format a version response as pretty-printed JSON."""

        return PrettyJSONFormatter._print_as_json(obj)
