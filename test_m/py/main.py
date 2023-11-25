from test_m.py.nodes.And import And
from test_m.py.nodes.BIndex import BIndex
from test_m.py.nodes.Cell import Cell
from test_m.py.nodes.ClassDef import ClassDef
from test_m.py.nodes.Colon import Colon
from test_m.py.nodes.Dismiss import Dismiss
from test_m.py.nodes.EQ import EQ
from test_m.py.nodes.Expression import Expression
from test_m.py.nodes.Field import Field
from test_m.py.nodes.For import For
from test_m.py.nodes.Function import Function
from test_m.py.nodes.GE import GE
from test_m.py.nodes.GT import GT
from test_m.py.nodes.Identifier import Identifier
from test_m.py.nodes.If import If
from test_m.py.nodes.IfBranch import IfBranch
from test_m.py.nodes.LDivide import LDivide
from test_m.py.nodes.LE import LE
from test_m.py.nodes.LT import LT
from test_m.py.nodes.Lambda import Lambda
from test_m.py.nodes.Literal import Literal
from test_m.py.nodes.MLDivide import MLDivide
from test_m.py.nodes.MRDivide import MRDivide
from test_m.py.nodes.MTimes import MTimes
from test_m.py.nodes.Matrix import Matrix
from test_m.py.nodes.MatrixLine import MatrixLine
from test_m.py.nodes.Methods import Methods
from test_m.py.nodes.Minus import Minus
from test_m.py.nodes.Modifier import Modifier
from test_m.py.nodes.NE import NE
from test_m.py.nodes.Negative import Negative
from test_m.py.nodes.Not import Not
from test_m.py.nodes.Or import Or
from test_m.py.nodes.PIndex import PIndex
from test_m.py.nodes.Paren import Paren
from test_m.py.nodes.Plus import Plus
from test_m.py.nodes.Properties import Properties
from test_m.py.nodes.RDivide import RDivide
from test_m.py.nodes.Segment import Segment
from test_m.py.nodes.Statement import Statement
from test_m.py.nodes.Switch import Switch
from test_m.py.nodes.SwitchCase import SwitchCase
from test_m.py.nodes.Times import Times
from test_m.py.nodes.Token import Token
from test_m.py.nodes.Transpose import Transpose
from test_m.py.nodes.Variable import Variable
from test_m.py.nodes.While import While
from test_m.py.output import output
from test_m.py.m2py import m2py
from mruntime import *
def compareFile(file1, file2): # retval: []
    nargin = 2
    content1 = readFile(file1)
    content2 = readFile(file2)
    content1 = split(replace(content1, ' ', ''), newline)
    content2 = split(replace(content2, ' ', ''), newline)
    if numel(content1) != numel(content2):
        warning('length of %s not equal with length of %s', file1, file2)
        return
    d = find(cellfun(lambda a, b: not strcmp(a, b), content1, content2))
    if not isempty(d):
        warning('%s vs %s: diff found in line %s\\n', file1, file2, mat2str(d))
        return
    disp(file1 + ' vs ' + file2 + ': equal without space')
    return
def readFile(filename): # retval: content
    nargin = 1
    nargout = 1
    fid = fopen(filename)
    content = native2unicode(tr(fread(fid)))
    fclose(fid)
    while contains(content, sprintf('\\r\\n')):
        content = replace(content, sprintf('\\r\\n'), newline)
    return content
def parseFile(filename, table): # retval: node
    nargin = 2
    nargout = 1
    content = readFile(filename)
    node = program(tokenize(content, table))
    return node
def tokenize(s, table): # retval: tokens
    nargin = 2
    nargout = 1
    j = 1
    tokens = List()
    count = 0
    lastToken = ''
    while j < numel(s):
        count = count + 1
        [j, type, token] = nextToken(s, j, table, lastToken)
        mparen(tokens.append, Token(type, token))
        lastToken = type
    tokens = mparen(tokens.toList, [])
    return tokens
