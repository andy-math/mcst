classdef List
    properties(Access=private)
        list = {};
        count = 0;
    end
    
    methods
        function self = append(self, item)
            if self.count == numel(self.list)
                li = cell(1, self.count*2);
                li(1:self.count) = self.list;
                self.list = li;
            end
            self.count = self.count+1;
            self.list{self.count} = item;
        end
        function li = toList(self, li)
            li = [li, self.list{:}];
        end
    end
end

