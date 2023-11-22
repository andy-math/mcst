classdef Colon < Expression
    properties
        begin Expression
        step Expression
        end_ Expression
    end
    methods
        function self = Colon(a, b, c)
            switch nargin
                case 0
                case 2
                    self.begin = a;
                    self.end_ = b;
                case 3
                    self.begin = a;
                    self.step = b;
                    self.end_ = c;
                otherwise
                    error('colon');
            end
        end
    end
end
