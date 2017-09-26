function createFromOmero(cExpGUI)
%Runs the Omero gui and if the user loads an experiment for segmentation, 
%creates or downloads a cExperiment from the user-selected Omero dataset.
%Newly-created cExperiment and cTimelapse files are saved as file
%attachments to the database.

%Get a dataset selection from the user:
dsStruct=omeroGUI('download','sce-bio-c04287.bio.ed.ac.uk');
%There are options other than selecting a dataset for segmentation in that
%gui - so only create a dataset if the correct button has been pressed
if strcmp(dsStruct.action,'segment')
    %Make sure DataPath folder is correctly set and emptied. When segmenting
    %this property is used for the folder in which cExperiment and cTimelapse
    %files will be stored after downloading (must be the same as cExperiment.saveFolder).
    if ispc
        dsStruct.OmeroDatabase.DataPath=['C:\Users\' getenv('USERNAME') '\OmeroTemp\'];
        if exist(dsStruct.OmeroDatabase.DataPath)==0
            mkdir(dsStruct.OmeroDatabase.DataPath);
        else
            delete([dsStruct.OmeroDatabase.DataPath '*']);
        end
    else
        %Choose a mac version here.
        [unused username]=system('whoami');
        username(end)=[];
        dsStruct.OmeroDatabase.DataPath=['/Users/' username '/Documents/OmeroTemp/'];
        if exist(dsStruct.OmeroDatabase.DataPath)==0
            mkdir(dsStruct.OmeroDatabase.DataPath);
        else
            delete([dsStruct.OmeroDatabase.DataPath '*']);
        end
    end
   
    
    %First check if a cExperiment exists for this dataset:
    fileAnnotations=getDatasetFileAnnotations(dsStruct.OmeroDatabase.Session,dsStruct.dataset);
    %Create a cell array of file annotation names
    for n=1:length(fileAnnotations)
        faNames{n}=char(fileAnnotations(n).getFile.getName.getValue);
    end
    exptName=dsStruct.dataset.getName.getValue;
    matched=strncmp('cExperiment_',faNames,12);    
    matched(strncmp('cExperiment_log',faNames,15))=0;%Remove the cExperiment log file
    if nnz(matched)==0
        %No cExperiment has yet been created for this dataset.
        %Create a new cExperiment from the Omero dataset
        inputName=inputdlg('Enter a name for your cExperiment','cExperiment name',1,{'001'});
        if isempty(inputName)
            inputName='001';
        else if size(inputName{1},2)==0
                inputName='001';
            end
        end
        cExpGUI.cExperiment=experimentTrackingOmero(dsStruct(1).dataset, dsStruct.OmeroDatabase.DataPath,dsStruct.OmeroDatabase, inputName);
        cExpGUI.cExperiment.segmentationSource='Omero';%Data will be retrieved from the Omero database for segmentation
        %Copy the channels lists to the cExperiment.
        cExpGUI.cExperiment.experimentInformation.channels=cExpGUI.cExperiment.OmeroDatabase.Channels;
        cExpGUI.cExperiment.experimentInformation.microscopeChannels=cExpGUI.cExperiment.OmeroDatabase.MicroscopeChannels;
        

        % createTimelapsePositions given with explicit arguments so that all
        % positions are loaded.
        cExpGUI.cExperiment.createTimelapsePositions([],'all');

        cExpGUI.cExperiment.saveExperiment;%Uploads the cExperiment file to the database
    else
        %There is at least one existing cExperiment file
        
        %Get the names (suffixes) of the existing files
        expNames=cellfun(@(x) x(13:end-4),faNames(matched),'UniformOutput',false);
        
        response=questdlg('There is already at least one cExperiment file associated with this dataset. Do you want to load an existing one or create a new one? If you create a new one the existing one will be unaffected.','cExperiment file exists','Load existing','Create new','Load existing');
        switch response
            case 'Load existing'
                %Dialogue to choose one of the existing cExperiments
                [s,v] = listdlg('PromptString','Select the cExperiment you want to open','SelectionMode','single','ListString',expNames);
                if v==1
                    expName=expNames{s};
                else
                    error('No dataset selected')
                end
                matchedExp=find(strcmp(['cExperiment_' expName '.mat'],faNames));
                matchedExp=matchedExp(1);
                %Download then load the cExperiment file
                disp('Downloading cExperiment file');
                getFileAnnotationContent(dsStruct.OmeroDatabase.Session, fileAnnotations(matchedExp), [dsStruct.OmeroDatabase.DataPath 'cExperiment_' expName '.mat']);
                if isempty(expName)%This is just for back compatibility
                    load([dsStruct.OmeroDatabase.DataPath 'cExperiment_.mat']);
                else
                    load([dsStruct.OmeroDatabase.DataPath char(fileAnnotations(matchedExp).getFile.getName.getValue)]);
                end
                %Confirm that the cExperiment save folder is the same as the
                %OmeroDatabase data folder (for back compatibility)
                cExperiment.saveFolder=dsStruct.OmeroDatabase.DataPath;
                
                %Loaded file will lack Omero objects - copy from dsStruct
                %NEED A CONVERSION SCRIPT TO CALL HERE - FOR CASES IN WHICH
                %EXPERIMENTS WERE CREATED FROM OMERO BUT AS
                %EXPERIMENTTRACKING OBJECTS, NOT EXPERIMENTTRACKINGOMERO
                %OBJECTS - EXPERIMENTTRACKING NO LONGER HAS AN
                %OMERODATABASE FIELD.
                %cExperiment = experimentTrackingOmero(cExperiment)
                cExperiment.OmeroDatabase=dsStruct.OmeroDatabase;
                cExperiment.omeroDs=dsStruct.dataset;
                cExpGUI.cExperiment=cExperiment;
                
                %Copy the channels lists to the cExperiment.
                cExpGUI.cExperiment.experimentInformation.channels=cExpGUI.cExperiment.OmeroDatabase.Channels;
                cExpGUI.cExperiment.experimentInformation.microscopeChannels=cExpGUI.cExperiment.OmeroDatabase.MicroscopeChannels;
                
                %If the current user is not the creator of this cExperiment then they will be prevented from making changes
                %Make this clear before offering the option to make an editable copy
                if ispc
                    userNames=dsStruct.OmeroDatabase.getSynonyms(getenv('USERNAME'));
                else
                    
                    userNames=dsStruct.OmeroDatabase.getSynonyms(username);
                end
                if ~any(strcmp(userNames,cExperiment.creator))
                    promptString='You did not create this dataset so you will not be able to make changes. You can make an editable copy or load the file as read only.';
                    loadString='Load read only';
                else
                    promptString='Load (and modify) original file or make an editable copy?';
                    loadString='Load original';
                end
                
                makeCopy=questdlg(promptString,'Make copy?',loadString,'Make copy',loadString);
                switch makeCopy
                    case loadString
                        %Use the the original cExperiment file loaded from the database
                        %Loaded file will lack Omero objects - copy from dsStruct
                        cExperiment.OmeroDatabase.Session=dsStruct.OmeroDatabase.Session;
                        cExperiment.OmeroDatabase.Client=dsStruct.OmeroDatabase.Session;
                        cExperiment.omeroDs=dsStruct.dataset;
                        cExpGUI.cExperiment=cExperiment;
                        %Download the cTimelapse files
                        for pos=1:length(cExperiment.dirs)
                            origName=[cExperiment.dirs{pos} 'cTimelapse_' expName '.mat'];
                            annotationMatch=strcmp(origName,faNames);
                            
                            if any(annotationMatch)
                                getFileAnnotationContent(dsStruct.OmeroDatabase.Session, fileAnnotations(annotationMatch), [dsStruct.OmeroDatabase.DataPath origName]);
                            end
                        end
                        
                        
                        
                    case 'Make copy'
                        %Get a new file name suffix
                        newName=false;
                        while ~newName
                            inputName=inputdlg('Enter a name for your cExperiment','cExperiment name',1,{getenv('USERNAME')});
                            inputName=inputName{:};
                            fullInputName=['cExperiment_' inputName '.mat'];
                            if ~any(strcmp(fullInputName, faNames))
                                newName=true;
                            else
                                disp('Filename in use. Please choose another');
                            end
                        end
                        %Write this name to cExperiment
                        cExperiment.rootFolder=inputName;
                        %Rename the cExperiment file
                        movefile([dsStruct.OmeroDatabase.DataPath 'cExperiment_' expName '.mat'],[dsStruct.OmeroDatabase.DataPath 'cExperiment_' inputName '.mat'],'f');
                        %Download all cTimelapse files and change their filenames and that of the cExperiment. Also change the rootFolder property
                        for pos=1:length(cExperiment.dirs)
                            origName=[cExperiment.dirs{pos} 'cTimelapse_' expName '.mat'];
                            newName=[cExperiment.dirs{pos} 'cTimelapse_' inputName '.mat'];
                            annotationMatch=strcmp(origName,faNames);
                            if ~isempty(find(annotationMatch, 1))
                                getFileAnnotationContent(dsStruct.OmeroDatabase.Session, fileAnnotations(annotationMatch), [dsStruct.OmeroDatabase.DataPath origName]);
                                %Rename the file
                                movefile([dsStruct.OmeroDatabase.DataPath origName],[dsStruct.OmeroDatabase.DataPath newName],'f')
                            end
                        end
                        %Upload the new files to the database
                        %cExperiment
                        cExperiment.saveExperiment;
                        %cTimelapses (and cCellVision if any)
                        for pos=1:length(cExperiment.dirs)
                            cTimelapsePath=[dsStruct.OmeroDatabase.DataPath cExperiment.dirs{pos} 'cTimelapse_' inputName '.mat'];
                            if exist(cTimelapsePath,'file')==2
                                cExperiment.OmeroDatabase.uploadFile(cTimelapsePath, cExperiment.omeroDs, 'cTimelapse file uploaded by createFromOmero');
                            end
                        end
                end
                
            case {'Create new', ''}
                %Need to create a new cExperiment with a name different from
                %any of the existing ones.
                novel=false;
                while ~novel
                    inputName=inputdlg('Enter a name for your cExperiment','cExperiment name',1,{'001'});
                    %Check input is OK
                    if isempty(inputName)
                        inputName='001';
                    else if size(inputName{1},2)==0
                            inputName='001';
                        end
                    end
                    %Check this name isn't already taken
                    if ~strcmp(expNames,inputName)
                        novel=true;
                    else
                        disp('this cExperiment name has been used already - try again.')
                    end
                end
                %if experimentTracking is called with a non character first
                %input this is assumed to be ab omerodatabase construction. The
                %2nd input is then not used.
                cExpGUI.cExperiment=experimentTrackingOmero(dsStruct(1).dataset,'not used', dsStruct.OmeroDatabase, inputName);
                cExpGUI.cExperiment.segmentationSource='Omero';%Data will be retrieved from the Omero database for segmentation
                %Copy the channels lists to the cExperiment.
                cExpGUI.cExperiment.experimentInformation.channels=cExpGUI.cExperiment.OmeroDatabase.Channels;
                cExpGUI.cExperiment.experimentInformation.microscopeChannels=cExpGUI.cExperiment.OmeroDatabase.MicroscopeChannels;
                
                % createTimelapsePositions given with explicit arguments so that all
                % positions are loaded.
                cExpGUI.cExperiment.createTimelapsePositions([],'all');

                %Upload the new cExperiment file to the database
                cExpGUI.cExperiment.saveExperiment;
        end
    end
    
    
    
    
    %Rename the figure - date and experiment folder name.
    set(cExpGUI.figure,'Name',[char(cExpGUI.cExperiment.omeroDs.getName.getValue) '  ' cExpGUI.cExperiment.OmeroDatabase.getDate(cExpGUI.cExperiment.omeroDs)])
    set(cExpGUI.posList,'String',cExpGUI.cExperiment.dirs);
    set(cExpGUI.posList,'Value',1);
    
    if ~cExpGUI.cExperiment.trapsPresent
        set(cExpGUI.selectTrapsToProcessButton,'Enable','off');
    else
        set(cExpGUI.selectTrapsToProcessButton,'Enable','on');
    end
    
    set(cExpGUI.selectChannelButton,'String',cExpGUI.cExperiment.channelNames,'Value',1);
    cExpGUI.channel = 1;

end