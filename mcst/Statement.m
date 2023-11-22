classdef Statement < Segment
    properties
        keyword char
        modifier Modifier
        lvalue Expression
        rvalue Expression
        comment char
    end
    
    methods
        function self = Statement(keyword, modifier, lvalue, rvalue, comment)
            self.keyword = keyword;
            self.modifier = modifier;
            self.lvalue = lvalue;
            self.rvalue = rvalue;
            self.comment = comment;
        end
    end
end

