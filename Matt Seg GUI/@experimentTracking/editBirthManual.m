function anything_changed = editBirthManual( cExperiment,add_or_remove, timepoint,position_index,trap_index,mother_label,daughter_label )
% addBirthManual( cExperiment,add_or_remove, timepoint,trap,mother_label,daughter_label )
% manually add or remove a birth event to lineageInfo.
% add_or_remove     -   '+' for add, '-' for remove.
% timepoint         -   timepoint at which to add birth. If remove, removes
%                       the nearest to this timepoint. 
% position          -   position index of mother.
% trap              -   trap number at which to remove birth
% mother_label      -   cell label of mother
% daughter_label    -   cell label of daughter. If not provided, is set to
%                       NaN
%
% WARNING : the addition/removal will be stored in the
% cExperiment.lineageInfo field, but the cExperiment will not be saved in
% this function. save separately.
%
% returns:
% anything_changed  -    flag. true of anything changed. false otherwise.
%
% See also, EXPERIMENTTRACKING.POPULATEMANUALLINEAGEINFO
if nargin<6 || isempty(daughter_label)
    daughter_label = NaN;
end

anything_changed = cExperiment.populateManualLineageInfo;

if isfield(cExperiment.lineageInfo,'motherInfo')
    cell_mother_index = (cExperiment.lineageInfo.motherInfo.manualInfo.posNum == position_index) &...
        (cExperiment.lineageInfo.motherInfo.manualInfo.trapNum == trap_index) & ...
        (cExperiment.lineageInfo.motherInfo.manualInfo.motherLabel == mother_label);
end

switch add_or_remove
    case '+'
        % if not already present, add cell to mother structure.
        if ~any(cell_mother_index)
            cell_mother_index = length(cExperiment.lineageInfo.motherInfo.manualInfo.posNum) + 1;
            cExperiment.lineageInfo.motherInfo.manualInfo.posNum(end+1) = position_index;
            cExperiment.lineageInfo.motherInfo.manualInfo.trapNum(end+1) = trap_index;
            cExperiment.lineageInfo.motherInfo.manualInfo.motherLabel(end+1) = mother_label;
            cExperiment.lineageInfo.motherInfo.birthTimeManual(cell_mother_index,:) = 0;
            cExperiment.lineageInfo.motherInfo.daughterLabelManual(cell_mother_index,:) = 0;
        end
        
        % extend birth structure if necessary
        if cExperiment.lineageInfo.motherInfo.birthTimeManual(cell_mother_index,end)~=0
            cExperiment.lineageInfo.motherInfo.birthTimeManual(:,(end+1):(end+10)) = 0;
            cExperiment.lineageInfo.motherInfo.daughterLabelManual(:,(end+1):(end+10)) = 0;
        end
        
        % complicated annoying code to put birth event in the right place.
        birth_times = cExperiment.lineageInfo.motherInfo.birthTimeManual(cell_mother_index,:);
        birth_times(birth_times==0) = [];
        daughter_labels =  cExperiment.lineageInfo.motherInfo.daughterLabelManual(cell_mother_index,1:length(birth_times));
        birth_times(end+1) = timepoint;
        daughter_labels(end+1) = daughter_label;
        [birth_times,I] = sort(birth_times,2,'ascend');
        daughter_labels = daughter_labels(I);
        cExperiment.lineageInfo.motherInfo.birthTimeManual(cell_mother_index,1:length(birth_times)) = birth_times;
        cExperiment.lineageInfo.motherInfo.daughterLabelManual(cell_mother_index,1:length(daughter_labels)) = daughter_labels;
        
        anything_changed = true;
        
    case '-'
        if ~any(cell_mother_index)
            fprintf('\n cell pos %d, trap %d , label %d is not a mother \n nothing recorded \n',position_index,trap_index,mother_label)
            return
        end
        birth_times = cExperiment.lineageInfo.motherInfo.birthTimeManual(cell_mother_index,:);
        birth_times(birth_times==0) = [];
        if isempty(birth_times)
            % no daughters for this mother
            return
        end
        daughter_labels =  cExperiment.lineageInfo.motherInfo.daughterLabelManual(cell_mother_index,1:length(birth_times));
        [~,k] = min(abs(birth_times - timepoint));
        birth_times(k) = [];
        birth_times(end+1) = 0;
        daughter_labels(k) = [];
        daughter_labels(end+1) = 0;
        cExperiment.lineageInfo.motherInfo.birthTimeManual(cell_mother_index,1:length(birth_times)) = birth_times;
        cExperiment.lineageInfo.motherInfo.daughterLabelManual(cell_mother_index,1:length(daughter_labels)) = daughter_labels;
        anything_changed = true;
        
end

end

