classdef List < handle
    properties
        list = {}
        count = 0
    end
    methods
        function append(self, item)
            if self.count == numel(self.list)
                li = cell(1, self.count * 2);
                li(1 : self.count) = self.list;
                self.list = li;
            end
            self.count = self.count + 1;
            self.list{self.count} = item;
        end
        function li = toList(self, li)
            li = [li, self.list{1 : self.count}];
        end
    end
end
