from test_m.py.nodes.Segment import Segment
from test_m.py.nodes.Matrix import Matrix
from test_m.py.nodes.MatrixLine import MatrixLine
from mruntime import *
def m2py(filename, node): # retval: []
    nargin = 2
    fid = fopen(filename, 'at+')
    fprintf(fid, 'from mruntime import *\\n')
    newNode = List()
    for i in colon(1, numel(node)):
        if isa(mparen(node, i), 'Function'):
            mparen(newNode.append, mparen(node, i))
    for i in colon(1, numel(node)):
        if not isa(mparen(node, i), 'Function'):
            mparen(newNode.append, mparen(node, i))
    node = mparen(newNode.toList, mparen(Segment.empty))
    ignore = outputNode(fid, 0, node, [], struct()) ##ok<NASGU>
    fclose(fid)
    return
def outputNode(fid, indent, node, retval, env): # retval: env
    nargin = 5
    nargout = 1
    assert(nargin == 5)
    assert(nargout == 1)
    if isempty(node):
        pass
    elif isList(node):
        for i in colon(1, numel(node)):
            env = outputNode(fid, indent, mparen(node, i), retval, env)
    elif isa(node, 'Segment'):
        env = outputSegment(fid, indent, node, retval, env)
    elif isa(node, 'Expression'):
        outputExpression(fid, indent, node)
    else:
        error('unexpected node')
    return env
def patchSwitch(fid, indent, value, body, retval, env): # retval: env
    nargin = 6
    nargout = 1
    assert(nargin == 6)
    assert(nargout == 1)
    for i in colon(1, numel(body)):
        if False and mparen(body, i).head.keyword:
            pass
        elif (mparen(body, i).head.keyword) == 'case':
            fprintf(fid, '%selif (', repmat(' ', 1, indent))
            outputExpression(fid, indent, value, env)
            if isa(mparen(body, i).head.rvalue, 'Cell'):
                fprintf(fid, ') in ')
            else:
                fprintf(fid, ') == ')
            outputExpression(fid, indent, mparen(body, i).head.rvalue, env)
            fprintf(fid, ':\\n')
            env = patchSwitchBody(fid, indent + 4, mparen(body, i).body, retval, env)
        elif (mparen(body, i).head.keyword) == 'otherwise':
            fprintf(fid, '%selse:\\n', repmat(' ', 1, indent))
            env = patchSwitchBody(fid, indent + 4, mparen(body, i).body, retval, env)
        else:
            error('unexpected token')
    return env
def patchSwitchBody(fid, indent, body, retval, env): # retval: env
    nargin = 5
    nargout = 1
    assert(nargin == 5)
    assert(nargout == 1)
    if isempty(body):
        fprintf(fid, '%spass\\n', repmat(' ', 1, indent))
    else:
        env = outputNode(fid, indent, body, retval, env)
    return env
def patchAssign(env, node): # retval: env
    nargin = 2
    nargout = 1
    assert(nargin == 2)
    assert(nargout == 1)
    if isempty(node):
        return env
    if isList(node):
        for i in colon(1, numel(node)):
            env = patchAssign(env, mparen(node, i))
        return env
    if False and type(node).__name__:
        pass
    elif (type(node).__name__) == 'Statement':
        env = patchAssign(env, node.lvalue)
    elif (type(node).__name__) == 'Matrix':
        env = patchAssign(env, node.line)
    elif (type(node).__name__) == 'MatrixLine':
        env = patchAssign(env, node.item)
    elif (type(node).__name__) in ['Field', 'PIndex', 'BIndex']:
        env = patchAssign(env, node.value)
    elif (type(node).__name__) == 'Identifier':
        env[node.identifier] = 'identifier'
    elif (type(node).__name__) == 'Dismiss':
        pass
    else:
        error('unexpected node')
    return env
def endLambda(node): # retval: b
    nargin = 1
    nargout = 1
    if isempty(node):
        b = false
        return b
    if isList(node):
        for i in colon(1, numel(node)):
            if endLambda(mparen(node, i)):
                b = true
                return b
        b = false
        return b
    if False and type(node).__name__:
        pass
    elif (type(node).__name__) == 'Literal':
        b = false
    elif (type(node).__name__) == 'Identifier':
        b = strcmp(node.identifier, 'end')
    elif (type(node).__name__) == 'Colon':
        b = endLambda(node.begin) or endLambda(node.end_) or endLambda(node.step)
    elif (type(node).__name__) in ['Plus', 'Minus']:
        b = endLambda(node.a) or endLambda(node.b)
    elif (type(node).__name__) == 'Not':
        b = endLambda(node.value)
    elif (type(node).__name__) == 'PIndex':
        b = false
    elif (type(node).__name__) == 'Matrix':
        b = endLambda(node.line)
    elif (type(node).__name__) == 'MatrixLine':
        b = endLambda(node.item)
    else:
        error('unexpected token')
    return b
