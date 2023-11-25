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
    tokens = TokenList(mparen(tokens.toList, []))
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
def field(tokens): # retval: node
    nargin = 1
    nargout = 1
    if False and mparen(tokens.get).type:
        pass
    elif (mparen(tokens.get).type) == 'identifier':
        node = Identifier(mparen(tokens.get).token)
        mparen(tokens.next)
    elif (mparen(tokens.get).type) == 'lparen':
        mparen(tokens.next)
        node = expression(tokens)
        if not strcmp(mparen(tokens.get).type, 'rparen'):
            error('unexpected token')
        mparen(tokens.next)
    else:
        error('unexpected token')
    return node
def colonOrExpression(tokens): # retval: node
    nargin = 1
    nargout = 1
    if strcmp(mparen(tokens.get).type, 'colon'):
        node = Colon(mparen(Expression.empty), mparen(Expression.empty), mparen(Expression.empty))
        mparen(tokens.next)
    else:
        node = expression(tokens)
    return node
def subscript(tokens, endToken): # retval: args
    nargin = 2
    nargout = 1
    args = List()
    while not strcmp(mparen(tokens.get).type, endToken):
        arg = colonOrExpression(tokens)
        mparen(args.append, arg)
        if strcmp(mparen(tokens.get).type, 'comma'):
            mparen(tokens.next)
        elif not strcmp(mparen(tokens.get).type, endToken):
            error('unexpected token')
    args = mparen(args.toList, mparen(Expression.empty))
    return args
def reference(tokens): # retval: node
    nargin = 1
    nargout = 1
    if not strcmp(mparen(tokens.get).type, 'identifier'):
        error('must be identifier')
    node = Identifier(mparen(tokens.get).token)
    mparen(tokens.next)
    while not isempty(mparen(tokens.get)):
        if False and mparen(tokens.get).type:
            pass
        elif (mparen(tokens.get).type) == 'field':
            mparen(tokens.next)
            node2 = field(tokens)
            node = Field(node, node2)
        elif (mparen(tokens.get).type) == 'lparen':
            mparen(tokens.next)
            args = subscript(tokens, 'rparen')
            mparen(tokens.next)
            node = PIndex(node, args)
        elif (mparen(tokens.get).type) == 'lbrace':
            mparen(tokens.next)
            args = subscript(tokens, 'rbrace')
            mparen(tokens.next)
            node = BIndex(node, args)
        else:
            break
    return node
def matrixLine(tokens): # retval: node
    nargin = 1
    nargout = 1
    args = List()
    if strcmp(mparen(tokens.get).type, 'comma'):
        mparen(tokens.next)
    while not ismember(mparen(tokens.get).type, ['rsquare', 'rbrace', 'newline', 'semi']):
        if strcmp(mparen(tokens.get).type, 'not') and ismember(mparen(tokens.ahead).type, ['rsquare', 'rbrace', 'newline', 'semi', 'comma']):
            arg = Dismiss()
            mparen(tokens.next)
        else:
            arg = expression(tokens)
        mparen(args.append, arg)
        if strcmp(mparen(tokens.get).type, 'comma'):
            mparen(tokens.next)
    args = mparen(args.toList, mparen(Expression.empty))
    if isempty(args):
        node = mparen(MatrixLine.empty)
    else:
        node = MatrixLine(args)
    return node
def matrixLiteral(tokens, left, right, class_): # retval: node
    nargin = 4
    nargout = 1
    if not strcmp(mparen(tokens.get).type, left):
        error(['must be ', left])
    mparen(tokens.next)
    args = List()
    while strcmp(mparen(tokens.get).type, 'semi') or strcmp(mparen(tokens.get).type, 'newline'):
        mparen(tokens.next)
    while not strcmp(mparen(tokens.get).type, right):
        arg = matrixLine(tokens)
        mparen(args.append, arg)
        while strcmp(mparen(tokens.get).type, 'semi') or strcmp(mparen(tokens.get).type, 'newline'):
            mparen(tokens.next)
    mparen(tokens.next)
    node = mparen(class_, mparen(args.toList, mparen(MatrixLine.empty)))
    return node
