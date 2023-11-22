classdef MRDivide < Expression
    properties
        a Expression
        b Expression
    end
    methods
        function self = MRDivide(a, b)
            self.a = a;
            self.b = b;
        end
    end
end
