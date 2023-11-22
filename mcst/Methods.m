classdef Methods < Segment
    properties
        head Statement
        fun Function
        end_ Statement
    end
    methods
        function self = Methods(head, fun, end_)
            self.head = head;
            self.fun = fun;
            self.end_ = end_;
        end
    end
end