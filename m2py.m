function m2py(filename, node)
    fid = fopen(filename, 'at+');
    functions = arrayfun(@(x)isa(x, 'Function'), node);
    node = [node(functions), node(~functions)];
    outputNode(fid, 0, node, []);
    fclose(fid);
end
function outputNode(fid, indent, node, retval)
    assert(nargin == 4);
    if isempty(node)
    elseif numel(node) > 1
        for i = 1 : numel(node)
            outputNode(fid, indent, node(i), retval);
        end
    elseif isa(node, 'Segment')
        outputSegment(fid, indent, node, retval);
    elseif isa(node, 'Expression')
        outputExpression(fid, indent, node);
    else
        error('unexpected node');
    end
end
function patchSwitch(fid, indent, value, body, retval)
    assert(nargin == 5);
    for i = 1:numel(body)
        switch body(i).head.keyword
            case 'case'
                fprintf(fid, '%selif (', repmat(' ', 1, indent));
                outputExpression(fid, indent, value);
                fprintf(fid, ') == ');
                outputExpression(fid, indent, body(i).head.rvalue);
                fprintf(fid, ':\n');
                patchSwitchBody(fid, indent + 4, body(i).body, retval);
            case 'otherwise'
                fprintf(fid, '%selse:\n', repmat(' ', 1, indent));
                patchSwitchBody(fid, indent + 4, body(i).body, retval);
            otherwise
                error('unexpected token');
        end
    end
end
function patchSwitchBody(fid, indent, body, retval)
    assert(nargin == 4);
    if isempty(body)
        fprintf(fid, '%spass\n', repmat(' ', 1, indent));
    else
        outputNode(fid, indent + 4, body, retval);
    end
end
function outputSegment(fid, indent, node, retval)
    assert(nargin == 4);
    switch class(node)
        case 'Function'
            fprintf(fid, '%sdef ', repmat(' ', 1, indent));
            outputExpression(fid, indent, node.head.rvalue);
            fprintf(fid, ': # retval: ');
            retval = node.head.lvalue;
            if isempty(retval)
                outputExpression(fid, indent, Matrix(MatrixLine.empty()));
            else
                outputExpression(fid, indent, retval);
            end
            fprintf(fid, '\n');
            outputNode(fid, indent + 4, node.body, retval);
            fprintf(fid, '%sreturn', repmat(' ', 1, indent + 4));
            if ~isempty(retval)
                fprintf(fid, ' ');
                outputExpression(fid, indent, retval);
            end
            fprintf(fid, '\n');
            % outputSegment(fid, indent, node.end_);
        case 'While'
            outputSegment(fid, indent, node.head, retval);
            outputNode(fid, indent + 4, node.body, retval);
            % outputSegment(fid, indent, node.end_);
        case 'For'
            fprintf(fid, '%sfor ', repmat(' ', 1, indent));
            outputExpression(fid, indent, node.head.lvalue);
            fprintf(fid, ' in ');
            outputExpression(fid, indent, node.head.rvalue);
            fprintf(fid, ':\n');
            outputNode(fid, indent + 4, node.body, retval);
            % outputSegment(fid, indent, node.end_);
        case 'If'
            outputNode(fid, indent, node.body, retval);
            % outputSegment(fid, indent, node.end_);
        case 'IfBranch'
            outputSegment(fid, indent, node.head, retval);
            outputNode(fid, indent + 4, node.body, retval);
        case 'Switch'
            value = node.head.rvalue;
            fprintf(fid, '%sif False and ', repmat(' ', 1, indent));
            outputExpression(fid, indent, value);
            fprintf(fid, ':\n%spass\n', repmat(' ', 1, indent + 4));
            patchSwitch(fid, indent, value, node.body, retval);
            % outputNode(fid, indent, node.body);
            % outputSegment(fid, indent, node.end_);
        case 'SwitchCase'
            outputSegment(fid, indent, node.head, retval);
            outputNode(fid, indent + 4, node.body, retval);
        case 'Statement'
            fprintf(fid, repmat(' ', 1, indent));
            if ~isempty(node.keyword)
                fprintf(fid, '%s', node.keyword);
                if ~isempty(node.rvalue)
                    fprintf(fid, ' ');
                end
                if ~isempty(node.modifier)
                    fprintf(fid, '(');
                    for i = 1:numel(node.modifier)
                        outputExpression(fid, indent, node.modifier(i));
                    end
                    fprintf(fid, ')');
                end
                if strcmp(node.keyword, 'return') && ~isempty(retval)
                    fprintf(fid, ' ');
                    outputExpression(fid, indent, retval);
                end
            end
            if ~isempty(node.lvalue)
                outputExpression(fid, indent, node.lvalue);
                fprintf(fid, ' = ');
            end
            if ~isempty(node.rvalue)
                outputExpression(fid, indent, node.rvalue);
                if isempty(node.keyword)
                    fprintf(fid, ';');
                end
            end
            if ismember(node.keyword, {'if', 'elseif', 'else', 'while', 'for'})
                fprintf(fid, ':');
            end
            if ~isempty(node.comment)
                if ~isempty(node.keyword) || ~isempty(node.lvalue) || ~isempty(node.rvalue)
                    fprintf(fid, ' ');
                end
                fprintf(fid, '#%s', node.comment(2:end));
            end
            fprintf(fid, '\n');
        case 'ClassDef'
            outputSegment(fid, indent, node.head, retval);
            outputNode(fid, indent + 4, node.property, retval);
            outputNode(fid, indent + 4, node.method, retval);
            outputSegment(fid, indent, node.end_, retval);
        case 'Properties'
            outputSegment(fid, indent, node.head, retval);
            outputNode(fid, indent + 4, node.prop, retval);
            outputSegment(fid, indent, node.end_, retval);
        case 'Methods'
            outputSegment(fid, indent, node.head, retval);
            outputNode(fid, indent + 4, node.fun, retval);
            outputSegment(fid, indent, node.end_, retval);
        case 'Variable'
            fprintf(fid, repmat(' ', 1, indent));
            fprintf(fid, '%s', node.name);
            if ~isempty(node.type)
                fprintf(fid, ' %s', node.type);
            end
            if ~isempty(node.default)
                fprintf(fid, ' = ');
                outputExpression(fid, indent, node.default);
            end
            if ~isempty(node.comment)
                fprintf(fid, ' %s', node.comment);
            end
            fprintf(fid, '\n');
        otherwise
            error('unexpected node');
    end
