function obj=measurefluorescence(obj)
% measurefluorescence --- records mean fluorescence in each cell at each timepoint
%
% Synopsis:  [obj]=measurefluorescence(obj)
%
% Input:     obj = an object of a timelapse class
%
% Output:    obj = an object of a timelapse class

% Notes:    Sets the timelapse.Data property. Measures mean fluorescence
%           in the z sections defined by obj.Sections for the channels defined by
%           obj.MeasuredChannels. This method requires files saved using
%           specific filenames in the folderwith path obj.Moviedir.
%           Sample filname: exp_000001_GFP_002.png
%           (GFP image, section 2, timepoint 1 of experiment 'exp')
%           This method currently assumes that an image is taken at every
%           time point in each channel - doesn't support data in which some
%           channels skip some timepoints.

numCells=max(obj.Tracked(:));%number of unique objects
obj.Data=zeros(numCells,size(obj.MeasuredChannels,2),size(obj.Tracked,3));%(cell number,channel,timepoint);
%Define a structure of fullfile structures - to carry the names of
%files to open
%Sample filename: exp_000001_GFP_002.png  (GFP image, section 2, timepoint 1)
for ch=1:size(obj.MeasuredChannels,2)
    chname=obj.Channels(obj.MeasuredChannels(ch));
    if iscell(chname)
        chname=chname{:};
    end
    if isempty(obj.Sections)
        chsectstring=strcat('*_',chname,'_*');
        chsectfiles(ch,1).filename=dir(fullfile(obj.Moviedir,chsectstring));
    else
        for sect=1:size(obj.Sections,1)
            sectname=num2str(obj.Sections(sect),'%03.0f');
            chsectstring=strcat('*_',chname,'_',sectname,'*');
            chsectfiles(ch,sect).filename=dir(fullfile(obj.Moviedir,chsectstring));
        end
    end
    
end
%The filename for a a given timepoint, channel and section is now:
%chsectfiles(ch,sect).filename(timepoint).name


%nested loops to populate data through the timepoints
for t=1:size(obj.Tracked,3)
    disp(strcat('Measuring tp:',num2str(t)));
    %Now loop through the channels
    for ch=1:size(obj.MeasuredChannels,2)
        %For each channel generate a dataset having all measured
        %sections at this timepoint
        if isempty(obj.Sections) %no z section given - assumes a single z stack.
            chtpdata=zeros(obj.ImageSize(2),obj.ImageSize(1),1);%(y,x,z)
            
            %read data into the chtpdata array.
            chtpdata(:,:)=imread(strcat(obj.Moviedir,'/',chsectfiles(ch,1).filename(t).name));
            
            for cell=1:numCells
                obj.Data(cell,ch,t)=mean(chtpdata(obj.Tracked(:,:,t)==cell));
            end
            
        else
            chtpdata=zeros(obj.ImageSize(2),obj.ImageSize(1),size(obj.Sections,1));%(y,x,z)
            
            %Now loop through the sections, reading the data into the
            %chtpdata array
            for sect=1:size(obj.Sections,1)
                chtpdata(:,:,sect)=imread(strcat(obj.Moviedir,'/',chsectfiles(ch,sect).filename(t).name));
            end
            
            %Calculate mean values for each cell
            for cell=1:numCells%Hasn't been tested. Should average reading from all z stacks of interest.
                obj.Data(cell,ch,t)=mean(chtpdata(obj.Tracked(:,:,t)==cell));
            end
            
        end
        
        
    end
end



