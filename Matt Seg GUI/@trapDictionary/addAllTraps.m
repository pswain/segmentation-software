function addAllTraps(cDictionary,cTimelapse)

traps_in_dictionary=length(cDictionary.cTrap);

for i=1:length(cTimelapse.cTrapsLabelled)
    cDictionary.cTrap(traps_in_dictionary+1).image=cTimelapse.returnSingleTrapTimelapse(i,'primary');
    traps_in_dictionary=traps_in_dictionary+1;
end