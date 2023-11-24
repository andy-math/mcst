from mruntime import *
from test_m.py.nodes.Expression import Expression
class LDivide(Expression):
    def __init__(self, *nargin): # retval: self
        [a, b] = nargin
        nargin = len(nargin)
        self.a = a
        self.b = b
    @staticmethod
    def empty():
        return []