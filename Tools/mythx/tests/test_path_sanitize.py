from unittest.mock import patch

import pytest

from mythx_cli.analyze.util import sanitize_paths

CWD = "/home/user/work/project"
FILE_1 = "test-1.sol"
FILE_2 = "test-2.sol"
TEST_PATH_1 = "/home/user/work/project/src/" + FILE_1
TEST_PATH_2 = "/home/user/work/project/src/" + FILE_2
SANI_PATH_1 = "src/" + FILE_1
SANI_PATH_2 = "src/" + FILE_2


@pytest.mark.parametrize(
    "sample,expected",
    (
        ({"source_list": []}, {"source_list": []}),
        ({"source_list": None}, {"source_list": None}),
        ({}, {}),
        (
            {
                "sources": {TEST_PATH_1: {"ast": {"absolutePath": TEST_PATH_1}}},
                "source_list": [TEST_PATH_1],
            },
            {
                "sources": {SANI_PATH_1: {"ast": {"absolutePath": SANI_PATH_1}}},
                "source_list": [SANI_PATH_1],
            },
        ),
        (
            {
                "sources": {TEST_PATH_1: {"legacyAST": {"absolutePath": TEST_PATH_1}}},
                "source_list": [TEST_PATH_1],
            },
            {
                "sources": {SANI_PATH_1: {"legacyAST": {"absolutePath": SANI_PATH_1}}},
                "source_list": [SANI_PATH_1],
            },
        ),
        (
            {
                "sources": {
                    TEST_PATH_1: {
                        "legacyAST": {"absolutePath": TEST_PATH_1},
                        "ast": {"absolutePath": TEST_PATH_1},
                    }
                },
                "source_list": [TEST_PATH_1],
            },
            {
                "sources": {
                    SANI_PATH_1: {
                        "legacyAST": {"absolutePath": SANI_PATH_1},
                        "ast": {"absolutePath": SANI_PATH_1},
                    }
                },
                "source_list": [SANI_PATH_1],
            },
        ),
        (
            {
                "sources": {
                    TEST_PATH_1: {
                        "legacyAST": {"absolutePath": TEST_PATH_1},
                        "ast": {"absolutePath": TEST_PATH_1},
                    },
                    TEST_PATH_2: {
                        "legacyAST": {"absolutePath": TEST_PATH_2},
                        "ast": {"absolutePath": TEST_PATH_2},
                    },
                },
                "source_list": [TEST_PATH_1, TEST_PATH_2],
            },
            {
                "sources": {
                    FILE_1: {
                        "legacyAST": {"absolutePath": FILE_1},
                        "ast": {"absolutePath": FILE_1},
                    },
                    FILE_2: {
                        "legacyAST": {"absolutePath": FILE_2},
                        "ast": {"absolutePath": FILE_2},
                    },
                },
                "source_list": [FILE_1, FILE_2],
            },
        ),
    ),
)
def test_sanitize_ast(sample, expected):
    with patch("pathlib.Path.cwd") as cwd_patch:
        cwd_patch.return_value = CWD
        sanitized = sanitize_paths(sample)
    assert expected == sanitized
