% script for playing with a an array of cell radii, mostly to come up with
% a cell shae space model.

%%  SINGLE TIMEPOINT

%% store original
original_radii_array_tp1 = radii_array_tp1;

%% reset

radii_array_tp1 = original_radii_array_tp1;

%% reorder to longest first
% permutes each radii so that the longest radii is the first entry and the
% 2nd longest is the 2nd (i.e. reassigns first radii and changes order for
% regularity).
radii_array_tp1 = ACBackGroundFunctions.reorder_radii(radii_array_tp1);

%% get stats

mean_radii = mean(radii_array_tp1);
cov_radii = cov(radii_array_tp1);

%% sample
mvnrnd(mean_radii,cov_radii)

%% sample and show
while true
sample_radii = mvnrnd(mean_radii,cov_radii);

angles = linspace(0,2*pi,length(sample_radii)+1);

angles = angles(1:(end-1));

[px,py] = ACBackGroundFunctions.get_full_points_from_radii(sample_radii,angles,[31 31],[61 61]);

imshow(ACBackGroundFunctions.px_py_to_logical(px,py,[61 61]),[]);
pause
end




%%  TWO TIMEPOINT

%% for testing

original_radii_array_tp1 = reshape(randperm(24),4,6);
original_radii_array_tp2 = reshape(randperm(24),4,6);

%% store original
original_radii_array_tp1 = radii_array_tp1;
original_radii_array_tp2 = radii_array_tp2;


%% reset

radii_array_tp1 = original_radii_array_tp1;
radii_array_tp2 = original_radii_array_tp2;


%% reorder to longest first
% permutes each radii so that the longest radii is the first entry and the
% 2nd longest is the 2nd (i.e. reassigns first radii and changes order for
% regularity).

radii_array_tp1 = ACBackGroundFunctions.reorder_radii(radii_array_tp1);
radii_array_tp2 = ACBackGroundFunctions.reorder_radii(radii_array_tp2);


%% test output

[~,loc1] = ismember(radii_array_tp1,original_radii_array_tp1);

[~,loc2] = ismember(radii_array_tp2,original_radii_array_tp2);

[loc1 zeros(size(loc1,1),1) loc2]



if any(loc1~=loc2)
    fprintf('test 1 failed\n')
else
    fprintf('test 1 passed\n')
end


if any(max(radii_array_tp1,[],2)~=radii_array_tp1(:,1))
    fprintf('test 2 failed\n')
else
    fprintf('test 2 passed\n')
end


if any(radii_array_tp1(:,2)<radii_array_tp1(:,end))
    fprintf('test 2 failed\n')
else
    fprintf('test 2 passed\n')
end

%% pick or paired sets

paired_radii_array = [radii_array_tp1 radii_array_tp2];
paired_radii_array(any(paired_radii_array==0,2),:) = [];

%% just small cells
threshold_size = 6;
paired_radii_array_small =  paired_radii_array(mean(paired_radii_array(:,1:6),2)<6,:);


mean_radii_small = mean(paired_radii_array_small);
cov_radii_small = cov(paired_radii_array_small);

%% just large cells


paired_radii_array_large =  paired_radii_array(mean(paired_radii_array(:,1:6),2)>=6,:);


mean_radii_large = mean(paired_radii_array_large);
cov_radii_large = cov(paired_radii_array_large);


%% get stats

mean_radii = mean(paired_radii_array);
cov_radii = cov(paired_radii_array);

%% sample
mvnrnd(mean_radii,cov_radii)

%% sample and show

f = figure;
pos = get(f,'Position');
while true
sample_radii = mvnrnd(mean_radii,cov_radii);

sample_radii_tp1 = sample_radii(1:6);
sample_radii_tp2 = sample_radii(7:end);

angles = linspace(0,2*pi,length(sample_radii_tp1)+1);

angles = angles(1:(end-1));

[px1,py1] = ACBackGroundFunctions.get_full_points_from_radii(sample_radii_tp1,angles,[31 31],[61 61]);

im1 = ACBackGroundFunctions.px_py_to_logical(px1,py1,[61 61]);

[px2,py2] = ACBackGroundFunctions.get_full_points_from_radii(sample_radii_tp2,angles,[31 31],[61 61]);


im2 = ACBackGroundFunctions.px_py_to_logical(px2,py2,[61 61]);

imshow(OverlapGreyRed(zeros(size(im1)),im1,[],im2,true),[])
set(f,'Position',pos)

pause

pos = get(f,'Position');

end

%% get probabilities 

ps_small = mvnpdf(paired_radii_array_small,mean_radii_small,cov_radii_small);
ps_large = mvnpdf(paired_radii_array_large,mean_radii_large,cov_radii_large);

ps = cat(1,ps_small,ps_large);

ps_cell1_small = mvnpdf(paired_radii_array_small(:,1:6),mean_radii_small(1:6),cov_radii_small(1:6,1:6));
ps_cell1_large = mvnpdf(paired_radii_array_large(:,1:6),mean_radii_large(1:6),cov_radii_large(1:6,1:6));

ps_cell1 = cat(1,ps_cell1_small,ps_cell1_large);

ps_small_cond = ps_small./ps_cell1_small;
ps_large_cond = ps_large./ps_cell1_large;

ps_cond = cat(1,ps_small_cond,ps_large_cond);


%% clear debris>> clear cExperiment
clear cExpGUI
clear px* py*
clear poses
clear loc* im* expi exps f


%% save

%save('~/Documents/microscope_files_swain_microscope_analysis/cCellVision_training/BF_OOF_24_25_30_pairs/curated_radii_processed.mat')

