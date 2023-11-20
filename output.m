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
            if isempty(node.args)
                printf(fid,indent,':');
                return
            end
            output(fid,node.args{1},indent);
            printf(fid,indent,' : ');
            output(fid,node.args{2},indent);
            if numel(node.args) == 3
                printf(fid,indent,' : ');
                output(fid,node.args{3},indent);
            end
        case 'keyword'
            printf(fid,indent,'%s\n',node.args{1});
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
        case {'while','function','for'}
            output(fid,node.args{1},indent);
            for i = 1:numel(node.args{2})
                output(fid,node.args{2}{i},indent+4);
            end
            output(fid,node.args{3},indent);
        case 'if'
            for i = 1:numel(node.args{1})
                output(fid,node.args{1}{i}{1},indent);
                output(fid,node.args{1}{i}{2},indent+4);
            end
            output(fid,node.args{2},indent);
        case 'switch'
            output(fid,node.args{1},indent);
            for i = 1:numel(node.args{2})
                output(fid,node.args{2}{i}{1},indent+4);
                output(fid,node.args{2}{i}{2},indent+8);
            end
            output(fid,node.args{3},indent);
        case 'transpose'
            output(fid,node.args{1},indent);
            printf(fid,indent,'.''');
        case 'statement'
            printf(fid,indent,'');
            if ~isempty(node.args{1})
                printf(fid,0,'%s',node.args{1});
                if ~isempty(node.args{2})
                    printf(fid,0,' ');
                end
            end
            if ~isempty(node.args{2})
                output(fid,node.args{2},0);
                if isempty(node.args{1})
                    printf(fid,0,';');
                end
            end
            if ~isempty(node.args{3})
                if ~isempty(node.args{1}) || ~isempty(node.args{2})
                    printf(fid,0,' ');
                end
                printf(fid,0,'%s',node.args{3});
            end
            printf(fid,0,'\n');
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
                if now
                    output(fid,node.args{1}{i},0);
                else
                    printf(fid,0,'\n');
                    printf(fid,indent+4,'');
                end
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
                if now
                    output(fid,node.args{1}{i},0);
                else
                    printf(fid,0,'\n');
                    printf(fid,indent+4,'');
                end
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