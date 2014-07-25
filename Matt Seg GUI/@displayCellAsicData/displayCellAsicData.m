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
    %                     Cell labels initially allocated when cells are
    %                     selected. Only cells in this original will have
    %                     data extracted. Position corresponds to the label
    %                     of these cells.
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
    %                     don't have data will cause a crash(again), so take care.
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
        cellsToPlot=[] %For automatic detection of whi5 cells
        cellsWithData=[]
        
        individualCellFigure=[]
        contourAxes=[]
        
        filepath=[]
        highlightedCell=[]
        keypoint=[] %Integer 
        upslopes=[] %Sparse cellNum x timepointNum logical. 1 where fluorescense begins
        downslopes=[] %As upslopes, but where fluorescense stops
        
        regionsOfInterest=[]%Struct for saving. 
        
        
    end
    
    methods
        function cData=displayCellAsicData(cTimelapse,cellsToPlot,filepath)
            %Class constructor: sets up the various plots, fetches the
            %images, plots the graphs, and sets up the GUI elements
            %2 Figures are used, on for the main image and GUI and one for
            %the plot.
            
            
            if cTimelapse.trapsPresent
                msgbox('This function will not work if traps are present');
                return
            end
            cData.cTimelapse=cTimelapse;
            if nargin>1 || ~isempty(cellsToPlot)
                cData.cellsToPlot = cellsToPlot;
            else
                cData.cellsToPlot=cData.cTimelapse.cellsToPlot;
            end
           
            if nargin>2
                filepath=[filepath '.mat'];
                cData.filepath=filepath;
            else
                filepath=[];
            end
                         
            [~, cData.cellsWithData]=find(cData.cTimelapse.cellsToPlot);
            numTime=length(cData.cTimelapse.cTimepoint);
            numCell=length(find(cData.cTimelapse.cellsToPlot(1,:)));
            if ~exist(filepath)
                cData.upslopes=sparse(numCell,numTime);
                cData.downslopes=sparse(numCell,numTime);
            else
                loadData(cData,filepath);
            end
            
            cData.regionsOfInterest=struct('upslopes',[],'downslopes',[],'keypoint',[],'extractedData',[],'cellLabels',[]);
            
            %Set up image
            set(0,'units','normalized');
         
            cData.imageFigure=figure('units','normalized','position',[0.1,0.25,0.4,0.4]);
            cData.subImage=subplot(1,1,1);
            
            rawImage=imread([cData.cTimelapse.timelapseDir filesep cData.cTimelapse.cTimepoint(1).filename{2}]);
            rawImage=double(rawImage)/double(max(rawImage(:)));
            cData.currentImage=cat(3,rawImage,rawImage,rawImage);
            
            
            [~, b]=find(cData.cellsToPlot);
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
            set(cData.subImage,'xtick',[]);
            set(cData.subImage,'ytick',[]);
            
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
            markSingleUp=uicontrol('style','pushbutton',...
                'string','Mark Upslope',...
                'units','normalized',...
                'position',[0.1,0.003,0.15,0.04],...
                'parent',cData.plotFigure,...
                'callback',@(src,event)markUpslope(cData));
            markSingleDown=uicontrol('style','pushbutton',...
                'string','Mark Downslope',...
                'units','normalized',...
                'position',[0.27,0.003,0.15,0.04],...
                'parent',cData.plotFigure,...
                'callback',@(src,event)markDownslope(cData));
%             clearMarks=uicontrol('style','pushbutton',...
%                 'string','Clear all',...
%                 'units','normalized',...
%                 'position',[0.34,0.003,0.15,0.04],...
%                 'parent',cData.plotFigure,...
%                 'callback',@(src,event)clearAllMarks(cData));
            keyPoint=uicontrol('style','pushbutton',...
                'string','Mark key point',...
                'units','normalized',...
                'position',[0.51,0.003,0.15,0.04],...
                'parent',cData.plotFigure,...
                'callback',@(src,event)markKeyPoint(cData));
            viewCell=uicontrol('style','pushbutton',...
                'string','ViewCellData',...
                'units','normalized',...
                'position',[0.68,0.003,0.15,0.04],...
                'parent',cData.plotFigure,...
                'callback',@(src,event)getPixels(cData));
            
            cData.slideListener=addlistener(cData.timepointSlider,'Value','PostSet',@(src,event)sliderChanged(cData));
            
            cData.channelListener=addlistener(cData.channelSelect,'Value','PostSet',@(src,event)setImage(cData));
            %Buttondownfcn listener
            set(cData.subImage,'buttondownfcn',{@mouseClick,cData},'hittest','on','visible','on');
            set(cData.imageFigure,'WindowScrollWheelFcn',@(src,event)cellAsic_ScrollWheel_cb(cData,src,event));
            set(cData.plotFigure,'WindowScrollWheelFcn',@(src,event)cellAsic_ScrollWheel_cb(cData,src,event));

        end
        %%
        function sliderChanged(cData)

            sliderVal=floor(get(cData.timepointSlider,'value'));
            set(cData.textbox,'String',int2str(sliderVal));
            
            setImage(cData)
            
            try
                [~]=get(cData.individualCellFigure);
            catch
                cData.individualCellFigure=[];
            end
            
            if ~isempty(cData.individualCellFigure)
                getPixels(cData);
            end
                
            
            timepoint=floor(get(cData.timepointSlider,'value'));
            set(cData.plotVMarker,'Xdata',[timepoint timepoint]);
        end %sliderChanged
        
        
        function mouseClick(hObject,event,cData)
           selectCell(hObject,cData);
            setImage(cData);
            updatePlot(cData);
        end
        
                
        function saveData(cData,filename)
            if nargin <2
                [filename pathname]=uigetfile;
                filename=[pathname filename];
            end
            cData.regionsOfInterest.upslopes=cData.upslopes;
            cData.regionsOfInterest.downslopes=cData.downslopes;
            cData.regionsOfInterest.keypoint=cData.keypoint;
            %Needed for data analysis
            cData.regionsOfInterest.extractedData=cData.cTimelapse.extractedData;
            [~, cellLabels]=find(cData.cTimelapse.cellsToPlot);%We really dont need the full matrix for anything here
            cData.regionsOfInterest.cellLabels=cellLabels;
            savefile=cData.regionsOfInterest;
            save(filename,'savefile');
        end
        
        function loadData(cData,filename)
            if nargin <2
                [filename pathname]=uigetfile('data.mat');
                filename=[pathname filename];
            end
            load(filename,'savefile');
            cData.upslopes=savefile.upslopes;
            cData.downslopes=savefile.downslopes;
            cData.keypoint=savefile.keypoint;
        end
        function markKeyPoint(cData)
            timepoint=get(cData.timepointSlider,'value');
            if cData.keypoint==timepoint
                cData.keypoint=[];
            else
                cData.keypoint=timepoint;
            end
            updatePlot(cData);
            saveData(cData, cData.filepath)

        end
        function clearAllMarks(cData)
            numTime=length(cData.cTimelapse.cTimepoint);
            numCell=length(find(cData.cTimelapse.cellsToPlot(1,:)));  
            
            cData.upslopes=sparse(numCell,numTime);
            cData.downslopes=sparse(numCell,numTime);
        end
        
        
        function printCAData( cData )
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
        
        
        
        
        %%Other methods
        setImage(cData)
        updatePlot(cData)
        cellAsic_ScrollWheel(GUI,src,event)
        getNearestPlotLine(src,event)
        selectCell(hObject,cData)
        markUpslope(cData)
        markDownslope(cData)
        getPixels(src,event,cData)
    end %methods
    
end %class

