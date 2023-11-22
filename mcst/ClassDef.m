classdef ClassDef < Segment
    properties
        head Statement
        property Properties
        method Methods
        end_ Statement
    end
    methods
        function self = ClassDef(head, property, method, end_)
            self.head = head;
            self.property = property;
            self.method = method;
            self.end_ = end_;
        end
    end
end