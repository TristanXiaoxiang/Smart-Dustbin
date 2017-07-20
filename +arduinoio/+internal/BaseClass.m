classdef (Hidden) BaseClass < handle
    %BaseClass Utility functions needed Arduino classes.
    % In addition, it will hide all methods that do not
    % make sense for our classes.
    %
    %    This undocumented class may be removed in a future release.
    
    % Copyright 2014 The MathWorks, Inc.
    %
    
     %% Properties
    properties (Access = private)
        %HasSaveWarningBeenIssued True if the
        %warnOnSaveAttempt method has been called.
        HasSaveWarningBeenIssued
    end
    
    %% -- Protected and private members of the class --
    % Non-public or hidden constructor
    methods(Hidden)
        function obj = BaseClass()
            obj.HasSaveWarningBeenIssued = false;
            
            % register error message catalog
            m = message('MATLAB:arduinoio:general:invalidPort', 'test');
            try
                m.getString();
            catch
                [~] = registerrealtimecataloglocation(arduinoio.SPPKGRoot);
            end
        end
    end
    
    % Allowing normal garbage collection, but prevent users from
    % explicitly deleting an object,
    methods (Access=protected)
        function delete(~)
        end
    end
    
    %% Hidden methods
    % Hide inherited methods we don't want to show.
    methods (Hidden)
        function result = ctranspose(obj)
            % provide access to the implementation
            [result] = obj.ctranspose@handle();
        end
        
        function result = eq(obj, varargin) 
            % provide access to the implementation
            [result] = obj.eq@handle(varargin{:});
        end
        
        function result = gt(obj, ~) %#ok<STOUT>s
            % errors if a user attempts this
            try
                obj.throwUnsupportedError;
            catch e
                throwAsCaller(e);
            end
        end
        
        function result = ge(obj, ~) %#ok<STOUT>
            % errors if a user attempts this
            try
                obj.throwUnsupportedError;
            catch e
                throwAsCaller(e);
            end
        end
        
        function result = fieldnames(obj)
            % provide access to the implementation
            result=obj.fieldnames@handle();
        end
        
        function result = fields(obj)
            % provide access to the implementation
            result = obj.fields@handle();
        end
        
        function result = findobj(obj,varargin)
            % provide access to the implementation
            result = obj.findobj@handle(varargin{:});
        end
        
        function result = findprop(obj,varargin)
            % provide access to the implementation
            result = obj.findprop@handle(varargin{:});
        end
        
        function result = le(obj, ~) %#ok<STOUT>
            % errors if a user attempts this
            try
                obj.throwUnsupportedError;
            catch e
                throwAsCaller(e);
            end
                
        end
        
        function result = lt(obj, ~) %#ok<STOUT>
            % errors if a user attempts this
            try
                obj.throwUnsupportedError;
            catch e
                throwAsCaller(e);
            end
        end
        
        function result = ne(obj, ~) %#ok<STOUT>
            % errors if a user attempts this
            try
                obj.throwUnsupportedError;
            catch e
                throwAsCaller(e);
            end
        end
        
        function notify(obj,varargin)
            % provide access to the implementation
            obj.notify@handle(varargin{:});
        end
        
        function result = permute(obj,varargin)
            % provide access to the implementation
            [result] = obj.permute@handle(varargin{:});
        end
        
        function result = reshape(obj,varargin)
            % provide access to the implementation
            [result] = obj.reshape@handle(varargin{:});
        end
        
        function result = transpose(obj)
            % provide access to the implementation
            [result] = obj.transpose@handle();
        end
        
        function addlistener(obj)
            obj.addlistener@handle();
        end
    end
    
    %% Hidden methods, disabled user override
    methods(Hidden,Sealed)
        function result = sort(obj)    %#ok<STOUT>
            % errors if a user attempts this
            try
                obj(1).throwUnsupportedError;
            catch e
                throwAsCaller(e);
            end
        end
        
        function sobj = saveobj(obj)
            %SAVEOBJ Handle save operations.
            %SAVEOBJ() Overrides ability to save Arduino objects.
            
            sobj = [];
            if obj.HasSaveWarningBeenIssued
                return
            end
            obj.HasSaveWarningBeenIssued = true;
            
            sWarningBacktrace = warning('off','backtrace');
            className = class(obj);
            n = strfind(className, '.');
            if ~isempty(n)
                % Remove package name
                className = className(n(end)+1:end);
            end
            warning(message('MATLAB:arduinoio:general:nosave', className));
            warning(sWarningBacktrace);
        end
    end
    
    %% Protected utility methods for use by a subclass
    methods (Sealed, Access = protected)
        function result = renderCellArrayOfStringsToString(~,cellArray,separator)
            assert(nargin==2 &&...
                iscellstr(cellArray) &&...
                isvector(cellArray) &&...
                ischar(separator))
            
            % Force to nx1
            if(size(cellArray,1)~=1)
                cellArray = cellArray';
            end
            
            % Insert the separator into a second row
            cellArray(2,:) = {separator};
            
            % Reshape the matrix to a vector, which puts the separators
            % between the original strings
            cellArray = reshape(cellArray,1,numel(cellArray));
            
            % Delete the last separator
            cellArray(end) = [];
            
            % Render them to a string
            result = cell2mat(cellArray);
        end
    end
    
    % Protected static methods for use by a subclass
    methods(Static,Sealed,Access=protected)
        function throwNotImplementedError()
            % Indicate that a particular API is not implemented.
            arduinoio.internal.BaseClass.localizedWarning('MATLAB:arduinoio:general:notImplemented');
        end
        
        function text = getLocalizedText(id,varargin)
            % This is used by MathWorks classes to retrieve arbitrary text
            % from the globalization dictionaries, and provides for localization.
            % The method signature of getLocalizedText(id,varargin) allows
            % arbitrary strings to be substituted into the message.
            
            % The localized text catalog ID system cannot handle doubles as parameters for substitutions,
            % and can throw an error if non-integral values are passed to
            % it.  To ensure this can't happen, we throw an error whenever
            % a parameter is not a string.
            if ~(all(cellfun(@ischar,varargin)))
                error(message('MATLAB:arduinoio:general:errorMessageParamNotString'));
            end
            
            
            % If you pass in an ID of 'MATLAB:arduinoio:general:foobar' it will find the
            % foobar key in the <MATLABROOT>/resources/MATLAB/en/arduinoio/general.xml
            % file.
            text = getString(message(id,varargin{:}));
        end
        
        function localized_fprintf(id,varargin)
            % This is used by MathWorks classes to display arbitrary text
            % from the globalization dictionaries, and provides for localization.
            % The method signature of localized_fprintf(id,varargin) allows
            % arbitrary strings to be substituted into the message. The
            % printed text automatically includes a new line.
            
            % If you pass in an ID of 'MATLAB:arduinoio:general:foobar' it will find the
            % foobar key in the <MATLABROOT>/resources/MATLAB/en/arduinoio/general.xml
            % file.
            fprintf(daq.internal.BaseClass.getLocalizedText(id,varargin{:}))
            fprintf('\n')
        end
        
        function e = getLocalizedException(id,varargin)
            % This is used by MathWorks classes to retrieve exceptions
            % using the globalization dictionaries, and provides for localization.
            % The method signature of getException (id,varargin) allows
            % arbitrary strings to be substituted into the message.
            
            % The localized text catalog ID system cannot handle doubles as parameters for substitutions,
            % and can throw an error if non-integral values are passed to
            % it.  To ensure this can't happen, we throw an error whenever
            % a parameter is not a string.
            if ~(all(cellfun(@ischar,varargin)))
                error(message('MATLAB:arduinoio:general:errorMessageParamNotString'));
            end
            
            % If you pass in an ID of 'MATLAB:arduinoio:general:foobar' it will find the
            % foobar key in the <MATLABROOT>/resources/MATLAB/en/arduinoio/general.xml
            % file.
            varargin = cellfun(@(x)strrep(x, '\', '\\'), varargin, 'UniformOutput', false);
            e = MException(id,getString(message(id,varargin{:})));
        end
        
        function localizedError(id,varargin)
            % This is used by MathWorks classes to generate errors using the
            % globalization dictionaries, and provides for localization.  The method
            % signature of error(id,varargin) allows arbitrary strings to be
            % substituted into the message.  It will use throwasCaller to
            % provide as accurate a caller stack as possible.
            
            % If you pass in an ID of 'MATLAB:arduinoio:general:foobar' it will find the
            % foobar key in the <MATLABROOT>/resources/MATLAB/en/arduinoio/general.xml
            % file.
            arduinoio.internal.BaseClass.getLocalizedException(id,varargin{:}).throwAsCaller;
        end
        
        function localizedWarning(id,varargin)
            % This is used by MathWorks classes to generate errors using
            % the globalization dictionaries, and provides for localization.  The
            % method signature of warning(id,varargin) allows arbitrary
            % strings to be substituted into the message.
            
            % If you pass in an ID of 'MATLAB:arduinoio:general:foobar' it will find the
            % foobar key in the <MATLABROOT>/resources/MATLAB/en/arduinoio/general.xml
            % file.
            
            % The localized text catalog ID system cannot handle doubles as parameters for substitutions,
            % and can throw an error if non-integral values are passed to
            % it.  To ensure this can't happen, we throw an error whenever
            % a parameter is not a string.
            if ~(all(cellfun(@ischar,varargin)))
                error(message('MATLAB:arduinoio:general:errorMessageParamNotString'));
            end
            
            % Turn off backtrace for a moment
            sWarningBacktrace = warning('off','backtrace');
            warning(message(id,varargin{:}));
            warning(sWarningBacktrace);
        end
    end
    
    % Superclass methods this class implements
    methods(Static, Sealed, Access=protected)
        function obj = getDefaultScalarElement() %#ok<STOUT>
            %getDefaultScalarElement Prevent sparse arrays of Arduino objects.
            %getDefaultScalarElement() This method is called when an attempt
            %is made to create a sparse array of objects in a
            %heterogeneous array.  It will cause an error.
            throwAsCaller(MException('MATLAB:arduinoio:general:nosparse', 'Arduino'));
        end
    end
    
    %% Private methods
    methods(Access=private)
        function throwUnsupportedError(obj)
            % throwUnsupportedError cause error indicating that
            % a particular operation is not supported.
            fcnName = dbstack;
            fcnName = fcnName(2).name;
            e = arduinoio.internal.BaseClass.getLocalizedException('MATLAB:arduinoio:general:unsupported',fcnName,class(obj));
            throw(e);
        end
    end
end
