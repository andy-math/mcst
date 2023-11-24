from mruntime import *
from test_m.py.nodes.Expression import Expression
class MatrixLine(Expression):
    def __init__(self, *nargin): # retval: self
        [item] = nargin
        nargin = len(nargin)
        self.item = item
    @staticmethod
    def empty():
        return []
