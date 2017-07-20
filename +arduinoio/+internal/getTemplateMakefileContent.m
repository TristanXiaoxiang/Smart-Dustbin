function contents = getTemplateMakefileContent(buildInfo, makefileName)
% GETTEMPLATEMAKEFILECONTENT - Returns all characters in the template
% makefile given the the makefile's name

%   Copyright 2014 The MathWorks, Inc.

    templateFile = fullfile(buildInfo.SPPKGPath, 'src', makefileName);
    [h, ~] = fopen(templateFile);
    if h < 0
        arduinoio.internal.localizedError('MATLAB:arduinoio:general:missingFile', templateFile);
    else
        contents = transpose(fread(h, '*char'));
    end
    fclose(h);
    
end