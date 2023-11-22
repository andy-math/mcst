classdef MLDivide < Expression
    properties
        a Expression
        b Expression
    end
    methods
        function self = MLDivide(a, b)
            self.a = a;
            self.b = b;
        end
    end
end
