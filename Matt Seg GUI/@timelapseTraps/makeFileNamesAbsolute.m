function makeFileNamesAbsolute(cTimelapse)

if ~strcmp(cTimelapse.timelapseDir,'ignore')
    
    for ti = 1:length(cTimelapse.cTimepoint)
        for ci = 1:length(cTimelapse.cTimepoint(ti).filename)
        
            cTimelapse.cTimepoint(ti).filename{ci} = fullfile(cTimelapse.timelapseDir,cTimelapse.cTimepoint(ti).filename{ci});
        
        end
    end
    
    cTimelapse.timelapseDir = 'ignore';
    
end


end