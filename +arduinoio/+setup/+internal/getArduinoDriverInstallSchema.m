function dlgstruct = getArduinoDriverInstallSchema( hStep, dlgstruct )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%   Copyright 2014 The MathWorks, Inc.

% Schema
%Update the dlgstruct to have nine rows

dlgstruct.LayoutGrid = [19 6];
dlgstruct.RowStretch = [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1 0];
dlgstruct.ColStretch = [1 1 0 0 0 0];
for i = 2:numel(dlgstruct.Items)
    dlgstruct.Items{i}.RowSpan = [19 19];
end
hSetup      = hwconnectinstaller.Setup.get();

i = 1;
Item(i).Name = hStep.StepData.Labels.Item1;
Item(i).Type = 'text';
Item(i).RowSpan = [1 1];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = sprintf('%s','');
Item(i).Type = 'text';
Item(i).RowSpan = [2 2];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = hStep.StepData.Labels.Item2;
Item(i).Type = 'text';
Item(i).RowSpan = [3 3];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = hStep.StepData.Labels.Item3;
Item(i).Type = 'text';
Item(i).RowSpan = [4 4];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = hStep.StepData.Labels.Item4;
Item(i).Type = 'text';
Item(i).RowSpan = [5 5];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = sprintf('%s','');
Item(i).Type = 'text';
Item(i).RowSpan = [6 6];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = hStep.StepData.Labels.Item5;
Item(i).Type = 'text';
Item(i).RowSpan = [7 7];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = sprintf('%s','');
Item(i).Type = 'text';
Item(i).RowSpan = [8 8];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = hStep.StepData.Labels.Item6;
Item(i).Type = 'text';
Item(i).RowSpan = [9 9];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = sprintf('%s','');
Item(i).Type = 'text';
Item(i).RowSpan = [10 10];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = hStep.StepData.Labels.Item7;
Item(i).Type = 'text';
Item(i).RowSpan = [11 11];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = hStep.StepData.Labels.Item8;
Item(i).Type = 'text';
Item(i).RowSpan = [12 12];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = hStep.StepData.Labels.Item9;
Item(i).Type = 'text';
Item(i).RowSpan = [13 13];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = sprintf('%s','');
Item(i).Type = 'text';
Item(i).RowSpan = [14 14];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = hStep.StepData.Labels.Item10;
Item(i).Type = 'text';
Item(i).RowSpan = [15 15];
Item(i).ColSpan = [1 1];

i = i+1;
Item(i).Name = hStep.StepData.Labels.Item11;
Item(i).Type = 'text';
Item(i).RowSpan = [16 16];
Item(i).ColSpan = [1 1];

EnableDriverInstall.Name                   = 'Enable Installation of Arduino USB Driver';
EnableDriverInstall.Type                   = 'checkbox';
EnableDriverInstall.Value                  = hSetup.FwUpdater.hFwUpdate.EnableDriverInstall;
EnableDriverInstall.Tag                    = [hStep.ID '_Step_EnableDriverInstall'];
EnableDriverInstall.RowSpan                = [17 17];
EnableDriverInstall.ColSpan                = [1 1];
EnableDriverInstall.MatlabMethod           = 'dialogCallback';
EnableDriverInstall.MatlabArgs             = {hStep, 'EnableDriverInstall', '%tag', '%value'};
EnableDriverInstall.DialogRefresh          = true;

% Return dlgstruct
dlgstruct.Items{1} = Item(1);
dlgstruct.Items{end+1} = Item(2);
dlgstruct.Items{end+1} = Item(3);
dlgstruct.Items{end+1} = Item(4);
dlgstruct.Items{end+1} = Item(5);
dlgstruct.Items{end+1} = Item(6);
dlgstruct.Items{end+1} = Item(7);
dlgstruct.Items{end+1} = Item(8);
dlgstruct.Items{end+1} = Item(9);
dlgstruct.Items{end+1} = Item(10);
dlgstruct.Items{end+1} = Item(11);
dlgstruct.Items{end+1} = Item(12);
dlgstruct.Items{end+1} = Item(13);
dlgstruct.Items{end+1} = Item(14);
dlgstruct.Items{end+1} = Item(15);
dlgstruct.Items{end+1} = Item(16);
dlgstruct.Items{end+1} = EnableDriverInstall;
end

