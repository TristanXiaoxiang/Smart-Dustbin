function generateMakefileSharedUtility(buildInfo, contents)
% GENERATEMAKEFILESHAREDUTILITY - Shared helper function for both avr and
% sam boards to replace the contents in template makefile with correct
% information and write the contents to ArduinoServer.mk in build folder

%   Copyright 2014 The MathWorks, Inc.

    contents = strrep(contents, '[arduino_dir]', strrep(buildInfo.ArduinoIDEPath, '\', '/'));
    contents = strrep(contents, '[server_dir]', strrep(buildInfo.ServerPath(1:end-1), '\', '/')); % chop off the last / 
    contents = strrep(contents, '[cpu]', buildInfo.MCU);
    contents = strrep(contents, '[f_cpu]', buildInfo.FCPU);
    contents = strrep(contents, '[port]', buildInfo.Port);
    
    if numel(buildInfo.VIDPID) == 2 % For boards that have a bootloader mode VID/PID and a sketch mode VID/PID
        VIDPIDFlag = ['-DUSB_VID=', buildInfo.VIDPID{2}(1:6), ' -DUSB_PID=', buildInfo.VIDPID{2}(8:end)];
    elseif numel(buildInfo.VIDPID) == 1 % For boards that only have one VID/PID 
        VIDPIDFlag = ['-DUSB_VID=', buildInfo.VIDPID{1}(1:6), ' -DUSB_PID=', buildInfo.VIDPID{1}(8:end)];
    else % For boards that does not have VID/PID 
        VIDPIDFlag = '';
    end
    contents = strrep(contents, '[vidpid]', VIDPIDFlag);
    
    if ispc
        platform = 'Windows';
    elseif ismac
        platform = 'Macintosh';
    else
        platform = 'Linux';
    end
    contents = strrep(contents, '[platform]', platform);
    
    if ~isempty(buildInfo.CIncludePaths)
        dirs = strjoin(buildInfo.CIncludePaths,'" -I"');
        dirs = ['-I"' dirs '"'];
        contents = strrep(contents, '[cinclude_dirs]', strrep(dirs, '\', '/'));
    else
        contents = strrep(contents, '[cinclude_dirs]', '');
    end
    
    if ~isempty(buildInfo.CXXIncludePaths)
        dirs = strjoin(buildInfo.CXXIncludePaths,'" -I"');
        dirs = ['-I"' dirs '"'];
        contents = strrep(contents, '[cxxinclude_dirs]', strrep(dirs, '\', '/'));
    else
        contents = strrep(contents, '[cxxinclude_dirs]', '');
    end

    if buildInfo.TraceOn
        contents = strrep(contents, '[additional_flags]', strcat('-DMW_DEBUG=1 -DMW_BOARD=', buildInfo.Board));
    else
        contents = strrep(contents, '[additional_flags]', strcat('-DMW_BOARD=', buildInfo.Board));
    end
    
    if isempty(buildInfo.CSource)
        dirs = '';
    else
        dirs = strjoin(buildInfo.CSource, ' ');
    end
    contents = strrep(contents, '[csrc]', strrep(dirs, '\', '/'));
    
    dirs = strjoin(buildInfo.CXXSource, ' ');
    contents = strrep(contents, '[cxxsrc]', strrep(dirs, '\', '/'));
    
    patternRules = '';
    if ~isempty(buildInfo.CIncludePaths)
        for ii = 1:length(buildInfo.CIncludePaths)
            oneRule = ['$(MAIN_DIR)/ArduinoServer/%.c.o: ', char(buildInfo.CIncludePaths(ii)), '/%.c', char(10), char(9), '$(CC) $(CINCLUDE_DIRS) $(CFLAGS) $< -o $@'];
            patternRules = [patternRules, char(10), char(10), oneRule]; %#ok<AGROW>
        end
    end
    contents = strrep(contents, '[additional_rules_c]', strrep(patternRules, '\', '/'));
    
    patternRules = '';
    if ~isempty(buildInfo.CXXIncludePaths)
        for ii = 1:length(buildInfo.CXXIncludePaths)
            oneRule = ['$(MAIN_DIR)/ArduinoServer/%.cpp.o: ', char(buildInfo.CXXIncludePaths(ii)), '/%.cpp', char(10), char(9), '$(CXX) $(CXXINCLUDE_DIRS) $(CXXFLAGS) $< -o $@'];
            patternRules = [patternRules, char(10), char(10), oneRule]; %#ok<AGROW>
        end
    end
    contents = strrep(contents, '[additional_rules_cxx]', strrep(patternRules, '\', '/'));
    
    filename = fullfile(buildInfo.ServerPath, 'ArduinoServer', 'ArduinoServer.mk');
    h = fopen(filename, 'w');
    try
        fwrite(h, contents);
    catch 
        arduinoio.internal.localizedError('MATLAB:arduinoio:general:noWritePermission');
    end
    fclose(h);
    
    if ~exist(fullfile(buildInfo.ServerPath, 'ArduinoServer', 'MW'), 'dir')
        mkdir(fullfile(buildInfo.ServerPath, 'ArduinoServer', 'MW'));
    end
end