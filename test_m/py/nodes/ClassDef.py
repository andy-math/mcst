from mruntime import *
from test_m.py.nodes.Segment import Segment
class ClassDef(Segment):
    def __init__(self, *nargin): # retval: self
        [head, property, method, end_] = nargin
        nargin = len(nargin)
        self.head = head
        self.property = property
        self.method = method
        self.end_ = end_
    @staticmethod
    def empty():
        return []
