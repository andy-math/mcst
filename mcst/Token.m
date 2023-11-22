classdef Token
    properties
        type char
        token char
    end
    methods
        function self = Token(type, token)
            self.type = type;
            self.token = token;
        end
    end
end
