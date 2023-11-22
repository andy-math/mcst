 classdef PIndex < Expression
    properties
        value Expression
        index Expression
    end
    methods
        function self = PIndex(value, index)
            self.value = value;
            self.index = index;
        end
    end
end

