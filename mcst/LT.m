classdef LT < Expression
    properties
        a Expression
        b Expression
    end
    methods
        function self = LT(a, b)
            self.a = a;
            self.b = b;
        end
    end
end
