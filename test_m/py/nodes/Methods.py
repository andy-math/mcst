from mruntime import *
from test_m.py.nodes.Segment import Segment
class Methods(Segment):
    def __init__(self, *nargin): # retval: self
        [head, fun, end_] = nargin
        nargin = len(nargin)
        self.head = head
        self.fun = fun
        self.end_ = end_
    @staticmethod
    def empty():
        return []
