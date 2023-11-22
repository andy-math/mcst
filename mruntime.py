from io import TextIOWrapper
from typing import Literal, NoReturn, Any, Union


def clc() -> None:
    pass


def clear() -> None:
    pass


def close(fig: str) -> None:
    pass


def isfolder(dir: str) -> bool:
    return False


def mkdir(dir: str) -> None:
    pass


def rmdir(dir: str) -> None:
    pass


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
    return len(a) == 0


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
        print(pattern % args)
    else:
        print(pattern % args)


def output(*args: Any) -> None:
    pass


def m2py(*args: Any) -> None:
    pass


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
    print(pattern % args)


def mparen(fun: Any, *index: Any) -> Any:
    if callable(fun):
        return fun(*index)
    for i in index:
        if isinstance(i, range):
            fun = fun[i.start - 1 : i.stop - 1 : i.step]
        else:
            fun = fun[i - 1]
    return fun


class List:
    def __init__(self) -> None:
        self.list: list[Any] = list()

    def append(self, item):
        self.list.append(item)

    def toList(self, a: Any):
        return list(self.list)


newline = "\n"
numel = len
false = False
string = str

del Literal
