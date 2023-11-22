classdef Lambda < Expression
    properties
        args Identifier
        expr Expression
    end
    methods
        function self = Lambda(args, expr)
            self.args = args;
            self.expr = expr;
        end
    end
end