def nextToken(s, j, table, lastToken): # retval: [j, type, token]
    nargin = 4
    nargout = 3
    while j <= numel(s) and mparen(s, j) == ' ':
        j = j + 1
    for i in colon(1, size(table, 1)):
        if j + numel(table[(i)-1][(2)-1]) - 1 <= numel(s) and strcmp(mparen(s, colon(j, j + numel(table[(i)-1][(2)-1]) - 1)), table[(i)-1][(2)-1]):
            type = table[(i)-1][(1)-1]
            token = table[(i)-1][(2)-1]
            j = j + numel(table[(i)-1][(2)-1])
            return [j, type, token]
    if mparen(s, j) == '\'':
        if strcmp(lastToken, 'identifier') or strcmp(lastToken, 'number'):
            type = 'ctranspose'
            token = '\''
            j = j + 1
            return [j, type, token]
        i = j
        j = j + 1
        while j <= numel(s) and not (mparen(s, j) == '\'' and (j + 1 > numel(s) or mparen(s, j + 1) != '\'')):
            j = j + 1 + (mparen(s, j) == '\'')
        j = j + 1
        type = 'chars'
        token = mparen(s, colon(i, j - 1))
        return [j, type, token]
    if mparen(s, j) == '"':
        i = j
        j = j + 1
        while j <= numel(s) and not (mparen(s, j) == '"' and (j + 1 > numel(s) or mparen(s, j + 1) != '"')):
            j = j + 1 + (mparen(s, j) == '"')
        j = j + 1
        type = 'string'
        token = mparen(s, colon(i, j - 1))
        return [j, type, token]
    if ('a' <= mparen(s, j) and mparen(s, j) <= 'z') or ('A' <= mparen(s, j) and mparen(s, j) <= 'Z'):
        i = j
        while j <= numel(s) and (('a' <= mparen(s, j) and mparen(s, j) <= 'z') or ('A' <= mparen(s, j) and mparen(s, j) <= 'Z') or ('0' <= mparen(s, j) and mparen(s, j) <= '9') or mparen(s, j) == '_'):
            j = j + 1
        token = mparen(s, colon(i, j - 1))
        if ismember(token, ['return', 'break', 'continue', 'if', 'elseif', 'for', 'else', 'while', 'end', 'function', 'switch', 'case', 'otherwise', 'classdef', 'properties', 'methods']):
            type = 'keyword'
        else:
            type = 'identifier'
        return [j, type, token]
    if ('0' <= mparen(s, j) and mparen(s, j) <= '9') or (mparen(s, j) == '.' and j + 1 <= numel(s) and '0' <= mparen(s, j + 1) and mparen(s, j + 1) <= '9'):
        # [int].[frac]e[sign][exp]
        i = j
        dot = false
        exp = false
        sign = false
        while j <= numel(s) and (('0' <= mparen(s, j) and mparen(s, j) <= '9') or (not dot and not exp and mparen(s, j) == '.') or (not exp and mparen(s, j) == 'e') or (exp and not sign and (mparen(s, j) == '-' or mparen(s, j) == '+'))):
            j = j + 1
        type = 'number'
        token = mparen(s, colon(i, j - 1))
        return [j, type, token]
    if mparen(s, j) == '%':
        i = j
        while j <= numel(s) and mparen(s, j) != newline:
            j = j + 1
        type = 'comment'
        token = mparen(s, colon(i, j - 1))
        return [j, type, token]
    error('unknown token')
    return [j, type, token]
