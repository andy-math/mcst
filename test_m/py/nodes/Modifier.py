from mruntime import *
from test_m.py.nodes.Expression import Expression
class Modifier(Expression):
    def __init__(self, *nargin): # retval: self
        [lvalue, rvalue] = nargin
        nargin = len(nargin)
        self.lvalue = lvalue
        self.rvalue = rvalue
    @staticmethod
    def empty():
        return []
