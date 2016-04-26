function extractParameters = guiSetExtractParameters( cExperiment,extractParameters )
%extractParameters = guiSetExtractParameters( cExperiment,extractParameters )
%
% a place for all the random GUI interfaces that have accumulated around
% extractParameters. If you want some sort of dialog box for your
% parameters extraciton method, put it here in the switch/case function
%
% cExperiment           :   object of the experimentTracking class
% extractParameters     :   parameters structure of the form:
%                           extractFunction   : function handle for function usedin extraction
%                           extractParameters : structure of parameters taken by that function
%
%
if nargin<2 || isempty(extractParameters)
    
    extractParameters = timelapseTraps.defaultExtractParameters;
end

if isequal(extractParameters.extractFunction,@extractCellDataStandard)
    functionParameters = extractParameters.functionParameters;
    
    list = {'max','mean','std','sum','basic'};
    dlg_title = 'What to extract?';
    prompt = {['All Params using max projection (max), std (std), mean (mean) or sum (sum) of stacks; or basic (basic)' ...
        ' the basic measure only compiles the x, y locations of cells along with the estimated radius so it is much faster, but less informative.'],'','',''};
    answer = listdlg('PromptString',prompt,'Name',dlg_title,'ListString',list,'SelectionMode','single',...
        'ListSize',[300 100]);
    
    type=list{answer};
    switch type
        case {'max','std','mean','sum'}
            functionParameters.type = type;
        case {'basic'}
            extractParameters.extractFunction = @extractCellParamsOnly;
            functionParameters = [];
    end
    
    if ~strcmp(type,'basic')
        
        % Ivan's set channel stuff
    if ~isempty(cExperiment.OmeroDatabase)
        channel_list = cExperiment.OmeroDatabase.Channels;
    else
        cTimelapse = cExperiment.loadCurrentTimelapse(1);
        channel_list = cTimelapse.channelNames;
    end
    %temp fix
    if isempty(channel_list);
        channel_list={'DIC','GFP','pHluorin405'};
    end
        dlg_title = 'Which channels to extract?';
        prompt = {['please select the channels for which you would like to extract data'],'',''};
        answer = listdlg('PromptString',prompt,'Name',dlg_title,'ListString',channel_list,'SelectionMode','multiple',...
        'ListSize',[300 100]);
        functionParameters.channels = answer;
        
        settings_dlg_struct = struct(...
        'title', 'nuclear label?',...
        'Description','If one of the channels is a nuclear label, please specify it here. This must be on of your extraction channels. If you have no particular marker please select '' not applicable '' ',...
        'forgotten_field_1',struct('entry_name',{{'nuclear tag field','nuclearChannel'}},'entry_value',{[{'not applicable'} channel_list(functionParameters.channels)]}),...
        'forgotten_field_2',struct('entry_name',{{'number of candidate nuclear pixels','maxAllowedOverlap'}},'entry_value',{25}),...
        'forgotten_field_3',struct('entry_name',{{'number of final nuclear pixels','maxPixOverlap'}},'entry_value',{5})...
        );
        
        answer_struct = settingsdlg(settings_dlg_struct);
        
        functionParameters.maxAllowedOverlap = answer_struct.maxAllowedOverlap;
        functionParameters.maxPixOverlap = answer_struct.maxPixOverlap;
        if strcmp(answer_struct.nuclearChannel,'not applicable')
            functionParameters.nuclearMarkerChannel = NaN;
        else
            functionParameters.nuclearMarkerChannel = find(strcmp(answer_struct.nuclearChannel,channel_list));
        end
    end
    
    extractParameters.functionParameters = functionParameters;
    
elseif isequal(extractParameters.extractFunction,@extractCellDataMatt)
    functionParameters = extractParameters.functionParameters;
    
    options.Default='No';
    options.Interpreter = 'tex';
    choice = questdlg('Change offsets before extracting the data? - 0 & 2 for Batgirl?','Offset Change',...
        'Yes','No',options);
    
    if strcmp(choice,'Yes')
        cExpGUI.cExperiment.setChannelOffset;
    end
    
    dlg_title = 'extraction type?';
    prompt = {['which property do you want to use to define the cell outline ']};
    answer = inputdlg(prompt,dlg_title,1,{'segmented'});
    functionParameters.cellSegType = answer{1};
    % general set type stuff
    list = {'max','basic'};
    dlg_title = 'What to extract?';
    prompt = {['All Params using max projection (max) or basic (basic)' ...
        ' the basic measure only compiles the x, y locations of cells along with the estimated radius so it is much faster, but less informative.'],'','',''};
    answer = listdlg('PromptString',prompt,'Name',dlg_title,'ListString',list,'SelectionMode','single',...
        'ListSize',[300 100]);
    
    type=list{answer};
    switch type
        case {'max','std','mean'}
            functionParameters.type = type;
        case {'basic'}
            extractParameters.extractFunction = @extractCellParamsOnly;
            functionParameters = [];
    end
    
    
    
    extractParameters.functionParameters = functionParameters;
    
end

end

