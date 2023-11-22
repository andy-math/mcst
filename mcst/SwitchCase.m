classdef SwitchCase < Segment
    properties
        head Segment
        body Segment
    end
    methods
        function self = SwitchCase(head, body)
            self.head = head;
            self.body = body;
        end
    end
end
