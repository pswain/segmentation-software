function compareExperimentTrackingObjsForTest(cExperiment_test,cExperiment_true,poses, report_string )
% compareExperimentTrackingObjsForTest(cExperiment_test,cExperiment_true,poses, report_string )
%
% reports difference between two cExperiment objects.
% See Also: REPORT_DIFFERENCES

if nargin<3 
    poses  = 1:length(cExperiment_true.dirs);
end

if nargin<4
    report_string = ''
end

cExperiment_true.cTimelapse = [];
cExperiment_test.cTimelapse = [];

cExperiment_true.logger = [];
cExperiment_test.logger = [];


if isequaln(cExperiment_test,cExperiment_true)
    
    fprintf('\n %s:  passed standard processing test\n',report_string)
else
    fprintf('\n %s             FAILED standard processing test \n',report_string)
    report_differences(cExperiment_true,cExperiment_test,sprintf('cExperiment_true'),sprintf('cExperiment_test'));
    
end

for diri=1:length(poses)
    
    cTimelapse_true = cExperiment_true.loadCurrentTimelapse(diri);
    cTimelapse_test = cExperiment_test.loadCurrentTimelapse(diri);
    
    
    cTimelapse_true.logger = [];
    cTimelapse_test.logger = [];
    
    if isequaln(cTimelapse_test,cTimelapse_true)
        
        fprintf('\n %s : passed standard processing: timelapse %d \n',report_string,diri)
    else
        fprintf('\n %s :        FAILED standard processing: timelapse %d \n',report_string,diri)
        report_differences(cTimelapse_true,cTimelapse_test,sprintf('cTimelapse_true_%d',diri),sprintf('cTimelapse_test_%d',diri));
        
    end
    
end


end

