import os


def pytest_generate_tests(metafunc):
    os.environ["MYTHX_API_KEY"] = "test"
