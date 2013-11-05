function ttacObject = getTrapImages(ttacObject,TrapBoolean)
%function to get trap images and trap grid image (i.e. a field of view with
%no cells)

ttacObject.TrapPresentBoolean = TrapBoolean;

if TrapBoolean
    
    %temporary until I write a proper trap entry GUI.
    filt = fspecial('disk',30);
    %for on the mac
    %AllTrapIm = double(imread('~/Documents/microscope_files_swain_microscope/traps_60x_empty_00/traps_60x_empty_000001_DIC_.png'));
    %for on the big PC
    AllTrapIm = double(imread('/Users/ebakker/Dropbox/MATLAB_DROPBOX/Matt Seg GUI/traps_60x_empty_000001_DIC_.png'));
    AllTrapIm = AllTrapIm - imfilter(AllTrapIm,filt,'replicate');
    ttacObject.TrapImage = imrotate(AllTrapIm(367:431,446:486),ttacObject.TimelapseTraps.image_rotation,'bilinear','loose');
    AllTrapIm = imrotate(AllTrapIm,ttacObject.TimelapseTraps.image_rotation,'bilinear','loose');
    ttacObject.TrapGridImage = AllTrapIm;
    %for future [xmin ymin width height]=getrect(figure)
    
end

end