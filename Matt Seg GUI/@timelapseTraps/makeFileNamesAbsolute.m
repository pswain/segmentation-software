function makeFileNamesAbsolute(cTimelapse)
%

if ~strcmp(cTimelapse.timelapseDir,'ignore') && ~isempty(cTimelapse.timelapseDir)
    
    for ti = 1:length(cTimelapse.cTimepoint)
        for ci = 1:length(cTimelapse.cTimepoint(ti).filename)
            
            filename = cTimelapse.cTimepoint(ti).filename{ci};
            loc = max([strfind(filename,'\') strfind(filename,'/') ],[],2);
            if isempty(loc)
                loc = 0;
            end
            filename = filename((loc+1):end);
            
            cTimelapse.cTimepoint(ti).filename{ci} = fullfile(cTimelapse.timelapseDir,filename);
        
        end
    end
    
    cTimelapse.timelapseDir = 'ignore';
    
end


end