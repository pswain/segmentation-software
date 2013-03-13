%% Example for the trapDictionary class

cDictionary=trapDictionary
cDictionary.addAllTrapsLabelSecondary(cTimelapse);
%%
cDictionary.addAllTraps(cTimelapse);

%display images and make the user label them
trap_num_to_label=1
cDictionary.labelTrap(trap_num_to_label);


% cDictionary.labelAllTrapsContinue();
%%
trap_num_to_label=4
cDictionary.labelTrap(trap_num_to_label);

