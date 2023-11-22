classdef Colon < Expression
    properties
        begin Expression
        step Expression
        end_ Expression
    end
    methods
        function self = Colon(begin, step, end_)
            self.begin = begin;
            self.step = step;
            self.end_ = end_;
        end
    end
end
