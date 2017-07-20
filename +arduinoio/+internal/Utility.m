classdef Utility < arduinoio.internal.BaseClass 
    
%   Copyright 2014 The MathWorks, Inc.
    
    properties(Access = protected)
        BoardInfo
    end
    
    properties(Access = private, Constant = true)
        Group = 'MATLAB_HARDWARE'
        Pref = 'ARDUINOIO'
    end
    
    properties(Access = protected, Constant = true)
        NLFeed = char(10)
    end

    
    methods (Abstract)
        portInfo = validatePort(obj, varargin);
        buildInfo = setProgrammer(obj, buildInfo);
        props = populateArduinoProperties(obj, props, defaultLibs);
    end
    
    %% Public methods
    methods (Access = public)
       function validateIDEPath(obj, IDEPath)
       % Check if the given IDEPath points to a non 1.5.x version of
       % Arduino IDE and if one or few files needed exists
            files = {fullfile('hardware','arduino','avr','cores','arduino', 'hooks.c'), fullfile('libraries','Servo','src','avr','Servo.cpp')};
            for i = 1:length(files)
                if ~exist(fullfile(IDEPath, files{i}), 'file')
                    obj.localizedError('MATLAB:arduinoio:general:invalidIDEPath', IDEPath)
                end
            end
       end
       
       function newLibs = validateLibraries(obj, libs)
       % Validate given library name strings to obtain the full list of
       % libraries including dependent libraries and check their existance
           libraryList = listArduinoLibraries();
           try
               validateFcn = @(x) validatestring(x, libraryList);
               originalLibs = libs;
               libs = strrep(libs, '\', '/');
               givenLibs = cellfun(validateFcn, libs, 'UniformOutput', false); % check given libraries all exist
               newLibs = arduinoio.internal.getFullLibraryList(givenLibs);
           catch e
                if isequal(e.identifier, 'MATLAB:unrecognizedStringChoice')
                    obj.localizedError('MATLAB:arduinoio:general:invalidLibrariesValue', strjoin(originalLibs, ', '), strjoin(libraryList', ', '))
                else
                    throwAsCaller(e);
                end
           end
       end
   
       function buildInfo = preBuildProcess(obj, buildInfo)
       % Populate all needed fields in buildInfo other than those got from
       % boards.xml
           buildInfo.ArduinoIDEPath = arduinoio.IDERoot;
           validateIDEPath(obj, buildInfo.ArduinoIDEPath);
           if strcmp(buildInfo.MCU, 'cortex-m3')
               buildInfo.Template = 'sam';            
           else
               buildInfo.Template = 'avr';
           end 
           buildInfo = setProgrammer(obj, buildInfo); % set the Programmer field of buildInfo structure
           buildInfo.SPPKGPath = arduinoio.SPPKGRoot; 
           
           getLibrarySources = @(x) getAllLibraryBuildInfo(obj, buildInfo.Libraries, x, buildInfo.Template);
           propertyNames = {'CIncludeDirectories', 'CFiles', 'CXXIncludeDirectories', 'CXXFiles'};
           propertyValues = cellfun(getLibrarySources, propertyNames, 'UniformOutput', false);
           
           buildInfo.CIncludePaths = propertyValues{1};
           buildInfo.CXXIncludePaths = [fullfile(buildInfo.SPPKGPath, 'src'), fullfile(buildInfo.ArduinoIDEPath, 'libraries', 'Firmata', 'src'), fullfile(tempdir, 'ArduinoServer'), propertyValues{3}];
           buildInfo.ServerPath = tempdir;
           buildInfo.CSource = propertyValues{2};
           buildInfo.CXXSource = [fullfile(buildInfo.SPPKGPath, 'src', 'MWArduino.cpp'), fullfile(buildInfo.ArduinoIDEPath, 'libraries', 'Firmata', 'src', 'Firmata.cpp'), fullfile(buildInfo.SPPKGPath, 'src', 'ArduinoServer.cpp'), propertyValues{4}];
       end
       
       function updatePreference(obj, port, board)
       % This function add the given input parameters to MATLAB preference
       % if none exists, or set the existing preference with the given
       % input parameters
            newPref.Port = port;
            newPref.Board = board;
                
            [isPref, oldPref] = getPreferences(obj);
            if isPref && ~isequal(newPref, oldPref) 
                setpref(obj.Group, obj.Pref, newPref);
            elseif ~isPref
                addpref(obj.Group, obj.Pref, newPref);
            end
       end
        
       function [isPref, pref] = getPreferences(obj)
           isPref = ispref(obj.Group, obj.Pref);
           pref = [];
           if isPref
               pref = getpref(obj.Group, obj.Pref);
           end
       end
           
       function updateServer(obj, buildInfo)
       % This function compiles all necessary source files and downloads
       % the executable to the hardware 
            origPort = buildInfo.Port;
            buildInfo = preBuildProcess(obj, buildInfo); % populate the complete set of fields in buildInfo structure
            if exist(fullfile(tempdir, 'ArduinoServer'), 'dir')
                rmdir(fullfile(tempdir, 'ArduinoServer'), 's');
            end
            
            generateDynamicCPP(obj, buildInfo.ServerPath, buildInfo.Libraries);
            if strcmp(buildInfo.Template,'avr')
                arduinoio.internal.generateAVRMakefile(buildInfo);
            else
                arduinoio.internal.generateSAMMakefile(buildInfo);
                if ispc % On Windows, open port with 1200bps to trigger reset
                    s = System.IO.Ports.SerialPort(buildInfo.Port);
                    s.Open();
                    s.BaudRate = 1200;
                    s.Close();
                    delete(s);
                end
            end
            cmdstr = [buildInfo.Programmer, ' -f ', fullfile(buildInfo.ServerPath, 'ArduinoServer', 'ArduinoServer.mk')];
            [status, result] = system(cmdstr);
            if status
                if buildInfo.TraceOn
                    obj.localizedError('MATLAB:arduinoio:general:failedUploadVerbose', result);
                else
                    obj.localizedError('MATLAB:arduinoio:general:failedUpload', buildInfo.Board, origPort);
                end
            end
       end
    end
    
    %% Protected methods
	methods(Access = protected)
        function props = populateArduinoPropertiesSharedUtility(obj, props)
        % Shared utility function used on Windows and Mac to populate
        % properties of arduino object
            [isPref, thePref] = getPreferences(obj);
            if isempty(props.Port) % calling constructor without parameters
                % Port and Board population
                if isPref
                    try
                        portInfo = validatePort(obj, thePref.Port);
                        props.Port = portInfo.port{1};
                        props.Board = portInfo.board;
                    catch
                        portInfo = validatePort(obj);
                        props.Port = portInfo.port{1};
                        props.Board = portInfo.board;
                    end
                else % first time calling constructor (without any parameters)
                    portInfo = validatePort(obj);
                    props.Port = portInfo.port{1};
                    props.Board = portInfo.board;
                end
                % Libraries population
                props.Libraries = {};
                props.LibrariesSpecified = false;
            else % calling constructor with parameters
                % Port and Board population
                if isempty(props.Board) % Given port number only
                    portInfo = validatePort(obj, props.Port);
                    props.Port = portInfo.port{1};
                    props.Board = portInfo.board;
                end
                % Libraries population
                if isempty(props.Libraries) % user specify '' or {} as Libraries value
                    props.Libraries = {};
                    props.LibrariesSpecified = true;
                elseif isempty(props.Libraries{1}) % Not given libraries
                    props.Libraries = {};
                    props.LibrariesSpecified = false;
                else
                    props.LibrariesSpecified = true;
                end
            end
        end
    end
    
    %% Private methods
	methods(Access = private)
       function generateDynamicCPP(obj, serverPath, libs)
       % Generate Dynamic.cpp file to be compiled with other source code to
       % register the libraries
            if ~exist(fullfile(serverPath, 'ArduinoServer'), 'dir')
                try
                    mkdir(fullfile(serverPath, 'ArduinoServer'));
                catch
                    obj.localizedError('MATLAB:arduinoio:general:noWritePermission');
                end
            end
            
            filename = fullfile(serverPath, 'ArduinoServer', 'Dynamic.cpp');
            h = fopen(filename, 'w');
            
            contents = [];
            
            for libCount = 1:length(libs)
                headerFile = arduinoio.internal.getDefaultLibraryPropertyValue(libs{libCount}, 'WrapperClassHeaderFile');
                contents = strcat(contents, ['#include "', headerFile, '"\n']); 
            end                        
           
            contents = [contents, '\nMWArduinoClass MWArduino;\n\n'];

            for libCount = 1:length(libs)
                className = arduinoio.internal.getDefaultLibraryPropertyValue(libs{libCount}, 'WrapperClassName');
                contents = strcat(contents, [className, ' a', className, '(MWArduino); // ID = ', num2str(libCount-1), '\n']); 
            end
            
            try
                fwrite(h, sprintf(contents));
            catch 
                f2 = strrep(filename, '\', '\\');
                obj.localizedError('MATLAB:arduinoio:general:noWritePermission', f2);
            end
            fclose(h);
        end
       
        function output = getAllLibraryBuildInfo(obj, libs, propName, arch)
        % Return combined values for given property name of all given
        % libraries for the given architecture
            output = {};
            for libCount = 1:length(libs)
               theLib = libs{libCount};
               thePath = arduinoio.internal.getDefaultLibraryPropertyValue(theLib, propName);
               if ~isempty(thePath)
                   fieldNames = fieldnames(thePath);
                   matches = strcmp(fieldNames, arch);
                   if sum(matches(:)) > 0 % given arch is among supported arch lists
                       theField = arch;
                   elseif strcmp(fieldNames{1}, 'all') % library is supported on all archs
                       theField = 'all';
                   else % given arch is not supported by the library
                       obj.localizedError('MATLAB:arduinoio:general:unsupportedArch', theLib, arch)
                   end
                   tmp = {};
                   for archCount = 1:length(thePath)
                       % architecture matches one of the possible architecture or same library source for all architectures
                       tmpPath = getfield(thePath(archCount), theField); %#ok<GFLD>
                       if ~isempty(tmpPath)
                            tmp = [tmp, tmpPath];  %#ok<AGROW>
                       end
                   end
                   output = [output, tmp];  %#ok<AGROW>
               end
            end
            output = unique(output);
        end
    end
end
