classdef Literal < Expression
    properties
        value char
    end
    methods
        function self = Literal(value)
            self.value = value;
        end
    end
end

