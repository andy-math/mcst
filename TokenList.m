classdef TokenList
    properties
        tokens
    end
    
    methods
        function self = TokenList(tokens)
            self.tokens = tokens;
        end
        function subs = subsref(self, subs, varargin)
            if strcmp(subs(1).type, '()')
                assert(numel(subs(1).subs) == 1 && numel(subs(1).subs{1}) == 1);
                subs = builtin('subsref', self.tokens, subs);
            else
                subs = builtin('subsref', self, subs);
            end
        end
        function n = numel(self, varargin)
            if ~isempty(varargin)
                n = 1;
            else
                n = numel(self.tokens);
            end
        end
    end
end

