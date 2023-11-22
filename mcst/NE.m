classdef NE < Expression
    properties
        a Expression
        b Expression
    end
    
    methods
        function self = NE(a, b)
            self.a = a;
            self.b = b;
        end
    end
end
