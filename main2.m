clc();
clear();
close('all');
grammar = struct();
grammar.('fieldExpr') = {
    {'identifier'}
    {'(','expression',')'}
    };
grammar.('field') = {{'.', 'fieldExpr'}};
grammar.('pindex') = {{'(', 'commaSeparatedExpr',')'}};
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
grammar.('entry') = {{'expression','eof'}};
terms = fieldnames(grammar);
first = struct();
follow = struct();
for i = 1:numel(terms)
    first = getFirst(first,terms{i},grammar);
    follow.(terms{i}) = {};
end
follow = getFollow(follow,'entry',grammar,first);
for i = 1:numel(terms)
    assert(~ismember('',[first.(terms{i}){:}]) || ~(any(ismember([first.(terms{i}){:}],follow.(terms{i}))) || any(ismember(follow.(terms{i}),[first.(terms{i}){:}]))));
    print(terms{i},grammar.(terms{i}),first.(terms{i}),follow.(terms{i}));
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
    disp(term+": "+string(follow).join(' '));
    for i = 1:numel(grammar)
        str = repmat(' ',1,4)+string(grammar{i}).join(' ');
        str = str.pad(40);
        str = str+string(first{i}).join(' ');
        disp(str);
    end
end


