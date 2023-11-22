classdef Function < Segment
    properties
        head Segment
        body Segment
        end_ Segment
    end
    methods
        function self = Function(head, body, end_)
            self.head = head;
            self.body = body;
            self.end_ = end_;
        end
    end
end
