classdef If < Segment
    properties
        body IfBranch
        end_ Segment
    end
    methods
        function self = If(body, end_)
            self.body = body;
            self.end_ = end_;
        end
    end
end