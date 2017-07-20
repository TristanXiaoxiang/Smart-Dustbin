function param = validateDigitalParameter(param)

%   Copyright 2014 The MathWorks, Inc.
    try
        validateattributes(param, {'numeric', 'logical'}, {'scalar', 'integer', 'real', 'finite', 'nonnan'});
    catch
        arduinoio.internal.localizedError('MATLAB:arduinoio:general:invalidDigitalType');
    end

    param = double(param);

    if ~((param == 0) || (param == 1))
        arduinoio.internal.localizedError('MATLAB:arduinoio:general:invalidDigitalValue');
    end
end