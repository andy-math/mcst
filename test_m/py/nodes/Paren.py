from mruntime import *
from test_m.py.nodes.Expression import Expression
class Paren(Expression):
    def __init__(self, *nargin): # retval: self
        [value] = nargin
        nargin = len(nargin)
        self.value = value
    @staticmethod
    def empty():
        return []
