import pytest
from click.testing import CliRunner
from mythx_models.response import AnalysisInputResponse, DetectedIssuesResponse

from mythx_cli.cli import cli

from .common import get_test_case, mock_context

TEST_GROUP_ID = "5e36ae133fb6020011a6b13c"
TEST_ANALYSIS_ID = "ebe5e298-b998-4b82-ba3e-e922cb0a43c4"
INPUT_RESPONSE: AnalysisInputResponse = get_test_case(
    "testdata/analysis-input-response.json", AnalysisInputResponse
)
ISSUES_RESPONSE: DetectedIssuesResponse = get_test_case(
    "testdata/detected-issues-response.json", DetectedIssuesResponse
)


def assert_content(data, ident, is_template):
    if not is_template:
        assert ident in data
        for item in INPUT_RESPONSE.source_list:
            assert item in data
        assert INPUT_RESPONSE.bytecode in data
        for filename in INPUT_RESPONSE.sources.keys():
            assert filename in data
        for source in map(lambda x: x["source"], INPUT_RESPONSE.sources.values()):
            for line in source.split("\n"):
                assert line in data
        for issue in ISSUES_RESPONSE:
            assert issue.swc_id in data
            assert issue.swc_title in data
    else:
        assert "mythx_models.response.analysis_status.analysisstatusresponse" in data
        assert "mythx_models.response.detected_issues.detectedissuesresponse" in data
        assert "mythx_models.response.analysis_input.analysisinputresponse" in data


@pytest.mark.parametrize(
    "ident,template",
    (
        (TEST_GROUP_ID, False),
        (TEST_ANALYSIS_ID, False),
        (TEST_GROUP_ID.lower(), False),
        (TEST_ANALYSIS_ID.lower(), False),
        (TEST_GROUP_ID, True),
        (TEST_ANALYSIS_ID, True),
        (TEST_GROUP_ID.lower(), True),
        (TEST_ANALYSIS_ID.lower(), True),
    ),
)
def test_renderer_group(ident, template):
    runner = CliRunner()
    with mock_context(), runner.isolated_filesystem():
        if template:
            with open("template.html", "w+") as tpl_f:
                tpl_f.write("{{ issues_list }}")
            arg_list = [
                "--output=test.html",
                "render",
                "--template=template.html",
                ident,
            ]
        else:
            arg_list = ["--output=test.html", "render", ident]
        result = runner.invoke(cli, arg_list)
        with open("test.html") as f:
            data = f.read()

        assert_content(data, ident, template)
        assert result.exit_code == 0


def test_invalid_id():
    runner = CliRunner()
    result = runner.invoke(cli, ["--output=test.html", "render", "--aesthetic", "foo"])
    assert result.exception is not None
    assert result.exit_code == 2
