classdef BIndex < Expression
    properties
        value Expression
        index Expression
    end
    methods
        function self = BIndex(value, index)
            self.value = value;
            self.index = index;
        end
    end
end
