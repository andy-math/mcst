classdef LDivide < Expression
    properties
        a Expression
        b Expression
    end
    
    methods
        function self = LDivide(a, b)
            self.a = a;
            self.b = b;
        end
    end
end