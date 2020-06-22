import json
import re

from click.testing import CliRunner
from mythx_models.response import VersionResponse

from mythx_cli.cli import cli

from .common import get_test_case, mock_context

VERSION_RESPONSE = get_test_case("testdata/version-response.json", VersionResponse)
VERSION_SIMPLE = get_test_case("testdata/version-simple.txt", raw=True)
VERSION_TABLE = get_test_case("testdata/version-table.txt", raw=True)


def test_version_local():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["version"])

        assert re.match(r"MythX CLI v\d+.\d+.\d+", result.output)
        assert result.exit_code == 0


def test_version_tabular():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["version", "--api"])

        assert result.output == VERSION_TABLE
        assert result.exit_code == 0


def test_version_json():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["--format", "json", "version", "--api"])

        assert json.loads(result.output) == VERSION_RESPONSE.to_dict()
        assert result.exit_code == 0


def test_version_json_pretty():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["--format", "json-pretty", "version", "--api"])

        assert json.loads(result.output) == VERSION_RESPONSE.to_dict()
        assert result.exit_code == 0


def test_version_simple():
    runner = CliRunner()
    with mock_context():
        result = runner.invoke(cli, ["--format", "simple", "version", "--api"])

        assert result.output == VERSION_SIMPLE
        assert result.exit_code == 0
