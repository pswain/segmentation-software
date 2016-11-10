function loadTimelapse(cTimelapse,searchString,magnfication,image_rotation,trapsPresent,timepointsToLoad,imScale)
%loadTimelapse(cTimelapse,searchString,magnfication,image_rotation,trapsPresent,timepointsToLoad,imScale)
%
%populates the cTimpoint field, determining how many timepoints there are
%in the timelapse by identifying images with a certain searchString.
%
%seaches through the timelapseDir for filenames with one of the strings
%given by the cell array of search strings searchStrings. Uses the ordered
%list of these to populate the cTimepoints - one cTimepoint for each
%matching file. It should be noted that if a searchString with numerous
%files is used it will first populate cTimpoint structures with all those
%matching searchString{1}, then with all those matching searchString{2}
%etc. etc. this is probably not desired, and as such only a single entry
%should be provided for searchString (e.g. searchString = {'DIC'})).
%
%expects images to be png,tif or TIF format.
%
% other fields (imScale,rotation,trapsPresent etc.) are also populated, by
% GUI if necessary.
%
% imScale can be set to the string 'gui' to populate it via user interface.

if isempty(cTimelapse.omeroImage)
    %get names of all files in the timelapseDir folder
    cTimelapse.channelNames=searchString;
    folder=cTimelapse.timelapseDir;
    tempdir=dir(folder);
    names=cell(1);
    for i=1:length(tempdir)
        names{i}=tempdir(i).name;
    end
    
    files=sort(names);
    folder=[folder filesep];
    %% Read images into timelapse class
    % Timelapse is a seletion of images from a file. These images must be
    % loaded in the correct order from low to high numbers to ensure that the
    % cell tracking performs correctly, and they must be rotated to ensure the
    % trap correctly aligns with the images
    
    cTimepointTemplate = cTimelapse.cTimepointTemplate;
    
    cTimelapse.cTimepoint = cTimepointTemplate;
    
    largestTimepoint = 0;
    if length(searchString)>1
        
        fprintf('\n\n WARNING!! numerous search string entries may produce strange results. \n\n')
    end
    for ss=1:length(searchString)
        timepoint_index=0;
        for n = 1:length(files);
            % check file name is an image and is not a hidden unix file
            if (~isempty(strfind(files{n},'tif'))|| ~isempty(strfind(files{n},'png')) || ~isempty(strfind(files{n},'TIF')))...
                    && isempty(regexp(files{n},'^\.','once'))
                if ~isempty(strfind(files{n},searchString{ss}))
                    cTimelapse.cTimepoint(timepoint_index+1).filename{ss}=files{n};
                    cTimelapse.cTimepoint(timepoint_index+1).trapLocations=[];
                    timepoint_index=timepoint_index+1;
                end
            end
        end
        largestTimepoint = max([timepoint_index;largestTimepoint]);
    end
    
    cTimelapse.timepointsToProcess = 1:largestTimepoint;
    cTimelapse.timepointsProcessed = false(1,largestTimepoint);
    
    
    if nargin>=6 && ~isempty(timepointsToLoad)
        if max(timepointsToLoad)>length(cTimelapse.cTimepoint)
            timepointsToLoad=timepointsToLoad(timepointsToLoad<=length(cTimelapse.cTimepoint));
        end
        cTimelapse.cTimepoint=cTimelapse.cTimepoint(timepointsToLoad);
    end
    image=imread([folder cTimelapse.cTimepoint(1).filename{1}]);
    
else
    %Image is from Omero database
    cTimepointTemplate = cTimelapse.cTimepointTemplate;
    
    cTimelapse.cTimepoint = cTimepointTemplate;
    
    %Correct Z position - load image from the middle of the stack
    pixels=cTimelapse.omeroImage.getPrimaryPixels;
    sizeT=pixels.getSizeT().getValue();
    cTimelapse.cTimepoint(sizeT).filename=[];%This makes sure cTimepoint has the correct length
    cTimelapse.timepointsToProcess = 1:sizeT;
    
    %Load first timepoint of this cTimelapse to fill out the remaining
    %details
    
    image=cTimelapse.returnSingleTimepoint(1,find(strcmp(cTimelapse.channelNames,searchString)));
end

cTimelapse.imSize=size(image);
if nargin<3 || isempty(magnfication)
    h=figure;imshow(image,[]);
    prompt = {'Enter the magnification of the objective used'};
    dlg_title = 'magnification';
    num_lines = 1;
    def = {'60'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    cTimelapse.magnification=str2num(answer{1});
    close(h);
else
    cTimelapse.magnification=magnfication;
end

%
if nargin<5 || isempty(trapsPresent)
    prompt = {'Are traps present in this Timelapse?'};
    dlg_title = 'TrapsPresent';
    num_lines = 1;
    def = {'Yes'};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    if ~strcmp(answer{1},'Yes')
        cTimelapse.trapsPresent=false;
    else
        cTimelapse.trapsPresent=true;
    end
else
    cTimelapse.trapsPresent=trapsPresent;
end

if (nargin<4 || isempty(image_rotation))
    if cTimelapse.trapsPresent
        h=figure;imshow(image,[]);
        prompt = {'Enter the rotation (in degrees) required to orient opening of traps to the left'};
        dlg_title = 'Rotation';
        num_lines = 1;
        def = {'0'};
        answer = inputdlg(prompt,dlg_title,num_lines,def);
        cTimelapse.image_rotation=str2num(answer{1});
        close(h);
    else
        cTimelapse.image_rotation=0;
    end
else
    cTimelapse.image_rotation=image_rotation;
end
if nargin<7 || strcmp(imScale,'gui')
    
    prompt = {'Enter desired image rescaling value'};
    dlg_title = 'Scaling';
    num_lines = 1;
    def = {''};
    answer = inputdlg(prompt,dlg_title,num_lines,def);
    cTimelapse.imScale=str2num(answer{1});
else
    cTimelapse.imScale=imScale;
end

end

