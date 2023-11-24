from mruntime import *
from test_m.py.nodes.Expression import Expression
class BIndex(Expression):
    def __init__(self, *nargin): # retval: self
        [value, index] = nargin
        nargin = len(nargin)
        self.value = value
        self.index = index
    @staticmethod
    def empty():
        return []
