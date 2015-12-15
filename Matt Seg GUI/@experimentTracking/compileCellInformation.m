function compileCellInformation(cExperiment,positionsToExtract,force)
% compileCellInformation(cExperiment,positionsToExtract,force)
%
% compiles all the data extracted in each of the positions into cellInf
% fiels of cExperiment.
%
% positionsToExtract    :   indexes of positions to extract. defaults to
%                           all positions.
% force                 :   boolean, defaults to false. If true, data is
%                           compiled even if the extraction parameters for
%                           each of the individual timelapses done match.
%                           Otherwise it will skip positions who's
%                           extractedData.extractionParameters field do not
%                           match those of the first timelapse.

if nargin<2 || isempty(positionsToExtract)
    positionsToExtract=1:length(cExperiment.dirs);
end

if nargin<3 || isempty(force)
    
    force = false;
    
end

cTimelapse=cExperiment.returnTimelapse(positionsToExtract(1));

cExperiment.cellInf=cTimelapse.extractedData;

[cExperiment.cellInf(:).posNum]=deal(ones(size(cExperiment.cellInf(1).trapNum)));

% list of fields that are not identically sized arrays
fields_treated_special = {'posNum','trapNum','cellNum','extractionParameters'};

% size of chunks to preallocate.
tempLen=50e3;
field_names = fieldnames(cExperiment.cellInf);
fields_to_treat = field_names(~ismember(field_names,fields_treated_special));

index = length(cExperiment.cellInf(1).posNum);
fprintf('positions extracted of %d : 1 ',length(positionsToExtract))
for posi=2:length(positionsToExtract)
    
    if index>= length(cExperiment.cellInf(1).posNum) || posi==2
        %preallocate more space
        for chi = 1:length(cExperiment.cellInf)
            for fi = 1:length(fields_to_treat)
                fn = fields_to_treat{fi};
                if fi==1 && chi==1 && posi==2
                    %timepoints in the data
                    tps = size(cExperiment.cellInf(chi).(fn),2);
                    data_template = spalloc(tempLen,tps,0.5*tempLen*tps);
                    %assumes only 50 percent of timepoints will be present on
                    %average.
                end
                cExperiment.cellInf(chi).(fn)((index+1):(index+tempLen),:)=data_template;
            end
            cExperiment.cellInf(chi).trapNum((index+1):(index+tempLen)) = zeros(1,tempLen);
            cExperiment.cellInf(chi).cellNum((index+1):(index+tempLen)) = zeros(1,tempLen);
            cExperiment.cellInf(chi).posNum((index+1):(index+tempLen)) = zeros(1,tempLen);
            
        end
        
    end
    
    pos = positionsToExtract(posi);
    cTimelapse=cExperiment.returnTimelapse(pos);
    
    if ~isequaln(cTimelapse.extractedData.extractionParameters,cExperiment.cellInf(1).extractionParameters) && ~force
        fprintf('\n not compiling data %d, extraction parameters do not match\n',pos)
        continue
    end
    
    num_cells = length(cTimelapse.extractedData(1).cellNum);
    for chi = 1:length(cExperiment.cellInf)
        for fi = 1:length(fields_to_treat)
            fn = fields_to_treat{fi};
            cExperiment.cellInf(chi).(fn)((index+1):(index+num_cells),:)=cTimelapse.extractedData(chi).(fn);
        end
        cExperiment.cellInf(chi).trapNum((index+1):(index+num_cells)) = cTimelapse.extractedData(chi).trapNum;
        cExperiment.cellInf(chi).cellNum((index+1):(index+num_cells)) = cTimelapse.extractedData(chi).cellNum;
        cExperiment.cellInf(chi).posNum((index+1):(index+num_cells)) = pos*ones(1,num_cells);
        
    end
    index = index + num_cells;
    
    cExperiment.cTimelapse = [];
    
    fprintf('%d ',posi)
end

%remove left over zeros from preallocation.
for chi=1:length(cExperiment.cellInf)
    for fi = 1:length(fields_to_treat)
        fn = fields_to_treat{fi};
        cExperiment.cellInf(chi).(fn)((index+1):end,:)=[];
    end
    cExperiment.cellInf(chi).trapNum((index+1):end) =[];
    cExperiment.cellInf(chi).cellNum((index+1):end) = [];
    cExperiment.cellInf(chi).posNum((index+1):end) = [];
    
end

if force
    [cExperiment.cellInf(:).extractionParameters] = deal([]);
end

fprintf('\ncompilation done \n\n')

cExperiment.saveExperiment();
end