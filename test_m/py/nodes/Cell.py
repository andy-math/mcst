from mruntime import *
from test_m.py.nodes.Expression import Expression
class Cell(Expression):
    def __init__(self, *nargin): # retval: self
        [line] = nargin
        nargin = len(nargin)
        self.line = line
    @staticmethod
    def empty():
        return []
