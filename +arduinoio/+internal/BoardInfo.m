classdef (Hidden, Sealed) BoardInfo < handle
    %BoardInfo
    %
    % Copyright 2014 The MathWorks, Inc.
    
    %% Properties
    %
    properties (SetAccess = private, GetAccess = {?arduinoio.internal.ResourceManager, ...
                                                  ?arduinoio.internal.WindowsUtility, ...
                                                  ?arduinoio.internal.MacUtility, ...
                                                  ?arduinoio.accessor.UnitTest})
        Boards
    end
    
    %% Methods
    %
    
    % Non public-constructor
    methods(Access=private)
        function obj = BoardInfo()
            obj.Boards = [];
            p = mfilename('fullpath');
            filename = fullfile(p, '..', 'boards.xml');
            xDoc = xmlread(filename);
            xRoot = xDoc.getDocumentElement;
            if strcmpi(xRoot.getNodeName, 'Arduino')
                boardNodes = xRoot.getChildNodes;
                for i1 = 0: boardNodes.getLength-1
                    boardNode = boardNodes.item(i1);
                    if boardNode.getNodeType ~= boardNode.ELEMENT_NODE
                        continue;
                    end
                    obj.Boards(end+1).Name = char(boardNode.getNodeName);
                    
                    childNode = boardNode.getFirstChild;
                    while ~isempty(childNode)
                        if childNode.getNodeType == childNode.ELEMENT_NODE
                            if isempty(childNode.getFirstChild)
                                childNode = childNode.getNextSibling;
                                continue;
                            end
                            childText = char(childNode.getFirstChild.getData);
                            switch char(childNode.getTagName)
                                case 'Protocol';
                                    obj.Boards(end).Protocol = childText;
                                case 'MemorySize';
                                    obj.Boards(end).MemorySize = str2num(childText);
                                case 'BaudRate';
                                    obj.Boards(end).BaudRate = str2num(childText);
                                case 'MCU';
                                    obj.Boards(end).MCU = childText;
                                case 'FCPU';
                                    obj.Boards(end).FCPU = str2num(childText);
                                case 'Core';
                                    obj.Boards(end).Core = childText;
                                case 'Variant';
                                    obj.Boards(end).Variant = childText;
                                case 'NumPins';
                                    obj.Boards(end).NumPins = str2num(childText); %#ok<*ST2NM>
                                case 'PinsDigital';
                                    obj.Boards(end).PinsDigital = str2num(childText);
                                case 'PinsAnalog';
                                    obj.Boards(end).PinsAnalog = str2num(childText);
                                case 'PinsPWM';
                                    obj.Boards(end).PinsPWM = str2num(childText);
                                case 'PinsServo';
                                    obj.Boards(end).PinsServo = str2num(childText);
                                case 'PinsI2C';
                                    obj.Boards(end).PinsI2C = str2num(childText);
                                case 'PinsSPI';
                                    obj.Boards(end).PinsSPI = str2num(childText);
                                case 'VID_PID';
                                    obj.Boards(end).VIDPID = eval(['{' childText '}']);
                            end
                        end
                        childNode = childNode.getNextSibling;
                    end
                end
            end
        end
    end
    
    % Destructor
    methods (Access = protected)
        function delete(obj)
            %delete Delete the hardware information
            obj.Boards = [];
        end
    end
    
    % Hidden static methods, which are used as friend methods
    methods(Hidden, Static)
        function value = getInstance()
            persistent Instance;
            
            if isempty(Instance) || ~isvalid(Instance)
                Instance = arduinoio.internal.BoardInfo();
            end
            value = Instance;
        end
    end
    
    methods(Access = private)
        % ----- Local function PARSECHILDNODES -----
        function children = parseChildNodes(theNode)
            % Recurse over node children.
            children = [];
            if theNode.hasChildNodes
                childNodes = theNode.getChildNodes;
                numChildNodes = childNodes.getLength;
                allocCell = cell(1, numChildNodes);
                
                children = struct(             ...
                    'Name', allocCell, 'Attributes', allocCell,    ...
                    'Data', allocCell, 'Children', allocCell);
                
                for count = 1:numChildNodes
                    theChild = childNodes.item(count-1);
                    children(count) = makeStructFromNode(theChild);
                end
            end
        end
        
        % ----- Local function MAKESTRUCTFROMNODE -----
        function nodeStruct = makeStructFromNode(theNode)
            % Create structure of node info.
            
            nodeStruct = struct(                         ...
                'Name', char(theNode.getNodeName),       ...
                'Attributes', parseAttributes(theNode),  ...
                'Data', '',                              ...
                'Children', parseChildNodes(theNode));
            
            if any(strcmp(methods(theNode), 'getData'))
                nodeStruct.Data = char(theNode.getData);
            else
                nodeStruct.Data = '';
            end
        end
        
        % ----- Local function PARSEATTRIBUTES -----
        function attributes = parseAttributes(theNode)
            % Create attributes structure.
            
            attributes = [];
            if theNode.hasAttributes
                theAttributes = theNode.getAttributes;
                numAttributes = theAttributes.getLength;
                allocCell = cell(1, numAttributes);
                attributes = struct('Name', allocCell, 'Value', ...
                    allocCell);
                
                for count = 1:numAttributes
                    attrib = theAttributes.item(count-1);
                    attributes(count).Name = char(attrib.getName);
                    attributes(count).Value = char(attrib.getValue);
                end
            end
        end
    end
end

% LocalWords:  fullpath MCU FCPU
