function out = contains(str,pttrn,varargin)
% Implement MATLAB's contains function. It can also handle cell input (for the main string) and regular expression for the pattern.
% CAVEAT: It does not work with MATLAB's advanced pattern (see warning)
%
% FORMAT out = contains(str,pttrn);
%
% INPUT
%   str   - main string of cell of strings testing for pattern.
%   pttrn - pattern string
%
% OUTPUT
%   out - 1xN logical array, where N is the number of main strings (in the cell).
%
%
% FORMAT out = contains(str,pttrn,'regularExpression',true);
% Input pttrn is a regular expression.

    argParse = inputParser;
    argParse.addParameter('regularExpression',false,@islogical);
    argParse.parse(varargin{:});

    if ~ischar(pttrn) % MATLAB's advanced pattern
        warning('MATLAB''s advanced pattern is not yet implemented');
        out = false;
        return;
    end

    if ~argParse.Results.regularExpression
        pttrn = ['.*' strrep(pttrn,'\','\\') '.*'];
    end

    switch class(str)
        case 'char'
            out = ~isempty(regexp(str,pttrn, 'once'));
        case 'cell'
            out = cellfun(@(p) ~isempty(regexp(p,pttrn, 'once')), str);
    end

end
