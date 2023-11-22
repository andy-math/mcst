classdef Field < Expression
    properties
        value Expression
        field Expression
    end
    methods
        function self = Field(value, field)
            self.value = value;
            self.field = field;
        end
    end
end
