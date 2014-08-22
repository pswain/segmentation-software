
thingToPut={1;2;3;4;5;'=sum(A1:A5)'}
[filename, path]=uiputfile('allData.xls');
xlswrite([path filename],thingToPut)
