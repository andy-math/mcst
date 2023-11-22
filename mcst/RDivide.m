classdef RDivide < Expression
    properties
        a Expression
        b Expression
    end
    methods
        function self = RDivide(a, b)
            self.a = a;
            self.b = b;
        end
    end
end
