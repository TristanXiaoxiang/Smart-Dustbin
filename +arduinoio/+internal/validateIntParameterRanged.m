function paramValue = validateIntParameterRanged(paramName, paramValue, min, max)

%   Copyright 2014 The MathWorks, Inc.
    try
        validateattributes(paramValue, {'double', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'}, {'scalar', 'integer', 'real', 'finite', 'nonnan'});
    catch
        arduinoio.internal.localizedError('MATLAB:arduinoio:general:invalidIntTypeRanged', ...
            paramName, num2str(min), num2str(max));
    end

    paramValue = floor(paramValue);
    
    if ~((paramValue >= min) && (paramValue <= max))
        arduinoio.internal.localizedError('MATLAB:arduinoio:general:invalidIntValueRanged', ...
            paramName, num2str(min), num2str(max));
    end
end

