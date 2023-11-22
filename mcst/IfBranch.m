classdef IfBranch < Segment
    properties
        head Statement
        body Segment
    end
    methods
        function self = IfBranch(head, body)
            self.head = head;
            self.body = body;
        end
    end
end
