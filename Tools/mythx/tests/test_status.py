import json
from unittest.mock import patch

from click.testing import CliRunner
from mythx_models.response import AnalysisStatusResponse, GroupStatusResponse

from mythx_cli.cli import cli

from .common import get_test_case, mock_context

GROUP_STATUS = get_test_case("testdata/group-status-response.json", GroupStatusResponse)
GROUP_STATUS_SIMPLE = get_test_case("testdata/group-status-simple.txt", raw=True)
GROUP_STATUS_TABLE = get_test_case("testdata/group-status-table.txt", raw=True)
ANALYSIS_STATUS = get_test_case(
    "testdata/analysis-status-response.json", AnalysisStatusResponse
)
ANALYSIS_STATUS_SIMPLE = get_test_case("testdata/analysis-status-simple.txt", raw=True)
ANALYSIS_STATUS_TABLE = get_test_case("testdata/analysis-status-table.txt", raw=True)


def test_status_tabular():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(
            cli, ["analysis", "status", "381eff48-04db-4f81-a417-8394b6614472"]
        )

        assert result.output == ANALYSIS_STATUS_TABLE
        assert result.exit_code == 0


def test_group_status_tabular():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["group", "status", "5dd40ca50d861d001101e888"])
        assert result.output == GROUP_STATUS_TABLE
        assert result.exit_code == 0


def test_status_json():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(
            cli,
            [
                "--format",
                "json",
                "analysis",
                "status",
                "381eff48-04db-4f81-a417-8394b6614472",
            ],
        )

        assert json.loads(result.output) == ANALYSIS_STATUS.to_dict()
        assert result.exit_code == 0


def test_group_status_json():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(
            cli, ["--format", "json", "group", "status", "5dd40ca50d861d001101e888"]
        )

        assert json.loads(result.output) == GROUP_STATUS.to_dict()
        assert result.exit_code == 0


def test_status_json_pretty():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(
            cli,
            [
                "--format",
                "json-pretty",
                "analysis",
                "status",
                "381eff48-04db-4f81-a417-8394b6614472",
            ],
        )

        assert json.loads(result.output) == ANALYSIS_STATUS.to_dict()
        assert result.exit_code == 0


def test_group_status_json_pretty():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(
            cli,
            ["--format", "json-pretty", "group", "status", "5dd40ca50d861d001101e888"],
        )

        assert json.loads(result.output) == GROUP_STATUS.to_dict()
        assert result.exit_code == 0


def test_status_simple():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(
            cli,
            [
                "--format",
                "simple",
                "analysis",
                "status",
                "381eff48-04db-4f81-a417-8394b6614472",
            ],
        )

        assert result.output == ANALYSIS_STATUS_SIMPLE
        assert result.exit_code == 0


def test_group_status_simple():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(
            cli, ["--format", "simple", "group", "status", "5dd40ca50d861d001101e888"]
        )

        assert result.output == GROUP_STATUS_SIMPLE
        assert result.exit_code == 0
