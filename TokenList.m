classdef TokenList < handle
    properties
        tokens
        i = 1;
    end
    
    methods
        function self = TokenList(tokens)
            self.tokens = tokens;
        end
        function n = numel(self, varargin)
            if ~isempty(varargin)
                n = 1;
            else
                n = numel(self.tokens);
            end
        end
        function next(self)
            self.i = self.i + 1;
        end
        function v = get(self)
            if self.i > numel(self.tokens)
                v = [];
            else
                v = self.tokens(self.i);
            end
        end
        function v = ahead(self)
            if self.i+1 > numel(self.tokens)
                v = [];
            else
                v = self.tokens(self.i+1);
            end
        end
    end
end

