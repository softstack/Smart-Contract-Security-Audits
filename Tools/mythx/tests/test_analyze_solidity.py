import os
from copy import deepcopy
from unittest import mock

import pytest
from click.testing import CliRunner
from mythx_models.response import (
    AnalysisInputResponse,
    AnalysisSubmissionResponse,
    DetectedIssuesResponse,
    Severity,
)

from mythx_cli.cli import cli

from .common import get_test_case, mock_context

ISSUES_RESPONSE = get_test_case(
    "testdata/detected-issues-response.json", DetectedIssuesResponse
)
INPUT_RESPONSE = get_test_case(
    "testdata/analysis-input-response.json", AnalysisInputResponse
)
SUBMISSION_RESPONSE = get_test_case(
    "testdata/analysis-submission-response.json", AnalysisSubmissionResponse
)
VERSION_ERROR = (
    "Error: Error installing solc version v9001: Invalid version string: '9001'"
)
ISSUES_TABLE = get_test_case("testdata/detected-issues-table.txt", raw=True)
PRAGMA_ERROR = "No pragma found - please specify a solc version with --solc-version"
SOLIDITY_CODE = """pragma solidity 0.4.13;

contract OutdatedCompilerVersion {
    uint public x = 1;
}
"""


def get_high_severity_report():
    issues_resp = deepcopy(ISSUES_RESPONSE)
    issues_resp.issue_reports[0].issues[0].severity = Severity.HIGH
    return issues_resp


def setup_solidity_file(
    base_path, name="test.sol", switch_dir=False, hide_pragma=False
):
    # switch to temp dir if requested
    if switch_dir:
        os.chdir(str(base_path))

    with open(str(base_path / name), "w+") as conf_f:
        if hide_pragma:
            conf_f.writelines(SOLIDITY_CODE.split("\n")[1:])
        else:
            conf_f.write(SOLIDITY_CODE)


def test_analyze(tmp_path):
    setup_solidity_file(tmp_path, name="outdated.sol", switch_dir=True)
    runner = CliRunner()

    with mock_context():
        result = runner.invoke(cli, ["analyze", "outdated.sol"], input="y\n")

    assert ISSUES_TABLE in result.output
    assert result.exit_code == 0


def test_analyze_multiple(tmp_path):
    setup_solidity_file(tmp_path, name="outdated.sol", switch_dir=True)
    setup_solidity_file(tmp_path, name="outdated2.sol", switch_dir=True)
    runner = CliRunner()

    with mock_context():
        result = runner.invoke(
            cli, ["analyze", "outdated.sol", "outdated2.sol"], input="y\n"
        )

    assert str(result.output).count(ISSUES_TABLE) == 2
    assert result.exit_code == 0


def test_property_checking(tmp_path):
    setup_solidity_file(tmp_path, name="outdated.sol", switch_dir=True)
    runner = CliRunner()

    with mock_context():
        result = runner.invoke(
            cli, ["analyze", "--check-properties", "outdated.sol"], input="y\n"
        )

    assert ISSUES_TABLE in result.output
    assert result.exit_code == 0


def test_multiple_in_group(tmp_path):
    setup_solidity_file(tmp_path, name="outdated.sol", switch_dir=True)
    setup_solidity_file(tmp_path, name="outdated2.sol", switch_dir=True)
    runner = CliRunner()

    with mock_context():
        result = runner.invoke(
            cli,
            ["analyze", "--create-group", "outdated.sol", "outdated2.sol"],
            input="y\n",
        )

    assert str(result.output).count(ISSUES_TABLE) == 2
    assert result.exit_code == 0


def test_blocking_ci(tmp_path):
    setup_solidity_file(tmp_path, name="outdated.sol", switch_dir=True)
    runner = CliRunner()

    with mock_context() as patches:
        patches[2].return_value = get_high_severity_report()
        result = runner.invoke(cli, ["--ci", "analyze"], input="y\n")

    assert "Assert Violation" in result.output
    assert INPUT_RESPONSE.source_list[0] in result.output
    assert result.exit_code == 1


def test_multiple_with_yaml_group(tmp_path):
    setup_solidity_file(tmp_path, name="outdated.sol", switch_dir=True)
    setup_solidity_file(tmp_path, name="outdated2.sol", switch_dir=True)
    runner = CliRunner()

    with open(".mythx.yml", "w+") as conf_f:
        conf_f.write("analyze:\n  create-group: true\n")

    with mock_context():
        result = runner.invoke(
            cli, ["analyze", "outdated.sol", "outdated2.sol"], input="y\n"
        )

    assert str(result.output).count(ISSUES_TABLE) == 2
    assert result.exit_code == 0


def test_missing_version_error(tmp_path):
    setup_solidity_file(
        tmp_path, name="outdated.sol", switch_dir=True, hide_pragma=True
    )
    runner = CliRunner()

    with mock_context():
        result = runner.invoke(cli, ["analyze", "outdated.sol"])

    assert PRAGMA_ERROR in result.output
    assert result.exit_code == 2


