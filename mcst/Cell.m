classdef Cell < Expression
    properties
        line MatrixLine
    end
    
    methods
        function self = Cell(line)
            self.line = line;
        end
    end
end

