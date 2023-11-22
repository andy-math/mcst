classdef Matrix < Expression
    properties
        line MatrixLine
    end
    
    methods
        function self = Matrix(line)
            self.line = line;
        end
    end
end

