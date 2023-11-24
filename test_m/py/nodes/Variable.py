from mruntime import *
from test_m.py.nodes.Segment import Segment
class Variable(Segment):
    def __init__(self, *nargin): # retval: self
        [name, type, default, comment] = nargin
        nargin = len(nargin)
        self.name = name
        self.type = type
        self.default = default
        self.comment = comment
    @staticmethod
    def empty():
        return []
