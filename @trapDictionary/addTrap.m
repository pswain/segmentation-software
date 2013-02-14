function addTrap(cDictionary,cTimelapse,trap_num_to_add)

traps_in_dictionary=length(cDictionary.cTrap);
cDictionary.cTrap(traps_in_dictionary+1).image=cTimelapse.returnSingleTrapTimelapse(trap_num_to_add);