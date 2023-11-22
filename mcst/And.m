classdef And < Expression
    properties
        a Expression
        b Expression
    end
    methods
        function self = And(a, b)
            self.a = a;
            self.b = b;
        end
    end
end
