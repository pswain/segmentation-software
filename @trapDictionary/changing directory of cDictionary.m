for i=1:length(cDictionary.cTimepoint)
    for j=1:2
    try
        files=cDictionary.cTimepoint(i).filename{j}
    
searchResult=regexp(files,'TimelapseImages/','end');

newName=[files(1:searchResult) '2012/' files(searchResult+1:end)];
cDictionary.cTimepoint(i).filename{j}=newName;
    catch
    end
    end
end
