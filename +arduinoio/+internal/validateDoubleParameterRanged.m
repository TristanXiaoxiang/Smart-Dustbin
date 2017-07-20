function paramValue = validateDoubleParameterRanged(paramName, paramValue, min, max, units)

%   Copyright 2014 The MathWorks, Inc.
    if nargin < 5
        units = [];
    end

    try
        validateattributes(paramValue, {'double'}, {'scalar', 'real', 'finite', 'nonnan'});
    catch
        if isempty(units)
            arduinoio.internal.localizedError('MATLAB:arduinoio:general:invalidDoubleTypeRanged', ...
                paramName, num2str(min), num2str(max));
        else
            arduinoio.internal.localizedError('MATLAB:arduinoio:general:invalidDoubleTypeRangedUnits', ...
                paramName, num2str(min), num2str(max), units);
        end
    end

    paramValue = double(paramValue);
    
    if ~((paramValue >= min) && (paramValue <= max))
        if isempty(units)
            arduinoio.internal.localizedError('MATLAB:arduinoio:general:invalidDoubleValueRanged', ...
                paramName, num2str(min), num2str(max));
        else
            arduinoio.internal.localizedError('MATLAB:arduinoio:general:invalidDoubleValueRangedUnits', ...
                paramName, num2str(min), num2str(max), units);
        end
    end
end

