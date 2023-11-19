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
{'newline', newline}
];
filename = [mfilename(), '.m'];
fid = fopen(filename);
content = native2unicode(fread(fid).');
fclose(fid);
while contains(content, sprintf('\r\n'))
    content = replace(content, sprintf('\r\n'), newline);
end
tokens = tokenize(content, table);
node = program(tokens);
fid = fopen('test.m', 'wt+');
output(fid, node, 0);
fclose(fid);
fid = fopen('test.m');
content2 = native2unicode(fread(fid).');
fclose(fid);
while contains(content2, sprintf('\r\n'))
    content2 = replace(content, sprintf('\r\n'), newline);
end
node2 = program(tokenize(content2, table));
disp("isequal = " + isequal(node, node2));
content = string(content).split(newline);
content2 = string(content2).split(newline);
disp("diff = " + mat2str(find(content ~= content2)));
function tokens = tokenize(s, table)
    j = 1;
    tokens = struct('type', cell(size(s)), 'token', cell(size(s)));
    count = 0;
    lastToken = '';
    while j < numel(s)
        count = count + 1;
        [j, tokens(count).type, tokens(count).token] = nextToken(s, j, table, lastToken);
        lastToken = tokens(count).type;
    end
    tokens = tokens(1 : count);
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
    node = astNode('identifier', tokens(i).token);
    i = i + 1;
    while i <= numel(tokens)
        switch tokens(i).type
            case 'field'
                i = i + 1;
                node = astNode('field', node, tokens(i).token);
                i = i + 1;
            case 'lparen'
                i = i + 1;
                args = {};
                while ~strcmp(tokens(i).type, 'rparen')
                    [i, args{1, end + 1}] = expression(tokens, i); %#ok<AGROW>
                    switch tokens(i).type
                        case 'rparen'
                        case 'comma'
                            i = i + 1;
                        otherwise
                            error('unexpected token');
                    end
                end
                i = i + 1;
                node = astNode('pindex', node, args);
            case 'lbrace'
                i = i + 1;
                args = {};
                while ~strcmp(tokens(i).type, 'rbrace')
                    [i, args{1, end + 1}] = expression(tokens, i); %#ok<AGROW>
                    switch tokens(i).type
                        case 'rbrace'
                        case 'comma'
                            i = i + 1;
                        otherwise
                            error('unexpected token');
                    end
                end
                i = i + 1;
                node = astNode('bindex', node, args);
            otherwise
                break
        end
    end
end
function [i, node] = matrixLiteral(tokens, i)
    if i <= 0 || i > numel(tokens)
        error('index out of range');
    end
    if ~strcmp(tokens(i).type, 'lsquare')
        error('must be lsquare');
    end
    i = i + 1;
    args = {};
    while ~strcmp(tokens(i).type, 'rsquare')
        switch tokens(i).type
            case 'comma'
                i = i + 1;
            case 'semi'
                args{1, end + 1} = astNode('newline'); %#ok<AGROW>
                i = i + 1;
            case 'newline'
                args{1, end + 1} = astNode('newline'); %#ok<AGROW>
                i = i + 1;
            case 'comment'
                args{1, end + 1} = astNode('comment', [], tokens(i).token); %#ok<AGROW>
                i = i + 1;
            otherwise
                [i, args{1, end + 1}] = expression(tokens, i); %#ok<AGROW>
        end
    end
    i = i + 1;
    node = astNode('matrix', args);
end
function [i, node] = cellLiteral(tokens, i)
    if i <= 0 || i > numel(tokens)
        error('index out of range');
    end
    if ~strcmp(tokens(i).type, 'lbrace')
        error('must be lbrace');
    end
    i = i + 1;
    args = {};
    while ~strcmp(tokens(i).type, 'rbrace')
        switch tokens(i).type
            case 'comma'
                i = i + 1;
            case 'semi'
                args{1, end + 1} = astNode('newline'); %#ok<AGROW>
                i = i + 1;
            case 'newline'
                args{1, end + 1} = astNode('newline'); %#ok<AGROW>
                i = i + 1;
            case 'comment'
                args{1, end + 1} = astNode('comment', [], tokens(i).token); %#ok<AGROW>
                i = i + 1;
            otherwise
                [i, args{1, end + 1}] = expression(tokens, i); %#ok<AGROW>
        end
    end
    i = i + 1;
    node = astNode('cell', args);
end
function [i, node] = operand(tokens, i)
    switch tokens(i).type
        case 'chars'
            node = astNode('literal', tokens(i).token);
            i = i + 1;
        case 'string'
            node = astNode('literal', tokens(i).token);
            i = i + 1;
        case 'number'
            node = astNode('literal', tokens(i).token);
            i = i + 1;
        case 'lparen'
            i = i + 1;
            [i, node] = expression(tokens, i);
            if ~strcmp(tokens(i).type, 'rparen')
                error('must be rparen');
            end
            i = i + 1;
            node = astNode('paren', node);
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
            node = astNode('identifier', 'end');
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
                node = astNode('transpose', node);
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
            node = astNode('negative', node);
        case 'not'
            i = i + 1;
            [i, node] = unary(tokens, i);
            node = astNode('not', node);
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
                node = astNode('times', node, node2);
            case 'ldivide'
                i = i + 1;
                [i, node2] = unary(tokens, i);
                node = astNode('ldivide', node, node2);
            case 'rdivide'
                i = i + 1;
                [i, node2] = unary(tokens, i);
                node = astNode('rdivide', node, node2);
            case 'mtimes'
                i = i + 1;
                [i, node2] = unary(tokens, i);
                node = astNode('mtimes', node, node2);
            case 'mldivide'
                i = i + 1;
                [i, node2] = unary(tokens, i);
                node = astNode('mldivide', node, node2);
            case 'mrdivide'
                i = i + 1;
                [i, node2] = unary(tokens, i);
                node = astNode('mrdivide', node, node2);
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
                node = astNode('plus', node, node2);
            case 'minus'
                i = i + 1;
                [i, node2] = mulDiv(tokens, i);
                node = astNode('minus', node, node2);
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
            node = astNode('colon', node, node2, node3);
        else
            node = astNode('colon', node, node2);
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
                node = astNode('le', node, node2);
            case 'ge'
                i = i + 1;
                [i, node2] = colonOperator(tokens, i);
                node = astNode('ge', node, node2);
            case 'lt'
                i = i + 1;
                [i, node2] = colonOperator(tokens, i);
                node = astNode('lt', node, node2);
            case 'gt'
                i = i + 1;
                [i, node2] = colonOperator(tokens, i);
                node = astNode('gt', node, node2);
            case 'eq'
                i = i + 1;
                [i, node2] = colonOperator(tokens, i);
                node = astNode('eq', node, node2);
            case 'ne'
                i = i + 1;
                [i, node2] = colonOperator(tokens, i);
                node = astNode('ne', node, node2);
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
                node = astNode('and', node, node2);
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
                node = astNode('or', node, node2);
            otherwise
                break
        end
    end
end
function [i, node] = expression(tokens, i)
    [i, node] = logicalOr(tokens, i);
end
function [i, node] = statement(tokens, i)
    if ~(strcmp(tokens(i).type, 'comment') || strcmp(tokens(i).type, 'newline'))
        [i, node] = expression(tokens, i);
        if i <= numel(tokens) && strcmp(tokens(i).type, 'assign')
            i = i + 1;
            [i, node2] = expression(tokens, i);
            node = astNode('assign', node, node2);
        end
        if i <= numel(tokens) && strcmp(tokens(i).type, 'semi')
            i = i + 1;
        end
    else
        node = [];
    end
    if i <= numel(tokens) && strcmp(tokens(i).type, 'comment')
        node = astNode('comment', node, tokens(i).token);
        i = i + 1;
    end
    if i <= numel(tokens) && strcmp(tokens(i).type, 'newline')
        i = i + 1;
    end
end
function [i, node] = whileBlock(tokens, i)
    if i <= 0 || i > numel(tokens)
        error('index out of range');
    end
    if ~strcmp(tokens(i).token, 'while')
        error('invalid keyword');
    end
    i = i + 1;
    [i, condition] = expression(tokens, i);
    if strcmp(tokens(i).type, 'comment')
        condition = astNode('comment', condition, tokens(i).token);
        i = i + 1;
    end
    if strcmp(tokens(i).type, 'newline')
        i = i + 1;
    end
    nodes = {};
    while ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'end'))
        [i, nodes{1, end + 1}] = block(tokens, i); %#ok<AGROW>
    end
    i = i + 1;
    if strcmp(tokens(i).type, 'comment')
        comment = astNode('comment', [], tokens(i).token);
        node = astNode('while', condition, nodes, comment);
        i = i + 1;
    else
        node = astNode('while', condition, nodes);
    end
    if i <= numel(tokens) && strcmp(tokens(i).type, 'newline')
        i = i + 1;
    end
