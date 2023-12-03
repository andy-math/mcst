classdef Token
    properties
        type char
        token char
        sym char
    end
    methods
        function self = Token(type, token, sym)
            self.type = type;
            self.token = token;
            self.sym = sym;
        end
    end
end
