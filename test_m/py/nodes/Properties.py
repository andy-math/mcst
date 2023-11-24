from mruntime import *
from test_m.py.nodes.Segment import Segment
class Properties(Segment):
    def __init__(self, *nargin): # retval: self
        [head, prop, end_] = nargin
        nargin = len(nargin)
        self.head = head
        self.prop = prop
        self.end_ = end_
    @staticmethod
    def empty():
        return []
