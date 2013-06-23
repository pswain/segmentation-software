function autoSelect(cExpGUI)

posVals=get(cExpGUI.posList,'Value');

params.fraction=.8; %fraction of timelapse length that cells must be present or
params.duration=3e3; %number of frames cells must be present
params.framesToCheck=100;

num_lines=1;
prompt = {'Fraction of whole timelapse a cell must be present'};
dlg_title = 'Fraction of Timelapse';    def = {num2str(params.fraction)};
answer = inputdlg(prompt,dlg_title,num_lines,def);
params.fraction=str2double(answer{1});

prompt = {'OR - number of frames a cell must be present'};
dlg_title = 'Duration';    def = {num2str(params.duration)};
answer = inputdlg(prompt,dlg_title,num_lines,def);
params.duration=str2double(answer{1});

prompt = {'Cell must appear in the first X frames'};
dlg_title = 'Frames To Check';    def = {num2str(params.framesToCheck)};
answer = inputdlg(prompt,dlg_title,num_lines,def);
params.framesToCheck=str2double(answer{1});



cExpGUI.cExperiment.selectCellsToPlotAutomatic(posVals,params);
