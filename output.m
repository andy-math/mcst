function output(fid,node,indent)
    if iscell(node)
        for i = 1:numel(node)
            output(fid,node{i},indent);
        end
        return
    end
    if isempty(node)
        return
    end
    if ~isstruct(node)
        warning('unknown node');
        disp(node);
        return
    end
    switch node.type
        case 'newline'
            printf(fid,indent,'\n');
        case 'colon'
            output(fid,node.args{1},indent);
            printf(fid,indent,' : ');
            output(fid,node.args{2},indent);
            if numel(node.args) == 3
                printf(fid,indent,' : ');
                output(fid,node.args{3},indent);
            end
        case 'keyword'
            printf(fid,indent,'%s\n',node.args{1});
        case 'comment'
            if ~isempty(node.args{1})
                printf(fid,indent,'');
                output(fid,node.args{1},0);
                printf(fid,0,'; %s\n',node.args{2});
            else
                printf(fid,indent,'%s\n',node.args{2});
            end
        case 'and'
            output(fid,node.args{1},indent);
            printf(fid,indent,' && ');
            output(fid,node.args{2},indent);
        case 'not'
            printf(fid,indent,'~');
            output(fid,node.args{1},indent);
        case 'or'
            output(fid,node.args{1},indent);
            printf(fid,indent,' || ');
            output(fid,node.args{2},indent);
        case 'le'
            output(fid,node.args{1},indent);
            printf(fid,indent,' <= ');
            output(fid,node.args{2},indent);
        case 'gt'
            output(fid,node.args{1},indent);
            printf(fid,indent,' > ');
            output(fid,node.args{2},indent);
        case 'lt'
            output(fid,node.args{1},indent);
            printf(fid,indent,' < ');
            output(fid,node.args{2},indent);
        case 'eq'
            output(fid,node.args{1},indent);
            printf(fid,indent,' == ');
            output(fid,node.args{2},indent);
        case 'ne'
            output(fid,node.args{1},indent);
            printf(fid,indent,' ~= ');
            output(fid,node.args{2},indent);
        case 'plus'
            output(fid,node.args{1},indent);
            printf(fid,indent,' + ');
            output(fid,node.args{2},indent);
        case 'minus'
            output(fid,node.args{1},indent);
            printf(fid,indent,' - ');
            output(fid,node.args{2},indent);
        case 'while'
            printf(fid,indent,'while ');
            output(fid,node.args{1},0);
            printf(fid,0,'\n');
            for i = 1:numel(node.args{2})
                output(fid,node.args{2}{i},indent+4);
            end
            printf(fid,indent,'end\n');
        case 'if'
            for i = 1:numel(node.args{1})
                if i == 1
                    printf(fid,indent,'if ');
                elseif ~isempty(node.args{1}{i}.args{1})
                    printf(fid,indent,'elseif ');
                else
                    printf(fid,indent,'else');
                end
                output(fid,node.args{1}{i},indent+4);
            end
            printf(fid,indent,'end\n');
        case 'switch'
            printf(fid,indent,'switch ');
            output(fid,node.args{1},0);
            printf(fid,0,'\n');
            for i = 1:numel(node.args{2})
                if ~isempty(node.args{2}{i}.args{1})
                    printf(fid,indent+4,'case ');
                else
                    printf(fid,indent+4,'otherwise');
                end
                output(fid,node.args{2}{i},indent+8);
            end
            printf(fid,indent,'end\n');
        case 'branch'
            if ~isempty(node.args{1})
                output(fid,node.args{1},0);
            end
            printf(fid,0,'\n');
            for i = 1:numel(node.args{2})
                output(fid,node.args{2}{i},indent);
            end
        case 'case'
            if ~isempty(node.args{1})
                output(fid,node.args{1},0);
            end
            printf(fid,0,'\n');
            for i = 1:numel(node.args{2})
                output(fid,node.args{2}{i},indent);
            end
        case 'transpose'
            output(fid,node.args{1},indent);
            printf(fid,indent,'.''');
        case 'statement'
            printf(fid,indent,'');
            output(fid,node.args{1},0);
            printf(fid,0,';\n');
        case 'literal'
            printf(fid,indent,'%s',node.args{1});
        case 'pindex'
            output(fid,node.args{1},indent);
            printf(fid,indent,'(');
            for i = 1:numel(node.args{2})-1
                output(fid,node.args{2}{i},indent);
                printf(fid,indent,', ');
            end
            if ~isempty(node.args{2})
                output(fid,node.args{2}{end},indent);
            end
            printf(fid,indent,')');
        case 'bindex'
            output(fid,node.args{1},indent);
            printf(fid,indent,'{');
            for i = 1:numel(node.args{2})-1
                output(fid,node.args{2}{i},indent);
                printf(fid,indent,', ');
            end
            if ~isempty(node.args{2})
                output(fid,node.args{2}{end},indent);
            end
            printf(fid,indent,'}');
        case 'field'
            output(fid,node.args{1},indent);
            printf(fid,indent,'.%s',node.args{2});
        case 'function'
            printf(fid,indent,'function ');
            output(fid,node.args{1},0);
            printf(fid,indent,'\n');
            for i = 1:numel(node.args{2})
                output(fid,node.args{2}{i},indent+4);
            end
            printf(fid,indent,'end\n');
        case 'for'
            printf(fid,indent,'for ');
            output(fid,node.args{1},0);
            printf(fid,indent,'\n');
            for i = 1:numel(node.args{2})
                output(fid,node.args{2}{i},indent+4);
            end
            printf(fid,indent,'end\n');
        case 'assign'
            output(fid,node.args{1},indent);
            printf(fid,indent,' = ');
            output(fid,node.args{2},indent);
        case 'paren'
            printf(fid,indent,'(');
            output(fid,node.args{1},indent);
            printf(fid,indent,')');
        case 'identifier'
            printf(fid,indent,'%s',node.args{1});
        case 'matrix'
            printf(fid,indent,'[');
            last = false;
            for i = 1:numel(node.args{1})
                now = ~strcmp(node.args{1}{i}.type,'newline');
                if last && now
                    printf(fid,0,', ');
                end
                output(fid,node.args{1}{i},indent);
                last = now;
            end
            printf(fid,indent,']');
        case 'cell'
            printf(fid,indent,'{');
            last = false;
            for i = 1:numel(node.args{1})
                now = ~strcmp(node.args{1}{i}.type,'newline');
                if last && now
                    printf(fid,0,', ');
                end
                output(fid,node.args{1}{i},indent);
                last = now;
            end
            printf(fid,indent,'}');
        case 'bracket'
            printf(fid,indent,'{');
            for i = 1:numel(node.args{1})-1
                output(fid,node.args{1}{i},indent);
                printf(fid,indent,', ');
            end
            if ~isempty(node.args{1})
                output(fid,node.args{1}{end},indent);
            end
            printf(fid,indent,'}');
        otherwise
            warning(['warning: unknown type ', node.type]);
    end
end
function printf(fid,indent,pattern,varargin)
    fprintf(fid,[repmat(' ',1,indent),pattern],varargin{:});
end