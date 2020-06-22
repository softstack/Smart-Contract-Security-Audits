"""This module contains various formatters for printing report data."""

from .json import JSONFormatter, PrettyJSONFormatter
from .simple_stdout import SimpleFormatter
from .sonarqube import SonarQubeFormatter
from .tabular import TabularFormatter

FORMAT_RESOLVER = {
    "simple": SimpleFormatter(),
    "json": JSONFormatter(),
    "json-pretty": PrettyJSONFormatter(),
    "table": TabularFormatter(),
    "sonar": SonarQubeFormatter(),
}

__all__ = [
    JSONFormatter,
    PrettyJSONFormatter,
    SimpleFormatter,
    TabularFormatter,
    SonarQubeFormatter,
]
