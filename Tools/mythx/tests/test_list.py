import json

from click.testing import CliRunner
from mythx_models.response import AnalysisListResponse, GroupListResponse

from mythx_cli.cli import cli

from .common import get_test_case, mock_context

GROUP_LIST = get_test_case("testdata/group-list-response.json", GroupListResponse)
GROUP_LIST_SIMPLE = get_test_case("testdata/group-list-simple.txt", raw=True)
GROUP_LIST_TABLE = get_test_case("testdata/group-list-table.txt", raw=True)
ANALYSIS_LIST = get_test_case(
    "testdata/analysis-list-response.json", AnalysisListResponse
)
ANALYSIS_LIST_SIMPLE = get_test_case("testdata/analysis-list-simple.txt", raw=True)
ANALYSIS_LIST_TABLE = get_test_case("testdata/analysis-list-table.txt", raw=True)


def test_list_tabular():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["analysis", "list"])

        assert result.output == ANALYSIS_LIST_TABLE
        assert result.exit_code == 0


def test_group_list_tabular():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["group", "list"])

        assert result.output == GROUP_LIST_TABLE
        assert result.exit_code == 0


def test_list_json():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["--format", "json", "analysis", "list"])

        assert json.loads(result.output) == ANALYSIS_LIST.to_dict()
        assert result.exit_code == 0


def test_group_list_json():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["--format", "json", "group", "list"])

        assert json.loads(result.output) == GROUP_LIST.to_dict()
        assert result.exit_code == 0


def test_list_json_pretty():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["--format", "json-pretty", "analysis", "list"])

        assert json.loads(result.output) == ANALYSIS_LIST.to_dict()
        assert result.exit_code == 0


def test_group_list_json_pretty():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["--format", "json-pretty", "group", "list"])

        assert json.loads(result.output) == GROUP_LIST.to_dict()
        assert result.exit_code == 0


def test_list_simple():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["--format", "simple", "analysis", "list"])

        assert result.output == ANALYSIS_LIST_SIMPLE
        assert result.exit_code == 0


def test_group_list_simple():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["--format", "simple", "group", "list"])

        assert result.output == GROUP_LIST_SIMPLE
        assert result.exit_code == 0
