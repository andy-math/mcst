from mruntime import *
from test_m.py.nodes.Expression import Expression
class Negative(Expression):
    def __init__(self, *nargin): # retval: self
        [expr] = nargin
        nargin = len(nargin)
        self.expr = expr
    @staticmethod
    def empty():
        return []
