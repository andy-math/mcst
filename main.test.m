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
output('main.test.m', parseFile('main.m', table));
output('output.test.m', parseFile('output.m', table));
compareFile('main.m', 'main.test.m');
compareFile('output.m', 'output.test.m');
function [] = forTestFunction()
    a.(1 + 1) = c;
    @bb;
    @(a, b, c)aa + bb;
    1;
end
function compareFile(file1, file2)
    content1 = readFile(file1);
    content2 = readFile(file2);
    content1 = split(replace(content1, ' ', ''), newline);
    content2 = split(replace(content2, ' ', ''), newline);
    content1(content1 == "") = [];
    content2(content2 == "") = [];
    if numel(content1) ~= numel(content2)
        fprintf(1, 'length of %s not equal with length of %s\n', file1, file2);
        return
    end
    d = find(string(content1) ~= string(content2));
    if ~isempty(d)
        fprintf(1, '%s vs %s: diff found in line %s\n', file1, file2, mat2str(d));
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
    tokens = cell(numel(s), 1);
    count = 0;
    lastToken = '';
    while j < numel(s)
        count = count + 1;
        [j, type, token] = nextToken(s, j, table, lastToken);
        tokens{count} = Token(type, token);
        lastToken = type;
    end
    tokens = cell2mat(tokens(1 : count));
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
        if strcmp(token, 'return') || strcmp(token, 'break') || strcmp(token, 'continue') || strcmp(token, 'if') || strcmp(token, 'elseif') || strcmp(token, 'for') || strcmp(token, 'else') || strcmp(token, 'while') || strcmp(token, 'end') || strcmp(token, 'function') || strcmp(token, 'switch') || strcmp(token, 'case') || strcmp(token, 'otherwise')
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
                args = {Expression.empty()};
                while ~strcmp(tokens(i).type, 'rparen')
                    if strcmp(tokens(i).type, 'colon')
                        args = append(args, Colon());
                        i = i + 1;
                    else
                        [i, arg] = expression(tokens, i);
                        args = append(args, arg);
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
                node = PIndex(node, [args{:}]);
            case 'lbrace'
                i = i + 1;
                args = {Expression.empty()};
                while ~strcmp(tokens(i).type, 'rbrace')
                    if strcmp(tokens(i).type, 'colon')
                        args = append(args, Colon());
                        i = i + 1;
                    else
                        [i, arg] = expression(tokens, i);
                        args = append(args, arg);
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
                node = BIndex(node, [args{:}]);
            otherwise
                break
        end
    end
end
function [i, node] = matrixLine(tokens, i)
    args = {Expression.empty()};
    if strcmp(tokens(i).type, 'comma')
        i = i + 1;
    end
    while ~(strcmp(tokens(i).type, 'rsquare') || strcmp(tokens(i).type, 'rbrace') || strcmp(tokens(i).type, 'newline') || strcmp(tokens(i).type, 'semi'))
        [i, arg] = expression(tokens, i);
        args = append(args, arg);
        if strcmp(tokens(i).type, 'comma')
            i = i + 1;
        end
    end
    if isempty(args)
        node = MatrixLine.empty();
    else
        node = MatrixLine([args{:}]);
    end
end
function [i, node] = matrixLiteral(tokens, i)
    if ~strcmp(tokens(i).type, 'lsquare')
        error('must be lsquare');
    end
    i = i + 1;
    args = {MatrixLine.empty()};
    while strcmp(tokens(i).type, 'semi') || strcmp(tokens(i).type, 'newline')
        i = i + 1;
    end
    while ~strcmp(tokens(i).type, 'rsquare')
        [i, arg] = matrixLine(tokens, i);
        args = append(args, arg);
        while strcmp(tokens(i).type, 'semi') || strcmp(tokens(i).type, 'newline')
            i = i + 1;
        end
    end
    i = i + 1;
    node = Matrix([args{:}]);
end
function [i, node] = cellLiteral(tokens, i)
    if ~strcmp(tokens(i).type, 'lbrace')
        error('must be lsquare');
    end
    i = i + 1;
    args = {MatrixLine.empty()};
    while strcmp(tokens(i).type, 'semi') || strcmp(tokens(i).type, 'newline')
        i = i + 1;
    end
    while ~strcmp(tokens(i).type, 'rbrace')
        [i, arg] = matrixLine(tokens, i);
        args = append(args, arg);
        while strcmp(tokens(i).type, 'semi') || strcmp(tokens(i).type, 'newline')
            i = i + 1;
        end
    end
    i = i + 1;
    node = Cell([args{:}]);
