classdef GE < Expression
    properties
        a Expression
        b Expression
    end
    
    methods
        function self = GE(a, b)
            self.a = a;
            self.b = b;
        end
    end
end

