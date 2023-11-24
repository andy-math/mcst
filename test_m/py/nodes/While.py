from mruntime import *
from test_m.py.nodes.Segment import Segment
class While(Segment):
    def __init__(self, *nargin): # retval: self
        [head, body, end_] = nargin
        nargin = len(nargin)
        self.head = head
        self.body = body
        self.end_ = end_
    @staticmethod
    def empty():
        return []
