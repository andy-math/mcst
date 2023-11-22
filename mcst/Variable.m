classdef Variable < Segment
    properties
        name char
        type char
        default Expression
        comment char
    end
    methods
        function self = Variable(name, type, default, comment)
            self.name = name;
            self.type = type;
            self.default = default;
            self.comment = comment;
        end
    end
end

