classdef MTimes < Expression
    properties
        a Expression
        b Expression
    end
    
    methods
        function self = MTimes(a, b)
            self.a = a;
            self.b = b;
        end
    end
end