classdef Transpose < Expression
    properties
        value Expression
    end
    
    methods
        function self = Transpose(value)
            self.value = value;
        end
    end
end

