%本Arduino案例演示了双向控制28BYJ-48步进电机的方法
%案例使用了 一个ULN2003 板来控制步进电机.
%28BYJ-48电机是四相八拍电机, 一个双极绕组在电机针脚pins 1 & 3上 另一个双极绕组在电机针脚pins 2 & 4上
%步角度为 5.625/64度，工作频率为100pps. 电流消耗92毫安。
%////////////////////////////////////////////////
 a = arduino('com5','Uno');
%确定电机针脚
motorPin1 = 8;    % Blue   - 28BYJ48 pin 1
motorPin2 = 9;    % Pink   - 28BYJ48 pin 2
motorPin3 = 10;   % Yellow - 28BYJ48 pin 3
motorPin4 = 11;   % Orange - 28BYJ48 pin 4
                      % Red    - 28BYJ48 pin 5 (VCC)
 
motorspeed = 1200;  %能够设定步进速度
count = 0;          % 计算累积步数
countsperrev = 512; % 一圈的步数
lookup = [1,0,0,0;
          1,1,0,0;
          0,1,0,0;
          0,1,1,0;
          0,0,1,0;
          0,0,1,1;
          0,0,0,1;
          1,0,0,1];
    
 lookup=logical(lookup);
%//////////////////////////////////////////////////////////////////////////////
%void setup() {
%确定电机针脚为输出
%  pinMode(motorPin1, OUTPUT);
%  pinMode(motorPin2, OUTPUT);
%  pinMode(motorPin3, OUTPUT);
%  pinMode(motorPin4, OUTPUT);
%  Serial.begin(9600);
%}
 
%//////////////////////////////////////////////////////////////////////////////
%以下程序使得正转一圈后反转一圈
while(1)
  if(count < countsperrev )
    %clockwise();%顺时针旋转
    for i = 0:7
        %setOutput(7-i);
        writeDigitalPin(a,motorPin1, lookup(7-i,1));
        writeDigitalPin(a,motorPin2, lookup(7-i,2));
        writeDigitalPin(a,motorPin3, lookup(7-i,3));
        writeDigitalPin(a,motorPin4, lookup(7-i,4));
        %delayMicroseconds(motorSpeed);
        pause(motorspeed/1000.000);
    end
    
  elseif (count == countsperrev * 2)
    count = 0;%正反各转一圈后累积步数清零
  else
    %anticlockwise();%正转一圈后反时针旋转
    for i = 0:8
        %setOutput(i);
        writeDigitalPin(a,motorPin1, lookup(i,1));
        writeDigitalPin(a,motorPin2, lookup(i,2));
        writeDigitalPin(a,motorPin3, lookup(i,3));
        writeDigitalPin(a,motorPin4, lookup(i,4));
        %delayMicroseconds(motorSpeed);
        pause(motorspeed/1000.000);
    end
  end
  count=count+1;
end
 