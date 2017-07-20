function [images]=imLoad(filename)
cut=[41,1,239,239];
NUMBEROFPICTURE=246;
for i=1:NUMBEROFPICTURE
   % x=strcat('im000',num2str(i));
   image=imread(['images/',filename,'/',num2str(i),'.jpg']);
    %image=imread('image/im0001.jpg');
   image= rgb2gray(image);
   image=imcrop(image,cut);
   images(:,:,i)=image;
end