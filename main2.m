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
    {'&','compare','elemAnd'}
    {}
    };
grammar.('elemAnd') = {{'compare','elemAnd2'}};
grammar.('elemOr2') = {
    {'|','compare','elemAnd'}
    {}
    };
grammar.('elemOr') = {{'elemAnd','elemOr2'}};
grammar.('logiAnd2') = {
    {'&&','elemOr','logiAnd2'}
    {}
    };
grammar.('logiAnd') = {{'elemOr','logiAnd2'}};

grammar.('logiOr2') = {
    {'&&','logiAnd','logiOr2'}
    {}
    };
grammar.('logiOr') = {{'logiAnd','logiOr2'}};
grammar.('expression') = {{'logiOr'}};
grammar.('commaSeparatedExpr2') = {
    {',','expression','commaSeparatedExpr2'}
    {}
    };
grammar.('commaSeparatedExpr') = {{'expression','commaSeparatedExpr2'}};
grammar.('entry') = {{'expression',-1}};
terms = fieldnames(grammar);
first = struct();
for i = 1:numel(terms)
    first = getFirst(first,terms{i},grammar);
end
function first = getFirst(first,term,grammar)
    if isfield(first, term)
        if isempty(first.(term))
            error('term %s has recursive definition', term);
        end
        return
    end
    first.(term) = {};
    set = {};
    for i = 1:numel(grammar.(term))
        if isempty(grammar.(term){i})
            if ismember('',set)
                error('term %s has duplicate first token', term);
            end
            set = [set, {''}]; %#ok<AGROW>
            continue
        end
        for j = 1:numel(grammar.(term){i})
            if isfield(grammar, grammar.(term){i}{j})
                first = getFirst(first,grammar.(term){i}{j},grammar);
                eps = strcmp(first.(grammar.(term){i}{j}),'');
                if any(ismember(first.(grammar.(term){i}{j})(~eps),set))
                    error('term %s has duplicate first token', term);
                end
                set = [set, first.(grammar.(term){i}{j})(~eps)]; %#ok<AGROW>
                if ~any(eps)
                    break
                elseif j == numel(grammar.(term){i})
                    if ismember('',set)
                        error('term %s has duplicate first token', term);
                    end
                    set = [set, {''}]; %#ok<AGROW>
                end
            else
                if ismember(grammar.(term){i}{j},set)
                    error('term %s has duplicate first token', term);
                end
                set = [set, {grammar.(term){i}{j}}]; %#ok<AGROW>
                break
            end
        end
    end
    first.(term) = set;
end