def lambda_(tokens): # retval: node
    nargin = 1
    nargout = 1
    if not strcmp(mparen(tokens.get).type, 'lambda'):
        error('unexpected token')
    mparen(tokens.next)
    if strcmp(mparen(tokens.get).type, 'lparen'):
        mparen(tokens.next)
        args = List()
        while not strcmp(mparen(tokens.get).type, 'rparen'):
            if not strcmp(mparen(tokens.get).type, 'identifier'):
                error('unexpected token')
            arg = Identifier(mparen(tokens.get).token)
            mparen(args.append, arg)
            mparen(tokens.next)
            if strcmp(mparen(tokens.get).type, 'comma'):
                mparen(tokens.next)
        mparen(tokens.next)
        args = mparen(args.toList, mparen(Identifier.empty))
    else:
        args = mparen(Identifier.empty)
    node = expression(tokens)
    node = Lambda(args, node)
    return node
def operand(tokens): # retval: node
    nargin = 1
    nargout = 1
    if False and mparen(tokens.get).type:
        pass
    elif (mparen(tokens.get).type) in ['chars', 'string', 'number']:
        node = Literal(mparen(tokens.get).token)
        mparen(tokens.next)
    elif (mparen(tokens.get).type) == 'lambda':
        node = lambda_(tokens)
    elif (mparen(tokens.get).type) == 'lparen':
        mparen(tokens.next)
        node = expression(tokens)
        if not strcmp(mparen(tokens.get).type, 'rparen'):
            error('must be rparen')
        mparen(tokens.next)
        node = Paren(node)
    elif (mparen(tokens.get).type) == 'lsquare':
        node = matrixLiteral(tokens, 'lsquare', 'rsquare', lambda *args: Matrix(*args))
    elif (mparen(tokens.get).type) == 'lbrace':
        node = matrixLiteral(tokens, 'lbrace', 'rbrace', lambda *args: Cell(*args))
    elif (mparen(tokens.get).type) == 'identifier':
        node = reference(tokens)
    elif (mparen(tokens.get).type) == 'keyword':
        if not strcmp(mparen(tokens.get).token, 'end'):
            error('must be end')
        node = Identifier('end')
        mparen(tokens.next)
    else:
        error('unexpected token')
    return node
def transPower(tokens): # retval: node
    nargin = 1
    nargout = 1
    node = operand(tokens)
    while not isempty(mparen(tokens.get)):
        if False and mparen(tokens.get).type:
            pass
        elif (mparen(tokens.get).type) == 'transpose':
            mparen(tokens.next)
            node = Transpose(node)
        else:
            break
    return node
def unary(tokens): # retval: node
    nargin = 1
    nargout = 1
    if False and mparen(tokens.get).type:
        pass
    elif (mparen(tokens.get).type) == 'plus':
        mparen(tokens.next)
        node = unary(tokens)
    elif (mparen(tokens.get).type) == 'minus':
        mparen(tokens.next)
        node = unary(tokens)
        node = Negative(node)
    elif (mparen(tokens.get).type) == 'not':
        mparen(tokens.next)
        node = unary(tokens)
        node = Not(node)
    else:
        node = transPower(tokens)
    return node
def wrap(fun1, fun2, tokens, node): # retval: node
    nargin = 4
    nargout = 1
    node2 = mparen(fun2, tokens)
    node = mparen(fun1, node, node2)
    return node
def mulDiv(tokens): # retval: node
    nargin = 1
    nargout = 1
    map = dict()
    map = put(map, 'times', lambda tokens, node: wrap(lambda *args: Times(*args), lambda *args: unary(*args), tokens, node))
    map = put(map, 'ldivide', lambda tokens, node: wrap(lambda *args: LDivide(*args), lambda *args: unary(*args), tokens, node))
    map = put(map, 'rdivide', lambda tokens, node: wrap(lambda *args: RDivide(*args), lambda *args: unary(*args), tokens, node))
    map = put(map, 'mtimes', lambda tokens, node: wrap(lambda *args: MTimes(*args), lambda *args: unary(*args), tokens, node))
    map = put(map, 'mldivide', lambda tokens, node: wrap(lambda *args: MLDivide(*args), lambda *args: unary(*args), tokens, node))
    map = put(map, 'mrdivide', lambda tokens, node: wrap(lambda *args: MRDivide(*args), lambda *args: unary(*args), tokens, node))
    node = lookAhead(tokens, lambda *args: unary(*args), map)
    return node
