function m2py(filename, node)
    fid = fopen(filename, 'at+');
    fprintf(fid, 'from mruntime import *\n');
    functions = arrayfun(@(x)isa(x, 'Function'), node);
    node = [node(functions), node(~functions)];
    [~] = outputNode(fid, 0, node, [], struct());
    fclose(fid);
end
function env = outputNode(fid, indent, node, retval, env)
    assert(nargin == 5);
    assert(nargout == 1);
    if isempty(node)
    elseif numel(node) > 1
        for i = 1 : numel(node)
            env = outputNode(fid, indent, node(i), retval, env);
        end
    elseif isa(node, 'Segment')
        env = outputSegment(fid, indent, node, retval, env);
    elseif isa(node, 'Expression')
        outputExpression(fid, indent, node);
    else
        error('unexpected node');
    end
end
function env = patchSwitch(fid, indent, value, body, retval, env)
    assert(nargin == 6);
    assert(nargout == 1);
    for i = 1:numel(body)
        switch body(i).head.keyword
            case 'case'
                fprintf(fid, '%selif (', repmat(' ', 1, indent));
                outputExpression(fid, indent, value, env);
                if isa(body(i).head.rvalue, 'Cell')
                    fprintf(fid, ') in ');
                else
                    fprintf(fid, ') == ');
                end
                outputExpression(fid, indent, body(i).head.rvalue, env);
                fprintf(fid, ':\n');
                env = patchSwitchBody(fid, indent + 4, body(i).body, retval, env);
            case 'otherwise'
                fprintf(fid, '%selse:\n', repmat(' ', 1, indent));
                env = patchSwitchBody(fid, indent + 4, body(i).body, retval, env);
            otherwise
                error('unexpected token');
        end
    end
end
function env = patchSwitchBody(fid, indent, body, retval, env)
    assert(nargin == 5);
    assert(nargout == 1);
    if isempty(body)
        fprintf(fid, '%spass\n', repmat(' ', 1, indent));
    else
        env = outputNode(fid, indent, body, retval, env);
    end
end
function env = patchAssign(env, node)
    assert(nargin == 2);
    assert(nargout == 1);
    if isempty(node)
        return
    end
    if numel(node) > 1
        for i = 1:numel(node)
            env = patchAssign(env, node(i));
        end
        return
    end
    switch class(node)
        case 'Statement'
            env = patchAssign(env, node.lvalue);
        case 'Matrix'
            env = patchAssign(env, node.line);
        case 'MatrixLine'
            env = patchAssign(env, node.item);
        case {'Field', 'PIndex', 'BIndex'}
            env = patchAssign(env, node.value);
        case 'Identifier'
            env.(node.identifier) = 'identifier';
        otherwise
            error('unexpected node');
    end
