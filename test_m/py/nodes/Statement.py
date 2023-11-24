from mruntime import *
from test_m.py.nodes.Segment import Segment
class Statement(Segment):
    def __init__(self, *nargin): # retval: self
        [keyword, modifier, lvalue, rvalue, comment] = nargin
        nargin = len(nargin)
        self.keyword = keyword
        self.modifier = modifier
        self.lvalue = lvalue
        self.rvalue = rvalue
        self.comment = comment
    @staticmethod
    def empty():
        return []