def lookAhead(tokens, next, map): # retval: node
    nargin = 3
    nargout = 1
    node = mparen(next, tokens)
    while not isempty(mparen(tokens.get)) and isKey(map, mparen(tokens.get).type):
        fun = mparen(map, mparen(tokens.get).type)
        mparen(tokens.next)
        node = mparen(fun, tokens, node)
    return node
def addSub(tokens): # retval: node
    nargin = 1
    nargout = 1
    map = dict()
    map = put(map, 'plus', lambda tokens, node: wrap(lambda *args: Plus(*args), lambda *args: mulDiv(*args), tokens, node))
    map = put(map, 'minus', lambda tokens, node: wrap(lambda *args: Minus(*args), lambda *args: mulDiv(*args), tokens, node))
    node = lookAhead(tokens, lambda *args: mulDiv(*args), map)
    return node
def colonOperator(tokens): # retval: node
    nargin = 1
    nargout = 1
    node = addSub(tokens)
    if not isempty(mparen(tokens.get)) and strcmp(mparen(tokens.get).type, 'colon'):
        mparen(tokens.next)
        node2 = addSub(tokens)
        if not isempty(mparen(tokens.get)) and strcmp(mparen(tokens.get).type, 'colon'):
            mparen(tokens.next)
            node3 = addSub(tokens)
            node = Colon(node, node2, node3)
        else:
            node = Colon(node, mparen(Expression.empty), node2)
    return node
def compare(tokens): # retval: node
    nargin = 1
    nargout = 1
    map = dict()
    map = put(map, 'le', lambda tokens, node: wrap(lambda *args: LE(*args), lambda *args: colonOperator(*args), tokens, node))
    map = put(map, 'ge', lambda tokens, node: wrap(lambda *args: GE(*args), lambda *args: colonOperator(*args), tokens, node))
    map = put(map, 'lt', lambda tokens, node: wrap(lambda *args: LT(*args), lambda *args: colonOperator(*args), tokens, node))
    map = put(map, 'gt', lambda tokens, node: wrap(lambda *args: GT(*args), lambda *args: colonOperator(*args), tokens, node))
    map = put(map, 'eq', lambda tokens, node: wrap(lambda *args: EQ(*args), lambda *args: colonOperator(*args), tokens, node))
    map = put(map, 'ne', lambda tokens, node: wrap(lambda *args: NE(*args), lambda *args: colonOperator(*args), tokens, node))
    node = lookAhead(tokens, lambda *args: colonOperator(*args), map)
    return node
def logicalAnd(tokens): # retval: node
    nargin = 1
    nargout = 1
    map = dict()
    map = put(map, 'and', lambda tokens, node: wrap(lambda *args: And(*args), lambda *args: compare(*args), tokens, node))
    node = lookAhead(tokens, lambda *args: compare(*args), map)
    return node
def logicalOr(tokens): # retval: node
    nargin = 1
    nargout = 1
    map = dict()
    map = put(map, 'or', lambda tokens, node: wrap(lambda *args: Or(*args), lambda *args: logicalAnd(*args), tokens, node))
    node = lookAhead(tokens, lambda *args: logicalAnd(*args), map)
    return node
def expression(tokens): # retval: node
    nargin = 1
    nargout = 1
    node = logicalOr(tokens)
    return node
def modifier(tokens): # retval: node
    nargin = 1
    nargout = 1
    if not strcmp(mparen(tokens.get).type, 'identifier'):
        error('unexpected token')
    rvalue = Identifier(mparen(tokens.get).token)
    mparen(tokens.next)
    if strcmp(mparen(tokens.get).type, 'assign'):
        mparen(tokens.next)
        lvalue = rvalue
        rvalue = Identifier(mparen(tokens.get).token)
        mparen(tokens.next)
    else:
        lvalue = mparen(Identifier.empty)
    node = Modifier(lvalue, rvalue)
    return node
