classdef RunCellSegMethods<MethodsSuperClass
    properties
        resultImage='Result';
    end
    methods
        function obj=RunCellSegMethods(varargin)
            % RunCellSegMethods --- constructor for RunCellSegMethods class
            %                    
            % Synopsis:           RunCellSegMethods(timelapse,varargin)
            %
            % Input:              Timelapse = an object of a Timelapse class
            %                     varargin = place in which parameters can be specified
            %                     in the conventional matlab way.
            %
            % Output:             obj = an object of class RunCellSegMethods
            
            %Create obj.parameters structure and define default parameter values                       
            obj.parameters=struct;
            obj.parameters.cellsegmethods={'Segmethod_1';'Segmethod_2';'Segmethod_3';'Segmethod_4';'Segmethod_5';'Segmethod_7';'Segmethod_6'};%Default list of cell segmentation methods. NOTE: If a parameter defines use of another class then it should also be written to obj.Classes, after the call to changeparams.
            obj.parameters.minpixels=200;
            obj.parameters.maxpixels=2000;
            
            %There are no required fields or images for this class

            %Define user information
            obj.description='OneCell object. Holds the data relating to segmentation of a single cell. The parameter ''cellsegmethods'' specifies a list of methods, each of which will be tried in turn to segment this cell.';
            obj.paramHelp.cellsegmethods = 'Parameter ''cellsegmethods'': A list of methods in the cellsegmethods class. These will be run in the order listed until one of them gives a successful result.';
            obj.paramHelp.minpixels = 'Parameter ''minpixels'': The minimum size of a result in pixels that will be considered a successful cell segmentation. Objects smaller than this will be rejected.';
            obj.paramHelp.maxpixels = 'Parameter ''maxpixels'': The maximum size of a result in pixels that will be considered a successful cell segmentation. Objects larget than this will be rejected.';
            
            %Call changeparams to redefine parameters if there are input arguments to this constructor              
            obj=obj.changeparams(varargin{:});
            
            %List the method and level classes that this method will use
            obj.Classes.classnames=obj.parameters.cellsegmethods;
            obj.Classes.packagenames='cellsegmethods';
            
        end
        function oneCellObj=run(obj, oneCellObj, regionObj, history)
            % run --- tries the range of available methods to find interior pixels of a single cell
            %
            % Synopsis:  oneCellObj = run(obj, oneCellObj,regionObj)
            %                        
            % Input:     obj = an object of class RunCellSegMethods
            %            oneCellobj = an object of a OneCell class
            %            regionObj = an object of a region class
            %               
            %
            % Output:    oneCellobj = an object of a OneCell class

            % Notes:     Populates the oneCellObj.Result and
            %            oneCellObj.Success and oneCellObj.Method fields. 
            %            Also populates all other fields necessary for the 
            %            segmentation methods used (eg edge detected
            %            images). Methods and the order in which they are
            %            used are specified before calling this function in
            %            the timelapseObj.SpecifiedParameters field. These
            %            methods are encoded in subclasses of the
            %            Segmethods superclass.
            oneCellObj.Success=0;
            n=1;
            fieldHistories=struct('histories',{});
          
            while oneCellObj.Success~=1 && n<=length(obj.parameters.cellsegmethods)
            
                if isfield(obj.Classes,'objectnumbers')
                   method=oneCellObj.Timelapse.methodFromNumber (obj.Classes.objectnumbers);
                else
                    method=oneCellObj.Timelapse.getobj('cellsegmethods',char(obj.parameters.cellsegmethods(n)));    
                   %Record that this runmethod object calls this class
                   obj.Classes.objectnumbers(n)=method.ObjectNumber;
                end            
                
                [oneCellObj fieldHistory]=method.initializeFields(oneCellObj);%populate the required fields of the OneCell object
                if ~isempty(fieldHistory)
                    fieldHistories(n).method=fieldHistory;                   
                end
                if any (ismember(method.requiredFields, 'Region'))
                    oneCellObj=method.run(oneCellObj,regionObj);
                else
                    oneCellObj=method.run(oneCellObj); 
                end        
                [oneCellObj.Success centroid]=oneCellObj.Timelapse.ObjectStruct.cellsegmethods.(char(obj.parameters.cellsegmethods(n))).testSuccess(oneCellObj.Result,obj.parameters.minpixels,obj.parameters.maxpixels);
                oneCellObj.CentroidX=centroid(1);oneCellObj.CentroidY=centroid(2);
                n=n+1;
            end
             %Save a version of this object without images in the
             %Timelapse.LevelObjects structure
             oneCellObj.SegMethod=method;
             %Timelapse.LevelObjects structure
             oneCellObj.Timelapse.saveLevelObject(oneCellObj);
             if oneCellObj.Success==1
                 %If segmentation has succeded, record segmentation method, etc.
                 %Write the result to Timelapse.Result
                 %Increment CurrentCell
                 oneCellObj.Timelapse.TrackingData(oneCellObj.Timelapse.CurrentFrame).cells(oneCellObj.Timelapse.CurrentCell).cellnumber=0;%not tracked yet so cellnumber is zero
                 oneCellObj.Timelapse.TrackingData(oneCellObj.Timelapse.CurrentFrame).cells(oneCellObj.Timelapse.CurrentCell).trackingnumber=oneCellObj.Timelapse.CurrentCell;
                 oneCellObj.Timelapse.LevelObjects.TrackingNumber(oneCellObj.Timelapse.NumLevelObjects)=oneCellObj.Timelapse.CurrentCell;
                 
                 oneCellObj.TrackingNumber=oneCellObj.Timelapse.CurrentCell;
                 %Add this (run) method to the history
                 oneCellObj.Timelapse.HistorySize=oneCellObj.Timelapse.HistorySize+1;
                 history.methodobj(oneCellObj.Timelapse.HistorySize)=obj.ObjectNumber;
                 history.levelobj(oneCellObj.Timelapse.HistorySize)=oneCellObj.ObjectNumber;
                 %Add the successful segmentation method to the history
                 oneCellObj.Timelapse.HistorySize=oneCellObj.Timelapse.HistorySize+1;
                 history.methodobj(oneCellObj.Timelapse.HistorySize)=oneCellObj.SegMethod.ObjectNumber;

                 %Need to add any of the method class objects used to
                 %make any of the required fields of this object - even if
                 %they were actually used while other method classes were
                 %being tested.
                 if size(fieldHistories,1)>0
                     fieldHistory=method.redefineFieldHistory(fieldHistories);
                     if ~isempty(fieldHistory)
                         [history oneCellObj]=insertFieldHistory(history, fieldHistory, fieldIndex, levelObj);
                         history=method.insertFieldHistory(history, fieldHistory);
                     end
                 end
                 history.levelobj(oneCellObj.Timelapse.HistorySize)=oneCellObj.ObjectNumber;
                 %Delete subsequent (preallocated) entries in the history - cell
                 %segmentation is complete
                 history.levelobj(oneCellObj.Timelapse.HistorySize+1:end)=[];
                 history.methodobj(oneCellObj.Timelapse.HistorySize+1:end)=[];               


           
