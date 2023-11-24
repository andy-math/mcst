import os


def read_file(filename: str) -> str:
    with open(filename) as f:
        content = f.read()
    while "\r\n" in content:
        content = content.replace("\r\n", "\n")
    return content


def test_main_m() -> None:
    assert read_file("main.m") == read_file("test_py/m/main.m")


def test_output_m() -> None:
    assert read_file("output.m") == read_file("test_py/m/output.m")


def test_nodes_m() -> None:
    files = os.listdir("mcst")
    for file in files:
        if not (file.startswith(".") or file.endswith(".asv")):
            assert read_file(f"mcst/{file}") == read_file(f"test_py/m/{file}")


def test_main_py() -> None:
    assert read_file("test_m/py/main.py") == read_file("test_py/py/main.py")


def test_output_py() -> None:
    assert read_file("test_m/py/output.py") == read_file("test_py/py/output.py")


def test_nodes_py() -> None:
    files = os.listdir("mcst")
    for file in files:
        if not (file.startswith(".") or file.endswith(".asv")):
            assert read_file(f"test_m/py/nodes/{file[:-2]}.py") == read_file(
                f"test_py/py/nodes/{file[:-2]}.py"
            )
