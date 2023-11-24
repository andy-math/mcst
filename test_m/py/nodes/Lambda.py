from mruntime import *
from test_m.py.nodes.Expression import Expression
class Lambda(Expression):
    def __init__(self, *nargin): # retval: self
        [args, expr] = nargin
        nargin = len(nargin)
        self.args = args
        self.expr = expr
    @staticmethod
    def empty():
        return []
