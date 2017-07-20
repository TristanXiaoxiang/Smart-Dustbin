classdef (Abstract)AddonBase < arduinoio.internal.BaseClass 
% ADDONBASE - Addon classes that do not define a library shall inherit from
% this base class to get Parent property.

% Copyright 2014 The MathWorks, Inc.

    properties(Hidden)
        Parent
    end
end