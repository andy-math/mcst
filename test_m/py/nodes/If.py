from mruntime import *
from test_m.py.nodes.Segment import Segment
class If(Segment):
    def __init__(self, *nargin): # retval: self
        [body, end_] = nargin
        nargin = len(nargin)
        self.body = body
        self.end_ = end_
    @staticmethod
    def empty():
        return []
