function savefile=autoselect(savefile)
%Defining a peak
%   If everything in both directions is less
%   If max is above a certain variance of background
%Defining a background
%   For array, subtract each element of array from first. Smallest abs
%   number is the background
data=savefile.extractedData;
intensity=full((data(2).max5)./(data(2).median));
tpToCheck=5;
background=[];
cellNum=[];
allAvg=[];

upslopes = zeros(size(intensity));
downslopes = zeros(size(intensity));
%% Finding up and downslopes

for cellNum=1:length(intensity(:,1))
    
    map=zeros(1,length(intensity(1,1:end-5)));
    for i =1:length(intensity(cellNum,1:end-5))
        for j=1:5
            temp=abs(intensity(cellNum,i)-intensity(cellNum,i+j));
            map(1,i)=map(i)+temp;
            
        end
    end
    
    posMin=find(map==min(map),1,'first');
    background=mean(intensity(cellNum,posMin:(posMin+5)));
    stDev=std(intensity(cellNum,posMin:(posMin+5)));
    allAvg=[allAvg,background];
    threshold=background+5*stDev;
    
    allDownslope=[];
    allUpslope=[];
    posMax=[];
    
    
    for i =1:length(intensity(cellNum,:))
        upslope=[];
        downslope=[];
        if i-tpToCheck<1
            if ~any(intensity(cellNum,1:i+tpToCheck)>intensity(cellNum,i)) && intensity(cellNum,i)>threshold
                posMax=[posMax i];
                
                downslope=find(intensity(cellNum,i+1:end)<threshold,1,'first');
                if ~isempty(downslope)
                    downslopes(cellNum, downslope+i)=1;
                end
                
                upslope=find(intensity(cellNum,1:i)<threshold,1,'last');
                if ~isempty(upslope)
                    upslopes(cellNum, upslope+1)=1;
                end
            end
        elseif i+tpToCheck>length(intensity(cellNum,:))
            if ~any(intensity(cellNum,i-tpToCheck:end)>intensity(cellNum,i)) && intensity(cellNum,i)>threshold
                posMax=[posMax i];
                downslope=find(intensity(cellNum,i+1:end)<threshold,1,'first');
                if ~isempty(downslope)
                    downslopes(cellNum, downslope+i)=1;
                end
                
                upslope=find(intensity(cellNum,1:i)<threshold,1,'last');
                if ~isempty(upslope)
                    upslopes(cellNum, upslope+1)=1;
                end
            end
        else
            if ~any(intensity(cellNum,i-tpToCheck:i+tpToCheck)>intensity(cellNum,i)) && intensity(cellNum,i)>threshold
                posMax=[posMax i];
                downslope=find(intensity(cellNum,i+1:end)<threshold,1,'first');
                if ~isempty(downslope)
                    downslopes(cellNum, downslope+i)=1;
                end
                
                upslope=find(intensity(cellNum,1:i)<threshold,1,'last');
                if ~isempty(upslope)
                    upslopes(cellNum, upslope+1)=1;
                end
            end
        end
    end
    
end
savefile.upslopes=upslopes;
savefile.downslopes=downslopes;


end