classdef GetFrequency<extractdata.ExtractData
    methods
        function obj=GetFrequency(varargin)
            obj.parameters = struct;
            obj.parameters.sourcedata='GFPSimpleSpotFind';
            obj.paramChoices.sourcedata='Data';%The choices will be the data fields of the timelapse object.
            obj.parameters.sections=1;%integer, number of sections at each timepoint that contain obj.parameters.chidentifier in their filename
            obj.parameters.measuredsections=[1];%integer vector, the sections to use as the source of the data
            obj.parameters.interval=5;%Time interval between images in this channel (in min)
            obj.parameters.window=100;
            obj.parameters.overlap=75;
            obj.parameters.nfft=200;
            obj.parameters.minconsec=100;%Minimum number of consecutive timepoints to be considered
            
            obj.description='GetFrequency method: Identifies the frequency of a periodic signal in the results output by another extractdata method. Uses the Fast Fourier Transform, Welch method: Harris, F. J. "On the Use of Windows for Harmonic Analysis with the Discrete Fourier Transform." Proceedings of the IEEE®. Vol. 66 (January 1978). ';
            
            obj.plottype='Histogram';
            
            
            obj=obj.changeparams(varargin{:});
            %The datafield is the name of the field in timelapse.Data that
            %the results will be stored in. It is defined after the call to
            %changeparams because it depends on one of the object
            %parameters.
            obj.datafield=[obj.parameters.sourcedata 'Frequency'];

        end
    
        function timelapseObj=run(obj, timelapseObj)
            % run --- records GetFrequency result for each cell in timelapseObj.Data
            %
            % Synopsis:  timelapseObj = run (obj, timelapseObj)
            %
            % Input:     obj = an object of class GetFrequency
            %            timelapseObj = an object of a timelapse class
            %
            % Output:    timelapseObj = an object of a timelapse class

            % Notes:    Adds to the Data property of timelapseObj.
            
            highest=timelapseObj.gethighest;
            obj.datafield=[obj.parameters.sourcedata 'Frequency'];%In case the parameter sourcedata has changed since the constructor was run
            %Write to stored version of this method object
            timelapseObj=setMethodObjField(timelapseObj, obj.ObjectNumber, 'datafield', obj.datafield);
    
            %Create 1d result array            
            timelapseObj.Data.(obj.datafield)=zeros(1,highest);             

            %Loop through the cells
            for c=1:highest
                %Update the progress bar
                obj.showProgress(100*c/highest,['Running GetFrequency. Cell number:' num2str(c)])
                
                %get the 1d data set + correct
                data=timelapseObj.Data.(obj.parameters.sourcedata)(c,:);
                %Calculate the longest run of non zero entries
                nonzero=data>0;
                dataDiff=diff(nonzero);
                pos=dataDiff==1;
                neg=dataDiff==-1;
                runStarts=find(pos);%The +1 entries in dataDiff are the starts of runs of consecutive nonzero entries
                runEnds=find(neg);%-1 entries are starts of runs of zeros.
                %Correct to make both vectors the same size
                if data(1)>0
                    runStarts=[1 runStarts];%add a 1 to the start of the vector
                end
                if data(end)>0
                    if ~isempty(runEnds)
                        runEnds(length(runEnds)+1)=length(data);
                    else
                        runEnds=length(data);
                    end
                end
                %Now have matching start and end points of nonzero runs
                try
                [runLength longest]=max(runEnds-runStarts);
                catch
                    disp('debug in getfrequency');
                end
                %Run the welch algorithm on the longest run if it's long enough
                if runLength>=obj.parameters.minconsec
                    data=data(runStarts(longest):runEnds(longest));
                    data=smooth(data);
                    %Subtract a moving average of the data (period 10)
                    l=length(data);
                    data2=zeros(l,1);
                    for n=1:l
                        if n<=l-10
                            movMean=mean(data(n:n+10));
                        else
                            movMean=mean(data(l-10:l));
                        end
                        data2(n)=data(n)-movMean;                        
                    end
                    data=data2;
                    
                    
                    
                    %Run the Welch algorithm
                    Fs=1/(obj.parameters.interval*60);%Fs=sampling frequency in Hz
                    %pxx=power spectrum
                    %f=frequencies
                    [pxx f] = pwelch(data,obj.parameters.window,obj.parameters.overlap,obj.parameters.nfft,Fs);
                    [maximum index]=max(pxx);
                    resultHz=f(index);%the frequency of the highest peak in Hz
                    resultS=1/resultHz;%Interval in s
                    resultMin=resultS/60;
                    timelapseObj.Data.(obj.datafield)(c)=resultMin;
                    if resultMin==200
                    disp('stop here');
                    end
                    
                else 
                    timelapseObj.Data.(obj.datafield)(c)=nan;
                end
            end
                
                
                
                
                
                
                
                
            obj.showProgress(0,'')
        end

    end
end