from mruntime import *
from test_m.py.nodes.Expression import Expression
class Colon(Expression):
    def __init__(self, *nargin): # retval: self
        [begin, step, end_] = nargin
        nargin = len(nargin)
        self.begin = begin
        self.step = step
        self.end_ = end_
    @staticmethod
    def empty():
        return []
