function selectTimelapse(cCellVisionGUI)
source=questdlg('Choose source of images', 'Create Timelapse from Images','Folder','Omero dataset','Folder');

switch source
    case 'Folder'
    	folder=uigetdir(pwd,'Select the folder containing the images associated with this timelapse');
    	fprintf('\n    Select the folder containing the images associated with this timelapse\n');
        omeroDs=0;
    case 'Omero dataset'
        %Make sure the download gui is on the path
        a=mfilename('fullpath');        
        k=strfind(a,filesep);
        b=[a(1:k(end-2)) 'GeneralFunctions'];
        addpath(genpath(b));
        [folder omeroDs]=downloadGUI(true,true);        
end


cCellVisionGUI.cTimelapse=timelapseTraps();
cCellVisionGUI.cTimelapse.omeroDs=omeroDs;
searchString = inputdlg('Enter the string to search for the brightfield/DIC images','SearchString',1,{'DIC'});
cCellVisionGUI.cTimelapse.loadTimelapse(searchString);

set(cCellVisionGUI.selectChannelButton,'String',searchString,'Value',1);