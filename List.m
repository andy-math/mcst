classdef List
    properties(SetAccess=immutable)
        append function_handle
        toList function_handle
    end
    methods
        function self = List()
            list = {};
            count = 0;
            self.append = @append;
            self.toList = @toList;
            function append(item)
                if count == numel(list)
                    li = cell(1, count * 2);
                    li(1 : count) = list;
                    list = li;
                end
                count = count + 1;
                list{count} = item;
            end
            function li = toList(li)
                li = [li, list{1 : count}];
            end
        end
    end
end