def field(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if False and mparen(tokens, i).type:
        pass
    elif (mparen(tokens, i).type) == 'identifier':
        node = Identifier(mparen(tokens, i).token)
        i = i + 1
    elif (mparen(tokens, i).type) == 'lparen':
        i = i + 1
        [i, node] = expression(tokens, i)
        if not strcmp(mparen(tokens, i).type, 'rparen'):
            error('unexpected token')
        i = i + 1
    else:
        error('unexpected token')
    return [i, node]
def colonOrExpression(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if strcmp(mparen(tokens, i).type, 'colon'):
        node = Colon(mparen(Expression.empty), mparen(Expression.empty), mparen(Expression.empty))
        i = i + 1
    else:
        [i, node] = expression(tokens, i)
    return [i, node]
def subscript(tokens, i, endToken): # retval: [i, args]
    nargin = 3
    nargout = 2
    args = List()
    while not strcmp(mparen(tokens, i).type, endToken):
        [i, arg] = colonOrExpression(tokens, i)
        mparen(args.append, arg)
        if strcmp(mparen(tokens, i).type, 'comma'):
            i = i + 1
        elif not strcmp(mparen(tokens, i).type, endToken):
            error('unexpected token')
    args = mparen(args.toList, mparen(Expression.empty))
    return [i, args]
def reference(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if i <= 0 or i > numel(tokens):
        error('index out of range')
    if not strcmp(mparen(tokens, i).type, 'identifier'):
        error('must be identifier')
    node = Identifier(mparen(tokens, i).token)
    i = i + 1
    while i <= numel(tokens):
        if False and mparen(tokens, i).type:
            pass
        elif (mparen(tokens, i).type) == 'field':
            i = i + 1
            [i, node2] = field(tokens, i)
            node = Field(node, node2)
        elif (mparen(tokens, i).type) == 'lparen':
            i = i + 1
            [i, args] = subscript(tokens, i, 'rparen')
            i = i + 1
            node = PIndex(node, args)
        elif (mparen(tokens, i).type) == 'lbrace':
            i = i + 1
            args = List()
            while not strcmp(mparen(tokens, i).type, 'rbrace'):
                if strcmp(mparen(tokens, i).type, 'colon'):
                    mparen(args.append, Colon())
                    i = i + 1
                else:
                    [i, arg] = expression(tokens, i)
                    mparen(args.append, arg)
                if False and mparen(tokens, i).type:
                    pass
                elif (mparen(tokens, i).type) == 'rbrace':
                    pass
                elif (mparen(tokens, i).type) == 'comma':
                    i = i + 1
                else:
                    error('unexpected token')
            i = i + 1
            node = BIndex(node, mparen(args.toList, mparen(Expression.empty)))
        else:
            break
    return [i, node]
def matrixLine(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    args = List()
    if strcmp(mparen(tokens, i).type, 'comma'):
        i = i + 1
    while not ismember(mparen(tokens, i).type, ['rsquare', 'rbrace', 'newline', 'semi']):
        if strcmp(mparen(tokens, i).type, 'not') and ismember(mparen(tokens, i + 1).type, ['rsquare', 'rbrace', 'newline', 'semi', 'comma']):
            arg = Dismiss()
            i = i + 1
        else:
            [i, arg] = expression(tokens, i)
        mparen(args.append, arg)
        if strcmp(mparen(tokens, i).type, 'comma'):
            i = i + 1
    args = mparen(args.toList, mparen(Expression.empty))
    if isempty(args):
        node = mparen(MatrixLine.empty)
    else:
        node = MatrixLine(args)
    return [i, node]
def matrixLiteral(tokens, i, left, right, class_): # retval: [i, node]
    nargin = 5
    nargout = 2
    if not strcmp(mparen(tokens, i).type, left):
        error(['must be ', left])
    i = i + 1
    args = List()
    while strcmp(mparen(tokens, i).type, 'semi') or strcmp(mparen(tokens, i).type, 'newline'):
        i = i + 1
    while not strcmp(mparen(tokens, i).type, right):
        [i, arg] = matrixLine(tokens, i)
        mparen(args.append, arg)
        while strcmp(mparen(tokens, i).type, 'semi') or strcmp(mparen(tokens, i).type, 'newline'):
            i = i + 1
    i = i + 1
    node = mparen(class_, mparen(args.toList, mparen(MatrixLine.empty)))
    return [i, node]
def lambda_(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if not strcmp(mparen(tokens, i).type, 'lambda'):
        error('unexpected token')
    i = i + 1
    if strcmp(mparen(tokens, i).type, 'lparen'):
        i = i + 1
        args = List()
        while not strcmp(mparen(tokens, i).type, 'rparen'):
            if not strcmp(mparen(tokens, i).type, 'identifier'):
                error('unexpected token')
            arg = Identifier(mparen(tokens, i).token)
            mparen(args.append, arg)
            i = i + 1
            if strcmp(mparen(tokens, i).type, 'comma'):
                i = i + 1
        i = i + 1
        args = mparen(args.toList, mparen(Identifier.empty))
    else:
        args = mparen(Identifier.empty)
    [i, node] = expression(tokens, i)
    node = Lambda(args, node)
    return [i, node]
def operand(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if False and mparen(tokens, i).type:
        pass
    elif (mparen(tokens, i).type) in ['chars', 'string', 'number']:
        node = Literal(mparen(tokens, i).token)
        i = i + 1
    elif (mparen(tokens, i).type) == 'lambda':
        [i, node] = lambda_(tokens, i)
    elif (mparen(tokens, i).type) == 'lparen':
        i = i + 1
        [i, node] = expression(tokens, i)
        if not strcmp(mparen(tokens, i).type, 'rparen'):
            error('must be rparen')
        i = i + 1
        node = Paren(node)
    elif (mparen(tokens, i).type) == 'lsquare':
        [i, node] = matrixLiteral(tokens, i, 'lsquare', 'rsquare', lambda *args: Matrix(*args))
    elif (mparen(tokens, i).type) == 'lbrace':
        [i, node] = matrixLiteral(tokens, i, 'lbrace', 'rbrace', lambda *args: Cell(*args))
    elif (mparen(tokens, i).type) == 'identifier':
        [i, node] = reference(tokens, i)
    elif (mparen(tokens, i).type) == 'keyword':
        if not strcmp(mparen(tokens, i).token, 'end'):
            error('must be end')
        node = Identifier('end')
        i = i + 1
    else:
        error('unexpected token')
    return [i, node]
def transPower(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    [i, node] = operand(tokens, i)
    while i <= numel(tokens):
        if False and mparen(tokens, i).type:
            pass
        elif (mparen(tokens, i).type) == 'transpose':
            i = i + 1
            node = Transpose(node)
        else:
            break
    return [i, node]
def unary(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if False and mparen(tokens, i).type:
        pass
    elif (mparen(tokens, i).type) == 'plus':
        i = i + 1
        [i, node] = unary(tokens, i)
    elif (mparen(tokens, i).type) == 'minus':
        i = i + 1
        [i, node] = unary(tokens, i)
        node = Negative(node)
    elif (mparen(tokens, i).type) == 'not':
        i = i + 1
        [i, node] = unary(tokens, i)
        node = Not(node)
    else:
        [i, node] = transPower(tokens, i)
    return [i, node]
def wrap(fun1, fun2, tokens, i, node): # retval: [i, node]
    nargin = 5
    nargout = 2
    [i, node2] = mparen(fun2, tokens, i)
    node = mparen(fun1, node, node2)
    return [i, node]
def mulDiv(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    map = dict()
    map = put(map, 'times', lambda tokens, i, node: wrap(lambda *args: Times(*args), lambda *args: unary(*args), tokens, i, node))
    map = put(map, 'ldivide', lambda tokens, i, node: wrap(lambda *args: LDivide(*args), lambda *args: unary(*args), tokens, i, node))
    map = put(map, 'rdivide', lambda tokens, i, node: wrap(lambda *args: RDivide(*args), lambda *args: unary(*args), tokens, i, node))
    map = put(map, 'mtimes', lambda tokens, i, node: wrap(lambda *args: MTimes(*args), lambda *args: unary(*args), tokens, i, node))
    map = put(map, 'mldivide', lambda tokens, i, node: wrap(lambda *args: MLDivide(*args), lambda *args: unary(*args), tokens, i, node))
    map = put(map, 'mrdivide', lambda tokens, i, node: wrap(lambda *args: MRDivide(*args), lambda *args: unary(*args), tokens, i, node))
    [i, node] = lookAhead(tokens, i, lambda *args: unary(*args), map)
    return [i, node]
def lookAhead(tokens, i, next, map): # retval: [i, node]
    nargin = 4
    nargout = 2
    [i, node] = mparen(next, tokens, i)
    while i <= numel(tokens) and isKey(map, mparen(tokens, i).type):
        fun = mparen(map, mparen(tokens, i).type)
        i = i + 1
        [i, node] = mparen(fun, tokens, i, node)
    return [i, node]
def addSub(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    map = dict()
    map = put(map, 'plus', lambda tokens, i, node: wrap(lambda *args: Plus(*args), lambda *args: mulDiv(*args), tokens, i, node))
    map = put(map, 'minus', lambda tokens, i, node: wrap(lambda *args: Minus(*args), lambda *args: mulDiv(*args), tokens, i, node))
    [i, node] = lookAhead(tokens, i, lambda *args: mulDiv(*args), map)
    return [i, node]
def colonOperator(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    [i, node] = addSub(tokens, i)
    if i <= numel(tokens) and strcmp(mparen(tokens, i).type, 'colon'):
        i = i + 1
        [i, node2] = addSub(tokens, i)
        if i <= numel(tokens) and strcmp(mparen(tokens, i).type, 'colon'):
            i = i + 1
            [i, node3] = addSub(tokens, i)
            node = Colon(node, node2, node3)
        else:
            node = Colon(node, mparen(Expression.empty), node2)
    return [i, node]
def compare(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    map = dict()
    map = put(map, 'le', lambda tokens, i, node: wrap(lambda *args: LE(*args), lambda *args: colonOperator(*args), tokens, i, node))
    map = put(map, 'ge', lambda tokens, i, node: wrap(lambda *args: GE(*args), lambda *args: colonOperator(*args), tokens, i, node))
    map = put(map, 'lt', lambda tokens, i, node: wrap(lambda *args: LT(*args), lambda *args: colonOperator(*args), tokens, i, node))
    map = put(map, 'gt', lambda tokens, i, node: wrap(lambda *args: GT(*args), lambda *args: colonOperator(*args), tokens, i, node))
    map = put(map, 'eq', lambda tokens, i, node: wrap(lambda *args: EQ(*args), lambda *args: colonOperator(*args), tokens, i, node))
    map = put(map, 'ne', lambda tokens, i, node: wrap(lambda *args: NE(*args), lambda *args: colonOperator(*args), tokens, i, node))
    [i, node] = lookAhead(tokens, i, lambda *args: colonOperator(*args), map)
    return [i, node]
def logicalAnd(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    map = dict()
    map = put(map, 'and', lambda tokens, i, node: wrap(lambda *args: And(*args), lambda *args: compare(*args), tokens, i, node))
    [i, node] = lookAhead(tokens, i, lambda *args: compare(*args), map)
    return [i, node]
def logicalOr(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    map = dict()
    map = put(map, 'or', lambda tokens, i, node: wrap(lambda *args: Or(*args), lambda *args: logicalAnd(*args), tokens, i, node))
    [i, node] = lookAhead(tokens, i, lambda *args: logicalAnd(*args), map)
    return [i, node]
def expression(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    [i, node] = logicalOr(tokens, i)
    return [i, node]
def modifier(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if not strcmp(mparen(tokens, i).type, 'identifier'):
        error('unexpected token')
    rvalue = Identifier(mparen(tokens, i).token)
    i = i + 1
    if strcmp(mparen(tokens, i).type, 'assign'):
        i = i + 1
        lvalue = rvalue
        rvalue = Identifier(mparen(tokens, i).token)
        i = i + 1
    else:
        lvalue = mparen(Identifier.empty)
    node = Modifier(lvalue, rvalue)
    return [i, node]
def statement(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if False and mparen(tokens, i).type:
        pass
    elif (mparen(tokens, i).type) in ['newline', 'semi']:
        error('unexpected token')
    elif (mparen(tokens, i).type) == 'keyword':
        keyword = mparen(tokens, i).token
        i = i + 1
    else:
        keyword = ''
    if ismember(keyword, ['properties', 'classdef', 'methods']) and strcmp(mparen(tokens, i).type, 'lparen'):
        i = i + 1
        modifiers = List()
        while not strcmp(mparen(tokens, i).type, 'rparen'):
            [i, mod] = modifier(tokens, i)
            mparen(modifiers.append, mod)
            if strcmp(mparen(tokens, i).type, 'comma'):
                i = i + 1
        i = i + 1
        modifiers = mparen(modifiers.toList, mparen(Modifier.empty))
    else:
        modifiers = mparen(Modifier.empty)
    if i <= numel(tokens) and not (strcmp(mparen(tokens, i).type, 'comment') or strcmp(mparen(tokens, i).type, 'newline')):
        [i, rvalue] = expression(tokens, i)
        if i <= numel(tokens) and strcmp(mparen(tokens, i).type, 'assign'):
            i = i + 1
            lvalue = rvalue
            [i, rvalue] = expression(tokens, i)
        else:
            lvalue = mparen(Expression.empty)
        if i <= numel(tokens) and (strcmp(mparen(tokens, i).type, 'semi') or strcmp(mparen(tokens, i).type, 'comma')):
            i = i + 1
    else:
        lvalue = mparen(Expression.empty)
        rvalue = mparen(Expression.empty)
    if i <= numel(tokens) and strcmp(mparen(tokens, i).type, 'comment'):
        comment = mparen(tokens, i).token
        i = i + 1
    else:
        comment = []
    node = Statement(keyword, modifiers, lvalue, rvalue, comment)
    while i <= numel(tokens) and (strcmp(mparen(tokens, i).type, 'semi') or strcmp(mparen(tokens, i).type, 'comma') or strcmp(mparen(tokens, i).type, 'newline')):
        i = i + 1
    return [i, node]
def variableDeclare(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    # name type = default
    if not strcmp(mparen(tokens, i).type, 'identifier'):
        error('unexpected token')
    name = mparen(tokens, i).token
    i = i + 1
    if strcmp(mparen(tokens, i).type, 'identifier'):
        type = mparen(tokens, i).token
        i = i + 1
    else:
        type = ''
    if strcmp(mparen(tokens, i).type, 'assign'):
        i = i + 1
        [i, expr] = expression(tokens, i)
    else:
        expr = mparen(Expression.empty)
    if i <= numel(tokens) and strcmp(mparen(tokens, i).type, 'comment'):
        comment = mparen(tokens, i).token
        i = i + 1
    else:
        comment = []
    node = Variable(name, type, expr, comment)
    while i <= numel(tokens) and (strcmp(mparen(tokens, i).type, 'semi') or strcmp(mparen(tokens, i).type, 'newline')):
        i = i + 1
    return [i, node]
def program(tokens): # retval: blocks
    nargin = 1
    nargout = 1
    blocks = List()
    i = 1
    while i <= numel(tokens):
        while strcmp(mparen(tokens, i).type, 'semi') or strcmp(mparen(tokens, i).type, 'newline'):
            i = i + 1
        [i, blk] = block(tokens, i)
        mparen(blocks.append, blk)
    blocks = mparen(blocks.toList, mparen(Segment.empty))
    return blocks
def controlBlock(tokens, i, token, class_): # retval: [i, node]
    nargin = 4
    nargout = 2
    if not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, token)):
        error(['expect ', token])
    [i, head] = statement(tokens, i)
    args = List()
    while not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, 'end')):
        [i, arg] = block(tokens, i)
        mparen(args.append, arg)
    [i, end_] = statement(tokens, i)
    node = mparen(class_, head, mparen(args.toList, mparen(Segment.empty)), end_)
    return [i, node]
def ifBlock(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, 'if')):
        error('expect if')
    branch = List()
    while not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, 'end')):
        [i, head] = statement(tokens, i)
        args = List()
        while not (strcmp(mparen(tokens, i).type, 'keyword') and ismember(mparen(tokens, i).token, ['end', 'else', 'elseif'])):
            [i, arg] = block(tokens, i)
            mparen(args.append, arg)
        mparen(branch.append, IfBranch(head, mparen(args.toList, mparen(Statement.empty))))
    [i, end_] = statement(tokens, i)
    node = If(mparen(branch.toList, mparen(IfBranch.empty)), end_)
    return [i, node]
def switchBlock(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, 'switch')):
        error('expect switch')
    [i, expr] = statement(tokens, i)
    branch = List()
    while not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, 'end')):
        [i, head] = statement(tokens, i)
        args = List()
        while not (strcmp(mparen(tokens, i).type, 'keyword') and ismember(mparen(tokens, i).token, ['end', 'case', 'otherwise'])):
            [i, arg] = block(tokens, i)
            mparen(args.append, arg)
        mparen(branch.append, SwitchCase(head, mparen(args.toList, mparen(Segment.empty))))
    [i, end_] = statement(tokens, i)
    node = Switch(expr, mparen(branch.toList, mparen(SwitchCase.empty)), end_)
    return [i, node]
def propertiesBlock(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, 'properties')):
        error('expect properties')
    [i, head] = statement(tokens, i)
    props = List()
    while not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, 'end')):
        [i, prop] = variableDeclare(tokens, i)
        mparen(props.append, prop)
    [i, end_] = statement(tokens, i)
    node = Properties(head, mparen(props.toList, mparen(Statement.empty)), end_)
    return [i, node]
def methodsBlock(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, 'methods')):
        error('expect methods')
    [i, head] = statement(tokens, i)
    meth = List()
    while not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, 'end')):
        if not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, 'function')):
            error('unexpected token')
        [i, fun] = block(tokens, i)
        mparen(meth.append, fun)
    [i, end_] = statement(tokens, i)
    node = Methods(head, mparen(meth.toList, mparen(Function.empty)), end_)
    return [i, node]
