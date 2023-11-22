classdef Properties < Segment
    properties
        head Statement
        prop Variable
        end_ Statement
    end
    methods
        function self = Properties(head, prop, end_)
            self.head = head;
            self.prop = prop;
            self.end_ = end_;
        end
    end
end
