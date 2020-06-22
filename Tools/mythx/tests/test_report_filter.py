from copy import deepcopy

import pytest
from mythx_models.response import DetectedIssuesResponse

from mythx_cli.formatter.util import filter_report

from .common import get_test_case

# contains SWC-110
RESPONSE = get_test_case(
    "testdata/detected-issues-response.json", DetectedIssuesResponse
)


@pytest.mark.parametrize(
    "blacklist,whitelist,severity,contained",
    (
        # blacklist
        ("SWC-110", "", "", False),
        ("swc-110", "", "", False),
        ("110", "", "", False),
        ("SWC-110,SWC-110", "", "", False),
        ("swc-110,swc-110", "", "", False),
        ("110,110", "", "", False),
        ("SWC-110,SWC-123", "", "", False),
        ("swc-110,swc-123", "", "", False),
        ("110,123", "", "", False),
        ("SWC-123", "", "", True),
        ("swc-123", "", "", True),
        ("123", "", "", True),
        ("invalid", "", "", True),
        # whitelist
        ("", "SWC-110", "", True),
        ("", "swc-110", "", True),
        ("", "110", "", True),
        ("", "SWC-110,SWC-110", "", True),
        ("", "swc-110,swc-110", "", True),
        ("", "110,110", "", True),
        ("", "SWC-123", "", False),
        ("", "swc-123", "", False),
        ("", "123", "", False),
        ("", "SWC-110,SWC-123", "", True),
        ("", "swc-110,swc-123", "", True),
        ("", "110,123", "", True),
        ("", "invalid", "", False),
        # severity
        ("", "", "unknown", True),
        ("", "", "Unknown", True),
        ("", "", "UNKNOWN", True),
        ("", "", "none", True),
        ("", "", "None", True),
        ("", "", "NONE", True),
        ("", "", "low", True),
        ("", "", "Low", True),
        ("", "", "LOW", True),
        ("", "", "medium", False),
        ("", "", "Medium", False),
        ("", "", "MEDIUM", False),
        ("", "", "high", False),
        ("", "", "High", False),
        ("", "", "HIGH", False),
        # mixed
        ("SWC-110", "SWC-110", "unknown", False),
        ("swc-110", "swc-110", "unknown", False),
        ("110", "110", "unknown", False),
        ("SWC-110,SWC-110", "SWC-110,SWC-110", "", False),
        ("swc-110,swc-110", "swc-110,swc-110", "", False),
        ("110,110", "110,110", "", False),
        ("SWC-110,SWC-123", "SWC-123", "", False),
        ("swc-110,swc-123", "swc-123", "", False),
        ("110,123", "123", "", False),
        ("SWC-123", "SWC-110", "", True),
        ("swc-123", "swc-110", "", True),
        ("123", "110", "", True),
        ("SWC-123", "SWC-110", "low", True),
        ("swc-123", "swc-110", "low", True),
        ("123", "110", "low", True),
        ("SWC-123", "SWC-110", "medium", False),
        ("swc-123", "swc-110", "medium", False),
        ("123", "110", "medium", False),
        ("invalid", "invalid", "", False),
    ),
)
def test_report_filter_blacklist(blacklist, whitelist, severity, contained):
    resp = deepcopy(RESPONSE)
    filter_report(
        resp, swc_blacklist=blacklist, swc_whitelist=whitelist, min_severity=severity
    )

    if contained:
        assert "SWC-110" in resp
    else:
        assert "SWC-110" not in resp
