function output(filename, node)
    fid = fopen(filename, 'wt+');
    outputNode(fid, 0, node);
    fclose(fid);
end
function outputNode(fid, indent, node)
    if isempty(node)
    elseif numel(node) > 1
        for i = 1 : numel(node)
            outputNode(fid, indent, node(i));
        end
    elseif isa(node, 'Segment')
        outputSegment(fid, indent, node);
    elseif isa(node, 'Expression')
        outputExpression(fid, indent, node);
    else
        error('unexpected node');
    end
end
function outputSegment(fid, indent, node)
    switch class(node)
        case 'Function'
            outputSegment(fid, indent, node.head);
            outputNode(fid, indent + 4, node.body);
            outputSegment(fid, indent, node.end_);
        case 'While'
            outputSegment(fid, indent, node.head);
            outputNode(fid, indent + 4, node.body);
            outputSegment(fid, indent, node.end_);
        case 'For'
            outputSegment(fid, indent, node.head);
            outputNode(fid, indent + 4, node.body);
            outputSegment(fid, indent, node.end_);
        case 'If'
            outputNode(fid, indent, node.body);
            outputSegment(fid, indent, node.end_);
        case 'IfBranch'
            outputSegment(fid, indent, node.head);
            outputNode(fid, indent + 4, node.body);
        case 'Switch'
            outputSegment(fid, indent, node.head);
            outputNode(fid, indent + 4, node.body);
            outputSegment(fid, indent, node.end_);
        case 'SwitchCase'
            outputSegment(fid, indent, node.head);
            outputNode(fid, indent + 4, node.body);
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
            if ~isempty(node.comment)
                if ~isempty(node.keyword) || ~isempty(node.lvalue) || ~isempty(node.rvalue)
                    fprintf(fid, ' ');
                end
                fprintf(fid, '%s', node.comment);
            end
            fprintf(fid, '\n');
        case 'ClassDef'
            outputSegment(fid, indent, node.head);
            outputNode(fid, indent + 4, node.property);
            outputNode(fid, indent + 4, node.method);
            outputSegment(fid, indent, node.end_);
        case 'Properties'
            outputSegment(fid, indent, node.head);
            outputNode(fid, indent + 4, node.prop);
            outputSegment(fid, indent, node.end_);
        case 'Methods'
            outputSegment(fid, indent, node.head);
            outputNode(fid, indent + 4, node.fun);
            outputSegment(fid, indent, node.end_);
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
    switch class(node)
        case 'Literal'
            fprintf(fid, '%s', node.value);
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
            fprintf(fid, '~');
            outputExpression(fid, indent, node.value);
        case 'Transpose'
            outputExpression(fid, indent, node.value);
            fprintf(fid, '.''');
        case 'Lambda'
            fprintf(fid, '@');
            if ~(isempty(node.args) && isa(node.expr, 'Identifier'))
                fprintf(fid, '(');
                for i = 1 : numel(node.args)
                    outputExpression(fid, indent, node.args(i));
                    if i < numel(node.args)
                        fprintf(fid, ', ');
                    end
                end
                fprintf(fid, ')');
            end
            outputExpression(fid, indent, node.expr);
        case 'Colon'
            if isempty(node.begin) && isempty(node.step) && isempty(node.end_)
                fprintf(fid, ':');
            elseif isempty(node.step)
                outputExpression(fid, indent, node.begin);
                fprintf(fid, ' : ');
                outputExpression(fid, indent, node.end_);
            else
                outputExpression(fid, indent, node.begin);
                fprintf(fid, ' : ');
                outputExpression(fid, indent, node.step);
                fprintf(fid, ' : ');
                outputExpression(fid, indent, node.end_);
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
            fprintf(fid, '{');
            for i = 1 : numel(node.index)
                outputExpression(fid, indent, node.index(i));
                if i < numel(node.index)
                    fprintf(fid, ', ');
                end
            end
            fprintf(fid, '}');
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
            fprintf(fid, '{');
            if numel(node.line) > 1
                fprintf(fid, '\n');
            end
            for i = 1 : numel(node.line)
                outputExpression(fid, indent, node.line(i));
                if numel(node.line) > 1
                    fprintf(fid, '\n');
                end
            end
            fprintf(fid, '}');
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
            fprintf(fid, ' ~= ');
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
            fprintf(fid, ' && ');
            outputExpression(fid, indent, node.b);
        case 'Or'
            outputExpression(fid, indent, node.a);
            fprintf(fid, ' || ');
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
