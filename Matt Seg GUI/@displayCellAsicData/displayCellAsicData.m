classdef displayCellAsicData < handle
    
    %displayCellAsicData Open two windows; one with a timelapse, and one with a plot of the intensity of fluorescense in varioius cells.
    %--------------------------------------------------------------
    %   Class to track the concentration of GFP in the nucleus of a
    %   cell. Designed to be a sub-class of experimentTrackingGUI, and expects
    %   data in the form that the timelapseTraps functions produce.
    %   
    %   Concentration of GFP is defined by max5/median pixel brightnes,
    %   where max5 is the mean brightnes of the 5 brightest pixels.
    %
    %   Print currently prints the 12th frame, 16th frame, and plot of
    %   intensity to a single image. Print all button will print each frame
    %   and the plot to a folder, in the same sub-folder the timelapse was
    %   made from.
    %   NOTE: Does not currently support traps
    %   
    %   KEY VARS:       cellsToPlot: 100x100 sparse matrix
    %                     Copy of cData.cTimelapse.cellsToPlot.
    %                     Tracks the labels of cells which should be
    %                     plotted. 1's in the matrix denote a cell which
    %                     is being tracked, while the row number gives its
    %                     label.
    %                     cellsToPlot is edited to track which cells are
    %                     currently selected in the GUI.
    %
    %                   trackingColors
    %                     Tracks the RGB color of individual cells in the
    %                     GUI. As with the previous, the row of a value
    %                     denotes the cell to which is applies, and the
    %                     three columns denote the RGB value in double
    %                     format.
    %
    %                   cellsWithData
    %                     Lists the cell labels which had data extracted
    %                     from them. Used to make sure that a cell with no
    %                     data cannot be selected (because that would crash
    %                     the thing)
    %
    %   SYNTAX:         displayCellAsicData(timelapseTrapsGUI)
    %                   displayCellAsicData(timelapseTrapsGUI, cellsTotrack)
    %           
    %                     cellsToTrack is an optional argument, which specifies an
    %                     alternate cData.cellsToTrack matrix (usually blank
    %                     to give no initial tracks). Including cells which
    %                     don't have data will cause a crash, so take care.
    %                                                                        
    
    properties
        cTimelapse=[]
        imageFigure=[]
        subImage=[]
        currentImage=[] %512x512x3 matrix of imagedata
        image=[] %image where image data is displayed
        timepointSlider=[]
        textbox=[]
        channelSelect=[]
        colorSelect=[]
        channelListener=[]
        slideListener=[]
        plotFigure=[]
        plotAxes=[]
        plotVMarker=[]
        trackingColors=[] %Track the colors used to identify the cells
        cellsToPlot=[]% For automatic detection of whi5 cells
        cellsWithData=[]
        
    end
    
    methods
        function cData=displayCellAsicData(cTimelapse,cellsToPlot)
            %Class constructor: sets up the various plots, fetches the
            %images, plots the graphs, and sets up the GUI elements
            %2 Figures are used, on for the main image and GUI and one for
            %the plot.
                        
            if cTimelapse.trapsPresent
                msgbox('This function wil not work if traps are present');
                return
            end
            cData.cTimelapse=cTimelapse;
            if nargin>1
                cData.cellsToPlot = cellsToPlot;
            else
                cData.cellsToPlot=cData.cTimelapse.cellsToPlot;
            end
            
            [~, cData.cellsWithData]=find(cData.cTimelapse.cellsToPlot);
            
            %Set up image
            set(0,'units','normalized');
         
            cData.imageFigure=figure('units','normalized','position',[0.1,0.25,0.4,0.4]);
            cData.subImage=subplot(1,1,1);
            rawImage=imread([cData.cTimelapse.timelapseDir filesep cData.cTimelapse.cTimepoint(1).filename{2}]);
            rawImage=double(rawImage)/double(max(rawImage(:)));
            cData.currentImage=cat(3,rawImage,rawImage,rawImage);
            
            
            [a b]=find(cData.cellsToPlot);
            cData.trackingColors=sparse(zeros(100,100));
            for i= 1:length(b);
                curColor=rand(1,3);
                position=find(cData.cTimelapse.cTimepoint(1).trapInfo.cellLabel==b(i));
                
                
                if ~isempty(position)
                    cData.trackingColors(position,1:3)=curColor;
                    maskImage=cat(3,ones(512,512)*curColor(1),ones(512,512)*curColor(2),ones(512,512)*curColor(3));
                    
                    outlines=full(cData.cTimelapse.cTimepoint(1).trapInfo.cell(position).segmented);
                    outlines=cat(3,outlines,outlines,outlines);
                    maskImage=maskImage.*outlines;
                    cData.currentImage(maskImage>0)=0;
                    cData.currentImage=imadd(cData.currentImage,maskImage);
                end
            end
            
            cData.image=imshow(cData.currentImage,[],'parent',cData.subImage);
            set(cData.image,'hittest','off');
            
            %Set up plot
            cData.plotFigure=figure('units','normalized','position',[0.5,0.25 0.4 0.4]);
            cData.plotAxes=axes('parent',cData.plotFigure,'color',[0.9,0.9,0.9]);
            timepoint=floor(get(cData.timepointSlider,'value'));
            if isempty(timepoint)
                timepoint=1;
            end
            cla(cData.plotAxes);
            data = cData.cTimelapse.extractedData;
            hold(cData.plotAxes,'on');
            [~, label]=find(cData.cellsToPlot);
            
            for i=1:length(label)
                numTimepoints=length(cData.cTimelapse.cTimepoint);
                median=data(2).median(i,:);
                m5=data(2).max5(i,:);
                plot(cData.plotAxes,1:numTimepoints,m5./median,'color',cData.trackingColors(label(i),1:3));
                
            end
            
            cData.plotVMarker=plot(cData.plotAxes, [timepoint timepoint], [1 2]);
            hold(cData.plotAxes,'off');
            SliderStep = [1/(length(cTimelapse.cTimepoint)-1) 1/(length(cTimelapse.cTimepoint)-1)];
            %set up UI controls
            timelapseSize = length(cData.cTimelapse.cTimepoint);
            cData.textbox=uicontrol('style','text',...
                'units','normalized',...
                'position',[0.19,0.05,0.05,0.04],...
                'string','1',...
                'parent',cData.imageFigure);
            cData.timepointSlider=uicontrol('style','slider',...
                'units','normalized',...
                'min',1,'max',timelapseSize,'Value',1,...
                'position',[0.25,0.05,0.5,0.04],...
                'sliderstep',SliderStep,...
                'parent',cData.imageFigure); %'Callback',{@sliderChanged,timelapse,image,plotAxes} Original. Moved to listener
            cData.channelSelect=uicontrol('style','popupmenu' ,...
                'string',cData.cTimelapse.channelNames,...
                'value',2,...
                'Units','normalized',...
                'position',[0.19,0.00,0.1,0.04],...
                'parent',cData.imageFigure);
            cData.colorSelect=uicontrol('style','popupmenu' ,...
                'string',{'Default','Red','Green','Blue'},...
                'Units','normalized',...
                'position',[0.32,0.00,0.1,0.04],...
                'parent',cData.imageFigure);
            printToExcel=uicontrol('style','pushbutton',...
                'string','Print to Excel',...
                'units','normalized',...
                'position',[0.545,0.003,0.1,0.04],...
                'parent',cData.imageFigure,...
                'callback',@(src,event)printCAData(cData));
            printAll=uicontrol('style','pushbutton',...
                'string','Print Images',...
                'units','normalized',...
                'position',[0.65,0.003,0.1,0.04],...
                'parent',cData.imageFigure,...
                'callback',@(src,event)printImages(cData));
            printSingleImage=uicontrol('style','pushbutton',...
                'string','Print Single Image',...
                'units','normalized',...
                'position',[0.755,0.003,0.1,0.04],...
                'parent',cData.imageFigure,...
                'callback',@(src,event)printSingle(cData));
            
            cData.slideListener=addlistener(cData.timepointSlider,'Value','PostSet',@(src,event)sliderChanged(cData));
            
            cData.channelListener=addlistener(cData.channelSelect,'Value','PostSet',@(src,event)setImage(cData));
            %Buttondownfcn listener
            set(cData.subImage,'buttondownfcn',{@mouseClick,cData},'hittest','on','visible','on')
            
            set(cData.imageFigure,'WindowScrollWheelFcn',@(src,event)cellAsic_ScrollWheel_cb(cData,src,event))
            set(cData.plotFigure,'WindowScrollWheelFcn',@(src,event)cellAsic_ScrollWheel_cb(cData,src,event))

        end
        %%
        function sliderChanged(cData)
            %Callback after 
            sliderVal=floor(get(cData.timepointSlider,'value'));
            %Update label
            set(cData.textbox,'String',int2str(sliderVal));
            
            %Update image
            setImage(cData)
            
            %Update plot
            timepoint=floor(get(cData.timepointSlider,'value'));
            
            set(cData.plotVMarker,'Xdata',[timepoint timepoint]);
        end %sliderChanged
        
        
        function mouseClick(hObject,event,cData)
            pos=get(hObject,'currentpoint');
            h=get(hObject,'parent');
            select=get(h,'selectiontype');
            pos=pos(1,1:2);%Returns two sets of identical co-ordinate. Presumably one is for image, and one for axes
            sliderVal=floor(get(cData.timepointSlider,'value'));
            disp(pos)
            nearestCell=cData.cTimelapse.ReturnNearestCellCentre(sliderVal,1,pos);                                                
            nearestCell=cData.cTimelapse.cTimepoint(sliderVal).trapInfo.cellLabel(nearestCell);
            disp(nearestCell)
            %make sure the cell selected has data
            if find(cData.cellsWithData==nearestCell)
                if strcmpi(select,'normal')
                    cData.cellsToPlot(1,nearestCell)=1;
                elseif strcmpi(select,'alt')
                    cData.cellsToPlot(1,nearestCell)=0;
                    cData.trackingColors(nearestCell,1:3)=0;
                end
            else
                disp('No data for cell');
            end
            setImage(cData);
            updatePlot(cData);
        end
        
        function printCAData( cData )
            %This is a lazy function so no comments for you
            [~, labels]=find(cData.cellsToPlot);
            extractedData=[];
           for  i=1:length(labels)               
               intensity=cData.cTimelapse.extractedData(1).max5(labels(i),:)./cData.cTimelapse.extractedData(1).median(labels(i),:);
               extractedData=[extractedData;labels(i),intensity];
           end
           [filename,pathname]=uiputfile('extractedData.xls');
           xlswrite([pathname filename], extractedData);
        end
        
        function printSingle(cData)
            channelVal=get(cData.channelSelect,'Value');
            identifier=[cData.cTimelapse.cTimepoint(1).filename{channelVal}(end-21:end-20)  '.tif']
            [filename,pathname]=uiputfile(identifier);
            
            printFigure=figure('visible','off');
            printImage=imshow(cData.currentImage,[]);
            saveas(printFigure,[pathname filename],'tif');
            close(printFigure);
        end
        
        function printImages(cData)
            channelVal=get(cData.channelSelect,'Value');
            outImages=[cData.cTimelapse.timelapseDir filesep cData.cTimelapse.cTimepoint(1).filename{channelVal}(1:end-8)];
            mkdir(outImages);
            printFigure=figure('visible','off');
            printImage=imshow(cData.currentImage,[]);
            for i=1:length(cData.cTimelapse.cTimepoint)
                set(cData.timepointSlider,'value',i);
                set(printImage,'cData',cData.currentImage);
                saveas(printFigure,[outImages filesep 'timepoint_' int2str(i)],'tif'); 
                
            end
            clf(printFigure);
            copyobj(cData.plotAxes,printFigure);
            saveas(printFigure,[outImages filesep 'plot'],'tif');
            close(printFigure);
        end
        
        
            

        
        
%         function clearButtonPress(src,event,cData)
%             cData.cellsToPlot=sparse(zeros(100,100));
%             setImage(cData)
%             up
%         end
        %%Other methods
        setImage(cData)
        updatePlot(cData)
        cellAsic_ScrollWheel(GUI,src,event)
    end %methods
    
end %class

