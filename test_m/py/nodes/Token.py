from mruntime import *
class Token:
    def __init__(self, *nargin): # retval: self
        [type, token] = nargin
        nargin = len(nargin)
        self.type = type
        self.token = token
    @staticmethod
    def empty():
        return []