end
function env = outputSegment(fid, indent, node, retval, env)
    assert(nargin == 5);
    assert(nargout == 1);
    switch class(node)
        case 'Function'
            newEnv = struct();
            fprintf(fid, '%sdef ', repmat(' ', 1, indent));
            outputExpression(fid, indent, node.head.rvalue.value, env);
            fprintf(fid, '(');
            for i = 1:numel(node.head.rvalue.index)
                outputExpression(fid, indent, node.head.rvalue.index(i), env);
                newEnv = patchAssign(newEnv, node.head.rvalue.index(i));
                if i < numel(node.head.rvalue.index)
                    fprintf(fid, ', ');
                end
            end
            fprintf(fid, '): # retval: ');
            retval = node.head.lvalue;
            if isempty(retval)
                outputExpression(fid, indent, Matrix(MatrixLine.empty()), env);
            else
                outputExpression(fid, indent, retval, env);
            end
            fprintf(fid, '\n');
            newEnv = outputNode(fid, indent + 4, node.body, retval, newEnv);
            fprintf(fid, '%sreturn', repmat(' ', 1, indent + 4));
            if ~isempty(retval)
                fprintf(fid, ' ');
                outputExpression(fid, indent, retval, newEnv);
            end
            fprintf(fid, '\n');
            % outputSegment(fid, indent, node.end_);
        case 'While'
            env = outputSegment(fid, indent, node.head, retval, env);
            env = outputNode(fid, indent + 4, node.body, retval, env);
            % outputSegment(fid, indent, node.end_);
        case 'For'
            fprintf(fid, '%sfor ', repmat(' ', 1, indent));
            outputExpression(fid, indent, node.head.lvalue, env);
            fprintf(fid, ' in ');
            outputExpression(fid, indent, node.head.rvalue, env);
            fprintf(fid, ':\n');
            env = outputNode(fid, indent + 4, node.body, retval, env);
            % outputSegment(fid, indent, node.end_);
        case 'If'
            env = outputNode(fid, indent, node.body, retval, env);
            % outputSegment(fid, indent, node.end_);
        case 'IfBranch'
            env = outputSegment(fid, indent, node.head, retval, env);
            env = outputNode(fid, indent + 4, node.body, retval, env);
        case 'Switch'
            value = node.head.rvalue;
            fprintf(fid, '%sif False and ', repmat(' ', 1, indent));
            outputExpression(fid, indent, value, env);
            fprintf(fid, ':\n%spass\n', repmat(' ', 1, indent + 4));
            env = patchSwitch(fid, indent, value, node.body, retval, env);
            % outputNode(fid, indent, node.body);
            % outputSegment(fid, indent, node.end_);
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
                        outputExpression(fid, indent, node.modifier(i), env);
                    end
                    fprintf(fid, ')');
                end
                if strcmp(node.keyword, 'return') && ~isempty(retval)
                    fprintf(fid, ' ');
                    outputExpression(fid, indent, retval, env);
                end
            end
            if ~isempty(node.lvalue)
                outputExpression(fid, indent, node.lvalue, env);
                fprintf(fid, ' = ');
            end
            if ~isempty(node.rvalue)
                outputExpression(fid, indent, node.rvalue, env);
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
            env = patchAssign(env, node);
        case 'ClassDef'
            if isa(node.head.rvalue, 'LT') && isa(node.head.rvalue.b, 'Identifier')
                fprintf(fid, 'from m2py.nodes.');
                outputExpression(fid, indent, node.head.rvalue.b, env);
                fprintf(fid, ' import ');
                outputExpression(fid, indent, node.head.rvalue.b, env);
                fprintf(fid, '\n');
            end
            fprintf(fid, '%sclass ', repmat(' ', 1, indent));
            if isa(node.head.rvalue, 'LT')
                outputExpression(fid, indent, node.head.rvalue.a, env);
                if isa(node.head.rvalue.b, 'Identifier')
                    fprintf(fid, '(');
                    outputExpression(fid, indent, node.head.rvalue.b, env);
                    fprintf(fid, ')');
                end
                className = node.head.rvalue.a.identifier;
            else
                outputExpression(fid, indent, node.head.rvalue, env);
                className = node.head.rvalue.identifier;
            end
            fprintf(fid, ':\n');
            for k = 1:numel(node.method)
                for i = 1:numel(node.method(k).fun)
                    fprintf(fid, '%sdef ', repmat(' ', 1, indent + 4));
                    funName = node.method(k).fun(i).head.rvalue.value.identifier;
                    if strcmp(className, funName)
                        fprintf(fid, '%s', '__init__');
                    else
                        fprintf(fid, '%s', funName);
                    end
                    fprintf(fid, '(self, *nargin): # retval: ');
                    retval = node.method(k).fun(i).head.lvalue;
                    if isempty(retval)
                        outputExpression(fid, indent + 4, Matrix(MatrixLine.empty()), env);
                    else
                        outputExpression(fid, indent + 4, retval, env);
                    end
                    fprintf(fid, '\n');
                    fprintf(fid, '%s[', repmat(' ', 1, indent + 8));
                    for j = 1:numel(node.method(k).fun(i).head.rvalue.index)
                        outputExpression(fid, indent + 4, node.method(k).fun(i).head.rvalue.index(j), env);
                        if j < numel(node.method(k).fun(i).head.rvalue.index)
                            fprintf(fid, ', ');
                        end
                    end
                    fprintf(fid, '] = nargin\n%snargin = len(nargin)\n', repmat(' ', 1, indent + 8));
                    env = outputNode(fid, indent + 8, node.method(k).fun(i).body, retval, env);
                    if ~strcmp(className, funName)
                        fprintf(fid, '%sreturn', repmat(' ', 1, indent + 8));
                        if ~isempty(retval)
                            fprintf(fid, ' ');
                            outputExpression(fid, indent + 4, retval, env);
                        end
                        fprintf(fid, '\n');
                    end
                end
            end
            fprintf(fid, '%s@staticmethod\n', repmat(' ', 1, indent + 4));
            fprintf(fid, '%sdef empty():\n', repmat(' ', 1, indent + 4));
            fprintf(fid, '%spass\n', repmat(' ', 1, indent + 8));
            % outputSegment(fid, indent, node.head, retval);
            % outputNode(fid, indent + 4, node.property, retval);
            % outputNode(fid, indent + 4, node.method, retval);
            % outputSegment(fid, indent, node.end_, retval);
        case 'Properties'
            env = outputSegment(fid, indent, node.head, retval, env);
            env = outputNode(fid, indent + 4, node.prop, retval, env);
            env = outputSegment(fid, indent, node.end_, retval, env);
        case 'Methods'
            env = outputSegment(fid, indent, node.head, retval, env);
            env = outputNode(fid, indent + 4, node.fun, retval, env);
            env = outputSegment(fid, indent, node.end_, retval, env);
        case 'Variable'
            fprintf(fid, repmat(' ', 1, indent));
            fprintf(fid, '%s', node.name);
            if ~isempty(node.type)
                fprintf(fid, ' %s', node.type);
            end
            if ~isempty(node.default)
                fprintf(fid, ' = ');
                outputExpression(fid, indent, node.default, env);
            end
            if ~isempty(node.comment)
                fprintf(fid, ' %s', node.comment);
            end
            fprintf(fid, '\n');
        otherwise
            error('unexpected node');
    end
