classdef FindMaxima<extractdata.ExtractData
    methods
        function obj=FindMaxima(varargin)
            obj.parameters = struct;
            obj.parameters.sourcedata='GFPSimpleSpotFind';
            obj.paramChoices.sourcedata='Data';%The choices will be the data fields of the timelapse object.
            obj.parameters.sections=1;%integer, number of sections at each timepoint that contain obj.parameters.chidentifier in their filename
            obj.parameters.measuredsections=[1];%integer vector, the sections to use as the source of the data
            obj.parameters.interval=5;%Time interval between images in this channel (in min)
            obj.parameters.mininterval=60;%Minimum interval between found maxima - eg to find cell cycle lengths this should be just below the minimum expected cell cycle length
            
            obj.description='FindMaxima method: Finds timepoints at which there are peaks in data extracted from a timelapse. Can be used, eg to identify cell cycle lengths for markers that show periodic expression.';           
                        
            
            obj=obj.changeparams(varargin{:});
            %The datafield is the name of the field in timelapse.Data that
            %the results will be stored in. It is defined after the call to
            %changeparams because it depends on one of the object
            %parameters.
            obj.datafield=[obj.parameters.sourcedata 'Maxima'];

        end
    
        function timelapseObj=run(obj, timelapseObj)
            % run --- records FindMaxima result for each cell in timelapseObj.Data
            %
            % Synopsis:  timelapseObj = run (obj, timelapseObj)
            %
            % Input:     obj = an object of class FindMaxima
            %            timelapseObj = an object of a timelapse class
            %
            % Output:    timelapseObj = an object of a timelapse class

            % Notes:    Adds to the Data property of timelapseObj.
            
            highest=timelapseObj.gethighest;
            obj.datafield=[obj.parameters.sourcedata 'FindMaxima'];%In case the parameter sourcedata has changed since the constructor was run
            %Write to stored version of this method object
            timelapseObj=setMethodObjField(timelapseObj, obj.ObjectNumber, 'datafield', obj.datafield);
    
            %Create result array            
            timelapseObj.Data.(obj.datafield)=zeros(timelapseObj.TimePoints,highest);             

            %Loop through the cells
            for c=1:highest
                %Update the progress bar
                obj.showProgress(100*c/highest,['Running FindMaxima. Cell number:' num2str(c)])
                
                %get the 1d data set
                data=timelapseObj.Data.(obj.parameters.sourcedata)(c,:);
                %Smooth the data then calculate first derivative/difference
                data=smooth(data);
                diffs=diff(data);
                %This will have reduced the size by 1 time point - insert a
                %zero value to correct for this
                diffs=[0 diffs'];
                %Find the peaks in the difference data - points at which
                %the values go up more than they went up between the two
                %previous timepoints (or the next two).
                [pks pktimes]=findpeaks(diffs);
                %Now need to process the results to remove unwanted peaks.
                %First remove any negative or zero valued peaks
                neg=pks<=0;
                pks(neg)=[];pktimes(neg)=[];
                %Then remove any that are less than the minimum distance
                %apart in time.
                %Minimum time interval in time points
                mintps=obj.parameters.mininterval/obj.parameters.interval;
                done=false;
                while done==false;
                    %Calculate the time intervals between adjacent remaining peaks
                    difftimes=diff(pktimes);
                    difftimes=[0 difftimes];
                    %Find peaks that give time intervals below the
                    %threshold
                    tooshort=difftimes<mintps;
                    
                    %tooshort is logical index to the 2nd peak in a pair
                    %with too short an interval. Looking only at the first 
                    %too short pair, delete the one with the lowest
                    %difference in values of pks - ie the smallest
                    %jump in the data from the previous timepoint
                    if any(tooshort)
                        tooshort=find(tooshort(2));%(tooshort(1) is always 1 regardless of the data - difftimes(1)==0) - so tooshort(2) is the first real value
                        value1=pks(tooshort(2)-1);
                        value2=pks(tooshort(2));
                        if value1>=value2
                            pks(tooshort(2))=[];pktimes(tooshort(2))=[];
                        else
                            pks(tooshort(2)-1)=[];pktimes(tooshort(2)-1)=[];
                        end                       
                    else
                        done=true;
                    end
                end
                %Record the result for this cell - list of timepoints at
                %which there is a peak
                timelapseObj.Data.(obj.datafield)(c,1:length(pktimes))=pktimes;
                timelapseObj.Data.(obj.datafield)(c,(timelapseObj.Data.(obj.datafield)(c,:)==0))=[];
            end                
            obj.showProgress(0,'')
        end

    end
end