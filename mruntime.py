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
        if isinstance(fun, dict):
            fun = fun[i]
        elif isinstance(i, range):
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


def put(a: dict[str, Any], b: str, c: Any) -> dict[str, Any]:
    a[b] = c
    return a


def isKey(a: dict[str, Any], b: str) -> bool:
    return b in a


def isequal(a: Any, b: Any) -> bool:
    return True


class TokenList:
    def __init__(self, tokens: list[str]) -> None:
        self.tokens = tokens
        self.i = 0

    def __getitem__(self, i: int) -> str:
        self.i = i
        return self.tokens[i]

    def __len__(self) -> int:
        return len(self.tokens)

    def next(self) -> None:
        self.i += 1

    def get(self) -> Union[list[str], str]:
        if self.i >= len(self.tokens):
            return []
        else:
            return self.tokens[self.i]

    def ahead(self) -> Union[list[str], str]:
        if self.i + 1 >= len(self.tokens):
            return []
        else:
            return self.tokens[self.i + 1]


newline = "\n"
numel = len
true = True
false = False
string = str
disp = print

del Literal
