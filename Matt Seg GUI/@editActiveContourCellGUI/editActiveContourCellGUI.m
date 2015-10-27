classdef editActiveContourCellGUI<handle
    properties
        figure = [];
        subImage = [];
        subAxes=[];
        slider = [];
        cTimelapse=[]
        channel=1;
        tracksDisplayBox=[];
        trapIndex = 1;
        CellLabel = [];
        subAxesTimepoints = [];
        subAxesIndex = [];
        ttacObject = [];
        
         %a boolean of whether to show the other channels in the
            %timelapse. Decide what to do with this later.
        ShowOtherChannels = true;
        BaseImages = [];
        CellOutlines = [];
        StripWidth = 7;
        TimepointsInStrip;
    end % properties
    
    % A GUI written by Elco to edit the outline of cells segmented by the
    % radial active contour methods.
    % Currently written to show the contour on all the available channels
    % and the transformed image.
    
      methods
        function CellACDisplay=editActiveContourCellGUI(ttacObject,Timepoint,TrapIndex,CellIndex,StripWidth,ShowOtherChannels)
            % CellACDisplay=editActiveContourCellGUI(ttacObject,TrapNum,CellNum,Timepoint(optional),StripWidth(optional))
            
           
            CellACDisplay.ttacObject = ttacObject;            
            
            if nargin<2 || isempty(Timepoint)
                Timepoint = 1;
            end
            
            if ~(nargin<3 || isempty(TrapIndex))
                CellACDisplay.trapIndex = TrapIndex;
            end
            
            if nargin<4 || isempty(CellIndex)
                CellIndex = 1;
            end
            
            if ~(nargin<5 || isempty(StripWidth))
                CellACDisplay.StripWidth = StripWidth;
            end
            
            if ~(nargin<6 || isempty(ShowOtherChannels))
                CellACDisplay.ShowOtherChannels = ShowOtherChannels;
            end
            
            
            MiddleOfStripWidth = ceil(CellACDisplay.StripWidth/2);

            maxTimepoint = ttacObject.LengthOfTimelapse;
            
            CellACDisplay.CellLabel = ttacObject.ReturnLabel(Timepoint,CellACDisplay.trapIndex,CellIndex);
            
            if CellACDisplay.ShowOtherChannels
                
                AvailableChannels = ttacObject.ReturnAvailableChannels;
           
                dis_h=(length(AvailableChannels) + 1);
            
            else
                dis_h = 2;
            end
            
            
            CellACDisplay.UpdateTimepointsInStrip(Timepoint);
            
            CellACDisplay.BaseImages = CellACDisplay.getImages;
            CellACDisplay.CellOutlines = CellACDisplay.getCellOutlines;
            
            
            CellACDisplay.figure=figure('MenuBar','none');
            
            CellACDisplay.subAxesTimepoints = zeros(dis_h,CellACDisplay.StripWidth);
            CellACDisplay.subAxes = zeros(dis_h,CellACDisplay.StripWidth);
            CellACDisplay.subAxesIndex = zeros(dis_h,CellACDisplay.StripWidth);

            
            t_width=.9/CellACDisplay.StripWidth;
            t_height=.9/dis_h;
            bb=.1/max([CellACDisplay.StripWidth dis_h+1]);
            index=1;
            for i=1:CellACDisplay.StripWidth
                for j=1:dis_h
                    
                    CellACDisplay.subAxesIndex(j,i) = index;
                    CellACDisplay.subAxes(index)=subplot('Position',[(t_width+bb)*(i-1)+bb/2 (t_height+bb)*(j-1)+bb*3 t_width t_height]);
                    %CellACDisplay.subAxesTimepoints(j,i)=CellACDisplay.TimepointsInStrip(i);
                    
                    CellACDisplay.subImage(j,i)=subimage(CellACDisplay.BaseImages{j}(:,:,i));
 
                    set(CellACDisplay.subAxes(index),'xtick',[],'ytick',[])
                    
                    % THIS FUNCTION CALLBACK SHOULD LOOK SOMETHING LIKE EditContour(CellACDisplay,Timepoint,trapNum,CellNum,pt,CellCenter)
                    set(CellACDisplay.subImage(index),'ButtonDownFcn',@(src,event) EditContour(CellACDisplay,CellACDisplay.subAxes(index),CellACDisplay.subAxesIndex(index))); % Set the motion detector.
                    set(CellACDisplay.subImage(index),'HitTest','on'); %now image button function will work

                    index=index+1;
                end
            end
            
            CellACDisplay.slider=uicontrol('Style','slider',...
                'Parent',gcf,...
                'Min',MiddleOfStripWidth,...
                'Max',maxTimepoint-MiddleOfStripWidth,...
                'Units','normalized',...
                'Value',Timepoint,...
                'Position',[bb*2/3 bb 1-bb/2 bb*1.5],...
                'SliderStep',[1/(maxTimepoint - MiddleOfStripWidth) 10/(maxTimepoint - MiddleOfStripWidth)],...
                'Callback',@(src,event)editActiveContourCell_slider_cb(CellACDisplay));
            
            %This hlistener line means that everytime the property 'Value'
            %of CellACDisplay.slider changes the callback slider_cb is run.
            hListener = addlistener(CellACDisplay.slider,'Value','PostSet',@(src,event)editActiveContourCell_slider_cb(CellACDisplay));
            
            if Timepoint<MiddleOfStripWidth
                Timepoint = ceil(MiddleOfStripWidth);
            elseif Timepoint>maxTimepoint-MiddleOfStripWidth
                Timepoint = floor(maxTimepoint-MiddleOfStripWidth);
            end
            set(CellACDisplay.slider,'Value',Timepoint);
            editActiveContourCell_slider_cb(CellACDisplay);
            
            %set the scroll wheel function
            
            set(CellACDisplay.figure,'WindowScrollWheelFcn',@(src,event)editActiveContourCell_ScrollWheel_cb(CellACDisplay,src,event));
            
        end
        
        function Images = getImages(CellACDisplay,Timepoints,TrapIndex,CellLabel)
            %Images = getImages(CellACDisplay,Timepoints,TrapIndex,CellLabel)
            
            %Return the images of the of the cell defined by
            %TrapIndex,CellLabel at the timepoints Timepoints. Images are
            %returned in all channels with the transformed images.
            
            
            %Timpoints is a row vector
            %TrapIndex is a single index
            %cellLabel is a single number
            
            
            if nargin<2
                Timepoints = CellACDisplay.ttacObject.TimepointsToCheck;
            end
            
            
            if nargin<3
                TrapIndex = CellACDisplay.trapIndex ;
            end
            
            
            if nargin<4
                CellLabel = CellACDisplay.CellLabel;
            end
            
            
            if CellACDisplay.ShowOtherChannels
                
                AvailableChannels = CellACDisplay.ttacObject.ReturnAvailableChannels;
           
            else
                AvailableChannels = 1;
            end
            
            Images = cell(1,(length(AvailableChannels)+1));
            
            [Images{:}] =  deal(zeros(CellACDisplay.ttacObject.Parameters.ImageSegmentation.SubImageSize,CellACDisplay.ttacObject.Parameters.ImageSegmentation.SubImageSize,size(Timepoints,2)));

            TrapIndex = TrapIndex*ones(size(Timepoints));
            
            CellLabel = CellLabel*ones(size(Timepoints));
            
            CellIndices = CellACDisplay.ttacObject.ReturnCellIndex(Timepoints,TrapIndex,CellLabel);
            
            CellsOfInterest = CellIndices>0;
            
            Timepoints = Timepoints(CellsOfInterest);
            TrapIndex = TrapIndex(CellsOfInterest);
            CellIndices = CellIndices(CellsOfInterest);
            
            
            %waitbar
            h = waitbar(0,'Please wait as we obtain your images ...');
                     
            if any(CellsOfInterest)
                
                [Images{1}(:,:,CellsOfInterest)   Images{2}(:,:,CellsOfInterest)]= CellACDisplay.ttacObject.ReturnTransformedImagesForSingleCell(Timepoints,TrapIndex,CellIndices);
                
                waitbar(2/(length(AvailableChannels)+1),h);
                
                if CellACDisplay.ShowOtherChannels && length(AvailableChannels)>1
                    
                    for chani = 2:length(AvailableChannels)
                        
                        waitbar((chani+1)/(length(AvailableChannels)+1),h);
                        
                        Images{chani+1}(:,:,CellsOfInterest) = CellACDisplay.ttacObject.ReturnImageOfSingleCell(Timepoints,TrapIndex,CellIndices,AvailableChannels(chani));
                        
                    end
                    
                end
                
            end
            
            close(h);
            
            %CellACDisplay.BaseImages = Images;
            
        end
        

        
        function CellOutlines = getCellOutlines(CellACDisplay,Timepoints,TrapIndex,CellLabel)
            %CellOutlines = getCellOutlines(CellACDisplay,Timepoints,TrapIndex,CellLabel)
            
                        
            %Return logicals of the outline of the cell defined by
            %TrapIndex,CellLabel at the timepoints Timepoints. 
            
            %Timpoints is a row vector
            %TrapIndex is a single index
            %cellLabel is a single number
            
            
            
            if nargin<2
                Timepoints = CellACDisplay.ttacObject.TimepointsToCheck;
            end
            
            
            if nargin<3
                TrapIndex = CellACDisplay.trapIndex ;
            end
            
            
            if nargin<4
                CellLabel = CellACDisplay.CellLabel;
            end

            
            CellOutlines = false(CellACDisplay.ttacObject.Parameters.ImageSegmentation.SubImageSize,CellACDisplay.ttacObject.Parameters.ImageSegmentation.SubImageSize,size(Timepoints,2));

            TrapIndex = TrapIndex*ones(size(Timepoints));
            
            CellLabel = CellLabel*ones(size(Timepoints));
            
            CellIndices = CellACDisplay.ttacObject.ReturnCellIndex(Timepoints,TrapIndex,CellLabel);
            
            CellsOfInterest = CellIndices>0;
            
            Timepoints = Timepoints(CellsOfInterest);
            TrapIndex = TrapIndex(CellsOfInterest);
            CellIndices = CellIndices(CellsOfInterest);
                 
            if any(CellsOfInterest)
                
                CellOutlines(:,:,CellsOfInterest)   = CellACDisplay.ttacObject.ReturnCellOutlinesForSingleCell(Timepoints,TrapIndex,CellIndices);  
                
            end
            
            %CellACDisplay.CellOutlines = CellOutlines;
            
        end
        
        
        
        function UpdateImages(CellACDisplay)
            %updates all the images in the GUI based on the BaseImages
            %property
            
            
            for widthi = 1:CellACDisplay.StripWidth
                for heighti = 1:length(CellACDisplay.BaseImages)
                    tempImage = CellACDisplay.BaseImages{heighti}(:,:,CellACDisplay.TimepointsInStrip(widthi));
                    tempOutline = CellACDisplay.CellOutlines(:,:,CellACDisplay.TimepointsInStrip(widthi));
                    tempImage = tempImage-min(tempImage(:));
                    tempImage = 0.7*tempImage/max(tempImage(:));
                    
                    %make the outline red
                    tempImage2 = tempImage;
                    tempImage2(tempOutline) = 0.95;
                    tempImage = cat(3,tempImage2,tempImage,tempImage);
                    
                    set(CellACDisplay.subImage(CellACDisplay.subAxesIndex(heighti,widthi)),'CData',tempImage);
                    
                end
            end
            
        end
        
        function UpdateTimepointsInStrip(CellACDisplay,Timepoint)
            
            MiddleOfStripWidth = ceil(CellACDisplay.StripWidth/2);
            
            TimepointsInStrip = (1:CellACDisplay.StripWidth) + Timepoint - MiddleOfStripWidth;
            
            if any(TimepointsInStrip<1)
                TimepointsInStrip = TimepointsInStrip + 1 - min(TimepointsInStrip,[],2);
            end
            
            if any(TimepointsInStrip>CellACDisplay.ttacObject.LengthOfTimelapse)
                TimepointsInStrip = TimepointsInStrip + CellACDisplay.ttacObject.LengthOfTimelapse  - max(TimepointsInStrip,[],2);
            end
            
            CellACDisplay.TimepointsInStrip = TimepointsInStrip;
            
            
            for widthi = 1:CellACDisplay.StripWidth
                
                CellACDisplay.subAxesTimepoints(:,widthi) = TimepointsInStrip(widthi);
            
            end
            
            set(CellACDisplay.figure,'Name',['Timepoints ' int2str(TimepointsInStrip(1)) ' to ' int2str(TimepointsInStrip(end))]);

            
            
            
        end


      end %methods
end%function