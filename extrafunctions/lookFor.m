function out = lookFor(str,pttrn,varargin)
% Look for substring in in the first string input, similarly to MATLAB's contains.
% It can also handle cell input (for the main string) and regular expression for the pattern.
%
% FORMAT out = lookFor(str,pttrn);
%
% INPUT
%   str   - main string of cell of strings testing for pattern.
%   pttrn - pattern string
%
% OUTPUT
%   out - 1xN logical array, where N is the number of main strings (in the cell).
%
%
% FORMAT out = lookFor(str,pttrn,'regularExpression',true);
% Input pttrn is a regular expression.

    argParse = inputParser;
    argParse.addParameter('regularExpression',false,@islogical);
    argParse.addParameter('ignoreCase',false,@islogical);
    argParse.parse(varargin{:});

    if argParse.Results.ignoreCase, fnc = @regexpi;
    else, fnc = @regexp;
    end

    if ~ischar(pttrn) % MATLAB's advanced pattern
        warning('MATLAB''s advanced pattern is not yet implemented');
        out = false;
        return;
    end

    if ~argParse.Results.regularExpression
        escCh = {'\' '.' '(' ')'};
        pttrn = ['.*' strreps(pttrn,escCh,cellfun(@(ch) ['\' ch], escCh, 'UniformOutput',false)) '.*'];
    end

    switch class(str)
        case 'char'
            out = ~isempty(fnc(str,pttrn, 'once'));
        case 'cell'
            out = cellfun(@(p) ~isempty(fnc(p,pttrn, 'once')), str);
    end

end
