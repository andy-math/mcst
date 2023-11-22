classdef LE < Expression
    properties
        a Expression
        b Expression
    end
    
    methods
        function self = LE(a, b)
            self.a = a;
            self.b = b;
        end
    end
end

