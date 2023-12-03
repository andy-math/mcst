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
grammar.('expression') = {
    {'logiOr'}
    {'lambda'}
    };
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
    {newline,'commaSeparatedExprOrEmpty','matrix2'}
    {}
    };
grammar.('matrix') = {{'[','commaSeparatedExprOrEmpty','matrix2',']'}};
grammar.('cell') = {{'{','commaSeparatedExprOrEmpty','matrix2','}'}};
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
grammar.('expressionOrEmpty') = {
    {'expression'}
    {}
    };
grammar.('line') = {
    {newline,'expressionOrEmpty','line'}
    {}
    };
grammar.('code') = {{'expressionOrEmpty','line','eof'}};
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
grammar = preprocess(grammar,first,follow);
content = readFile('expr.txt');
tokens = tokenize(content);
tic
parse(tokens,grammar,'code',1);
toc
function content = readFile(filename)
    fid = fopen(filename);
    content = native2unicode(fread(fid).');
    fclose(fid);
    while contains(content, sprintf('\r\n'))
        content = replace(content, sprintf('\r\n'), newline);
    end
end
function i = parse(tokens,grammar,term,i)
    stack = cell(size(tokens));
    stack{1} = {term,1};
    count = 1;
    while count > 0
        term = stack{count}{1};
        j = stack{count}{2};
        if isa(term,'char')
            term = grammar.(term);
            token = tokens{i};
            index = find(strcmp(token.sym,term.first));
            if isempty(index)
                error('unexpected token');
            end
            index = term.index(index);
            term = term.grammar{index};
            stack{count}{1} = term;
        end
        while j <= numel(term)
            if isfield(grammar,term{j})
                stack{count}{2} = j+1;
                count = count+1;
                stack{count} = {term{j}, 1};
                break
            else
                token = tokens{i};
                if strcmp(token.sym,term{j})
                    i = i+1;
                    j = j+1;
                else
                    error('unexpected token');
                end
            end
        end
        if j > numel(term)
            count = count-1;
        end
    end
end
function tokens = tokenize(s)
    table = {
        '&&'
        '||'
        '.*'
        './'
        '.\'
        '.'''
        '=='
        '~='
        '<='
        '>='
        '('
        ')'
        '['
        ']'
        '{'
        '}'
        ';'
        ':'
        ','
        '+'
        '-'
        '*'
        '/'
        '\'
        '<'
        '>'
        '='
        '~'
        '.'
        '@'
        newline
        };
    j = 1;
    tokens = List();
    count = 0;
    lastToken = '';
    while j < numel(s)
        count = count + 1;
        [j, type, token, sym] = nextToken(s, j, table, lastToken);
        tokens.append(Token(type, token, sym));
        lastToken = type;
    end
    tokens.append(Token('eof','eof','eof'));
    tokens = tokens.list;
end
function [j, type, token, sym] = nextToken(s, j, table, lastToken)
    while j <= numel(s) && s(j) == ' '
        j = j + 1;
    end
    for i = 1 : numel(table)
        if j + numel(table{i}) - 1 <= numel(s) && strcmp(s(j : j + numel(table{i}) - 1), table{i})
            type = table{i};
            token = table{i};
            sym = table{i};
            j = j + numel(table{i});
            return
        end
    end
    if s(j) == ''''
        if strcmp(lastToken, 'identifier') || strcmp(lastToken, 'number')
            type = 'ctranspose';
            token = '''';
            sym = '''';
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
        sym = 'chars';
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
        sym = 'string';
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
            sym = token;
        else
            type = 'identifier';
            sym = 'identifier';
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
        sym = 'number';
        return
    end
    if s(j) == '%'
        i = j;
        while j <= numel(s) && s(j) ~= newline
            j = j + 1;
        end
        type = 'comment';
        token = s(i : j - 1);
        sym = 'comment';
        return
    end
    error('unknown token');
end
function follow = getFollow(follow,term,grammar,first)
    generatorList = grammar.(term);
    for i = 1:numel(generatorList)
        last = follow.(term);
        generator = generatorList{i};
        for j = numel(generator):-1:1
            if isfield(grammar,generator{j})
                vis = ismember(last,follow.(generator{j}));
                if ~all(vis)
                    follow.(grammar.(term){i}{j}) = [follow.(generator{j}), last(~vis)];
                    follow = getFollow(follow,generator{j},grammar,first);
                end
                f = [first.(generator{j}){:}];
                eps = strcmp(f,'');
                if any(eps)
                    vis = ismember(f,last);
                    last = [last, f(~(eps | vis))]; %#ok<AGROW>
                else
                    last = f(~eps);
                end
            else
                last = {generator{j}};
            end
        end
    end
end
function grammar = preprocess(grammar,first,follow)
    terms = fieldnames(grammar);
    for i = 1:numel(terms)
        term = terms{i};
        first_ = first.(term);
        empty = find(cellfun(@isempty,grammar.(term)));
        assert(numel(empty) <= 1);
        if ~isempty(empty)
            first_{empty} = follow.(term);
        end
        assert(numel(unique([first_{:}])) == numel([first_{:}]));
        index = arrayfun(@(i)repmat(i,size(first_{i})),1:numel(first_),'un',0);
        grammar_ = grammar.(term);
        grammar.(term) = struct();
        grammar.(term).('grammar') = grammar_;
        grammar.(term).('first') = [first_{:}];
        grammar.(term).('index') = [index{:}];
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
    generatorList = grammar.(term);
    set = cell(1, numel(generatorList));
    for i = 1:numel(generatorList)
        generator = generatorList{i};
        if isempty(generator)
            if ismember('',[set{:}])
                error('term %s has duplicate first token', term);
            end
            set{i} = {''};
            continue
        end
        set{i} = {};
        for j = 1:numel(generator)
            if isfield(grammar, generator{j})
                first = getFirst(first,generator{j},grammar);
                subset = [first.(generator{j}){:}];
                eps = strcmp(subset,'');
                if any(ismember(subset(~eps),[set{:}]))
                    error('term %s has duplicate first token', term);
                end
                set{i} = [set{i}, subset(~eps)];
                if ~any(eps)
                    break
                elseif j == numel(generator)
                    if ismember('',[set{:}])
                        error('term %s has duplicate first token', term);
                    end
                    set{i} = [set{i}, {''}];
                end
            else
                if ismember(generator{j},[set{:}])
                    error('term %s has duplicate first token', term);
                end
                set{i} = [set{i}, {generator{j}}];
                break
            end
        end
    end
    first.(term) = set;
end
function print(term,grammar,first,follow)
    assert(numel(grammar) == numel(first));
    eps = false;
    disp(term+": ");
    for i = 1:numel(grammar)
        if ~isempty(grammar{i})
            str = repmat(' ',1,4)+string(grammar{i}).join(' ');
        else
            str = repmat(' ',1,4)+"{}";
            eps = true;
        end
        str = str.pad(40);
        first_ = first{i};
        str = str+string(first_).join(' ');
        disp(str.replace(newline,'newline'));
    end
    if ~eps
        str = repmat(' ',1,4)+"`follow`";
        str = str.pad(40);
        str = str+string(follow).join(' ');
        disp(str.replace(newline,'newline'));
    end
end


