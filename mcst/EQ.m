classdef EQ < Expression
    properties
        a Expression
        b Expression
    end
    methods
        function self = EQ(a, b)
            self.a = a;
            self.b = b;
        end
    end
end
