classdef Minus < Expression
    properties
        a Expression
        b Expression
    end
    
    methods
        function self = Minus(a, b)
            self.a = a;
            self.b = b;
        end
    end
end

