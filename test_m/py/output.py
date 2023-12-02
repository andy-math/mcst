from mruntime import *
def output(filename, node): # retval: []
    nargin = 2
    fid = fopen(filename, 'wt+')
    outputNode(fid, 0, node)
    fclose(fid)
    return
def outputNode(fid, indent, node): # retval: []
    nargin = 3
    if isempty(node):
        pass
    elif isList(node):
        for i in colon(1, numel(node)):
            outputNode(fid, indent, mparen(node, i))
    elif isa(node, 'Segment'):
        outputSegment(fid, indent, node)
    elif isa(node, 'Expression'):
        outputExpression(fid, indent, node)
    else:
        error('unexpected node')
    return
def outputSegment(fid, indent, node): # retval: []
    nargin = 3
    if False and type(node).__name__:
        pass
    elif (type(node).__name__) == 'Function':
        outputSegment(fid, indent, node.head)
        outputNode(fid, indent + 4, node.body)
        outputSegment(fid, indent, node.end_)
    elif (type(node).__name__) == 'While':
        outputSegment(fid, indent, node.head)
        outputNode(fid, indent + 4, node.body)
        outputSegment(fid, indent, node.end_)
    elif (type(node).__name__) == 'For':
        outputSegment(fid, indent, node.head)
        outputNode(fid, indent + 4, node.body)
        outputSegment(fid, indent, node.end_)
    elif (type(node).__name__) == 'If':
        outputNode(fid, indent, node.body)
        outputSegment(fid, indent, node.end_)
    elif (type(node).__name__) == 'IfBranch':
        outputSegment(fid, indent, node.head)
        outputNode(fid, indent + 4, node.body)
    elif (type(node).__name__) == 'Switch':
        outputSegment(fid, indent, node.head)
        outputNode(fid, indent + 4, node.body)
        outputSegment(fid, indent, node.end_)
    elif (type(node).__name__) == 'SwitchCase':
        outputSegment(fid, indent, node.head)
        outputNode(fid, indent + 4, node.body)
    elif (type(node).__name__) == 'Statement':
        fprintf(fid, repmat(' ', 1, indent))
        if not isempty(node.keyword):
            fprintf(fid, '%s', node.keyword)
            if not isempty(node.rvalue):
                fprintf(fid, ' ')
            if not isempty(node.modifier):
                fprintf(fid, '(')
                for i in colon(1, numel(node.modifier)):
                    outputExpression(fid, indent, mparen(node.modifier, i))
                fprintf(fid, ')')
        if not isempty(node.lvalue):
            outputExpression(fid, indent, node.lvalue)
            fprintf(fid, ' = ')
        if not isempty(node.rvalue):
            outputExpression(fid, indent, node.rvalue)
            ffid = fopen('expr.txt', 'at')
            outputExpression(ffid, 0, node.rvalue)
            fprintf(ffid, '\\n')
            fclose(ffid)
            if isempty(node.keyword):
                fprintf(fid, ';')
        if not isempty(node.comment):
            if not isempty(node.keyword) or not isempty(node.lvalue) or not isempty(node.rvalue):
                fprintf(fid, ' ')
            fprintf(fid, '%s', node.comment)
        fprintf(fid, '\\n')
    elif (type(node).__name__) == 'ClassDef':
        outputSegment(fid, indent, node.head)
        outputNode(fid, indent + 4, node.property)
        outputNode(fid, indent + 4, node.method)
        outputSegment(fid, indent, node.end_)
    elif (type(node).__name__) == 'Properties':
        outputSegment(fid, indent, node.head)
        outputNode(fid, indent + 4, node.prop)
        outputSegment(fid, indent, node.end_)
    elif (type(node).__name__) == 'Methods':
        outputSegment(fid, indent, node.head)
        outputNode(fid, indent + 4, node.fun)
        outputSegment(fid, indent, node.end_)
    elif (type(node).__name__) == 'Variable':
        fprintf(fid, repmat(' ', 1, indent))
        fprintf(fid, '%s', node.name)
        if not isempty(node.type):
            fprintf(fid, ' %s', node.type)
        if not isempty(node.default):
            fprintf(fid, ' = ')
            outputExpression(fid, indent, node.default)
        if not isempty(node.comment):
            fprintf(fid, ' %s', node.comment)
        fprintf(fid, '\\n')
    else:
        error('unexpected node')
    return