end
function outputExpression(fid, indent, node, env)
    assert(nargin == 4);
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
            outputExpression(fid, indent, node.value, env);
            fprintf(fid, '.');
            if ~isa(node.field, 'Identifier')
                fprintf(fid, '(');
            end
            outputExpression(fid, indent, node.field, env);
            if ~isa(node.field, 'Identifier')
                fprintf(fid, ')');
            end
        case 'Paren'
            fprintf(fid, '(');
            outputExpression(fid, indent, node.value, env);
            fprintf(fid, ')');
        case 'Not'
            fprintf(fid, 'not ');
            outputExpression(fid, indent, node.value, env);
        case 'Transpose'
            fprintf(fid, 'tr(');
            outputExpression(fid, indent, node.value, env);
            fprintf(fid, ')');
        case 'Lambda'
            fprintf(fid, 'lambda ');
            if ~(isempty(node.args) && isa(node.expr, 'Identifier'))
                for i = 1 : numel(node.args)
                    outputExpression(fid, indent, node.args(i), env);
                    if i < numel(node.args)
                        fprintf(fid, ', ');
                    end
                end
            else
                fprintf(fid, '*args');
            end
            fprintf(fid, ': ');
            outputExpression(fid, indent, node.expr, env);
            if isempty(node.args) && isa(node.expr, 'Identifier')
                fprintf(fid, '(*args)');
            end
        case 'Colon'
            if isempty(node.begin) && isempty(node.step) && isempty(node.end_)
                fprintf(fid, 'colon(None, None, None)');
            elseif isempty(node.step)
                fprintf(fid, 'colon(');
                outputExpression(fid, indent, node.begin, env);
                fprintf(fid, ', ');
                outputExpression(fid, indent, node.end_, env);
                fprintf(fid, ')');
            else
                fprintf(fid, 'colon(');
                outputExpression(fid, indent, node.begin, env);
                fprintf(fid, ', ');
                outputExpression(fid, indent, node.step, env);
                fprintf(fid, ', ');
                outputExpression(fid, indent, node.end_, env);
                fprintf(fid, ')');
            end
        case 'PIndex'
            if isa(node.value, 'Identifier') && ~(isfield(env, node.value.identifier) && strcmp(env.(node.value.identifier), 'identifier'))
                outputExpression(fid, indent, node.value, env);
                fprintf(fid, '(');
                for i = 1 : numel(node.index)
                    outputExpression(fid, indent, node.index(i), env);
                    if i < numel(node.index)
                        fprintf(fid, ', ');
                    end
                end
                fprintf(fid, ')');
            else
                fprintf(fid, 'mparen(');
                outputExpression(fid, indent, node.value, env);
                if ~isempty(node.index)
                    fprintf(fid, ', ');
                    for i = 1 : numel(node.index)
                        outputExpression(fid, indent, node.index(i), env);
                        if i < numel(node.index)
                            fprintf(fid, ', ');
                        end
                    end
                end
                fprintf(fid, ')');
            end
        case 'BIndex'
            outputExpression(fid, indent, node.value, env);
            for i = 1 : numel(node.index)
                fprintf(fid, '[(');
                outputExpression(fid, indent, node.index(i), env);
                fprintf(fid, ')-1]');
            end
        case 'MatrixLine'
            for i = 1 : numel(node.item)
                outputExpression(fid, indent, node.item(i), env);
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
                outputExpression(fid, indent, node.line(i), env);
                if numel(node.line) > 1
                    fprintf(fid, ',\n');
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
                outputExpression(fid, indent, node.line(i), env);
                if numel(node.line) > 1
                    fprintf(fid, '\n');
                end
            end
            fprintf(fid, ']');
        case 'LT'
            outputExpression(fid, indent, node.a, env);
            fprintf(fid, ' < ');
            outputExpression(fid, indent, node.b, env);
        case 'GT'
            outputExpression(fid, indent, node.a, env);
            fprintf(fid, ' > ');
            outputExpression(fid, indent, node.b, env);
        case 'LE'
            outputExpression(fid, indent, node.a, env);
            fprintf(fid, ' <= ');
            outputExpression(fid, indent, node.b, env);
        case 'GE'
            outputExpression(fid, indent, node.a, env);
            fprintf(fid, ' >= ');
            outputExpression(fid, indent, node.b, env);
        case 'EQ'
            outputExpression(fid, indent, node.a, env);
            fprintf(fid, ' == ');
            outputExpression(fid, indent, node.b, env);
        case 'NE'
            outputExpression(fid, indent, node.a, env);
            fprintf(fid, ' != ');
            outputExpression(fid, indent, node.b, env);
        case 'Plus'
            outputExpression(fid, indent, node.a, env);
            fprintf(fid, ' + ');
            outputExpression(fid, indent, node.b, env);
        case 'Minus'
            outputExpression(fid, indent, node.a, env);
            fprintf(fid, ' - ');
            outputExpression(fid, indent, node.b, env);
        case 'And'
            outputExpression(fid, indent, node.a, env);
            fprintf(fid, ' and ');
            outputExpression(fid, indent, node.b, env);
        case 'Or'
            outputExpression(fid, indent, node.a, env);
            fprintf(fid, ' or ');
            outputExpression(fid, indent, node.b, env);
        case 'MTimes'
            outputExpression(fid, indent, node.a, env);
            fprintf(fid, ' * ');
            outputExpression(fid, indent, node.b, env);
        case 'Modifier'
            if ~isempty(node.lvalue)
                outputExpression(fid, indent, node.lvalue, env);
                fprintf(fid, '=');
            end
            outputExpression(fid, indent, node.rvalue, env);
        otherwise
            error('unexpected node');
    end
end
