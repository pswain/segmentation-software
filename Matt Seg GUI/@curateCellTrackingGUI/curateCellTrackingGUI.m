classdef curateCellTrackingGUI<handle
    properties
        figure = [];
        subImage = [];
        subAxes=[];
        slider = [];
        cTimelapse=[]
        channel=1;
        tracksDisplayBox=[];
        trapIndex = 1;
        CellLabel = 1;
        subAxesTimepoints = [];
        subAxesIndex = [];
        Channels = 1;
        PermuteVector = []; %vector of permutations of cel labels to make colours more different and visualisation easier.
        ColourScheme = 'trackedCellOnly';
        
        %a boolean of whether to show the other channels in the
        %timelapse. Decide what to do with this later.
        ShowOtherChannels = false;
        BaseImages = []; % images stored of traps
        CellOutlines = [];% outlines stored of traps
        DataObtained = []; %vector of whether the data has been obtained for each timepoint.
        StripWidth = 5;
        TimepointsInStrip;
    end % properties
    
    % A GUI written by Elco to edit the outline of cells segmented by the
    % radial active contour methods.
    % Currently written to show the contour on all the available channels
    % and the transformed image.
    
    methods
        function TrackingCurator=curateCellTrackingGUI(cTimelapse,Timepoint,TrapIndex,StripWidth,ShowOtherChannels,ColourScheme)
            % TrackingCurator=editActiveContourCellGUI(ttacObject,TrapNum,CellNum,Timepoint(optional),StripWidth(optional),ShowOtherChannels(optional),ColourScheme(optional))
            
            AllowedColourSchemes = {'multicoloured' 'trackedCellOnly'}; % a cell array of allowed colour scheme strings
            
            TrackingCurator.cTimelapse = cTimelapse;
            
            if nargin<2 || isempty(Timepoint)
                Timepoint = min(TrackingCurator.cTimelapse.timepointsToProcess);
            end
            
            if ~(nargin<3 || isempty(TrapIndex))
                TrackingCurator.trapIndex = TrapIndex;
            end
            
            if ~(nargin<4 || isempty(StripWidth))
                TrackingCurator.StripWidth = StripWidth;
            end
            
            if ~(nargin<5 || isempty(ShowOtherChannels))
                TrackingCurator.ShowOtherChannels = ShowOtherChannels;
            end
            
            if ~(nargin<6 || isempty(ColourScheme) )
                
                if ~any(strcmp(ColourScheme,AllowedColourSchemes))
                    
                    fprintf('Colourscheme given (%s) is not an allowed colour scheme. \nAllowed Colour Schemes are',ColourScheme)
                    
                    for i=1:length(AllowedColourSchemes)
                        fprintf('%s \n',AllowedColourSchemes{i})
                    end
                else
                    
                    TrackingCurator.ColourScheme = ColourScheme;
                end
            end
            
            MiddleOfStripWidth = ceil(TrackingCurator.StripWidth/2);
            
            maxTimepoint =max(TrackingCurator.cTimelapse.timepointsToProcess);
            
            if TrackingCurator.StripWidth>maxTimepoint
                TrackingCurator.StripWidth = maxTimepoint;
            end
            
            TrackingCurator.PermuteVector = randperm(TrackingCurator.cTimelapse.cTimepoint(1).trapMaxCell(TrackingCurator.trapIndex));
            
            if TrackingCurator.ShowOtherChannels
                
                AvailableChannels = 1:length(cTimelapse.channelNames);
                TrackingCurator.Channels = AvailableChannels;
                
            end
            
            dis_h=(length(TrackingCurator.Channels));
            
            
            TrackingCurator.UpdateTimepointsInStrip(Timepoint);
            
            TrackingCurator.instantiateImages;
            TrackingCurator.instantiateCellOutlines;
            TrackingCurator.DataObtained = false(1,maxTimepoint);
            
            
            
            TrackingCurator.figure=figure('MenuBar','none');
            
            TrackingCurator.subAxesTimepoints = zeros(dis_h,TrackingCurator.StripWidth);
            TrackingCurator.subAxes = zeros(dis_h,TrackingCurator.StripWidth);
            TrackingCurator.subAxesIndex = zeros(dis_h,TrackingCurator.StripWidth);
            
            
            t_width=.9/TrackingCurator.StripWidth;
            t_height=.9/dis_h;
            bb=.1/max([TrackingCurator.StripWidth dis_h+1]);
            index=1;
            for i=1:TrackingCurator.StripWidth
                for j=1:dis_h
                    
                    TrackingCurator.subAxesIndex(j,i) = index;
                    TrackingCurator.subAxes(index)=subplot('Position',[(t_width+bb)*(i-1)+bb/2 (t_height+bb)*(j-1)+bb*3 t_width t_height]);
                    %TrackingCurator.subAxesTimepoints(j,i)=TrackingCurator.TimepointsInStrip(i);
                    
                    TrackingCurator.subImage(j,i)=subimage(TrackingCurator.BaseImages{j}(:,:,i));
                    
                    set(TrackingCurator.subAxes(index),'xtick',[],'ytick',[])
                    
                    % THIS FUNCTION CALLBACK SHOULD LOOK SOMETHING LIKE EditContour(TrackingCurator,Timepoint,trapNum,CellNum,pt,CellCenter)
                    set(TrackingCurator.subImage(index),'ButtonDownFcn',@(src,event) EditTracking(TrackingCurator,TrackingCurator.subAxes(index),TrackingCurator.subAxesIndex(index))); % Set the motion detector.
                    set(TrackingCurator.subImage(index),'HitTest','on'); %now image button function will work
                    
                    index=index+1;
                end
            end
            
            if TrackingCurator.StripWidth<maxTimepoint
                %if the StripWidth is larger than the nmber of timepoints
                %in the timelapse the slider should not be made and the
                %figure should simply display all the images in the
                %timelapse.
                
                TrackingCurator.slider=uicontrol('Style','slider',...
                    'Parent',gcf,...
                    'Min',min(TrackingCurator.cTimelapse.timepointsToProcess)+MiddleOfStripWidth - 1,...
                    'Max',1+maxTimepoint-MiddleOfStripWidth,...
                    'Units','normalized',...
                    'Value',Timepoint,...
                    'Position',[bb*2/3 bb 1-bb/2 bb*1.5],...
                    'SliderStep',[1/(maxTimepoint - MiddleOfStripWidth) 10/(maxTimepoint - MiddleOfStripWidth)],...
                    'Callback',@(src,event)curateCellTrackingGUI_slider_cb(TrackingCurator));
                
                %This hlistener line means that everytime the property 'Value'
                %of TrackingCurator.slider changes the callback slider_cb is run.
                hListener = addlistener(TrackingCurator.slider,'Value','PostSet',@(src,event)curateCellTrackingGUI_slider_cb(TrackingCurator));
                
                if Timepoint<min(TrackingCurator.cTimelapse.timepointsToProcess)+MiddleOfStripWidth
                    Timepoint = floor(min(TrackingCurator.cTimelapse.timepointsToProcess)+MiddleOfStripWidth);
                elseif Timepoint>maxTimepoint-MiddleOfStripWidth
                    Timepoint = ceil(maxTimepoint-MiddleOfStripWidth);
                end
                set(TrackingCurator.slider,'Value',Timepoint);
                curateCellTrackingGUI_slider_cb(TrackingCurator);
                
                %set the scroll wheel function - just a generic move slider
                %function
                
                set(TrackingCurator.figure,'WindowScrollWheelFcn',@(src,event)curateCellTrackingGUI_ScrollWheel_cb(TrackingCurator,src,event));
            else
          
                TrackingCurator.UpdateTimepointsInStrip(1);%the input given shouldn't matter in this case.
                TrackingCurator.UpdateImages;
                
            end
            
            set(TrackingCurator.figure,'WindowKeyPressFcn',@(src,event)curateCellTrackingGUI_KeyPress_cb(TrackingCurator,src,event));

                
        end
        
        function Images = getImages(TrackingCurator,Timepoints,TrapIndex)
            %Images = getImages(TrackingCurator,Timepoints,TrapIndex)
            
            %Return the images of the of the cell defined by
            %TrapIndex,CellLabel at the timepoints Timepoints. Images are
            %returned in all channels with the transformed images.
            
            
            %Timpoints is a row vector
            %TrapIndex is a single index

            
            DoAWaitBar = false;
            if nargin<2
                Timepoints = TrackingCurator.cTimelapse.timepointsToProcess;
                DoAWaitBar = true;
                
            end
            
            
            if nargin<3
                TrapIndex = TrackingCurator.trapIndex ;
            end
            
            
            if DoAWaitBar
                h = waitbar(0,'Please wait as we obtain your images ...');
            end
            
            Images = cell(1,(length(TrackingCurator.Channels)));
            
            [Images{:}] =  deal(zeros((2*TrackingCurator.cTimelapse.cTrapSize.bb_height)+1,(2*TrackingCurator.cTimelapse.cTrapSize.bb_width)+1,size(Timepoints,2)));
            
            ProgressCounter = 0;
            TotalTime = length(TrackingCurator.Channels)*length(Timepoints);
            for CH = TrackingCurator.Channels
                for TPi = 1:length(Timepoints)
                    Images{CH}(:,:,TPi) = double(TrackingCurator.cTimelapse.returnTrapsTimepoint(TrapIndex,Timepoints(TPi),CH));
                    if DoAWaitBar
                        ProgressCounter = ProgressCounter+1;
                        waitbar(ProgressCounter/TotalTime,h);
                    end
                end
            end
            
            if DoAWaitBar
                close(h);
            end
            
            %TrackingCurator.BaseImages = Images;
            
        end
        
        
        function Images = instantiateImages(TrackingCurator)
            %Images = instantiateImages(TrackingCurator)
            
            %Return empty cells for the images
            
            Timepoints = TrackingCurator.cTimelapse.timepointsToProcess;
            
            Images = cell(1,(length(TrackingCurator.Channels)));
            
            [Images{:}] =  deal(zeros((2*TrackingCurator.cTimelapse.cTrapSize.bb_height)+1,(2*TrackingCurator.cTimelapse.cTrapSize.bb_width)+1,size(Timepoints,2)));
            
            TrackingCurator.BaseImages = Images;
        end
        
        
          function CellOutines = instantiateCellOutlines(TrackingCurator)
            %Images = instantiateCellOutlines(TrackingCurator)
            
            %Return empty cells for the images
            
            Timepoints = TrackingCurator.cTimelapse.timepointsToProcess;
            
            CellOutlines = zeros((2*TrackingCurator.cTimelapse.cTrapSize.bb_height)+1,(2*TrackingCurator.cTimelapse.cTrapSize.bb_width)+1,size(Timepoints,2));
            
            TrackingCurator.CellOutlines = CellOutlines;
           
        end
        
        
        
        function CellOutlines = getCellOutlines(TrackingCurator,Timepoints,TrapIndex)
            %CellOutlines = getCellOutlines(TrackingCurator,Timepoints,TrapIndex,CellLabel)
            
            
            %Return logicals of the outline of the cell defined by
            %TrapIndex,CellLabel at the timepoints Timepoints.
            
            %Timpoints is a row vector
            %TrapIndex is a single index
            %cellLabel is a single number
            
            
            if nargin<2
                Timepoints = TrackingCurator.cTimelapse.timepointsToProcess;
            end
            
            
            if nargin<3
                TrapIndex = TrackingCurator.trapIndex ;
            end
            
            
            CellOutlines = zeros((2*TrackingCurator.cTimelapse.cTrapSize.bb_height)+1,(2*TrackingCurator.cTimelapse.cTrapSize.bb_width)+1,size(Timepoints,2));
            if nargin<2
                h = waitbar(0,'Please wait as we obtain your cell outlines ...');
                ProgressCounter = 0;
                TotalTime = length(Timepoints);
            end
            
            for TPi = 1:length(Timepoints)
             
                if ~isempty(TrackingCurator.cTimelapse.cTimepoint(Timepoints(TPi)).trapInfo)
                    if TrackingCurator.cTimelapse.cTimepoint(Timepoints(TPi)).trapInfo(TrapIndex).cellsPresent
                        
                        tempCellOutline = CellOutlines(:,:,TPi);
                        for CI = 1:length(TrackingCurator.cTimelapse.cTimepoint(Timepoints(TPi)).trapInfo(TrapIndex).cell)
                            
                            tempCellOutline(imdilate(full(TrackingCurator.cTimelapse.cTimepoint(Timepoints(TPi)).trapInfo(TrapIndex).cell(CI).segmented),[0 1 0;1 1 1;0 1 0],'same')) =...
                                TrackingCurator.PermuteVector(TrackingCurator.cTimelapse.cTimepoint(Timepoints(TPi)).trapInfo(TrapIndex).cellLabel(CI));
                            
                        end
                        
                        CellOutlines(:,:,TPi) = tempCellOutline(:,:);
                        
                    end
                else
                    
                    fprintf('\n \n No trap infor at timepoint %d \n \n',Timepoints(TPi))
                    
                end
                if nargin<2
                    ProgressCounter = ProgressCounter+1;
                    waitbar(ProgressCounter/TotalTime,h)
                end
            end
            if nargin<2
                close(h);
            end
            
            CellOutlines = double(CellOutlines);
        end
        
        
        
        function UpdateImages(TrackingCurator)
            %updates all the images in the GUI based on the BaseImages
            %property
            
            
            for widthi = 1:TrackingCurator.StripWidth
                if ~TrackingCurator.DataObtained(TrackingCurator.TimepointsInStrip(widthi))
                    Image = TrackingCurator.getImages(TrackingCurator.TimepointsInStrip(widthi));
                    Outline = TrackingCurator.getCellOutlines(TrackingCurator.TimepointsInStrip(widthi));
                    for heighti = 1:length(TrackingCurator.BaseImages)
                        TrackingCurator.BaseImages{heighti}(:,:,TrackingCurator.TimepointsInStrip(widthi)) = Image{heighti}(:,:);
                    end
                    TrackingCurator.CellOutlines(:,:,TrackingCurator.TimepointsInStrip(widthi)) = Outline(:,:);
                    %store information that data is saved
                    TrackingCurator.DataObtained(TrackingCurator.TimepointsInStrip(widthi)) = 1;
                end
                for heighti = 1:length(TrackingCurator.BaseImages)
                    tempImage = TrackingCurator.BaseImages{heighti}(:,:,TrackingCurator.TimepointsInStrip(widthi));
                    tempOutline = TrackingCurator.CellOutlines(:,:,TrackingCurator.TimepointsInStrip(widthi));
                    tempImage = tempImage-min(tempImage(:));
                    tempImage = tempImage/max(tempImage(:));
                    
                    %make the outline of cells coloured according to cell
                    %label
                    switch TrackingCurator.ColourScheme
                        case 'multicoloured'
                            tempImage = 0.3*tempImage;
                            tempImage = cat(3,tempImage,tempImage,tempImage);
                            [tempIndexI, tempIndexJ] = find(tempOutline==0,1);
                            tempOutline(tempIndexI,tempIndexJ) = TrackingCurator.cTimelapse.cTimepoint(1).trapMaxCell(TrackingCurator.trapIndex);
                            
                            tempOutline = label2rgb(tempOutline,'jet','w','noshuffle');
                            tempOutline(tempIndexI,tempIndexJ,:) = 255;
                            tempOutline = (0.95/0.3)*double(tempOutline)/255;
                            tempImage = tempImage.*double(tempOutline);
                            
                        case 'trackedCellOnly'
                            
                            tempImage = 0.7*tempImage; 
                            RedandGreen = tempImage;
                            Blue = tempImage;
                            Blue(tempOutline~=0 & tempOutline ~= TrackingCurator.PermuteVector(TrackingCurator.CellLabel)) = 0.95;
                            RedandGreen(tempOutline == TrackingCurator.PermuteVector(TrackingCurator.CellLabel)) = 0.95;
                            tempImage = cat(3,RedandGreen,RedandGreen,Blue);
                    end
                            
                    set(TrackingCurator.subImage(TrackingCurator.subAxesIndex(heighti,widthi)),'CData',tempImage);
                    
                    
                    
                end
            end
            
        end
        
        function UpdateTimepointsInStrip(TrackingCurator,Timepoint)
            
            MiddleOfStripWidth = ceil(TrackingCurator.StripWidth/2);
            
            TimepointsInStrip = (1:TrackingCurator.StripWidth) + Timepoint - MiddleOfStripWidth;
            
            if any(TimepointsInStrip<1)
                TimepointsInStrip = TimepointsInStrip + 1 - min(TimepointsInStrip,[],2);
            end
            
            if any(TimepointsInStrip>length(TrackingCurator.cTimelapse.cTimepoint))
                TimepointsInStrip = TimepointsInStrip + length(TrackingCurator.cTimelapse.cTimepoint)  - max(TimepointsInStrip,[],2);
            end
            
            TrackingCurator.TimepointsInStrip = TimepointsInStrip;
            
            
            for widthi = 1:TrackingCurator.StripWidth
                
                TrackingCurator.subAxesTimepoints(:,widthi) = TimepointsInStrip(widthi);
                
            end
            
             CI = TrackingCurator.cTimelapse.cTimepoint(TimepointsInStrip(MiddleOfStripWidth)).trapInfo(TrackingCurator.trapIndex).cellLabel == TrackingCurator.CellLabel;
             
             if any(CI) && isfield(TrackingCurator.cTimelapse.cTimepoint(TimepointsInStrip(MiddleOfStripWidth)).trapInfo(TrackingCurator.trapIndex).cell(CI), 'crossCorrelationScore');
                 CC = TrackingCurator.cTimelapse.cTimepoint(TimepointsInStrip(MiddleOfStripWidth)).trapInfo(TrackingCurator.trapIndex).cell(CI).crossCorrelationScore;
                 DI = TrackingCurator.cTimelapse.cTimepoint(TimepointsInStrip(MiddleOfStripWidth)).trapInfo(TrackingCurator.trapIndex).cell(CI).decisionImageScore;
                 
                 if isnan(CC)
                     set(TrackingCurator.figure,'Name',['Tracking Curation: Timepoints ' int2str(TimepointsInStrip(1)) ' to ' int2str(TimepointsInStrip(end)) ' of trap ' int2str(TrackingCurator.trapIndex) ' Decision Image Score = ' sprintf('%f',DI)]);
                 else
                     set(TrackingCurator.figure,'Name',['Tracking Curation: Timepoints ' int2str(TimepointsInStrip(1)) ' to ' int2str(TimepointsInStrip(end)) ' of trap ' int2str(TrackingCurator.trapIndex) ' Cross Correlation Score = ' sprintf('%f',CC)]);
                 end
                 
             else
                 
                 set(TrackingCurator.figure,'Name',['Tracking Curation: Timepoints ' int2str(TimepointsInStrip(1)) ' to ' int2str(TimepointsInStrip(end)) ' of trap ' int2str(TrackingCurator.trapIndex) ]);
                 
             end
             
            
            
        end
        
        
    end %methods
end%function