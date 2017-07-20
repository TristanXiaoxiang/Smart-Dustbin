function image_shot(is_shot,directory,obj)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
persistent i
if isempty(i)
   i = 1; 
end
if is_shot
    date_string=datestr(date,29);%读取系统时间
    filename=[date_string,'-',num2str(i)];%生成制定格式图片名：2015-05-12-1.2.3.....(序号）
    frame = getsnapshot(obj);%抓图
    imwrite(frame,[directory,filename,'.jpg']);%存图'
    i=i+1;
else
    clear i;%清除局部变量
    delete(obj);%关闭摄像头
end

end