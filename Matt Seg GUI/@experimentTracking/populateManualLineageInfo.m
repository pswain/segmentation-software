function info_added = populateManualLineageInfo( cExperiment)
% info_added = populateManualLineageInfo( cExperiment)
% populate the manual elements of the lineageInfo so that birth events can
% be manually curated
% only does anything if the field isn't already there. Returns flag
%   info_added : true if info was added, false if it was already there.
% See also, EXPERIMENTTRACKING.EDITBIRTHMANUAL
info_added = false;

if isempty(cExperiment.lineageInfo)
    warning('must run lineage tracking scripts before addind daughter events manually')
    return
end

if ~isfield(cExperiment.lineageInfo.motherInfo,'birthTimeManual') ...
        || isempty(cExperiment.lineageInfo.motherInfo.birthTimeManual)
    cExperiment.lineageInfo.motherInfo.birthTimeManual= ...
        cExperiment.lineageInfo.motherInfo.birthTimeHMM;
    cExperiment.lineageInfo.motherInfo.daughterLabelManual= ...
        cExperiment.lineageInfo.motherInfo.daughterLabelHMM;
    cExperiment.lineageInfo.motherInfo.deathTimeManual = ...
        NaN*ones(size(cExperiment.lineageInfo.motherInfo.birthTimeHMM,1),1);
    
    % in case the cell numbers are editted in the future, want to
    % record the current list of mother trap/pos numbers
    cExperiment.lineageInfo.motherInfo.manualInfo.trapNum=cExperiment.lineageInfo.motherInfo.motherTrap;
    cExperiment.lineageInfo.motherInfo.manualInfo.posNum=cExperiment.lineageInfo.motherInfo.motherPosNum;
    cExperiment.lineageInfo.motherInfo.manualInfo.motherLabel=cExperiment.lineageInfo.motherInfo.motherLabel;
    
    % save the manual info (even if no edits have been made,
    % save the existence of the field)
    info_added = true;
end

end

