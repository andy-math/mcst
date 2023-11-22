classdef Negative < Expression
    properties
        expr Expression
    end
    
    methods
        function self = Negative(expr)
            self.expr = expr;
        end
    end
end

