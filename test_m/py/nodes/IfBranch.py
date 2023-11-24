from mruntime import *
from test_m.py.nodes.Segment import Segment
class IfBranch(Segment):
    def __init__(self, *nargin): # retval: self
        [head, body] = nargin
        nargin = len(nargin)
        self.head = head
        self.body = body
    @staticmethod
    def empty():
        return []