end
function outputExpression(fid, indent, node)
    assert(nargin == 3);
    switch class(node)
        case 'Literal'
            if startsWith(node.value, '''')
                fprintf(fid, '''%s''', replace(replace(node.value(2:end-1),'\','\\'), '''''', '\'''));
            elseif startsWith(node.value, '"')
                fprintf(fid, '''%s''', replace(replace(node.value(2:end-1),'\','\\'), '""', '\"'));
            else
                fprintf(fid, '%s', node.value);
            end
        case 'Identifier'
            fprintf(fid, '%s', node.identifier);
        case 'Field'
            outputExpression(fid, indent, node.value);
            fprintf(fid, '.');
            if ~isa(node.field, 'Identifier')
                fprintf(fid, '(');
            end
            outputExpression(fid, indent, node.field);
            if ~isa(node.field, 'Identifier')
                fprintf(fid, ')');
            end
        case 'Paren'
            fprintf(fid, '(');
            outputExpression(fid, indent, node.value);
            fprintf(fid, ')');
        case 'Not'
            fprintf(fid, 'not ');
            outputExpression(fid, indent, node.value);
        case 'Transpose'
            fprintf(fid, 'tr(');
            outputExpression(fid, indent, node.value);
            fprintf(fid, ')');
        case 'Lambda'
            fprintf(fid, 'lambda ');
            if ~(isempty(node.args) && isa(node.expr, 'Identifier'))
                for i = 1 : numel(node.args)
                    outputExpression(fid, indent, node.args(i));
                    if i < numel(node.args)
                        fprintf(fid, ', ');
                    end
                end
            else
                fprintf(fid, '*args');
            end
            fprintf(fid, ': ');
            outputExpression(fid, indent, node.expr);
            if isempty(node.args) && isa(node.expr, 'Identifier')
                fprintf(fid, '(*args)');
            end
        case 'Colon'
            if isempty(node.begin) && isempty(node.step) && isempty(node.end_)
                fprintf(fid, 'colon(None, None, None)');
            elseif isempty(node.step)
                fprintf(fid, 'colon(');
                outputExpression(fid, indent, node.begin);
                fprintf(fid, ', ');
                outputExpression(fid, indent, node.end_);
                fprintf(fid, ')');
            else
                fprintf(fid, 'colon(');
                outputExpression(fid, indent, node.begin);
                fprintf(fid, ', ');
                outputExpression(fid, indent, node.step);
                fprintf(fid, ', ');
                outputExpression(fid, indent, node.end_);
                fprintf(fid, ')');
            end
        case 'PIndex'
            outputExpression(fid, indent, node.value);
            fprintf(fid, '(');
            for i = 1 : numel(node.index)
                outputExpression(fid, indent, node.index(i));
                if i < numel(node.index)
                    fprintf(fid, ', ');
                end
            end
            fprintf(fid, ')');
        case 'BIndex'
            outputExpression(fid, indent, node.value);
            fprintf(fid, '(');
            for i = 1 : numel(node.index)
                outputExpression(fid, indent, node.index(i));
                if i < numel(node.index)
                    fprintf(fid, ', ');
                end
            end
            fprintf(fid, ')');
        case 'MatrixLine'
            for i = 1 : numel(node.item)
                outputExpression(fid, indent, node.item(i));
                if i < numel(node.item)
                    fprintf(fid, ', ');
                end
            end
        case 'Matrix'
            fprintf(fid, '[');
            if numel(node.line) > 1
                fprintf(fid, '\n');
                fprintf(fid, '%s', repmat(' ', 1, indent + 4));
            end
            for i = 1 : numel(node.line)
                outputExpression(fid, indent, node.line(i));
                if numel(node.line) > 1
                    fprintf(fid, '\n');
                    fprintf(fid, '%s', repmat(' ', 1, indent + 4));
                end
            end
            fprintf(fid, ']');
        case 'Cell'
            fprintf(fid, '[');
            if numel(node.line) > 1
                fprintf(fid, '\n');
            end
            for i = 1 : numel(node.line)
                outputExpression(fid, indent, node.line(i));
                if numel(node.line) > 1
                    fprintf(fid, '\n');
                end
            end
            fprintf(fid, ']');
        case 'LT'
            outputExpression(fid, indent, node.a);
            fprintf(fid, ' < ');
            outputExpression(fid, indent, node.b);
        case 'GT'
            outputExpression(fid, indent, node.a);
            fprintf(fid, ' > ');
            outputExpression(fid, indent, node.b);
        case 'LE'
            outputExpression(fid, indent, node.a);
            fprintf(fid, ' <= ');
            outputExpression(fid, indent, node.b);
        case 'GE'
            outputExpression(fid, indent, node.a);
            fprintf(fid, ' >= ');
            outputExpression(fid, indent, node.b);
        case 'EQ'
            outputExpression(fid, indent, node.a);
            fprintf(fid, ' == ');
            outputExpression(fid, indent, node.b);
        case 'NE'
            outputExpression(fid, indent, node.a);
            fprintf(fid, ' != ');
            outputExpression(fid, indent, node.b);
        case 'Plus'
            outputExpression(fid, indent, node.a);
            fprintf(fid, ' + ');
            outputExpression(fid, indent, node.b);
        case 'Minus'
            outputExpression(fid, indent, node.a);
            fprintf(fid, ' - ');
            outputExpression(fid, indent, node.b);
        case 'And'
            outputExpression(fid, indent, node.a);
            fprintf(fid, ' and ');
            outputExpression(fid, indent, node.b);
        case 'Or'
            outputExpression(fid, indent, node.a);
            fprintf(fid, ' or ');
            outputExpression(fid, indent, node.b);
        case 'MTimes'
            outputExpression(fid, indent, node.a);
            fprintf(fid, ' * ');
            outputExpression(fid, indent, node.b);
        case 'Modifier'
            if ~isempty(node.lvalue)
                outputExpression(fid, indent, node.lvalue);
                fprintf(fid, '=');
            end
            outputExpression(fid, indent, node.rvalue);
        otherwise
            error('unexpected node');
    end
end
