from io import TextIOWrapper
from typing import Literal, NoReturn, Any, Union, Callable
import importlib
import shutil

import os


def clc() -> None:
    pass


def clear() -> None:
    pass


def close(fig: str) -> None:
    pass


def isfolder(dir: str) -> bool:
    return os.path.isdir(dir)


def isfile(file: str) -> bool:
    return os.path.isfile(file)


def delete(file: str) -> None:
    os.remove(file)


def mkdir(dir: str) -> None:
    os.mkdir(dir)


def rmdir(dir: str, s: Literal["s"]) -> None:
    shutil.rmtree(dir)


def fopen(filename: str, mode: Literal["rt", "wt+"] = "rt") -> TextIOWrapper:
    return open(filename, mode)


def native2unicode(a: str) -> str:
    return a


def tr(a: str) -> str:
    return a


def fread(file: TextIOWrapper) -> str:
    return file.read()


def fclose(file: TextIOWrapper) -> None:
    file.close()


def error(arg: str) -> NoReturn:
    raise Exception(arg)


def ismember(a: str, b: str) -> bool:
    return a in b


def strcmp(a: str, b: str) -> bool:
    return a == b


def isempty(a: list[Any]) -> bool:
    return hasattr(a, "__len__") and len(a) == 0


def size(a: list[Any], b: int) -> int:
    return len(a)


def colon(*args: int) -> range:
    if len(args) == 2:
        return range(args[0], args[1] + 1)
    elif len(args) == 3:
        return range(args[0], args[2] + 1, args[1])
    else:
        error("colon")


def contains(a: str, b: str) -> bool:
    return b in a


def startsWith(a: str, b: str) -> bool:
    return a.startswith(b)


def endsWith(a: str, b: str) -> bool:
    return a.endswith(b)


def fprintf(file: Union[Literal[1], TextIOWrapper], pattern: str, *args: str) -> None:
    if file == 1:
        print("\x1b[32m" + (pattern.replace("\\n", "\n") % args) + "\x1b[0m", end="")
    else:
        print((pattern.replace("\\n", "\n") % args), end="", file=file)


def replace(a: str, b: str, c: str) -> str:
    return a.replace(b, c)


def sprintf(a: str) -> str:
    assert a == "\\r\\n"
    return "\r\n"


def split(a: str, b: str) -> list[str]:
    return a.split(b)


def find(a: list[bool]) -> list[int]:
    return [i for i, x in enumerate(a) if x]


def mat2str(a: Any) -> str:
    return repr(a)


def warning(pattern: str, *args: str) -> None:
    print("\x1b[31m" + (pattern % args) + "\x1b[0m")


def mparen(fun: Any, *index: Any) -> Any:
    if callable(fun):
        return fun(*index)
    for i in index:
        if isinstance(i, range):
            fun = fun[i.start - 1 : i.stop - 1 : i.step]
        else:
            fun = fun[i - 1]
    return fun


def configure() -> tuple[Literal["test_py/m"], Literal["test_py/py"]]:
    if not isfolder("test_py"):
        mkdir("test_py")
    if not isfolder("test_py/m"):
        mkdir("test_py/m")
    if not isfolder("test_py/py"):
        mkdir("test_py/py")
    return "test_py/m", "test_py/py"


class File:
    def __init__(self, name: str) -> None:
        self.name = name


def dir(path: str) -> list[File]:
    return [File(x) for x in sorted(os.listdir(path))]


def repmat(c: str, a: Literal[1], b: int) -> str:
    return c * b


def isa(a: Any, b: str) -> bool:
    mod = importlib.import_module(f"test_m.py.nodes.{b}")
    return isinstance(a, getattr(mod, b))


def isList(a: Any) -> bool:
    return isinstance(a, list)


def cellfun(fun: Callable[..., Any], a: list[Any], *b: list[Any]) -> list[Any]:
    assert all(len(a) == len(x) for x in b)
    return [fun(*x) for x in zip(a, *b)]


arrayfun = cellfun


def mparenl(a: Any, b: Callable[[int], Any]) -> Any:
    return mparen(a, *b(len(a)))


def struct() -> dict[Any, Any]:
    return {}


def isfield(d: dict[Any, Any], k: Any) -> bool:
    return k in d


def num2str(a: int) -> str:
    return str(a)


class List:
    def __init__(self) -> None:
        self.list: list[Any] = list()

    def append(self, item):
        self.list.append(item)

    def toList(self, a: Any):
        return list(self.list)


newline = "\n"
numel = len
true = True
false = False
string = str

del Literal