def outputExpression(fid, indent, node): # retval: []
    nargin = 3
    if False and type(node).__name__:
        pass
    elif (type(node).__name__) == 'Literal':
        fprintf(fid, '%s', node.value)
    elif (type(node).__name__) == 'Identifier':
        fprintf(fid, '%s', node.identifier)
    elif (type(node).__name__) == 'Field':
        outputExpression(fid, indent, node.value)
        fprintf(fid, '.')
        if not isa(node.field, 'Identifier'):
            fprintf(fid, '(')
        outputExpression(fid, indent, node.field)
        if not isa(node.field, 'Identifier'):
            fprintf(fid, ')')
    elif (type(node).__name__) == 'Paren':
        fprintf(fid, '(')
        outputExpression(fid, indent, node.value)
        fprintf(fid, ')')
    elif (type(node).__name__) == 'Not':
        fprintf(fid, '~')
        outputExpression(fid, indent, node.value)
    elif (type(node).__name__) == 'Transpose':
        outputExpression(fid, indent, node.value)
        fprintf(fid, '.\'')
    elif (type(node).__name__) == 'Lambda':
        fprintf(fid, '@')
        if not (isempty(node.args) and isa(node.expr, 'Identifier')):
            fprintf(fid, '(')
            for i in colon(1, numel(node.args)):
                outputExpression(fid, indent, mparen(node.args, i))
                if i < numel(node.args):
                    fprintf(fid, ', ')
            fprintf(fid, ')')
        outputExpression(fid, indent, node.expr)
    elif (type(node).__name__) == 'Colon':
        if isempty(node.begin) and isempty(node.step) and isempty(node.end_):
            fprintf(fid, ':')
        elif isempty(node.step):
            outputExpression(fid, indent, node.begin)
            fprintf(fid, ' : ')
            outputExpression(fid, indent, node.end_)
        else:
            outputExpression(fid, indent, node.begin)
            fprintf(fid, ' : ')
            outputExpression(fid, indent, node.step)
            fprintf(fid, ' : ')
            outputExpression(fid, indent, node.end_)
    elif (type(node).__name__) == 'PIndex':
        outputExpression(fid, indent, node.value)
        fprintf(fid, '(')
        for i in colon(1, numel(node.index)):
            outputExpression(fid, indent, mparen(node.index, i))
            if i < numel(node.index):
                fprintf(fid, ', ')
        fprintf(fid, ')')
    elif (type(node).__name__) == 'BIndex':
        outputExpression(fid, indent, node.value)
        fprintf(fid, '{')
        for i in colon(1, numel(node.index)):
            outputExpression(fid, indent, mparen(node.index, i))
            if i < numel(node.index):
                fprintf(fid, ', ')
        fprintf(fid, '}')
    elif (type(node).__name__) == 'MatrixLine':
        for i in colon(1, numel(node.item)):
            outputExpression(fid, indent, mparen(node.item, i))
            if i < numel(node.item):
                fprintf(fid, ', ')
    elif (type(node).__name__) == 'Matrix':
        fprintf(fid, '[')
        if numel(node.line) > 1:
            fprintf(fid, '\\n')
            fprintf(fid, '%s', repmat(' ', 1, indent + 4))
        for i in colon(1, numel(node.line)):
            outputExpression(fid, indent, mparen(node.line, i))
            if numel(node.line) > 1:
                fprintf(fid, '\\n')
                fprintf(fid, '%s', repmat(' ', 1, indent + 4))
        fprintf(fid, ']')
    elif (type(node).__name__) == 'Cell':
        fprintf(fid, '{')
        if numel(node.line) > 1:
            fprintf(fid, '\\n')
        for i in colon(1, numel(node.line)):
            outputExpression(fid, indent, mparen(node.line, i))
            if numel(node.line) > 1:
                fprintf(fid, '\\n')
        fprintf(fid, '}')
    elif (type(node).__name__) == 'LT':
        outputExpression(fid, indent, node.a)
        fprintf(fid, ' < ')
        outputExpression(fid, indent, node.b)
    elif (type(node).__name__) == 'GT':
        outputExpression(fid, indent, node.a)
        fprintf(fid, ' > ')
        outputExpression(fid, indent, node.b)
    elif (type(node).__name__) == 'LE':
        outputExpression(fid, indent, node.a)
        fprintf(fid, ' <= ')
        outputExpression(fid, indent, node.b)
    elif (type(node).__name__) == 'GE':
        outputExpression(fid, indent, node.a)
        fprintf(fid, ' >= ')
        outputExpression(fid, indent, node.b)
    elif (type(node).__name__) == 'EQ':
        outputExpression(fid, indent, node.a)
        fprintf(fid, ' == ')
        outputExpression(fid, indent, node.b)
    elif (type(node).__name__) == 'NE':
        outputExpression(fid, indent, node.a)
        fprintf(fid, ' ~= ')
        outputExpression(fid, indent, node.b)
    elif (type(node).__name__) == 'Plus':
        outputExpression(fid, indent, node.a)
        fprintf(fid, ' + ')
        outputExpression(fid, indent, node.b)
    elif (type(node).__name__) == 'Minus':
        outputExpression(fid, indent, node.a)
        fprintf(fid, ' - ')
        outputExpression(fid, indent, node.b)
    elif (type(node).__name__) == 'And':
        outputExpression(fid, indent, node.a)
        fprintf(fid, ' && ')
        outputExpression(fid, indent, node.b)
    elif (type(node).__name__) == 'Or':
        outputExpression(fid, indent, node.a)
        fprintf(fid, ' || ')
        outputExpression(fid, indent, node.b)
    elif (type(node).__name__) == 'MTimes':
        outputExpression(fid, indent, node.a)
        fprintf(fid, ' * ')
        outputExpression(fid, indent, node.b)
    elif (type(node).__name__) == 'Modifier':
        if not isempty(node.lvalue):
            outputExpression(fid, indent, node.lvalue)
            fprintf(fid, '=')
        outputExpression(fid, indent, node.rvalue)
    elif (type(node).__name__) == 'Dismiss':
        fprintf(fid, '~')
    else:
        error('unexpected node')
    return