def statement(tokens): # retval: node
    nargin = 1
    nargout = 1
    if False and mparen(tokens.get).type:
        pass
    elif (mparen(tokens.get).type) in ['newline', 'semi']:
        error('unexpected token')
    elif (mparen(tokens.get).type) == 'keyword':
        keyword = mparen(tokens.get).token
        mparen(tokens.next)
    else:
        keyword = ''
    if ismember(keyword, ['properties', 'classdef', 'methods']) and strcmp(mparen(tokens.get).type, 'lparen'):
        mparen(tokens.next)
        modifiers = List()
        while not strcmp(mparen(tokens.get).type, 'rparen'):
            [i, mod] = modifier(tokens, i)
            mparen(modifiers.append, mod)
            if strcmp(mparen(tokens.get).type, 'comma'):
                mparen(tokens.next)
        mparen(tokens.next)
        modifiers = mparen(modifiers.toList, mparen(Modifier.empty))
    else:
        modifiers = mparen(Modifier.empty)
    if not isempty(mparen(tokens.get)) and not (strcmp(mparen(tokens.get).type, 'comment') or strcmp(mparen(tokens.get).type, 'newline')):
        rvalue = expression(tokens)
        if not isempty(mparen(tokens.get)) and strcmp(mparen(tokens.get).type, 'assign'):
            mparen(tokens.next)
            lvalue = rvalue
            rvalue = expression(tokens)
        else:
            lvalue = mparen(Expression.empty)
        if not isempty(mparen(tokens.get)) and (strcmp(mparen(tokens.get).type, 'semi') or strcmp(mparen(tokens.get).type, 'comma')):
            mparen(tokens.next)
    else:
        lvalue = mparen(Expression.empty)
        rvalue = mparen(Expression.empty)
    if not isempty(mparen(tokens.get)) and strcmp(mparen(tokens.get).type, 'comment'):
        comment = mparen(tokens.get).token
        mparen(tokens.next)
    else:
        comment = []
    node = Statement(keyword, modifiers, lvalue, rvalue, comment)
    while not isempty(mparen(tokens.get)) and (strcmp(mparen(tokens.get).type, 'semi') or strcmp(mparen(tokens.get).type, 'comma') or strcmp(mparen(tokens.get).type, 'newline')):
        mparen(tokens.next)
    return node
def variableDeclare(tokens): # retval: node
    nargin = 1
    nargout = 1
    # name type = default
    if not strcmp(mparen(tokens.get).type, 'identifier'):
        error('unexpected token')
    name = mparen(tokens.get).token
    mparen(tokens.next)
    if strcmp(mparen(tokens.get).type, 'identifier'):
        type = mparen(tokens.get).token
        mparen(tokens.next)
    else:
        type = ''
    if strcmp(mparen(tokens.get).type, 'assign'):
        mparen(tokens.next)
        expr = expression(tokens)
    else:
        expr = mparen(Expression.empty)
    if not isempty(mparen(tokens.get)) and strcmp(mparen(tokens.get).type, 'comment'):
        comment = mparen(tokens.get).token
        mparen(tokens.next)
    else:
        comment = []
    node = Variable(name, type, expr, comment)
    while not isempty(mparen(tokens.get)) and (strcmp(mparen(tokens.get).type, 'semi') or strcmp(mparen(tokens.get).type, 'newline')):
        mparen(tokens.next)
    return node
def program(tokens): # retval: blocks
    nargin = 1
    nargout = 1
    blocks = List()
    while not isempty(mparen(tokens.get)):
        while strcmp(mparen(tokens.get).type, 'semi') or strcmp(mparen(tokens.get).type, 'newline'):
            mparen(tokens.next)
        blk = block(tokens)
        mparen(blocks.append, blk)
    blocks = mparen(blocks.toList, mparen(Segment.empty))
    return blocks
def controlBlock(tokens, token, class_): # retval: node
    nargin = 3
    nargout = 1
    if not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, token)):
        error(['expect ', token])
    head = statement(tokens)
    args = List()
    while not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, 'end')):
        arg = block(tokens)
        mparen(args.append, arg)
    end_ = statement(tokens)
    node = mparen(class_, head, mparen(args.toList, mparen(Segment.empty)), end_)
    return node
