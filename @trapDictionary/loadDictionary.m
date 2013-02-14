function loadDictionary(cDictionary)

[filename pathname]=uigetfile('*.mat','Select the dictionary of labelled cell/trap images you want to load');

cDictionary=load(fullfile(pathname,filename));
