classdef Or < Expression
    properties
        a Expression
        b Expression
    end
    methods
        function self = Or(a, b)
            self.a = a;
            self.b = b;
        end
    end
end
