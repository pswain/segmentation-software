temp=collectData(exp.currentGUI);
if isempty(temp)
    numFrames=length(exp.currentGUI.cTimelapse.extractedData(1).median(1,:));
    temp=zeros(1,numFrames+1);
end
allData=[allData;-ones(1,length(temp(1,:)));temp];