function initializeImageProperties(cTimelapse,image,image_rotation,trapsPresent,pixel_size)
% INITIALIZEIMAGEPROPERTIES subfunction of LOADTIMELAPSE that sets up
% rotation,magnification, etc. 
% Put in a separate function so it could be shared by TIMELAPSETRAPS and
% TIMELAPSETRAPSOMERO. 
%
% INPUTS
% cTimelapse         -  object of the timelapseTraps class
% image              -  an image from the timelapse (for display)
% 
% all other inputs taken verbatim from TIMELAPSETRAPS.LOADTIMELAPSE.
%
% populates the rawImSize and imSize properties - though imSize will be
% overwritten when the cellVision is loaded.
%
% See also, TIMELAPSETRAPS.LOADTIMELAPSE


cTimelapse.rawImSize=size(image);
cTimelapse.imSize = cTimelapse.rawImSize;

%
if nargin<4 || isempty(trapsPresent)
    prompt = {'Are traps present in this Timelapse?'};
    dlg_title = 'Traps Present';
    answer = questdlg(prompt,dlg_title,'Yes','No','Yes');
    if strcmp(answer,'Yes')
        cTimelapse.trapsPresent=true;
    else
        cTimelapse.trapsPresent=false;
    end
else
    cTimelapse.trapsPresent=trapsPresent;
end

% only asks for rotation of traps are present, otherwise it is needless.
if nargin<3 || isempty(image_rotation)
    if cTimelapse.trapsPresent
        h=figure;imshow(image,[]);
        prompt = {'Enter the rotation (in degrees counter-clockwise) required to orient opening of traps to the left'};
        dlg_title = 'Rotation';
        num_lines = 1;
        def = {'0'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        cTimelapse.image_rotation=str2double(answer{1});
        close(h);
    else
        cTimelapse.image_rotation=0;
    end
else
    cTimelapse.image_rotation=image_rotation;
end
if nargin<5 || isempty(pixel_size)
    
    prompt = {'Enter the size of the pixels in this image in micrometers (for swainlab microscopes at 60x magnification this is 0.263 micrometers)'};
    dlg_title = 'Pixel Size';
    num_lines = 1;
    def = {'0.263'};
    answer = inputdlg(prompt,dlg_title,num_lines,def,struct('Interpreter','tex'));
    cTimelapse.pixelSize=str2double(answer{1});
else
    cTimelapse.pixelSize=pixel_size;
end


end