%                %write the modified method object back to the stored version               
%                             
%                 
%                 
%                 
%                 
                 %Now record the TrackingData entry for this cell in the
                 %timelapse
                 oneCellObj.Timelapse.TrackingData(oneCellObj.Timelapse.CurrentFrame).cells(oneCellObj.Timelapse.CurrentCell).methodobj = [history.methodobj];%Record this here because segmentation has worked with this history
                 oneCellObj.Timelapse.TrackingData(oneCellObj.Timelapse.CurrentFrame).cells(oneCellObj.Timelapse.CurrentCell).levelobj = [history.levelobj];
                 oneCellObj.Timelapse.TrackingData(oneCellObj.Timelapse.CurrentFrame).cells(oneCellObj.Timelapse.CurrentCell).centroidx=centroid(1)+regionObj.TopLeftx;
                 oneCellObj.Timelapse.TrackingData(oneCellObj.Timelapse.CurrentFrame).cells(oneCellObj.Timelapse.CurrentCell).centroidy=centroid(2)+regionObj.TopLefty;
                 oneCellObj.Timelapse.TrackingData(oneCellObj.Timelapse.CurrentFrame).cells(oneCellObj.Timelapse.CurrentCell).region=[regionObj.TopLeftx regionObj.TopLefty regionObj.xLength regionObj.yLength];
                 oneCellObj.Timelapse.TrackingData(oneCellObj.Timelapse.CurrentFrame).cells(oneCellObj.Timelapse.CurrentCell).segobject=oneCellObj.ObjectNumber;%The object whose segmentation method has performed this segmentation

%                 
                 
                 
                 oneCellObj.FullSizeResult=false(oneCellObj.Timelapse.ImageSize(2), oneCellObj.Timelapse.ImageSize(1));
                 oneCellObj.FullSizeResult(regionObj.TopLefty:regionObj.TopLefty+regionObj.yLength-1,(regionObj.TopLeftx:regionObj.TopLeftx+regionObj.xLength-1))=oneCellObj.Result;
                 %Timelapse.Result dimensions are (y,x,trackingnumber,frame)
                 oneCellObj.Timelapse.Result(oneCellObj.Timelapse.CurrentFrame).timepoints(oneCellObj.Timelapse.CurrentCell).slices=sparse(oneCellObj.FullSizeResult);            
                 oneCellObj.Timelapse.CurrentCell=oneCellObj.Timelapse.CurrentCell+1;
                 %Record that this cell belongs to a given region
                 regionObj.TrackingNumbers(size(regionObj.TrackingNumbers,2)+1)=oneCellObj.Timelapse.CurrentCell;
             end

            end
     end
    
    
    
end