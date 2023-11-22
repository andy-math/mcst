classdef MatrixLine < Expression
    properties
        item Expression
    end
    
    methods
        function self = MatrixLine(item)
            self.item = item;
        end
    end
end

