function localizedError(id, varargin)

%   Copyright 2014 The MathWorks, Inc.
    varargin = cellfun(@(x)strrep(x, '\', '\\'), varargin, 'UniformOutput', false);
    MException(id,getString(message(id, varargin{:}))).throwAsCaller;
end

