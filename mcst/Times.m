classdef Times < Expression
    properties
        a Expression
        b Expression
    end
    
    methods
        function self = Times(a, b)
            self.a = a;
            self.b = b;
        end
    end
end