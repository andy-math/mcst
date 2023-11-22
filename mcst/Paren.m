classdef Paren < Expression
    properties
        value Expression
    end
    methods
        function self = Paren(value)
            self.value = value;
        end
    end
end