end
function [i, node] = switchBlock(tokens, i)
    if i <= 0 || i > numel(tokens)
        error('index out of range');
    end
    if ~strcmp(tokens(i).token, 'switch')
        error('invalid keyword');
    end
    i = i + 1;
    [i, expr] = expression(tokens, i);
    if strcmp(tokens(i).type, 'newline')
        i = i + 1;
    end
    branch = {};
    while ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'end'))
        if ~strcmp(tokens(i).type, 'keyword')
            error('must be keyword');
        end
        switch tokens(i).token
            case 'case'
                i = i + 1;
                [i, case_] = expression(tokens, i);
                if strcmp(tokens(i).type, 'newline')
                    i = i + 1;
                end
                nodes = {};
                while ~(strcmp(tokens(i).type, 'keyword') && (strcmp(tokens(i).token, 'case') || strcmp(tokens(i).token, 'end') || strcmp(tokens(i).token, 'otherwise')))
                    [i, nodes{1, end + 1}] = block(tokens, i); %#ok<AGROW>
                end
                branch{1, end + 1} = astNode('case', case_, nodes); %#ok<AGROW>
            case 'otherwise'
                i = i + 1;
                if strcmp(tokens(i).type, 'newline')
                    i = i + 1;
                end
                nodes = {};
                while ~(strcmp(tokens(i).type, 'keyword') && (strcmp(tokens(i).token, 'case') || strcmp(tokens(i).token, 'end') || strcmp(tokens(i).token, 'otherwise')))
                    [i, nodes{1, end + 1}] = block(tokens, i); %#ok<AGROW>
                end
                branch{1, end + 1} = astNode('case', [], nodes); %#ok<AGROW>
            otherwise
                error('unexpected token');
        end
    end
    i = i + 1;
    node = astNode('switch', expr, branch);
