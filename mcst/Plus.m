classdef Plus < Expression
    properties
        a Expression
        b Expression
    end
    methods
        function self = Plus(a, b)
            self.a = a;
            self.b = b;
        end
    end
end
