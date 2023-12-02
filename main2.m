clc();
clear();
close('all');
grammar = struct();
grammar.('fieldExpr') = {
    {'identifier'}
    {'(','expression',')'}
    };
grammar.('literal') = {
    {'chars'}
    {'number'}
    {'string'}
    {'end'}
};
grammar.('field') = {{'.', 'fieldExpr'}};
grammar.('pindex') = {{'(', 'commaSeparatedExprOrEmpty',')'}};
grammar.('bindex') = {{'{', 'commaSeparatedExpr','}'}};
grammar.('subsref') = {
    {'field', 'subsref'}
    {'pindex', 'subsref'}
    {'bindex', 'subsref'}
    {}
    };
grammar.('operand') = {
    {'identifier', 'subsref'}
    {'literal'}
    {'(','expression',')'}
    {'matrix'}
    {'cell'}
    {'lambda'}
    };
grammar.('powerTrans2') = {
    {'.''', 'powerTrans2'}
    {'.^', 'operand', 'powerTrans2'}
    {'''', 'powerTrans2'}
    {'^', 'operand', 'powerTrans2'}
    {}
    };
grammar.('powerTrans') = {
    {'operand', 'powerTrans2'}
    };
grammar.('unary') = {
    {'+', 'unary'}
    {'-', 'unary'}
    {'~', 'unary'}
    {'powerTrans'}
    };
grammar.('mulDiv2') = {
    {'.*','unary','mulDiv2'}
    {'./','unary','mulDiv2'}
    {'.\','unary','mulDiv2'}
    {'*','unary','mulDiv2'}
    {'/','unary','mulDiv2'}
    {'\','unary','mulDiv2'}
    {}
    };
grammar.('mulDiv') = {{'unary', 'mulDiv2'}};
grammar.('addSub2') = {
    {'+', 'mulDiv', 'addSub2'}
    {'-', 'mulDiv', 'addSub2'}
    {}
    };
grammar.('addSub') = {{'mulDiv', 'addSub2'}};
grammar.('colon3') = {
    {':','addSub'}
    {}
    };
grammar.('colon2') = {
    {':','addSub','colon3'}
    {}
    };
grammar.('colon') = {{'addSub', 'colon2'}};
grammar.('compare2') = {
    {'<','colon','compare2'}
    {'<=','colon','compare2'}
    {'>','colon','compare2'}
    {'>=','colon','compare2'}
    {'==','colon','compare2'}
    {'~=','colon','compare2'}
    {}
    };
grammar.('compare') = {{'colon','compare2'}};
grammar.('elemAnd2') = {
    {'&','compare','elemAnd2'}
    {}
    };
grammar.('elemAnd') = {{'compare','elemAnd2'}};
grammar.('elemOr2') = {
    {'|','elemAnd','elemOr2'}
    {}
    };
grammar.('elemOr') = {{'elemAnd','elemOr2'}};
grammar.('logiAnd2') = {
    {'&&','elemOr','logiAnd2'}
    {}
    };
grammar.('logiAnd') = {{'elemOr','logiAnd2'}};

grammar.('logiOr2') = {
    {'||','logiAnd','logiOr2'}
    {}
    };
grammar.('logiOr') = {{'logiAnd','logiOr2'}};
grammar.('expression') = {{'logiOr'}};
grammar.('commaSeparatedExpr2') = {
    {',','expression','commaSeparatedExpr2'}
    {}
    };
grammar.('commaSeparatedExpr') = {{'expression','commaSeparatedExpr2'}};
grammar.('commaSeparatedExprOrEmpty') = {
    {'commaSeparatedExpr'}
    {}
    };
grammar.('matrix2') = {
    {';','commaSeparatedExprOrEmpty','matrix2'}
    {'newline','commaSeparatedExprOrEmpty','matrix2'}
    {}
    };
grammar.('matrix') = {{'[','commaSeparatedExprOrEmpty','matrix2',']'}};
grammar.('cell') = {{'{','commaSeparatedExprOrEmpty','matrix2','}'}};
grammar.('entry') = {{'expression','newline'}};
grammar.('code2') = {
    {'entry','code2'}
    {}
    };
grammar.('code') = {{'code2','eof'}};
grammar.('commaSeparatedIdentifier2') = {
    {',','identifier','commaSeparatedIdentifier2'}
    {}
    };
grammar.('commaSeparatedIdentifier') = {
    {'identifier','commaSeparatedIdentifier2'}
    {}
    };
grammar.('lambdaBody') = {
    {'(','commaSeparatedIdentifier',')','expression'}
    {'identifier'}
    };
grammar.('lambda') = {{'@','lambdaBody'}};
terms = fieldnames(grammar);
first = struct();
follow = struct();
for i = 1:numel(terms)
    first = getFirst(first,terms{i},grammar);
    follow.(terms{i}) = {};
end
follow = getFollow(follow,'code',grammar,first);
for i = 1:numel(terms)
    if ismember('',[first.(terms{i}){:}]) && (any(ismember([first.(terms{i}){:}],follow.(terms{i}))) || any(ismember(follow.(terms{i}),[first.(terms{i}){:}])))
        warning(terms{i})
    end
    print(terms{i},grammar.(terms{i}),first.(terms{i}),follow.(terms{i}));
end
return
content = readFile('expr.txt');
tokens = tokenize(content);
parse(tokens,'code',grammar,first,follow)
function content = readFile(filename)
    fid = fopen(filename);
    content = native2unicode(fread(fid).');
    fclose(fid);
    while contains(content, sprintf('\r\n'))
        content = replace(content, sprintf('\r\n'), newline);
    end
end
function node = parse(tokens,term,grammar,first,follow)
    if ismember(tokens.get().type,{'identifier','newline','chars','string','number','eof'})
        sym = tokens.get().type;
    else
        sym = tokens.get().token;
    end
    if ismember('',[first.(term){:}]) && ismember(sym,follow.(term))
        node = [];
        return
    end
    for i = 1:numel(grammar.(term))
        if ismember(sym,first.(term){i})
            for j = 1:numel(grammar.(term){i})
                if isfield(grammar,grammar.(term){i}{j})
                    parse(tokens,grammar.(term){i}{j},grammar,first,follow);
                else
                    if ismember(tokens.get().type,{'identifier','newline','chars','string','number','eof'})
                        sym = tokens.get().type;
                    else
                        sym = tokens.get().token;
                    end
                    if strcmp(sym,grammar.(term){i}{j})
                        fprintf('%s',tokens.get().token);
                        tokens.next();
                    else
                        error('unexpected token');
                    end
                end
            end
            return
        end
    end
    error('unexpected token');
end
function tokens = tokenize(s)
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
    tokens.append(Token('eof','eof'));
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
function follow = getFollow(follow,term,grammar,first)
    for i = 1:numel(grammar.(term))
        last = follow.(term);
        for j = numel(grammar.(term){i}):-1:1
            if isfield(grammar,grammar.(term){i}{j})
                vis = ismember(last,follow.(grammar.(term){i}{j}));
                if ~all(vis)
                    follow.(grammar.(term){i}{j}) = [follow.(grammar.(term){i}{j}), last(~vis)];
                    follow = getFollow(follow,grammar.(term){i}{j},grammar,first);
                end
                f = [first.(grammar.(term){i}{j}){:}];
                eps = strcmp(f,'');
                if any(eps)
                    vis = ismember(f,last);
                    last = [last, f(~(eps | vis))]; %#ok<AGROW>
                else
                    last = f(~eps);
                end
            else
                last = {grammar.(term){i}{j}};
            end
        end
    end
end
function first = getFirst(first,term,grammar)
    if isfield(first, term)
        if isempty(first.(term))
            error('term %s has recursive definition', term);
        end
        return
    end
    first.(term) = {};
    set = cell(1, numel(grammar.(term)));
    for i = 1:numel(grammar.(term))
        if isempty(grammar.(term){i})
            if ismember('',[set{:}])
                error('term %s has duplicate first token', term);
            end
            set{i} = {''};
            continue
        end
        set{i} = {};
        for j = 1:numel(grammar.(term){i})
            if isfield(grammar, grammar.(term){i}{j})
                first = getFirst(first,grammar.(term){i}{j},grammar);
                subset = [first.(grammar.(term){i}{j}){:}];
                eps = strcmp(subset,'');
                if any(ismember(subset(~eps),[set{:}]))
                    error('term %s has duplicate first token', term);
                end
                set{i} = [set{i}, subset(~eps)];
                if ~any(eps)
                    break
                elseif j == numel(grammar.(term){i})
                    if ismember('',[set{:}])
                        error('term %s has duplicate first token', term);
                    end
                    set{i} = [set{i}, {''}];
                end
            else
                if ismember(grammar.(term){i}{j},[set{:}])
                    error('term %s has duplicate first token', term);
                end
                set{i} = [set{i}, {grammar.(term){i}{j}}];
                break
            end
        end
    end
    first.(term) = set;
end
function print(term,grammar,first,follow)
    assert(numel(grammar) == numel(first));
    if isempty(follow)
        disp(term+":");
    else
        disp(term+": "+string(follow).join(' '));
    end
    for i = 1:numel(grammar)
        str = repmat(' ',1,4)+string(grammar{i}).join(' ');
        str = str.pad(40);
        str = str+string(first{i}).join(' ');
        disp(str);
    end
end