def classBlock(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, 'classdef')):
        error('expect classdef')
    [i, head] = statement(tokens, i)
    property = List()
    method = List()
    while not (strcmp(mparen(tokens, i).type, 'keyword') and strcmp(mparen(tokens, i).token, 'end')):
        if not strcmp(mparen(tokens, i).type, 'keyword'):
            error('unexpected token')
        if False and mparen(tokens, i).token:
            pass
        elif (mparen(tokens, i).token) == 'properties':
            [i, prop] = propertiesBlock(tokens, i)
            mparen(property.append, prop)
        elif (mparen(tokens, i).token) == 'methods':
            [i, meth] = methodsBlock(tokens, i)
            mparen(method.append, meth)
        else:
            error('unexpected keyword')
    property = mparen(property.toList, mparen(Properties.empty))
    method = mparen(method.toList, mparen(Methods.empty))
    [i, end_] = statement(tokens, i)
    node = ClassDef(head, property, method, end_)
    return [i, node]
def block(tokens, i): # retval: [i, node]
    nargin = 2
    nargout = 2
    if not strcmp(mparen(tokens, i).type, 'keyword'):
        [i, node] = statement(tokens, i)
        return [i, node]
    if False and mparen(tokens, i).token:
        pass
    elif (mparen(tokens, i).token) in ['return', 'continue', 'break']:
        [i, node] = statement(tokens, i)
    elif (mparen(tokens, i).token) == 'for':
        [i, node] = controlBlock(tokens, i, 'for', lambda *args: For(*args))
    elif (mparen(tokens, i).token) == 'while':
        [i, node] = controlBlock(tokens, i, 'while', lambda *args: While(*args))
    elif (mparen(tokens, i).token) == 'function':
        [i, node] = controlBlock(tokens, i, 'function', lambda *args: Function(*args))
    elif (mparen(tokens, i).token) == 'if':
        [i, node] = ifBlock(tokens, i)
    elif (mparen(tokens, i).token) == 'switch':
        [i, node] = switchBlock(tokens, i)
    elif (mparen(tokens, i).token) == 'classdef':
        [i, node] = classBlock(tokens, i)
    else:
        error('unexpected keyword')
    while i <= numel(tokens) and (strcmp(mparen(tokens, i).type, 'semi') or strcmp(mparen(tokens, i).type, 'newline') or strcmp(mparen(tokens, i).type, 'comma')):
        i = i + 1
    return [i, node]
