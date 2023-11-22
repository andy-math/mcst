classdef Not < Expression
    properties
        value Expression
    end
    methods
        function self = Not(value)
            self.value = value;
        end
    end
end
