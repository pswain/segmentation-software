function StackViewer = UpdateImages(StackViewer)
%StackViewer = UpdateImages(StackViewer) Updates the images in the GUI. Called
%whenever the scale bar is moved or a new PSF selected.

fprintf('\n   Write a new UpdateImages method or it will always be blank \n')
    
    set(StackViewer.MainImageHandle,'CData',zeros(512,512));

    %if your image is not 512 by 512 nees to set xlim and ylim of main axis
    %to be [0.5 (size of image +0.5)] with a line like:
    
    %set(StackViewer.MainAxisHandle,'ylim',[0.5 12.5])
    %set(StackViewer.MainAxisHandle,'xlim',[0.5 12.5])
    
    %this example is for an image of size 12.


end