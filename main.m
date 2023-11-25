clc();
clear();
close('all');
table = [
    {'and', '&&'}
    {'or', '||'}
    {'times', '.*'}
    {'rdivide', './'}
    {'ldivide', '.\'}
    {'transpose', '.'''}
    {'eq', '=='}
    {'ne', '~='}
    {'le', '<='}
    {'ge', '>='}
    {'lparen', '('}
    {'rparen', ')'}
    {'lsquare', '['}
    {'rsquare', ']'}
    {'lbrace', '{'}
    {'rbrace', '}'}
    {'semi', ';'}
    {'colon', ':'}
    {'comma', ','}
    {'plus', '+'}
    {'minus', '-'}
    {'mtimes', '*'}
    {'mrdivide', '/'}
    {'mldivide', '\'}
    {'lt', '<'}
    {'gt', '>'}
    {'assign', '='}
    {'not', '~'}
    {'field', '.'}
    {'lambda', '@'}
    {'newline', newline}
    ];
[testdir, pydir] = configure();
if isfolder(pydir + "/nodes")
    rmdir(pydir + "/nodes", 's');
end
mkdir(pydir + "/nodes");
fid = fopen(pydir + "/main.py", 'wt+');
files = dir('mcst');
for i = 1 : numel(files)
    if ~(startsWith(files(i).name, '.') || endsWith(files(i).name, '.asv'))
        node = parseFile("mcst/" + files(i).name, table);
        output(testdir + "/" + files(i).name, node);
        m2py(pydir + "/nodes/" + files(i).name(1 : end - 2) + ".py", node);
        fprintf(fid, 'from test_m.py.nodes.%s import %s\n', files(i).name(1 : end - 2), files(i).name(1 : end - 2));
        compareFile("mcst/" + files(i).name, testdir + "/" + files(i).name);
    end
end
fprintf(fid, 'from test_m.py.output import output\n');
fprintf(fid, 'from test_m.py.m2py import m2py\n');
fclose(fid);
if isfile(pydir + "/output.py")
    delete(pydir + "/output.py");
end
fid = fopen(pydir + "/m2py.py", 'wt+');
fprintf(fid, 'from test_m.py.nodes.Segment import Segment\n');
fprintf(fid, 'from test_m.py.nodes.Matrix import Matrix\n');
fprintf(fid, 'from test_m.py.nodes.MatrixLine import MatrixLine\n');
fclose(fid);
%
node = parseFile('main.m', table);
output(testdir + "/main.m", node);
m2py(pydir + "/main.py", node);
compareFile('main.m', testdir + "/main.m");
%
node = parseFile('output.m', table);
output(testdir + "/output.m", node);
m2py(pydir + "/output.py", node);
compareFile('output.m', testdir + "/output.m");
%
output(testdir + "/List.m", parseFile('List.m', table));
compareFile('List.m', testdir + "/List.m");
%
node = parseFile('m2py.m', table);
output(testdir + "/m2py.m", node);
m2py(pydir + "/m2py.py", node);
compareFile('m2py.m', testdir + "/m2py.m");
function compareFile(file1, file2)
    content1 = readFile(file1);
    content2 = readFile(file2);
    content1 = split(replace(content1, ' ', ''), newline);
    content2 = split(replace(content2, ' ', ''), newline);
    if numel(content1) ~= numel(content2)
        warning('length of %s not equal with length of %s', file1, file2);
        return
    end
    d = find(cellfun(@(a, b)~strcmp(a, b), content1, content2));
    if ~isempty(d)
        warning('%s vs %s: diff found in line %s\n', file1, file2, mat2str(d));
        return
    end
    disp(file1 + " vs " + file2 + ": equal without space");
end
function content = readFile(filename)
    fid = fopen(filename);
    content = native2unicode(fread(fid).');
    fclose(fid);
    while contains(content, sprintf('\r\n'))
        content = replace(content, sprintf('\r\n'), newline);
    end
end
function node = parseFile(filename, table)
    content = readFile(filename);
    node = program(tokenize(content, table));
end
function tokens = tokenize(s, table)
    j = 1;
    tokens = List();
    count = 0;
    lastToken = '';
    while j < numel(s)
        count = count + 1;
        [j, type, token] = nextToken(s, j, table, lastToken);
        tokens.append(Token(type, token));
        lastToken = type;
    end
    tokens = tokens.toList([]);
end
function [j, type, token] = nextToken(s, j, table, lastToken)
    while j <= numel(s) && s(j) == ' '
        j = j + 1;
    end
    for i = 1 : size(table, 1)
        if j + numel(table{i, 2}) - 1 <= numel(s) && strcmp(s(j : j + numel(table{i, 2}) - 1), table{i, 2})
            type = table{i, 1};
            token = table{i, 2};
            j = j + numel(table{i, 2});
            return
        end
    end
    if s(j) == ''''
        if strcmp(lastToken, 'identifier') || strcmp(lastToken, 'number')
            type = 'ctranspose';
            token = '''';
            j = j + 1;
            return
        end
        i = j;
        j = j + 1;
        while j <= numel(s) && ~(s(j) == '''' && (j + 1 > numel(s) || s(j + 1) ~= ''''))
            j = j + 1 + (s(j) == '''');
        end
        j = j + 1;
        type = 'chars';
        token = s(i : j - 1);
        return
    end
    if s(j) == '"'
        i = j;
        j = j + 1;
        while j <= numel(s) && ~(s(j) == '"' && (j + 1 > numel(s) || s(j + 1) ~= '"'))
            j = j + 1 + (s(j) == '"');
        end
        j = j + 1;
        type = 'string';
        token = s(i : j - 1);
        return
    end
    if ('a' <= s(j) && s(j) <= 'z') || ('A' <= s(j) && s(j) <= 'Z')
        i = j;
        while j <= numel(s) && (('a' <= s(j) && s(j) <= 'z') || ('A' <= s(j) && s(j) <= 'Z') || ('0' <= s(j) && s(j) <= '9') || s(j) == '_')
            j = j + 1;
        end
        token = s(i : j - 1);
        if ismember(token, {'return', 'break', 'continue', 'if', 'elseif', 'for', 'else', 'while', 'end', 'function', 'switch', 'case', 'otherwise', 'classdef', 'properties', 'methods'})
            type = 'keyword';
        else
            type = 'identifier';
        end
        return
    end
    if ('0' <= s(j) && s(j) <= '9') || (s(j) == '.' && j + 1 <= numel(s) && '0' <= s(j + 1) && s(j + 1) <= '9')
        % [int].[frac]e[sign][exp]
        i = j;
        dot = false;
        exp = false;
        sign = false;
        while j <= numel(s) && (('0' <= s(j) && s(j) <= '9') || (~dot && ~exp && s(j) == '.') || (~exp && s(j) == 'e') || (exp && ~sign && (s(j) == '-' || s(j) == '+')))
            j = j + 1;
        end
        type = 'number';
        token = s(i : j - 1);
        return
    end
    if s(j) == '%'
        i = j;
        while j <= numel(s) && s(j) ~= newline
            j = j + 1;
        end
        type = 'comment';
        token = s(i : j - 1);
        return
    end
    error('unknown token');
end
function [i, node] = field(tokens, i)
    switch tokens(i).type
        case 'identifier'
            node = Identifier(tokens(i).token);
            i = i + 1;
        case 'lparen'
            i = i + 1;
            [i, node] = expression(tokens, i);
            if ~strcmp(tokens(i).type, 'rparen')
                error('unexpected token');
            end
            i = i + 1;
        otherwise
            error('unexpected token');
    end
end
function [i, node] = colonOrExpression(tokens, i)
    if strcmp(tokens(i).type, 'colon')
        node = Colon(Expression.empty(), Expression.empty(), Expression.empty());
        i = i + 1;
    else
        [i, node] = expression(tokens, i);
    end
end
function [i, args] = subscript(tokens, i, endToken)
    args = List();
    while ~strcmp(tokens(i).type, endToken)
        [i, arg] = colonOrExpression(tokens, i);
        args.append(arg);
        if strcmp(tokens(i).type, 'comma')
            i = i + 1;
        elseif ~strcmp(tokens(i).type, endToken)
            error('unexpected token');
        end
    end
    args = args.toList(Expression.empty());
end
function [i, node] = reference(tokens, i)
    if i <= 0 || i > numel(tokens)
        error('index out of range');
    end
    if ~strcmp(tokens(i).type, 'identifier')
        error('must be identifier');
    end
    node = Identifier(tokens(i).token);
    i = i + 1;
    while i <= numel(tokens)
        switch tokens(i).type
            case 'field'
                i = i + 1;
                [i, node2] = field(tokens, i);
                node = Field(node, node2);
            case 'lparen'
                i = i + 1;
                [i, args] = subscript(tokens, i, 'rparen');
                i = i + 1;
                node = PIndex(node, args);
            case 'lbrace'
                i = i + 1;
                [i, args] = subscript(tokens, i, 'rbrace');
                i = i + 1;
                node = BIndex(node, args);
            otherwise
                break
        end
    end
end
function [i, node] = matrixLine(tokens, i)
    args = List();
    if strcmp(tokens(i).type, 'comma')
        i = i + 1;
    end
    while ~ismember(tokens(i).type, {'rsquare', 'rbrace', 'newline', 'semi'})
        if strcmp(tokens(i).type, 'not') && ismember(tokens(i + 1).type, {'rsquare', 'rbrace', 'newline', 'semi', 'comma'})
            arg = Dismiss();
            i = i + 1;
        else
            [i, arg] = expression(tokens, i);
        end
        args.append(arg);
        if strcmp(tokens(i).type, 'comma')
            i = i + 1;
        end
    end
    args = args.toList(Expression.empty());
    if isempty(args)
        node = MatrixLine.empty();
    else
        node = MatrixLine(args);
    end
end
function [i, node] = matrixLiteral(tokens, i, left, right, class_)
    if ~strcmp(tokens(i).type, left)
        error(['must be ', left]);
    end
    i = i + 1;
    args = List();
    while strcmp(tokens(i).type, 'semi') || strcmp(tokens(i).type, 'newline')
        i = i + 1;
    end
    while ~strcmp(tokens(i).type, right)
        [i, arg] = matrixLine(tokens, i);
        args.append(arg);
        while strcmp(tokens(i).type, 'semi') || strcmp(tokens(i).type, 'newline')
            i = i + 1;
        end
    end
    i = i + 1;
    node = class_(args.toList(MatrixLine.empty()));
end
function [i, node] = lambda_(tokens, i)
    if ~strcmp(tokens(i).type, 'lambda')
        error('unexpected token');
    end
    i = i + 1;
    if strcmp(tokens(i).type, 'lparen')
        i = i + 1;
        args = List();
        while ~strcmp(tokens(i).type, 'rparen')
            if ~strcmp(tokens(i).type, 'identifier')
                error('unexpected token');
            end
            arg = Identifier(tokens(i).token);
            args.append(arg);
            i = i + 1;
            if strcmp(tokens(i).type, 'comma')
                i = i + 1;
            end
        end
        i = i + 1;
        args = args.toList(Identifier.empty());
    else
        args = Identifier.empty();
    end
    [i, node] = expression(tokens, i);
    node = Lambda(args, node);
end
function [i, node] = operand(tokens, i)
    switch tokens(i).type
        case {'chars', 'string', 'number'}
            node = Literal(tokens(i).token);
            i = i + 1;
        case 'lambda'
            [i, node] = lambda_(tokens, i);
        case 'lparen'
            i = i + 1;
            [i, node] = expression(tokens, i);
            if ~strcmp(tokens(i).type, 'rparen')
                error('must be rparen');
            end
            i = i + 1;
            node = Paren(node);
        case 'lsquare'
            [i, node] = matrixLiteral(tokens, i, 'lsquare', 'rsquare', @Matrix);
        case 'lbrace'
            [i, node] = matrixLiteral(tokens, i, 'lbrace', 'rbrace', @Cell);
        case 'identifier'
            [i, node] = reference(tokens, i);
        case 'keyword'
            if ~strcmp(tokens(i).token, 'end')
                error('must be end');
            end
            node = Identifier('end');
            i = i + 1;
        otherwise
            error('unexpected token');
    end
end
function [i, node] = transPower(tokens, i)
    [i, node] = operand(tokens, i);
    while i <= numel(tokens)
        switch tokens(i).type
            case 'transpose'
                i = i + 1;
                node = Transpose(node);
            otherwise
                break
        end
    end
end
function [i, node] = unary(tokens, i)
    switch tokens(i).type
        case 'plus'
            i = i + 1;
            [i, node] = unary(tokens, i);
        case 'minus'
            i = i + 1;
            [i, node] = unary(tokens, i);
            node = Negative(node);
        case 'not'
            i = i + 1;
            [i, node] = unary(tokens, i);
            node = Not(node);
        otherwise
            [i, node] = transPower(tokens, i);
    end
end
function [i, node] = wrap(fun1, fun2, tokens, i, node)
    [i, node2] = fun2(tokens, i);
    node = fun1(node, node2);
end
function [i, node] = mulDiv(tokens, i)
    map = dict();
    map = put(map, 'times', @(tokens, i, node)wrap(@Times, @unary, tokens, i, node));
    map = put(map, 'ldivide', @(tokens, i, node)wrap(@LDivide, @unary, tokens, i, node));
    map = put(map, 'rdivide', @(tokens, i, node)wrap(@RDivide, @unary, tokens, i, node));
    map = put(map, 'mtimes', @(tokens, i, node)wrap(@MTimes, @unary, tokens, i, node));
    map = put(map, 'mldivide', @(tokens, i, node)wrap(@MLDivide, @unary, tokens, i, node));
    map = put(map, 'mrdivide', @(tokens, i, node)wrap(@MRDivide, @unary, tokens, i, node));
    [i, node] = lookAhead(tokens, i, @unary, map);
end
function [i, node] = lookAhead(tokens, i, next, map)
    [i, node] = next(tokens, i);
    while i <= numel(tokens) && isKey(map, tokens(i).type)
        fun = map(tokens(i).type);
        i = i + 1;
        [i, node] = fun(tokens, i, node);
    end
end
function [i, node] = addSub(tokens, i)
    map = dict();
    map = put(map, 'plus', @(tokens, i, node)wrap(@Plus, @mulDiv, tokens, i, node));
    map = put(map, 'minus', @(tokens, i, node)wrap(@Minus, @mulDiv, tokens, i, node));
    [i, node] = lookAhead(tokens, i, @mulDiv, map);
end
function [i, node] = colonOperator(tokens, i)
    [i, node] = addSub(tokens, i);
    if i <= numel(tokens) && strcmp(tokens(i).type, 'colon')
        i = i + 1;
        [i, node2] = addSub(tokens, i);
        if i <= numel(tokens) && strcmp(tokens(i).type, 'colon')
            i = i + 1;
            [i, node3] = addSub(tokens, i);
            node = Colon(node, node2, node3);
        else
            node = Colon(node, Expression.empty(), node2);
        end
    end
end
function [i, node] = compare(tokens, i)
    map = dict();
    map = put(map, 'le', @(tokens, i, node)wrap(@LE, @colonOperator, tokens, i, node));
    map = put(map, 'ge', @(tokens, i, node)wrap(@GE, @colonOperator, tokens, i, node));
    map = put(map, 'lt', @(tokens, i, node)wrap(@LT, @colonOperator, tokens, i, node));
    map = put(map, 'gt', @(tokens, i, node)wrap(@GT, @colonOperator, tokens, i, node));
    map = put(map, 'eq', @(tokens, i, node)wrap(@EQ, @colonOperator, tokens, i, node));
    map = put(map, 'ne', @(tokens, i, node)wrap(@NE, @colonOperator, tokens, i, node));
    [i, node] = lookAhead(tokens, i, @colonOperator, map);
end
function [i, node] = logicalAnd(tokens, i)
    map = dict();
    map = put(map, 'and', @(tokens, i, node)wrap(@And, @compare, tokens, i, node));
    [i, node] = lookAhead(tokens, i, @compare, map);
end
function [i, node] = logicalOr(tokens, i)
    map = dict();
    map = put(map, 'or', @(tokens, i, node)wrap(@Or, @logicalAnd, tokens, i, node));
    [i, node] = lookAhead(tokens, i, @logicalAnd, map);
end
function [i, node] = expression(tokens, i)
    [i, node] = logicalOr(tokens, i);
end
function [i, node] = modifier(tokens, i)
    if ~strcmp(tokens(i).type, 'identifier')
        error('unexpected token');
    end
    rvalue = Identifier(tokens(i).token);
    i = i + 1;
    if strcmp(tokens(i).type, 'assign')
        i = i + 1;
        lvalue = rvalue;
        rvalue = Identifier(tokens(i).token);
        i = i + 1;
    else
        lvalue = Identifier.empty();
    end
    node = Modifier(lvalue, rvalue);
end
function [i, node] = statement(tokens, i)
    switch tokens(i).type
        case {'newline', 'semi'}
            error('unexpected token');
        case 'keyword'
            keyword = tokens(i).token;
            i = i + 1;
        otherwise
            keyword = '';
    end
    if ismember(keyword, {'properties', 'classdef', 'methods'}) && strcmp(tokens(i).type, 'lparen')
        i = i + 1;
        modifiers = List();
        while ~strcmp(tokens(i).type, 'rparen')
            [i, mod] = modifier(tokens, i);
            modifiers.append(mod);
            if strcmp(tokens(i).type, 'comma')
                i = i + 1;
            end
        end
        i = i + 1;
        modifiers = modifiers.toList(Modifier.empty());
    else
        modifiers = Modifier.empty();
    end
    if i <= numel(tokens) && ~(strcmp(tokens(i).type, 'comment') || strcmp(tokens(i).type, 'newline'))
        [i, rvalue] = expression(tokens, i);
        if i <= numel(tokens) && strcmp(tokens(i).type, 'assign')
            i = i + 1;
            lvalue = rvalue;
            [i, rvalue] = expression(tokens, i);
        else
            lvalue = Expression.empty();
        end
        if i <= numel(tokens) && (strcmp(tokens(i).type, 'semi') || strcmp(tokens(i).type, 'comma'))
            i = i + 1;
        end
    else
        lvalue = Expression.empty();
        rvalue = Expression.empty();
    end
    if i <= numel(tokens) && strcmp(tokens(i).type, 'comment')
        comment = tokens(i).token;
        i = i + 1;
    else
        comment = [];
    end
    node = Statement(keyword, modifiers, lvalue, rvalue, comment);
    while i <= numel(tokens) && (strcmp(tokens(i).type, 'semi') || strcmp(tokens(i).type, 'comma') || strcmp(tokens(i).type, 'newline'))
        i = i + 1;
    end
end
function [i, node] = variableDeclare(tokens, i)
    % name type = default
    if ~strcmp(tokens(i).type, 'identifier')
        error('unexpected token');
    end
    name = tokens(i).token;
    i = i + 1;
    if strcmp(tokens(i).type, 'identifier')
        type = tokens(i).token;
        i = i + 1;
    else
        type = '';
    end
    if strcmp(tokens(i).type, 'assign')
        i = i + 1;
        [i, expr] = expression(tokens, i);
    else
        expr = Expression.empty();
    end
    if i <= numel(tokens) && strcmp(tokens(i).type, 'comment')
        comment = tokens(i).token;
        i = i + 1;
    else
        comment = [];
    end
    node = Variable(name, type, expr, comment);
    while i <= numel(tokens) && (strcmp(tokens(i).type, 'semi') || strcmp(tokens(i).type, 'newline'))
        i = i + 1;
    end
end
function blocks = program(tokens)
    blocks = List();
    i = 1;
    while i <= numel(tokens)
        while strcmp(tokens(i).type, 'semi') || strcmp(tokens(i).type, 'newline')
            i = i + 1;
        end
        [i, blk] = block(tokens, i);
        blocks.append(blk);
    end
    blocks = blocks.toList(Segment.empty());
end
function [i, node] = controlBlock(tokens, i, token, class_)
    if ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, token))
        error(['expect ', token]);
    end
    [i, head] = statement(tokens, i);
    args = List();
    while ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'end'))
        [i, arg] = block(tokens, i);
        args.append(arg);
    end
    [i, end_] = statement(tokens, i);
    node = class_(head, args.toList(Segment.empty()), end_);
end
function [i, node] = ifBlock(tokens, i)
    if ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'if'))
        error('expect if');
    end
    branch = List();
    while ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'end'))
        [i, head] = statement(tokens, i);
        args = List();
        while ~(strcmp(tokens(i).type, 'keyword') && ismember(tokens(i).token, {'end', 'else', 'elseif'}))
            [i, arg] = block(tokens, i);
            args.append(arg);
        end
        branch.append(IfBranch(head, args.toList(Statement.empty())));
    end
    [i, end_] = statement(tokens, i);
    node = If(branch.toList(IfBranch.empty()), end_);
end
function [i, node] = switchBlock(tokens, i)
    if ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'switch'))
        error('expect switch');
    end
    [i, expr] = statement(tokens, i);
    branch = List();
    while ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'end'))
        [i, head] = statement(tokens, i);
        args = List();
        while ~(strcmp(tokens(i).type, 'keyword') && ismember(tokens(i).token, {'end', 'case', 'otherwise'}))
            [i, arg] = block(tokens, i);
            args.append(arg);
        end
        branch.append(SwitchCase(head, args.toList(Segment.empty())));
    end
    [i, end_] = statement(tokens, i);
    node = Switch(expr, branch.toList(SwitchCase.empty()), end_);
end
function [i, node] = propertiesBlock(tokens, i)
    if ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'properties'))
        error('expect properties');
    end
    [i, head] = statement(tokens, i);
    props = List();
    while ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'end'))
        [i, prop] = variableDeclare(tokens, i);
        props.append(prop);
    end
    [i, end_] = statement(tokens, i);
    node = Properties(head, props.toList(Statement.empty()), end_);
end
function [i, node] = methodsBlock(tokens, i)
    if ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'methods'))
        error('expect methods');
    end
    [i, head] = statement(tokens, i);
    meth = List();
    while ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'end'))
        if ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'function'))
            error('unexpected token');
        end
        [i, fun] = block(tokens, i);
        meth.append(fun);
    end
    [i, end_] = statement(tokens, i);
    node = Methods(head, meth.toList(Function.empty()), end_);
end
function [i, node] = classBlock(tokens, i)
    if ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'classdef'))
        error('expect classdef');
    end
    [i, head] = statement(tokens, i);
    property = List();
    method = List();
    while ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'end'))
        if ~strcmp(tokens(i).type, 'keyword')
            error('unexpected token');
        end
        switch tokens(i).token
            case 'properties'
                [i, prop] = propertiesBlock(tokens, i);
                property.append(prop);
            case 'methods'
                [i, meth] = methodsBlock(tokens, i);
                method.append(meth);
            otherwise
                error('unexpected keyword');
        end
    end
    property = property.toList(Properties.empty());
    method = method.toList(Methods.empty());
    [i, end_] = statement(tokens, i);
    node = ClassDef(head, property, method, end_);
end
function [i, node] = block(tokens, i)
    if ~strcmp(tokens(i).type, 'keyword')
        [i, node] = statement(tokens, i);
        return
    end
    switch tokens(i).token
        case {'return', 'continue', 'break'}
            [i, node] = statement(tokens, i);
        case 'for'
            [i, node] = controlBlock(tokens, i, 'for', @For);
        case 'while'
            [i, node] = controlBlock(tokens, i, 'while', @While);
        case 'function'
            [i, node] = controlBlock(tokens, i, 'function', @Function);
        case 'if'
            [i, node] = ifBlock(tokens, i);
        case 'switch'
            [i, node] = switchBlock(tokens, i);
        case 'classdef'
            [i, node] = classBlock(tokens, i);
        otherwise
            error('unexpected keyword');
    end
    while i <= numel(tokens) && (strcmp(tokens(i).type, 'semi') || strcmp(tokens(i).type, 'newline') || strcmp(tokens(i).type, 'comma'))
        i = i + 1;
    end
end
