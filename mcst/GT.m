classdef GT < Expression
    properties
        a Expression
        b Expression
    end
    methods
        function self = GT(a, b)
            self.a = a;
            self.b = b;
        end
    end
end