clc()
clear()
close('all')
table = [
    ['and', '&&'],
    ['or', '||'],
    ['times', '.*'],
    ['rdivide', './'],
    ['ldivide', '.\\'],
    ['transpose', '.\''],
    ['eq', '=='],
    ['ne', '~='],
    ['le', '<='],
    ['ge', '>='],
    ['lparen', '('],
    ['rparen', ')'],
    ['lsquare', '['],
    ['rsquare', ']'],
    ['lbrace', '{'],
    ['rbrace', '}'],
    ['semi', ';'],
    ['colon', ':'],
    ['comma', ','],
    ['plus', '+'],
    ['minus', '-'],
    ['mtimes', '*'],
    ['mrdivide', '/'],
    ['mldivide', '\\'],
    ['lt', '<'],
    ['gt', '>'],
    ['assign', '='],
    ['not', '~'],
    ['field', '.'],
    ['lambda', '@'],
    ['newline', newline],
    ]
[testdir, pydir] = configure()
if isfolder(pydir + '/nodes'):
    rmdir(pydir + '/nodes', 's')
mkdir(pydir + '/nodes')
fid = fopen(pydir + '/main.py', 'wt+')
files = dir('mcst')
for i in colon(1, numel(files)):
    if not (startsWith(mparen(files, i).name, '.') or endsWith(mparen(files, i).name, '.asv')):
        node = parseFile('mcst/' + mparen(files, i).name, table)
        output(testdir + '/' + mparen(files, i).name, node)
        m2py(pydir + '/nodes/' + mparenl(mparen(files, i).name, lambda end: (colon(1, end - 2),)) + '.py', node)
        fprintf(fid, 'from test_m.py.nodes.%s import %s\\n', mparenl(mparen(files, i).name, lambda end: (colon(1, end - 2),)), mparenl(mparen(files, i).name, lambda end: (colon(1, end - 2),)))
        compareFile('mcst/' + mparen(files, i).name, testdir + '/' + mparen(files, i).name)
fprintf(fid, 'from test_m.py.output import output\\n')
fprintf(fid, 'from test_m.py.m2py import m2py\\n')
fclose(fid)
if isfile(pydir + '/output.py'):
    delete(pydir + '/output.py')
fid = fopen(pydir + '/m2py.py', 'wt+')
fprintf(fid, 'from test_m.py.nodes.Segment import Segment\\n')
fprintf(fid, 'from test_m.py.nodes.Matrix import Matrix\\n')
fprintf(fid, 'from test_m.py.nodes.MatrixLine import MatrixLine\\n')
fclose(fid)
#
node = parseFile('main.m', table)
output(testdir + '/main.m', node)
m2py(pydir + '/main.py', node)
compareFile('main.m', testdir + '/main.m')
#
node = parseFile('output.m', table)
output(testdir + '/output.m', node)
m2py(pydir + '/output.py', node)
compareFile('output.m', testdir + '/output.m')
#
output(testdir + '/List.m', parseFile('List.m', table))
compareFile('List.m', testdir + '/List.m')
#
node = parseFile('m2py.m', table)
output(testdir + '/m2py.m', node)
m2py(pydir + '/m2py.py', node)
compareFile('m2py.m', testdir + '/m2py.m')
