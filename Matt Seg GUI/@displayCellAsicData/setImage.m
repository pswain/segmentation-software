function setImage(cData)
%%setImage Set the image displayed on the timelapse to the appropriate one
%%for the timepoint and channel, then overlay the tracking circles
%TODO
%Change from making a full mask image to just coloring the circles
%Comment and help section
%Multiple color selection
    channel=get(cData.channelSelect,'value');
    sliderVal=floor(get(cData.timepointSlider,'Value'));
    rawImage=imread([cData.cTimelapse.timelapseDir filesep cData.cTimelapse.cTimepoint(sliderVal).filename{channel}]);
    outlines=[];
    %Scale and convert to RGB
    rawImage=double(rawImage)/double(max(rawImage(:)));
    cData.currentImage=cat(3,rawImage,rawImage,rawImage);
    [traps, labels]=find(cData.cellsToPlot);
    for i= 1:length(labels);
        %Find the position of this cell by matching its label to the
        %cellLabel vector
        if cData.cTimelapse.trapsPresent
            [~, position]=find(cData.cTimelapse.cTimepoint(sliderVal).trapInfo(1).cellLabel==labels(i));
        else
            %Do something
        end
        %Pick a color for the circle if one is not already there
        %Stored in a sparse matrix, in same location as the data itself
        if cData.trackingColors(labels(i),1:3)==0 %If no color is allocated
            colorOption=get(cData.colorSelect,'Value');
            switch colorOption
                case 1 %"Default"
                    curColor=rand(1,3);
                    
                case 2 %"Red"
                    curColor=[1 0 0];
                case 3 %"Green"
                    curColor=[0 0.8 0];
                case 4 %"Blue"
                    curColor=[0 0 1];
                    
            end
            cData.trackingColors(labels(i),1:3)=curColor;
        else % Use the alredy allocated color
            curColor=cData.trackingColors(labels(i),1:3);
        end
        
        if ~isempty(position)
            outlines=cData.cTimelapse.cTimepoint(sliderVal).trapInfo(traps(i)).cell(position).segmented;
            
            trapXPos=cData.cTimelapse.cTimepoint(sliderVal).trapLocations(traps(i)).xcenter-ceil(0.5*length(outlines(1,:)));
            trapYPos=cData.cTimelapse.cTimepoint(sliderVal).trapLocations(traps(i)).ycenter-ceil(0.5*length(outlines(1,:)));
            tempImage=zeros(size(cData.currentImage));
            tempImage(outlines>0)=1;
            outlines=imtranslate(tempImage,[trapYPos trapXPos]);
            center=cData.cTimelapse.cTimepoint(sliderVal).trapInfo(traps(i)).cell(position).cellCenter;
            outlines=cat(3,full(outlines*curColor(1)),full(outlines*curColor(2)),full(outlines*curColor(3)));
            
            cData.currentImage(outlines>0)=0;
            cData.currentImage=imadd(cData.currentImage,outlines);
            cData.currentImage=insertText(cData.currentImage,center,labels(i),...
                                            'TextColor',full(curColor),'BoxOpacity',0);
        end
    end
    %Update image


    set(cData.image,'cdata',cData.currentImage);

end %setImage