end
function [i, node] = lambda(tokens, i)
    if ~strcmp(tokens(i).type, 'lambda')
        error('unexpected token');
    end
    i = i + 1;
    if strcmp(tokens(i).type, 'lparen')
        i = i + 1;
        args = {Identifier.empty()};
        while ~strcmp(tokens(i).type, 'rparen')
            if ~strcmp(tokens(i).type, 'identifier')
                error('unexpected token');
            end
            arg = Identifier(tokens(i).token);
            args = append(args, arg);
            i = i + 1;
            if strcmp(tokens(i).type, 'comma')
                i = i + 1;
            end
        end
        i = i + 1;
        args = [args{:}];
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
            [i, node] = lambda(tokens, i);
        case 'lparen'
            i = i + 1;
            [i, node] = expression(tokens, i);
            if ~strcmp(tokens(i).type, 'rparen')
                error('must be rparen');
            end
            i = i + 1;
            node = Paren(node);
        case 'lsquare'
            [i, node] = matrixLiteral(tokens, i);
        case 'lbrace'
            [i, node] = cellLiteral(tokens, i);
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
            node = Colon(node, node2);
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
function [i, node] = statement(tokens, i)
    switch tokens(i).type
        case {'newline', 'semi'}
            error('unexpected token');
        case 'keyword'
            keyword = tokens(i).token;
            i = i + 1;
        otherwise
            keyword = [];
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
    node = Statement(keyword, lvalue, rvalue, comment);
end
function statements = parseStatement(tokens)
    i = 1;
    statements = {};
    while i <= numel(tokens)
        if i <= numel(tokens) && strcmp(tokens(i).type, 'newline') || strcmp(tokens(i).type, 'semi')
            i = i + 1;
            continue
        end
        [i, stmt] = statement(tokens, i);
        statements = append(statements, stmt);
    end
    statements = [statements{:}];
end
function blocks = program(tokens)
    statements = parseStatement(tokens);
    blocks = {};
    i = 1;
    while i <= numel(statements)
        [i, blk] = block(statements, i);
        blocks = append(blocks, blk);
    end
    blocks = [blocks{:}];
end
function [i, node] = controlBlock(statements, i, token, class)
    if ~strcmp(statements(i).keyword, token)
        error(['expect ', token]);
    end
    head = statements(i);
    i = i + 1;
    args = {Segment.empty()};
    while ~strcmp(statements(i).keyword, 'end')
        [i, arg] = block(statements, i);
        args = append(args, arg);
    end
    node = class(head, [args{:}], statements(i));
    i = i + 1;
end
function [i, node] = ifBlock(statements, i)
    if ~strcmp(statements(i).keyword, 'if')
        error('expect if');
    end
    branch = {};
    while ~strcmp(statements(i).keyword, 'end')
        head = statements(i);
        i = i + 1;
        args = {Statement.empty()};
        while ~(strcmp(statements(i).keyword, 'end') || strcmp(statements(i).keyword, 'else') || strcmp(statements(i).keyword, 'elseif'))
            [i, arg] = block(statements, i);
            args = append(args, arg);
        end
        branch = append(branch, IfBranch(head, [args{:}]));
    end
    node = If([branch{:}], statements(i));
    i = i + 1;
end
function [i, node] = switchBlock(statements, i)
    if ~strcmp(statements(i).keyword, 'switch')
        error('expect switch');
    end
    expr = statements(i);
    i = i + 1;
    branch = {};
    while ~strcmp(statements(i).keyword, 'end')
        head = statements(i);
        i = i + 1;
        args = {Segment.empty()};
        while ~(strcmp(statements(i).keyword, 'end') || strcmp(statements(i).keyword, 'case') || strcmp(statements(i).keyword, 'otherwise'))
            [i, arg] = block(statements, i);
            args = append(args, arg);
        end
        branch = append(branch, SwitchCase(head, [args{:}]));
    end
    node = Switch(expr, [branch{:}], statements(i));
    i = i + 1;
end
function [i, node] = block(statements, i)
    if ~isa(statements(i), 'Statement')
        error('unexpected token');
    end
    if isempty(statements(i).keyword)
        node = statements(i);
        i = i + 1;
        return
    end
    switch statements(i).keyword
        case {'return', 'continue', 'break'}
            node = statements(i);
            i = i + 1;
            return
        case 'for'
            [i, node] = controlBlock(statements, i, 'for', @For);
        case 'while'
            [i, node] = controlBlock(statements, i, 'while', @While);
        case 'function'
            [i, node] = controlBlock(statements, i, 'function', @Function);
        case 'if'
            [i, node] = ifBlock(statements, i);
        case 'switch'
            [i, node] = switchBlock(statements, i);
        otherwise
            error('unexpected token');
    end
end
function t = Token(type, token)
    t.type = type;
    t.token = token;
end
