classdef Statement < Segment
    properties
        keyword char
        lvalue Expression
        rvalue Expression
        comment char
    end
    
    methods
        function self = Statement(keyword, lvalue, rvalue, comment)
            self.keyword = keyword;
            self.lvalue = lvalue;
            self.rvalue = rvalue;
            self.comment = comment;
        end
    end
end