def ifBlock(tokens): # retval: node
    nargin = 1
    nargout = 1
    if not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, 'if')):
        error('expect if')
    branch = List()
    while not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, 'end')):
        head = statement(tokens)
        args = List()
        while not (strcmp(mparen(tokens.get).type, 'keyword') and ismember(mparen(tokens.get).token, ['end', 'else', 'elseif'])):
            arg = block(tokens)
            mparen(args.append, arg)
        mparen(branch.append, IfBranch(head, mparen(args.toList, mparen(Statement.empty))))
    end_ = statement(tokens)
    node = If(mparen(branch.toList, mparen(IfBranch.empty)), end_)
    return node
def switchBlock(tokens): # retval: node
    nargin = 1
    nargout = 1
    if not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, 'switch')):
        error('expect switch')
    expr = statement(tokens)
    branch = List()
    while not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, 'end')):
        head = statement(tokens)
        args = List()
        while not (strcmp(mparen(tokens.get).type, 'keyword') and ismember(mparen(tokens.get).token, ['end', 'case', 'otherwise'])):
            arg = block(tokens)
            mparen(args.append, arg)
        mparen(branch.append, SwitchCase(head, mparen(args.toList, mparen(Segment.empty))))
    end_ = statement(tokens)
    node = Switch(expr, mparen(branch.toList, mparen(SwitchCase.empty)), end_)
    return node
def propertiesBlock(tokens): # retval: node
    nargin = 1
    nargout = 1
    if not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, 'properties')):
        error('expect properties')
    head = statement(tokens)
    props = List()
    while not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, 'end')):
        prop = variableDeclare(tokens)
        mparen(props.append, prop)
    end_ = statement(tokens)
    node = Properties(head, mparen(props.toList, mparen(Statement.empty)), end_)
    return node
def methodsBlock(tokens): # retval: node
    nargin = 1
    nargout = 1
    if not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, 'methods')):
        error('expect methods')
    head = statement(tokens)
    meth = List()
    while not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, 'end')):
        if not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, 'function')):
            error('unexpected token')
        fun = block(tokens)
        mparen(meth.append, fun)
    end_ = statement(tokens)
    node = Methods(head, mparen(meth.toList, mparen(Function.empty)), end_)
    return node
def classBlock(tokens): # retval: node
    nargin = 1
    nargout = 1
    if not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, 'classdef')):
        error('expect classdef')
    head = statement(tokens)
    property = List()
    method = List()
    while not (strcmp(mparen(tokens.get).type, 'keyword') and strcmp(mparen(tokens.get).token, 'end')):
        if not strcmp(mparen(tokens.get).type, 'keyword'):
            error('unexpected token')
        if False and mparen(tokens.get).token:
            pass
        elif (mparen(tokens.get).token) == 'properties':
            prop = propertiesBlock(tokens)
            mparen(property.append, prop)
        elif (mparen(tokens.get).token) == 'methods':
            meth = methodsBlock(tokens)
            mparen(method.append, meth)
        else:
            error('unexpected keyword')
    property = mparen(property.toList, mparen(Properties.empty))
    method = mparen(method.toList, mparen(Methods.empty))
    end_ = statement(tokens)
    node = ClassDef(head, property, method, end_)
    return node
def block(tokens): # retval: node
    nargin = 1
    nargout = 1
    if not strcmp(mparen(tokens.get).type, 'keyword'):
        node = statement(tokens)
        return node
    if False and mparen(tokens.get).token:
        pass
    elif (mparen(tokens.get).token) in ['return', 'continue', 'break']:
        node = statement(tokens)
    elif (mparen(tokens.get).token) == 'for':
        node = controlBlock(tokens, 'for', lambda *args: For(*args))
    elif (mparen(tokens.get).token) == 'while':
        node = controlBlock(tokens, 'while', lambda *args: While(*args))
    elif (mparen(tokens.get).token) == 'function':
        node = controlBlock(tokens, 'function', lambda *args: Function(*args))
    elif (mparen(tokens.get).token) == 'if':
        node = ifBlock(tokens)
    elif (mparen(tokens.get).token) == 'switch':
        node = switchBlock(tokens)
    elif (mparen(tokens.get).token) == 'classdef':
        node = classBlock(tokens)
    else:
        error('unexpected keyword')
    while not isempty(mparen(tokens.get)) and (strcmp(mparen(tokens.get).type, 'semi') or strcmp(mparen(tokens.get).type, 'newline') or strcmp(mparen(tokens.get).type, 'comma')):
        mparen(tokens.next)
    return node
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
