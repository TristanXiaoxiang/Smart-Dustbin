function paramValue = validateDoubleParameterPos(paramName, paramValue)

%   Copyright 2014 The MathWorks, Inc.
    try
        validateattributes(paramValue, {'double'}, {'scalar', 'real', 'finite', 'nonnan', 'positive'});
    catch
        arduinoio.internal.localizedError('MATLAB:arduinoio:general:invalidDoubleTypePos', paramName);
    end

    paramValue = double(paramValue);
end

