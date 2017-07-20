
imaqhwinfo
obj = videoinput('winvideo');
%obj = videoinput('winvideo',1,'YUY2_320x240');
%preview( src );
set(obj, 'FramesPerTrigger', 1);
set(obj, 'TriggerRepeat', Inf);
%start(obj);
%objRes = get(obj, 'VideoResolution'); 
%nBands = get(obj, 'NumberOfBands');
%hImage = image(zeros(objRes(2), objRes(1), nBands));
%preview(obj, hImage);
%frame = getsnapshot(obj);%获取视频的一帧
%imshow(frame);%显示获取那一帧
%RGBframe = YBR2RGB(frame);
%imwrite(frame,'snap.jpg','jpg');

%imwrite(getsnapshot(obj), 'im.jpg');
%定义一个监控界面
hf = figure('Units', 'Normalized', 'Menubar', 'None','NumberTitle', 'off', 'Name', '实时拍照系统');
ha = axes('Parent', hf, 'Units', 'Normalized', 'Position', [0.05 0.2 0.85 0.7]);
axis off
%定义两个按钮控件
hb1 = uicontrol('Parent', hf, 'Units', 'Normalized','Position', [0.15 0.05 0.2 0.1], 'String', '预览', 'Callback', ['objRes = get(obj, ''VideoResolution'');' ...
     'nBands = get(obj, ''NumberOfBands'');' ...
     'hImage = image(zeros(objRes(2), objRes(1), nBands));' ...
     'preview(obj, hImage);']);
hb2 = uicontrol('Parent', hf, 'Units', 'Normalized','Position', [0.45 0.05 0.2 0.1], 'String', '拍照', 'Callback', 'imwrite(getsnapshot(obj), ''im001.jpg'')');
hb3 = uicontrol('Parent', hf, 'Units', 'Normalized','Position', [0.75 0.05 0.2 0.1], 'String', '分析', 'Callback', ['[W1,WB1] = Classify(''C:\\MATLAB\\SupportPackages\\R2014a\\arduinoio\\im.jpg'');' ...
     '[W2,WB2] = Classify(''C:\\MATLAB\\SupportPackages\\R2014a\\arduinoio\\im001.jpg'');' ...
     'r = corr2(WB1,WB2)']);
%delete(obj);







