classdef Switch < Segment
    properties
        head Segment
        body SwitchCase
        end_ Segment
    end
    methods
        function self = Switch(head, body, end_)
            self.head = head;
            self.body = body;
            self.end_ = end_;
        end
    end
end