def test_user_solc_version(tmp_path):
    setup_solidity_file(
        tmp_path, name="outdated.sol", switch_dir=True, hide_pragma=True
    )
    runner = CliRunner()

    with mock_context():
        result = runner.invoke(
            cli, ["analyze", "--solc-version", "0.4.13", "outdated.sol"], input="y\n"
        )

    assert ISSUES_TABLE in result.output
    assert result.exit_code == 0


def test_config_solc_version(tmp_path):
    setup_solidity_file(
        tmp_path, name="outdated.sol", switch_dir=True, hide_pragma=True
    )
    runner = CliRunner()
    with open(".mythx.yml", "w+") as conf_f:
        conf_f.write("analyze:\n  solc: 0.4.13\n")

    with mock_context():
        result = runner.invoke(cli, ["analyze", "outdated.sol"], input="y\n")

    assert ISSUES_TABLE in result.output
    assert result.exit_code == 0


def test_default_recursive_blacklist(tmp_path):
    setup_solidity_file(tmp_path, name="outdated.sol", switch_dir=True)
    runner = CliRunner()

    with mock_context():
        # create blacklisted dir with sol file
        os.mkdir("./node_modules")
        setup_solidity_file(tmp_path, name="node_modules/outdated2.sol")

        result = runner.invoke(cli, ["analyze", "--create-group", "."], input="y\n")

    assert ISSUES_TABLE in result.output
    assert result.exit_code == 0


@pytest.mark.parametrize(
    "params,value,contained,retval",
    (
        pytest.param(
            ["analyze", "--async"],
            SUBMISSION_RESPONSE.analysis.uuid,
            True,
            0,
            id="analyze async",
        ),
        pytest.param(["analyze"], ISSUES_TABLE, True, 0, id="issue table no params"),
        pytest.param(
            ["analyze", "--swc-blacklist", "SWC-110"],
            INPUT_RESPONSE.source_list[0],
            False,
            0,
            id="blacklist 110",
        ),
        pytest.param(
            ["analyze", "--min-severity", "high"],
            INPUT_RESPONSE.source_list[0],
            False,
            0,
            id="high sev filter",
        ),
        pytest.param(
            ["analyze", "outdated.sol"],
            ISSUES_TABLE,
            True,
            0,
            id="issue table file param",
        ),
        pytest.param(
            ["analyze", "--create-group", "outdated.sol"],
            ISSUES_TABLE,
            True,
            0,
            id="create group",
        ),
        pytest.param(["analyze", "."], ISSUES_TABLE, True, 0, id="explicit cwd"),
        pytest.param(
            ["analyze", ".:OutdatedCompilerVersion"],
            ISSUES_TABLE,
            True,
            0,
            id="explicit cwd with include",
        ),
        pytest.param(
            ["analyze", "outdated.sol:OutdatedCompilerVersion"],
            INPUT_RESPONSE.source_list[0],
            True,
            0,
            id="valid include path syntax",
        ),
        pytest.param(
            ["analyze", "outdated.sol:invalid"],
            INPUT_RESPONSE.source_list[0],
            False,
            2,
            id="invalid include path syntax",
        ),
        pytest.param(
            ["analyze", "--include", "OutdatedCompilerVersion"],
            INPUT_RESPONSE.source_list[0],
            True,
            0,
            id="recursive valid include",
        ),
        pytest.param(
            ["analyze", "--include", "invalid"],
            INPUT_RESPONSE.source_list[0],
            False,
            2,
            id="recursive invalid include",
        ),
        pytest.param(
            ["analyze", "--solc-version", "9001", "outdated.sol"],
            VERSION_ERROR,
            True,
            2,
            id="invalid solc version",
        ),
    ),
)
def test_parameters(tmp_path, params, value, contained, retval):
    setup_solidity_file(tmp_path, name="outdated.sol", switch_dir=True)
    runner = CliRunner()

    with mock_context():
        result = runner.invoke(cli, params, input="y\n")

    if contained:
        assert value in result.output
    else:
        assert value not in result.output
    assert result.exit_code == retval


@pytest.mark.parametrize("retval,stdout", ((0, "contract Foo {}"), (1, ""), (127, "")))
def test_scribble_call(tmp_path, retval, stdout):
    setup_solidity_file(tmp_path, name="outdated.sol", switch_dir=True)
    runner = CliRunner()
    returner = mock.MagicMock()
    returner.returncode = retval
    returner.stdout.decode = lambda: stdout

    with mock.patch(
        "mythx_cli.analyze.solidity.subprocess.run"
    ) as run_mock, mock_context():
        run_mock.return_value = returner
        result = runner.invoke(
            cli, ["analyze", "--scribble", "outdated.sol"], input="y\n"
        )

    run_mock.assert_called_once_with(
        ["scribble", "outdated.sol"], stdout=mock.ANY, stderr=mock.ANY
    )
    assert result.exit_code == retval
