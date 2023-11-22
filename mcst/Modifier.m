classdef Modifier < Expression
    properties
        lvalue Identifier
        rvalue Identifier
    end
    methods
        function self = Modifier(lvalue, rvalue)
            self.lvalue = lvalue;
            self.rvalue = rvalue;
        end
    end
end