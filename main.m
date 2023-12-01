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
%
% fieldExpr           -> 'identifier'
%                      | '(' expression ')'
% field               -> '.' fieldExpr
% pindex              -> '(' commaSeparatedExpr ')'
% bindex              -> '{' commaSeparatedExpr '}'
% subsref             -> field subsref
%                      | pindex subsref
%                      | bindex subsref
%                      | ''
% operand             -> 'identifier' subsref
%                      | 'literal'
%                      | '(' expression ')'
% powerTrans2         -> '.''' powerTrans2
%                      | '.^' powerTrans2
%                      | '''' powerTrans2
%                      | '^' powerTrans2
%                      | ''
% powerTrans          -> operand powerTrans2
% unary               -> '+' unary
%                      | '-' unary
%                      | '~' unary
%                      | powerTrans
% mulDiv2             -> '.*' unary mulDiv2
%                      | './' unary mulDiv2
%                      | '.\' unary mulDiv2
%                      | '*' unary mulDiv2
%                      | '/' unary mulDiv2
%                      | '\' unary mulDiv2
%                      | ''
% mulDiv              -> unary mulDiv2
% addSub2             -> '+' mulDiv addSub2
%                      | '-' mulDiv addSub2
%                      | ''
% addSub              -> mulDiv addSub2
% colon3              -> ':' addSub
%                      | ''
% colon2              -> ':' addSub colon3
%                      | ''
% colon               -> addSub colon2
% compare2            -> '<' colon compare2
%                      | '<=' colon compare2
%                      | '>' colon compare2
%                      | '>=' colon compare2
%                      | '==' colon compare2
%                      | '~=' colon compare2
%                      | ''
% compare             -> colon compare2
% elemAnd2            -> '&' compare elemAnd2
%                      | ''
% elemAnd             -> compare elemAnd2
% elemOr2             -> '|' elemAnd elemOr2
%                      | ''
% elemOr              -> elemAnd elemOr2
% logiAnd2            -> '&&' elemOr logiAnd2
%                      | ''
% logiAnd             -> elemOr logiAnd2
% logiOr2             -> '||' logiAnd logiOr2
%                      | ''
% logiOr              -> logiAnd logiOr2
% expression          -> logiOr
% commaSeparatedExpr2 -> ',' expression
%                      | ''
% commaSeparatedExpr  -> expression commaSeparatedExpr2
% entry               -> expression #
% 
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
    tokens = TokenList(tokens.toList([]));
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
function node = field(tokens)
    switch tokens.get().type
        case 'identifier'
            node = Identifier(tokens.get().token);
            tokens.next();
        case 'lparen'
            tokens.next();
            node = expression(tokens);
            if ~strcmp(tokens.get().type, 'rparen')
                error('unexpected token');
            end
            tokens.next();
        otherwise
            error('unexpected token');
    end
end
function node = colonOrExpression(tokens)
    if strcmp(tokens.get().type, 'colon')
        node = Colon(Expression.empty(), Expression.empty(), Expression.empty());
        tokens.next();
    else
        node = expression(tokens);
    end
end
function args = subscript(tokens, endToken)
    args = List();
    while ~strcmp(tokens.get().type, endToken)
        arg = colonOrExpression(tokens);
        args.append(arg);
        if strcmp(tokens.get().type, 'comma')
            tokens.next();
        elseif ~strcmp(tokens.get().type, endToken)
            error('unexpected token');
        end
    end
    args = args.toList(Expression.empty());
end
function node = reference(tokens)
    if ~strcmp(tokens.get().type, 'identifier')
        error('must be identifier');
    end
    node = Identifier(tokens.get().token);
    tokens.next();
    while ~isempty(tokens.get())
        switch tokens.get().type
            case 'field'
                tokens.next();
                node2 = field(tokens);
                node = Field(node, node2);
            case 'lparen'
                tokens.next();
                args = subscript(tokens, 'rparen');
                tokens.next();
                node = PIndex(node, args);
            case 'lbrace'
                tokens.next();
                args = subscript(tokens, 'rbrace');
                tokens.next();
                node = BIndex(node, args);
            otherwise
                break
        end
    end
end
function node = matrixLine(tokens)
    args = List();
    if strcmp(tokens.get().type, 'comma')
        tokens.next();
    end
    while ~ismember(tokens.get().type, {'rsquare', 'rbrace', 'newline', 'semi'})
        if strcmp(tokens.get().type, 'not') && ismember(tokens.ahead().type, {'rsquare', 'rbrace', 'newline', 'semi', 'comma'})
            arg = Dismiss();
            tokens.next();
        else
            arg = expression(tokens);
        end
        args.append(arg);
        if strcmp(tokens.get().type, 'comma')
            tokens.next();
        end
    end
    args = args.toList(Expression.empty());
    if isempty(args)
        node = MatrixLine.empty();
    else
        node = MatrixLine(args);
    end
end
function node = matrixLiteral(tokens, left, right, class_)
    if ~strcmp(tokens.get().type, left)
        error(['must be ', left]);
    end
    tokens.next();
    args = List();
    while strcmp(tokens.get().type, 'semi') || strcmp(tokens.get().type, 'newline')
        tokens.next();
    end
    while ~strcmp(tokens.get().type, right)
        arg = matrixLine(tokens);
        args.append(arg);
        while strcmp(tokens.get().type, 'semi') || strcmp(tokens.get().type, 'newline')
            tokens.next();
        end
    end
    tokens.next();
    node = class_(args.toList(MatrixLine.empty()));
end
function node = lambda_(tokens)
    if ~strcmp(tokens.get().type, 'lambda')
        error('unexpected token');
    end
    tokens.next();
    if strcmp(tokens.get().type, 'lparen')
        tokens.next();
        args = List();
        while ~strcmp(tokens.get().type, 'rparen')
            if ~strcmp(tokens.get().type, 'identifier')
                error('unexpected token');
            end
            arg = Identifier(tokens.get().token);
            args.append(arg);
            tokens.next();
            if strcmp(tokens.get().type, 'comma')
                tokens.next();
            end
        end
        tokens.next();
        args = args.toList(Identifier.empty());
    else
        args = Identifier.empty();
    end
    node = expression(tokens);
    node = Lambda(args, node);
end
function node = operand(tokens)
    switch tokens.get().type
        case {'chars', 'string', 'number'}
            node = Literal(tokens.get().token);
            tokens.next();
        case 'lambda'
            node = lambda_(tokens);
        case 'lparen'
            tokens.next();
            node = expression(tokens);
            if ~strcmp(tokens.get().type, 'rparen')
                error('must be rparen');
            end
            tokens.next();
            node = Paren(node);
        case 'lsquare'
            node = matrixLiteral(tokens, 'lsquare', 'rsquare', @Matrix);
        case 'lbrace'
            node = matrixLiteral(tokens, 'lbrace', 'rbrace', @Cell);
        case 'identifier'
            node = reference(tokens);
        case 'keyword'
            if ~strcmp(tokens.get().token, 'end')
                error('must be end');
            end
            node = Identifier('end');
            tokens.next();
        otherwise
            error('unexpected token');
    end
end
function node = transPower(tokens)
    node = operand(tokens);
    while ~isempty(tokens.get())
        switch tokens.get().type
            case 'transpose'
                tokens.next();
                node = Transpose(node);
            otherwise
                break
        end
    end
end
function node = unary(tokens)
    switch tokens.get().type
        case 'plus'
            tokens.next();
            node = unary(tokens);
        case 'minus'
            tokens.next();
            node = unary(tokens);
            node = Negative(node);
        case 'not'
            tokens.next();
            node = unary(tokens);
            node = Not(node);
        otherwise
            node = transPower(tokens);
    end
end
function node = wrap(fun1, fun2, tokens, node)
    node2 = fun2(tokens);
    node = fun1(node, node2);
end
function node = mulDiv(tokens)
    map = dict();
    map = put(map, 'times', @(tokens, node)wrap(@Times, @unary, tokens, node));
    map = put(map, 'ldivide', @(tokens, node)wrap(@LDivide, @unary, tokens, node));
    map = put(map, 'rdivide', @(tokens, node)wrap(@RDivide, @unary, tokens, node));
    map = put(map, 'mtimes', @(tokens, node)wrap(@MTimes, @unary, tokens, node));
    map = put(map, 'mldivide', @(tokens, node)wrap(@MLDivide, @unary, tokens, node));
    map = put(map, 'mrdivide', @(tokens, node)wrap(@MRDivide, @unary, tokens, node));
    node = lookAhead(tokens, @unary, map);
end
function node = lookAhead(tokens, next, map)
    node = next(tokens);
    while ~isempty(tokens.get()) && isKey(map, tokens.get().type)
        fun = map(tokens.get().type);
        tokens.next();
        node = fun(tokens, node);
    end
end
function node = addSub(tokens)
    map = dict();
    map = put(map, 'plus', @(tokens, node)wrap(@Plus, @mulDiv, tokens, node));
    map = put(map, 'minus', @(tokens, node)wrap(@Minus, @mulDiv, tokens, node));
    node = lookAhead(tokens, @mulDiv, map);
end
function node = colonOperator(tokens)
    node = addSub(tokens);
    if ~isempty(tokens.get()) && strcmp(tokens.get().type, 'colon')
        tokens.next();
        node2 = addSub(tokens);
        if ~isempty(tokens.get()) && strcmp(tokens.get().type, 'colon')
            tokens.next();
            node3 = addSub(tokens);
            node = Colon(node, node2, node3);
        else
            node = Colon(node, Expression.empty(), node2);
        end
    end
end
function node = compare(tokens)
    map = dict();
    map = put(map, 'le', @(tokens, node)wrap(@LE, @colonOperator, tokens, node));
    map = put(map, 'ge', @(tokens, node)wrap(@GE, @colonOperator, tokens, node));
    map = put(map, 'lt', @(tokens, node)wrap(@LT, @colonOperator, tokens, node));
    map = put(map, 'gt', @(tokens, node)wrap(@GT, @colonOperator, tokens, node));
    map = put(map, 'eq', @(tokens, node)wrap(@EQ, @colonOperator, tokens, node));
    map = put(map, 'ne', @(tokens, node)wrap(@NE, @colonOperator, tokens, node));
    node = lookAhead(tokens, @colonOperator, map);
end
function node = logicalAnd(tokens)
    map = dict();
    map = put(map, 'and', @(tokens, node)wrap(@And, @compare, tokens, node));
    node = lookAhead(tokens, @compare, map);
end
function node = logicalOr(tokens)
    map = dict();
    map = put(map, 'or', @(tokens, node)wrap(@Or, @logicalAnd, tokens, node));
    node = lookAhead(tokens, @logicalAnd, map);
end
function node = expression(tokens)
    node = logicalOr(tokens);
end
function node = modifier(tokens)
    if ~strcmp(tokens.get().type, 'identifier')
        error('unexpected token');
    end
    rvalue = Identifier(tokens.get().token);
    tokens.next();
    if strcmp(tokens.get().type, 'assign')
        tokens.next();
        lvalue = rvalue;
        rvalue = Identifier(tokens.get().token);
        tokens.next();
    else
        lvalue = Identifier.empty();
    end
    node = Modifier(lvalue, rvalue);
end
function node = statement(tokens)
    switch tokens.get().type
        case {'newline', 'semi'}
            error('unexpected token');
        case 'keyword'
            keyword = tokens.get().token;
            tokens.next();
        otherwise
            keyword = '';
    end
    if ismember(keyword, {'properties', 'classdef', 'methods'}) && strcmp(tokens.get().type, 'lparen')
        tokens.next();
        modifiers = List();
        while ~strcmp(tokens.get().type, 'rparen')
            [i, mod] = modifier(tokens, i);
            modifiers.append(mod);
            if strcmp(tokens.get().type, 'comma')
                tokens.next();
            end
        end
        tokens.next();
        modifiers = modifiers.toList(Modifier.empty());
    else
        modifiers = Modifier.empty();
    end
    if ~isempty(tokens.get()) && ~(strcmp(tokens.get().type, 'comment') || strcmp(tokens.get().type, 'newline'))
        rvalue = expression(tokens);
        if ~isempty(tokens.get()) && strcmp(tokens.get().type, 'assign')
            tokens.next();
            lvalue = rvalue;
            rvalue = expression(tokens);
        else
            lvalue = Expression.empty();
        end
        if ~isempty(tokens.get()) && (strcmp(tokens.get().type, 'semi') || strcmp(tokens.get().type, 'comma'))
            tokens.next();
        end
    else
        lvalue = Expression.empty();
        rvalue = Expression.empty();
    end
    if ~isempty(tokens.get()) && strcmp(tokens.get().type, 'comment')
        comment = tokens.get().token;
        tokens.next();
    else
        comment = [];
    end
    node = Statement(keyword, modifiers, lvalue, rvalue, comment);
    while ~isempty(tokens.get()) && (strcmp(tokens.get().type, 'semi') || strcmp(tokens.get().type, 'comma') || strcmp(tokens.get().type, 'newline'))
        tokens.next();
    end
end
function node = variableDeclare(tokens)
    % name type = default
    if ~strcmp(tokens.get().type, 'identifier')
        error('unexpected token');
    end
    name = tokens.get().token;
    tokens.next();
    if strcmp(tokens.get().type, 'identifier')
        type = tokens.get().token;
        tokens.next();
    else
        type = '';
    end
    if strcmp(tokens.get().type, 'assign')
        tokens.next();
        expr = expression(tokens);
    else
        expr = Expression.empty();
    end
    if ~isempty(tokens.get()) && strcmp(tokens.get().type, 'comment')
        comment = tokens.get().token;
        tokens.next();
    else
        comment = [];
    end
    node = Variable(name, type, expr, comment);
    while ~isempty(tokens.get()) && (strcmp(tokens.get().type, 'semi') || strcmp(tokens.get().type, 'newline'))
        tokens.next();
    end
end
function blocks = program(tokens)
    blocks = List();
    while ~isempty(tokens.get())
        while strcmp(tokens.get().type, 'semi') || strcmp(tokens.get().type, 'newline')
            tokens.next();
        end
        blk = block(tokens);
        blocks.append(blk);
    end
    blocks = blocks.toList(Segment.empty());
end
function node = controlBlock(tokens, token, class_)
    if ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, token))
        error(['expect ', token]);
    end
    head = statement(tokens);
    args = List();
    while ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, 'end'))
        arg = block(tokens);
        args.append(arg);
    end
    end_ = statement(tokens);
    node = class_(head, args.toList(Segment.empty()), end_);
end
function node = ifBlock(tokens)
    if ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, 'if'))
        error('expect if');
    end
    branch = List();
    while ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, 'end'))
        head = statement(tokens);
        args = List();
        while ~(strcmp(tokens.get().type, 'keyword') && ismember(tokens.get().token, {'end', 'else', 'elseif'}))
            arg = block(tokens);
            args.append(arg);
        end
        branch.append(IfBranch(head, args.toList(Statement.empty())));
    end
    end_ = statement(tokens);
    node = If(branch.toList(IfBranch.empty()), end_);
end
function node = switchBlock(tokens)
    if ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, 'switch'))
        error('expect switch');
    end
    expr = statement(tokens);
    branch = List();
    while ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, 'end'))
        head = statement(tokens);
        args = List();
        while ~(strcmp(tokens.get().type, 'keyword') && ismember(tokens.get().token, {'end', 'case', 'otherwise'}))
            arg = block(tokens);
            args.append(arg);
        end
        branch.append(SwitchCase(head, args.toList(Segment.empty())));
    end
    end_ = statement(tokens);
    node = Switch(expr, branch.toList(SwitchCase.empty()), end_);
end
function node = propertiesBlock(tokens)
    if ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, 'properties'))
        error('expect properties');
    end
    head = statement(tokens);
    props = List();
    while ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, 'end'))
        prop = variableDeclare(tokens);
        props.append(prop);
    end
    end_ = statement(tokens);
    node = Properties(head, props.toList(Statement.empty()), end_);
end
function node = methodsBlock(tokens)
    if ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, 'methods'))
        error('expect methods');
    end
    head = statement(tokens);
    meth = List();
    while ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, 'end'))
        if ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, 'function'))
            error('unexpected token');
        end
        fun = block(tokens);
        meth.append(fun);
    end
    end_ = statement(tokens);
    node = Methods(head, meth.toList(Function.empty()), end_);
end
function node = classBlock(tokens)
    if ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, 'classdef'))
        error('expect classdef');
    end
    head = statement(tokens);
    property = List();
    method = List();
    while ~(strcmp(tokens.get().type, 'keyword') && strcmp(tokens.get().token, 'end'))
        if ~strcmp(tokens.get().type, 'keyword')
            error('unexpected token');
        end
        switch tokens.get().token
            case 'properties'
                prop = propertiesBlock(tokens);
                property.append(prop);
            case 'methods'
                meth = methodsBlock(tokens);
                method.append(meth);
            otherwise
                error('unexpected keyword');
        end
    end
    property = property.toList(Properties.empty());
    method = method.toList(Methods.empty());
    end_ = statement(tokens);
    node = ClassDef(head, property, method, end_);
end
function node = block(tokens)
    if ~strcmp(tokens.get().type, 'keyword')
        node = statement(tokens);
        return
    end
    switch tokens.get().token
        case {'return', 'continue', 'break'}
            node = statement(tokens);
        case 'for'
            node = controlBlock(tokens, 'for', @For);
        case 'while'
            node = controlBlock(tokens, 'while', @While);
        case 'function'
            node = controlBlock(tokens, 'function', @Function);
        case 'if'
            node = ifBlock(tokens);
        case 'switch'
            node = switchBlock(tokens);
        case 'classdef'
            node = classBlock(tokens);
        otherwise
            error('unexpected keyword');
    end
    while ~isempty(tokens.get()) && (strcmp(tokens.get().type, 'semi') || strcmp(tokens.get().type, 'newline') || strcmp(tokens.get().type, 'comma'))
        tokens.next();
    end
end
