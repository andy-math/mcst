classdef Identifier < Expression
    properties
        identifier char
    end
    methods
        function self = Identifier(identifier)
            self.identifier = identifier;
        end
    end
end

