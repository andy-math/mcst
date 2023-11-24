from mruntime import *
from test_m.py.nodes.Expression import Expression
class Identifier(Expression):
    def __init__(self, *nargin): # retval: self
        [identifier] = nargin
        nargin = len(nargin)
        self.identifier = identifier
    @staticmethod
    def empty():
        return []