def outputSegment(fid, indent, node, retval, env): # retval: env
    nargin = 5
    nargout = 1
    assert(nargin == 5)
    assert(nargout == 1)
    if False and type(node).__name__:
        pass
    elif (type(node).__name__) == 'Function':
        newEnv = struct()
        fprintf(fid, '%sdef ', repmat(' ', 1, indent))
        outputExpression(fid, indent, node.head.rvalue.value, env)
        fprintf(fid, '(')
        for i in colon(1, numel(node.head.rvalue.index)):
            outputExpression(fid, indent, mparen(node.head.rvalue.index, i), env)
            newEnv = patchAssign(newEnv, mparen(node.head.rvalue.index, i))
            if i < numel(node.head.rvalue.index):
                fprintf(fid, ', ')
        fprintf(fid, '): # retval: ')
        retval = node.head.lvalue
        if isempty(retval):
            outputExpression(fid, indent, Matrix(mparen(MatrixLine.empty)), env)
        else:
            outputExpression(fid, indent, retval, env)
        fprintf(fid, '\\n%snargin = %s\\n', repmat(' ', 1, indent + 4), num2str(numel(node.head.rvalue.index)))
        if not isempty(node.head.lvalue):
            if isa(node.head.lvalue, 'Identifier'):
                fprintf(fid, '%snargout = 1\\n', repmat(' ', 1, indent + 4))
            else:
                fprintf(fid, '%snargout = %s\\n', repmat(' ', 1, indent + 4), num2str(numel(mparen(node.head.lvalue.line, 1).item)))
        newEnv = outputNode(fid, indent + 4, node.body, retval, newEnv)
        fprintf(fid, '%sreturn', repmat(' ', 1, indent + 4))
        if not isempty(retval):
            fprintf(fid, ' ')
            outputExpression(fid, indent, retval, newEnv)
        fprintf(fid, '\\n')
        # outputSegment(fid, indent, node.end_);
    elif (type(node).__name__) == 'While':
        env = outputSegment(fid, indent, node.head, retval, env)
        env = outputNode(fid, indent + 4, node.body, retval, env)
        # outputSegment(fid, indent, node.end_);
    elif (type(node).__name__) == 'For':
        fprintf(fid, '%sfor ', repmat(' ', 1, indent))
        outputExpression(fid, indent, node.head.lvalue, env)
        fprintf(fid, ' in ')
        outputExpression(fid, indent, node.head.rvalue, env)
        fprintf(fid, ':\\n')
        env = outputNode(fid, indent + 4, node.body, retval, env)
        # outputSegment(fid, indent, node.end_);
    elif (type(node).__name__) == 'If':
        env = outputNode(fid, indent, node.body, retval, env)
        # outputSegment(fid, indent, node.end_);
    elif (type(node).__name__) == 'IfBranch':
        env = outputSegment(fid, indent, node.head, retval, env)
        env = outputNode(fid, indent + 4, node.body, retval, env)
        if isempty(node.body):
            fprintf(fid, '%spass\\n', repmat(' ', 1, indent + 4))
    elif (type(node).__name__) == 'Switch':
        value = node.head.rvalue
        fprintf(fid, '%sif False and ', repmat(' ', 1, indent))
        outputExpression(fid, indent, value, env)
        fprintf(fid, ':\\n%spass\\n', repmat(' ', 1, indent + 4))
        env = patchSwitch(fid, indent, value, node.body, retval, env)
        # outputNode(fid, indent, node.body);
        # outputSegment(fid, indent, node.end_);
    elif (type(node).__name__) == 'Statement':
        fprintf(fid, repmat(' ', 1, indent))
        if not isempty(node.keyword):
            if strcmp(node.keyword, 'elseif'):
                fprintf(fid, 'elif')
            else:
                fprintf(fid, '%s', node.keyword)
            if not isempty(node.rvalue):
                fprintf(fid, ' ')
            if not isempty(node.modifier):
                fprintf(fid, '(')
                for i in colon(1, numel(node.modifier)):
                    outputExpression(fid, indent, mparen(node.modifier, i), env)
                fprintf(fid, ')')
            if strcmp(node.keyword, 'return') and not isempty(retval):
                fprintf(fid, ' ')
                outputExpression(fid, indent, retval, env)
        if not isempty(node.lvalue):
            outputExpression(fid, indent, node.lvalue, env)
            fprintf(fid, ' = ')
        if not isempty(node.rvalue):
            outputExpression(fid, indent, node.rvalue, env)
        if ismember(node.keyword, ['if', 'elseif', 'else', 'while', 'for']):
            fprintf(fid, ':')
        if not isempty(node.comment):
            if not isempty(node.keyword) or not isempty(node.lvalue) or not isempty(node.rvalue):
                fprintf(fid, ' ')
            fprintf(fid, '#%s', mparenl(node.comment, lambda end: (colon(2, end),)))
        fprintf(fid, '\\n')
        env = patchAssign(env, node)
    elif (type(node).__name__) == 'ClassDef':
        if isa(node.head.rvalue, 'LT') and isa(node.head.rvalue.b, 'Identifier'):
            fprintf(fid, 'from test_m.py.nodes.')
            outputExpression(fid, indent, node.head.rvalue.b, env)
            fprintf(fid, ' import ')
            outputExpression(fid, indent, node.head.rvalue.b, env)
            fprintf(fid, '\\n')
        fprintf(fid, '%sclass ', repmat(' ', 1, indent))
        if isa(node.head.rvalue, 'LT'):
            outputExpression(fid, indent, node.head.rvalue.a, env)
            if isa(node.head.rvalue.b, 'Identifier'):
                fprintf(fid, '(')
                outputExpression(fid, indent, node.head.rvalue.b, env)
                fprintf(fid, ')')
            className = node.head.rvalue.a.identifier
        else:
            outputExpression(fid, indent, node.head.rvalue, env)
            className = node.head.rvalue.identifier
        fprintf(fid, ':\\n')
        for k in colon(1, numel(node.method)):
            for i in colon(1, numel(mparen(node.method, k).fun)):
                fprintf(fid, '%sdef ', repmat(' ', 1, indent + 4))
                funName = mparen(mparen(node.method, k).fun, i).head.rvalue.value.identifier
                if strcmp(className, funName):
                    fprintf(fid, '%s', '__init__')
                else:
                    fprintf(fid, '%s', funName)
                fprintf(fid, '(self, *nargin): # retval: ')
                retval = mparen(mparen(node.method, k).fun, i).head.lvalue
                if isempty(retval):
                    outputExpression(fid, indent + 4, Matrix(mparen(MatrixLine.empty)), env)
                else:
                    outputExpression(fid, indent + 4, retval, env)
                fprintf(fid, '\\n')
                fprintf(fid, '%s[', repmat(' ', 1, indent + 8))
                for j in colon(1, numel(mparen(mparen(node.method, k).fun, i).head.rvalue.index)):
                    outputExpression(fid, indent + 4, mparen(mparen(mparen(node.method, k).fun, i).head.rvalue.index, j), env)
                    if j < numel(mparen(mparen(node.method, k).fun, i).head.rvalue.index):
                        fprintf(fid, ', ')
                fprintf(fid, '] = nargin\\n%snargin = len(nargin)\\n', repmat(' ', 1, indent + 8))
                env = outputNode(fid, indent + 8, mparen(mparen(node.method, k).fun, i).body, retval, env)
                if not strcmp(className, funName):
                    fprintf(fid, '%sreturn', repmat(' ', 1, indent + 8))
                    if not isempty(retval):
                        fprintf(fid, ' ')
                        outputExpression(fid, indent + 4, retval, env)
                    fprintf(fid, '\\n')
        fprintf(fid, '%s@staticmethod\\n', repmat(' ', 1, indent + 4))
        fprintf(fid, '%sdef empty():\\n', repmat(' ', 1, indent + 4))
        fprintf(fid, '%sreturn []\\n', repmat(' ', 1, indent + 8))
        # outputSegment(fid, indent, node.head, retval);
        # outputNode(fid, indent + 4, node.property, retval);
        # outputNode(fid, indent + 4, node.method, retval);
        # outputSegment(fid, indent, node.end_, retval);
    elif (type(node).__name__) == 'Properties':
        env = outputSegment(fid, indent, node.head, retval, env)
        env = outputNode(fid, indent + 4, node.prop, retval, env)
        env = outputSegment(fid, indent, node.end_, retval, env)
    elif (type(node).__name__) == 'Methods':
        env = outputSegment(fid, indent, node.head, retval, env)
        env = outputNode(fid, indent + 4, node.fun, retval, env)
        env = outputSegment(fid, indent, node.end_, retval, env)
    elif (type(node).__name__) == 'Variable':
        fprintf(fid, repmat(' ', 1, indent))
        fprintf(fid, '%s', node.name)
        if not isempty(node.type):
            fprintf(fid, ' %s', node.type)
        if not isempty(node.default):
            fprintf(fid, ' = ')
            outputExpression(fid, indent, node.default, env)
        if not isempty(node.comment):
            fprintf(fid, ' %s', node.comment)
        fprintf(fid, '\\n')
    else:
        error('unexpected node')
    return env
