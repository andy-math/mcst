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
if isfolder('m2py/nodes')
    rmdir('m2py/nodes', 's');
end
mkdir('m2py/nodes');
fid = fopen('m2py/main.py', 'wt+');
files = dir('mcst');
for i = 1 : numel(files)
    if ~(startsWith(files(i).name, '.') || endsWith(files(i).name, '.asv'))
        node = parseFile("mcst/" + files(i).name, table);
        output("test/" + files(i).name, node);
        m2py("m2py/nodes/" + files(i).name(1 : end - 2) + ".py", node);
        fprintf(fid, 'from m2py.nodes.%s import %s\n', files(i).name(1 : end - 2), files(i).name(1 : end - 2));
        compareFile("mcst/" + files(i).name, "test/" + files(i).name);
    end
end
fclose(fid);
node = parseFile('main.m', table);
output('test/main.m', node);
m2py('m2py/main.py', node);
output('test/output.m', parseFile('output.m', table));
output('test/List.m', parseFile('List.m', table));
compareFile('main.m', 'test/main.m');
compareFile('output.m', 'test/output.m');
compareFile('List.m', 'test/List.m');
function compareFile(file1, file2)
    content1 = readFile(file1);
    content2 = readFile(file2);
    content1 = split(replace(content1, ' ', ''), newline);
    content2 = split(replace(content2, ' ', ''), newline);
    if numel(content1) ~= numel(content2)
        warning('length of %s not equal with length of %s', file1, file2);
        return
    end
    d = find(string(content1) ~= string(content2));
    if ~isempty(d)
        warning('%s vs %s: diff found in line %s\n', file1, file2, mat2str(d));
        return
    end
    fprintf(1, '%s vs %s: equal without space\n', file1, file2);
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
                switch tokens(i).type
                    case 'identifier'
                        node = Field(node, Identifier(tokens(i).token));
                        i = i + 1;
                    case 'lparen'
                        i = i + 1;
                        [i, expr] = expression(tokens, i);
                        if ~strcmp(tokens(i).type, 'rparen')
                            error('unexpected token');
                        end
                        i = i + 1;
                        node = Field(node, expr);
                    otherwise
                        error('unexpected token');
                end
            case 'lparen'
                i = i + 1;
                args = List();
                while ~strcmp(tokens(i).type, 'rparen')
                    if strcmp(tokens(i).type, 'colon')
                        args.append(Colon(Expression.empty(), Expression.empty(), Expression.empty()));
                        i = i + 1;
                    else
                        [i, arg] = expression(tokens, i);
                        args.append(arg);
                    end
                    switch tokens(i).type
                        case 'rparen'
                        case 'comma'
                            i = i + 1;
                        otherwise
                            error('unexpected token');
                    end
                end
                i = i + 1;
                node = PIndex(node, args.toList(Expression.empty()));
            case 'lbrace'
                i = i + 1;
                args = List();
                while ~strcmp(tokens(i).type, 'rbrace')
                    if strcmp(tokens(i).type, 'colon')
                        args.append(Colon());
                        i = i + 1;
                    else
                        [i, arg] = expression(tokens, i);
                        args.append(arg);
                    end
                    switch tokens(i).type
                        case 'rbrace'
                        case 'comma'
                            i = i + 1;
                        otherwise
                            error('unexpected token');
                    end
                end
                i = i + 1;
                node = BIndex(node, args.toList(Expression.empty()));
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
    while ~(strcmp(tokens(i).type, 'rsquare') || strcmp(tokens(i).type, 'rbrace') || strcmp(tokens(i).type, 'newline') || strcmp(tokens(i).type, 'semi'))
        [i, arg] = expression(tokens, i);
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
function [i, node] = mulDiv(tokens, i)
    [i, node] = unary(tokens, i);
    while i <= numel(tokens)
        switch tokens(i).type
            case 'times'
                i = i + 1;
                [i, node2] = unary(tokens, i);
                node = Times(node, node2);
            case 'ldivide'
                i = i + 1;
                [i, node2] = unary(tokens, i);
                node = LDivide(node, node2);
            case 'rdivide'
                i = i + 1;
                [i, node2] = unary(tokens, i);
                node = RDivide(node, node2);
            case 'mtimes'
                i = i + 1;
                [i, node2] = unary(tokens, i);
                node = MTimes(node, node2);
            case 'mldivide'
                i = i + 1;
                [i, node2] = unary(tokens, i);
                node = MLDivide(node, node2);
            case 'mrdivide'
                i = i + 1;
                [i, node2] = unary(tokens, i);
                node = MRDivide(node, node2);
            otherwise
                break
        end
    end
end
function [i, node] = addSub(tokens, i)
    [i, node] = mulDiv(tokens, i);
    while i <= numel(tokens)
        switch tokens(i).type
            case 'plus'
                i = i + 1;
                [i, node2] = mulDiv(tokens, i);
                node = Plus(node, node2);
            case 'minus'
                i = i + 1;
                [i, node2] = mulDiv(tokens, i);
                node = Minus(node, node2);
            otherwise
                break
        end
    end
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
    [i, node] = colonOperator(tokens, i);
    if i <= numel(tokens)
        switch tokens(i).type
            case 'le'
                i = i + 1;
                [i, node2] = colonOperator(tokens, i);
                node = LE(node, node2);
            case 'ge'
                i = i + 1;
                [i, node2] = colonOperator(tokens, i);
                node = GE(node, node2);
            case 'lt'
                i = i + 1;
                [i, node2] = colonOperator(tokens, i);
                node = LT(node, node2);
            case 'gt'
                i = i + 1;
                [i, node2] = colonOperator(tokens, i);
                node = GT(node, node2);
            case 'eq'
                i = i + 1;
                [i, node2] = colonOperator(tokens, i);
                node = EQ(node, node2);
            case 'ne'
                i = i + 1;
                [i, node2] = colonOperator(tokens, i);
                node = NE(node, node2);
        end
    end
end
function [i, node] = logicalAnd(tokens, i)
    [i, node] = compare(tokens, i);
    while i <= numel(tokens)
        switch tokens(i).type
            case 'and'
                i = i + 1;
                [i, node2] = compare(tokens, i);
                node = And(node, node2);
            otherwise
                break
        end
    end
end
function [i, node] = logicalOr(tokens, i)
    [i, node] = logicalAnd(tokens, i);
    while i <= numel(tokens)
        switch tokens(i).type
            case 'or'
                i = i + 1;
                [i, node2] = compare(tokens, i);
                node = Or(node, node2);
            otherwise
                break
        end
    end
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
