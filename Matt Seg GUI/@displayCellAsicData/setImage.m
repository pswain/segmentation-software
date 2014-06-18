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
    [~, labels]=find(cData.cellsToPlot);
    for i= 1:length(labels);
        [~, position]=find(cData.cTimelapse.cTimepoint(sliderVal).trapInfo.cellLabel==labels(i));
        
        %Pick a color for the circle if one is not already there
        %Stored in a sparse matrix, in same location as the data itself
        if cData.trackingColors(labels(i),1:3)==0
            colorOption=get(cData.colorSelect,'Value');
            switch colorOption
                case 1 %"Default"
                    curColor=rand(1,3);
                    
                case 2 %"Red"
                    curColor=[1 0 0];
                case 3 %"Yellow"
                    curColor=[0 0.8 0];
                case 4 %"Blue"
                    curColor=[0 0 1];
                    
            end
            cData.trackingColors(labels(i),1:3)=curColor;
        else
            curColor=cData.trackingColors(labels(i),1:3);
        end
        
        if ~isempty(position)
            outlines=cData.cTimelapse.cTimepoint(sliderVal).trapInfo.cell(position).segmented;
            outlines=cat(3,full(outlines*curColor(1)),full(outlines*curColor(2)),full(outlines*curColor(3)));
            
            cData.currentImage(outlines>0)=0;
            cData.currentImage=imadd(cData.currentImage,outlines);
        end
    end
    %Update image


    set(cData.image,'cdata',cData.currentImage);

end %setImage