def outputExpression(fid, indent, node, env): # retval: []
    nargin = 4
    assert(nargin == 4)
    if False and type(node).__name__:
        pass
    elif (type(node).__name__) == 'Literal':
        if startsWith(node.value, '\''):
            fprintf(fid, '\'%s\'', replace(replace(mparenl(node.value, lambda end: (colon(2, end - 1),)), '\\', '\\\\'), '\'\'', '\\\''))
        elif startsWith(node.value, '"'):
            fprintf(fid, '\'%s\'', replace(replace(mparenl(node.value, lambda end: (colon(2, end - 1),)), '\\', '\\\\'), '""', '\\"'))
        else:
            fprintf(fid, '%s', node.value)
    elif (type(node).__name__) == 'Identifier':
        fprintf(fid, '%s', node.identifier)
    elif (type(node).__name__) == 'Field':
        outputExpression(fid, indent, node.value, env)
        if isa(node.field, 'Identifier'):
            fprintf(fid, '.')
            outputExpression(fid, indent, node.field, env)
        else:
            fprintf(fid, '[')
            outputExpression(fid, indent, node.field, env)
            fprintf(fid, ']')
    elif (type(node).__name__) == 'Paren':
        fprintf(fid, '(')
        outputExpression(fid, indent, node.value, env)
        fprintf(fid, ')')
    elif (type(node).__name__) == 'Not':
        fprintf(fid, 'not ')
        outputExpression(fid, indent, node.value, env)
    elif (type(node).__name__) == 'Transpose':
        fprintf(fid, 'tr(')
        outputExpression(fid, indent, node.value, env)
        fprintf(fid, ')')
    elif (type(node).__name__) == 'Lambda':
        fprintf(fid, 'lambda ')
        if not (isempty(node.args) and isa(node.expr, 'Identifier')):
            for i in colon(1, numel(node.args)):
                outputExpression(fid, indent, mparen(node.args, i), env)
                if i < numel(node.args):
                    fprintf(fid, ', ')
        else:
            fprintf(fid, '*args')
        fprintf(fid, ': ')
        outputExpression(fid, indent, node.expr, env)
        if isempty(node.args) and isa(node.expr, 'Identifier'):
            fprintf(fid, '(*args)')
    elif (type(node).__name__) == 'Colon':
        if isempty(node.begin) and isempty(node.step) and isempty(node.end_):
            fprintf(fid, 'colon(None, None, None)')
        elif isempty(node.step):
            fprintf(fid, 'colon(')
            outputExpression(fid, indent, node.begin, env)
            fprintf(fid, ', ')
            outputExpression(fid, indent, node.end_, env)
            fprintf(fid, ')')
        else:
            fprintf(fid, 'colon(')
            outputExpression(fid, indent, node.begin, env)
            fprintf(fid, ', ')
            outputExpression(fid, indent, node.step, env)
            fprintf(fid, ', ')
            outputExpression(fid, indent, node.end_, env)
            fprintf(fid, ')')
    elif (type(node).__name__) == 'PIndex':
        if isa(node.value, 'Identifier') and not (isfield(env, node.value.identifier) and strcmp(env[node.value.identifier], 'identifier')):
            if isa(node.value, 'Identifier') and strcmp(node.value.identifier, 'class'):
                fprintf(fid, 'type')
            else:
                outputExpression(fid, indent, node.value, env)
            fprintf(fid, '(')
            for i in colon(1, numel(node.index)):
                outputExpression(fid, indent, mparen(node.index, i), env)
                if i < numel(node.index):
                    fprintf(fid, ', ')
            fprintf(fid, ')')
        elif endLambda(node.index):
            fprintf(fid, 'mparenl(')
            outputExpression(fid, indent, node.value, env)
            if not isempty(node.index):
                fprintf(fid, ', lambda end: (')
                for i in colon(1, numel(node.index)):
                    outputExpression(fid, indent, mparen(node.index, i), env)
                    if i < numel(node.index):
                        fprintf(fid, ', ')
                if numel(node.index) == 1:
                    fprintf(fid, ',')
                fprintf(fid, ')')
            fprintf(fid, ')')
        else:
            fprintf(fid, 'mparen(')
            outputExpression(fid, indent, node.value, env)
            if not isempty(node.index):
                fprintf(fid, ', ')
                for i in colon(1, numel(node.index)):
                    outputExpression(fid, indent, mparen(node.index, i), env)
                    if i < numel(node.index):
                        fprintf(fid, ', ')
            fprintf(fid, ')')
        if isa(node.value, 'Identifier') and strcmp(node.value.identifier, 'class'):
            fprintf(fid, '.__name__')
    elif (type(node).__name__) == 'BIndex':
        outputExpression(fid, indent, node.value, env)
        for i in colon(1, numel(node.index)):
            fprintf(fid, '[(')
            outputExpression(fid, indent, mparen(node.index, i), env)
            fprintf(fid, ')-1]')
    elif (type(node).__name__) == 'MatrixLine':
        for i in colon(1, numel(node.item)):
            outputExpression(fid, indent, mparen(node.item, i), env)
            if i < numel(node.item):
                fprintf(fid, ', ')
    elif (type(node).__name__) == 'Matrix':
        fprintf(fid, '[')
        if numel(node.line) > 1:
            fprintf(fid, '\\n')
            fprintf(fid, '%s', repmat(' ', 1, indent + 4))
        for i in colon(1, numel(node.line)):
            outputExpression(fid, indent, mparen(node.line, i), env)
            if numel(node.line) > 1:
                fprintf(fid, ',\\n')
                fprintf(fid, '%s', repmat(' ', 1, indent + 4))
        fprintf(fid, ']')
    elif (type(node).__name__) == 'Cell':
        fprintf(fid, '[')
        if numel(node.line) > 1:
            fprintf(fid, '\\n')
        for i in colon(1, numel(node.line)):
            outputExpression(fid, indent, mparen(node.line, i), env)
            if numel(node.line) > 1:
                fprintf(fid, '\\n')
        fprintf(fid, ']')
    elif (type(node).__name__) == 'LT':
        outputExpression(fid, indent, node.a, env)
        fprintf(fid, ' < ')
        outputExpression(fid, indent, node.b, env)
    elif (type(node).__name__) == 'GT':
        outputExpression(fid, indent, node.a, env)
        fprintf(fid, ' > ')
        outputExpression(fid, indent, node.b, env)
    elif (type(node).__name__) == 'LE':
        outputExpression(fid, indent, node.a, env)
        fprintf(fid, ' <= ')
        outputExpression(fid, indent, node.b, env)
    elif (type(node).__name__) == 'GE':
        outputExpression(fid, indent, node.a, env)
        fprintf(fid, ' >= ')
        outputExpression(fid, indent, node.b, env)
    elif (type(node).__name__) == 'EQ':
        outputExpression(fid, indent, node.a, env)
        fprintf(fid, ' == ')
        outputExpression(fid, indent, node.b, env)
    elif (type(node).__name__) == 'NE':
        outputExpression(fid, indent, node.a, env)
        fprintf(fid, ' != ')
        outputExpression(fid, indent, node.b, env)
    elif (type(node).__name__) == 'Plus':
        outputExpression(fid, indent, node.a, env)
        fprintf(fid, ' + ')
        outputExpression(fid, indent, node.b, env)
    elif (type(node).__name__) == 'Minus':
        outputExpression(fid, indent, node.a, env)
        fprintf(fid, ' - ')
        outputExpression(fid, indent, node.b, env)
    elif (type(node).__name__) == 'And':
        outputExpression(fid, indent, node.a, env)
        fprintf(fid, ' and ')
        outputExpression(fid, indent, node.b, env)
    elif (type(node).__name__) == 'Or':
        outputExpression(fid, indent, node.a, env)
        fprintf(fid, ' or ')
        outputExpression(fid, indent, node.b, env)
    elif (type(node).__name__) == 'MTimes':
        outputExpression(fid, indent, node.a, env)
        fprintf(fid, ' * ')
        outputExpression(fid, indent, node.b, env)
    elif (type(node).__name__) == 'Modifier':
        if not isempty(node.lvalue):
            outputExpression(fid, indent, node.lvalue, env)
            fprintf(fid, '=')
        outputExpression(fid, indent, node.rvalue, env)
    elif (type(node).__name__) == 'Dismiss':
        fprintf(fid, '_')
    else:
        error('unexpected node')
    return
