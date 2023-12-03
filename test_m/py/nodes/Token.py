from mruntime import *
class Token:
    def __init__(self, *nargin): # retval: self
        [type, token, sym] = nargin
        nargin = len(nargin)
        self.type = type
        self.token = token
        self.sym = sym
    @staticmethod
    def empty():
        return []