end
function [i, node] = ifBlock(tokens, i)
    if i <= 0 || i > numel(tokens)
        error('index out of range');
    end
    branch = {};
    while ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'end'))
        if ~strcmp(tokens(i).type, 'keyword')
            error('must be keyword');
        end
        switch tokens(i).token
            case {'if', 'elseif'}
                i = i + 1;
                [i, case_] = expression(tokens, i);
                if strcmp(tokens(i).type, 'newline')
                    i = i + 1;
                end
                nodes = {};
                while ~(strcmp(tokens(i).type, 'keyword') && (strcmp(tokens(i).token, 'elseif') || strcmp(tokens(i).token, 'else') || strcmp(tokens(i).token, 'end') || strcmp(tokens(i).token, 'otherwise')))
                    [i, nodes{1, end + 1}] = block(tokens, i); %#ok<AGROW>
                end
                branch{1, end + 1} = astNode('branch', case_, nodes); %#ok<AGROW>
            case 'else'
                i = i + 1;
                if strcmp(tokens(i).type, 'newline')
                    i = i + 1;
                end
                nodes = {};
                while ~(strcmp(tokens(i).type, 'keyword') && (strcmp(tokens(i).token, 'elseif') || strcmp(tokens(i).token, 'else') || strcmp(tokens(i).token, 'end') || strcmp(tokens(i).token, 'otherwise')))
                    [i, nodes{1, end + 1}] = block(tokens, i); %#ok<AGROW>
                end
                branch{1, end + 1} = astNode('branch', [], nodes); %#ok<AGROW>
            otherwise
                error('unexpected token');
        end
    end
    i = i + 1;
    node = astNode('if', branch);
end
function [i, node] = functionBlock(tokens, i)
    if i <= 0 || i > numel(tokens)
        error('index out of range');
    end
    if ~strcmp(tokens(i).token, 'function')
        error('invalid keyword');
    end
    i = i + 1;
    [i, fun] = statement(tokens, i);
    nodes = {};
    while ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'end'))
        [i, nodes{1, end + 1}] = block(tokens, i); %#ok<AGROW>
    end
    i = i + 1;
    node = astNode('function', fun, nodes);
end
function [i, node] = forBlock(tokens, i)
    if i <= 0 || i > numel(tokens)
        error('index out of range');
    end
    if ~strcmp(tokens(i).token, 'for')
        error('invalid keyword');
    end
    i = i + 1;
    [i, fun] = statement(tokens, i);
    nodes = {};
    while ~(strcmp(tokens(i).type, 'keyword') && strcmp(tokens(i).token, 'end'))
        [i, nodes{1, end + 1}] = block(tokens, i); %#ok<AGROW>
    end
    i = i + 1;
    node = astNode('for', fun, nodes);
end
function [i, node] = block(tokens, i)
    if strcmp(tokens(i).type, 'keyword')
        switch tokens(i).token
            case 'while'
                [i, node] = whileBlock(tokens, i);
            case 'switch'
                [i, node] = switchBlock(tokens, i);
            case 'if'
                [i, node] = ifBlock(tokens, i);
            case 'for'
                [i, node] = forBlock(tokens, i);
            case 'function'
                [i, node] = functionBlock(tokens, i);
            case 'return'
                node = astNode('keyword', 'return');
                i = i + 1;
            case 'continue'
                node = astNode('keyword', 'continue');
                i = i + 1;
            case 'break'
                node = astNode('keyword', 'break');
                i = i + 1;
            otherwise
                error('unknown keyword');
        end
    else
        [i, node] = statement(tokens, i);
        if ~isempty(node) && ~strcmp(node.type, 'comment')
            node = astNode('statement', node);
        end
    end
end
function node = program(tokens)
    i = 1;
    node = {};
    while i <= numel(tokens)
        [i, node{1, end + 1}] = block(tokens, i); %#ok<AGROW>
    end
end
function node = astNode(type, varargin)
    node.type = type;
    node.args = varargin;
end
