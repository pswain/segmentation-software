function PositionsFromDeltavision()
%%cellasic files have specific properties that create an additional step
%%for processing with the segmentation software:
%they come in the dv format, which should be read with bfopen.
%%additionally, the DIC images are named REF and the relevant fluorescent
%%sequences will come as a projection PRJ. at phase one, we will
%%a, try to  find file names with matching prj and ref files
%%b) generate png dic and gfp sequences for each channel and put them all
%%under the corresponding name_DIC or name_channel
%%the script currently assumes that the files are in deltavision format.

[locationpath]= uigetdir([],'Select the directory where the deltavision files are');
[destinationpath ]= uigetdir([], 'Select the directory where the output image sequences will be saved');
%experimentIdentifier=inputdlg('Enter the identifier for your entire experiment');
dicFiles=dir( [locationpath filesep '*REF.dv']);
zProjectionFiles= dir( [locationpath filesep '*PRJ.dv']);

%As it stands the last 4 characters are _REF or _PRJ, so we can remove them
%to get the filename

%because there will be a dic file per z projection file, then each number
%should correspond technically to the same position imaged. ie. dicFile(1)
%and zProjectionFiles(1) are images of the same cell.


for i=1:size(dicFiles,1) %for each dic file there will be a z projection
   
    experimentIdentifier = dicFiles(i).name(1:end-8);
    disp(['Reading series ' experimentIdentifier])
    pospath= destinationpath ;
%    posname=['pos' num2str(i)];
    mkdir(pospath,experimentIdentifier);
    disp('REF')
    imdic= bfopen([locationpath filesep dicFiles(i).name]);
    disp('PRJ')
    imprj= bfopen([locationpath filesep zProjectionFiles(i).name]);
    for k=1:size(imdic{1},1)
        %For some reason experimentIdentifier is an array of one cell
        imwrite(imdic{1}{k}, [destinationpath filesep experimentIdentifier filesep experimentIdentifier '_REF_w-50_t' sprintf('%02d',k) '.tif'], 'TIF');
        imwrite(imprj{1}{k}, [destinationpath filesep experimentIdentifier filesep experimentIdentifier '_PRJ_w525_t' sprintf('%02d',k) '.tif'], 'TIF');

    end

end








