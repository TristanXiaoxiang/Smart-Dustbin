function completeOverride = executeArduinoDriverInstall( hStep, command, varargin )
%EXECUTEUPDATEFIRMWARE Execute function callback for the Update Firmware
%step

%   Copyright 2014 The MathWorks, Inc.

completeOverride = false;
switch(command)
    case 'initialize',
        if (isempty(hStep.StepData))
            xlateEnt = struct(...
                'Item1','', ...
                'Item2','', ...
                'Item3','', ...
                'Item4','', ...
                'Item5','', ...
                'Item6','', ...
                'Item7','', ...
                'Item8','', ...
				'Item9','', ...
				'Item10','', ...
                'Item11','');                
            %xlateEnt = hwconnectinstaller.internal.getXlateEntries('hwconnectinstaller','setup','ARDUINODriverInstall',xlateEnt);
            
            % To be Deleted when message is created in hwconnectinstaller
            % resource component
            xlateEnt.Item1 = 'Arduino USB Driver Installation';
            xlateEnt.Item2 = 'You can install the driver for Arduino hardware.';
            xlateEnt.Item3 = 'This process installs the Arduino USB driver on your desktop.';
            xlateEnt.Item4 = 'After you complete this setup , you can connect to your Arduino hardware in MATLAB.';
            xlateEnt.Item5 = 'To install Arduino USB Driver:';
            xlateEnt.Item6 = '1. Click on the "Next" button below to continue with the installation.';
            xlateEnt.Item7 = 'Notes:';
            xlateEnt.Item8 = 'Installation of driver requires Administrator privileges. Make sure you have setup your Windows';
            xlateEnt.Item9 = ' User Account Control(UAC) and Local Security Policy Settings correctly.';
			xlateEnt.Item10 = 'If this is the first time using Arduino on this machine, you need to replug the hardware after';
			xlateEnt.Item11 = ' the installation finishes.';
  
            hStep.StepData.Labels = xlateEnt;
            hStep.StepData.Icon   = fullfile(matlabroot,'toolbox', 'shared', 'hwconnectinstaller','resources','warning.png');
            hStep.StepData.UpdateStatus = '';
        end


    case 'callback'
        completeOverride = true;
        assert(~isempty(hStep.StepData));
        switch(varargin{1})
            case 'EnableDriverInstall',
                hSetup         = hwconnectinstaller.Setup.get();
                hFwUpdate      = hSetup.FwUpdater.hFwUpdate;
                hFwUpdate.EnableDriverInstall = varargin{3};
            case 'Help',
				open(fullfile(arduinoio.SPPKGRoot, 'arduinoio_ug_book.pdf'));
            otherwise,
                completeOverride = false;
        end
    case 'next'
        hSetup = hwconnectinstaller.Setup.get();
        hFwUpdate = hSetup.FwUpdater.hFwUpdate;
        
        if(hFwUpdate.EnableDriverInstall)
            hFwUpdate.installArduinoUSBDriver();
        end
 end

