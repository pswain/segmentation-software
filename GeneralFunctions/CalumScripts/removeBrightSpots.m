[filename path]=uigetfile;
image=imread([path filename]);
image(image>1000)=max(image(image<1000));
imwrite(image,[path filename]);
