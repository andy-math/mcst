from mruntime import *
from test_m.py.nodes.Expression import Expression
class Field(Expression):
    def __init__(self, *nargin): # retval: self
        [value, field] = nargin
        nargin = len(nargin)
        self.value = value
        self.field = field
    @staticmethod
    def empty():
        return []
