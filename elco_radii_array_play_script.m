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
% for the test input

[~,loc1] = ismember(radii_array_tp1,original_radii_array_tp1);

[~,loc2] = ismember(radii_array_tp2,original_radii_array_tp2);

n = 24;

[loc1(1:n,:) zeros(n,1) loc2(1:n,:)];



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
    fprintf('test 3 failed\n')
else
    fprintf('test 3 passed\n')
end


%% visualisation

%% scatter plot
h = plot(radii_array_tp1(:), radii_array_tp2(:),'or');
hold on
y_lim = h.Parent.YLim;
plot(y_lim,y_lim,'-b')
hold off

%% plot of mean and variance in bins

r1 = radii_array_tp1(:);
r2 = radii_array_tp2(:);

to_remove = (r1==0) | (r2==0);

r1 = r1(~to_remove);
r2 = r2(~to_remove);


[bin_val,bin_loc,bin_adherence] = histcounts(r1(:));

means1 = zeros(size(bin_val));
means2 = means1;
stds = means1;
jbtests = means1;

for i=1:length(bin_val)
    means1(i) = mean(r1(bin_adherence==i));
    means2(i) = mean(r2(bin_adherence==i));
    stds(i) = std(r2(bin_adherence==i));
    if sum(bin_adherence==i)>1
        [~,jbtests(i)] = jbtest(r1(bin_adherence==i));
    end
end

errorbar(means1,means2,stds);
hold on
plot(means1,means1,'-or');
hold off

figure;
plot(means1,stds)

%% plot normalise radii

r2_n = r2./r1;


[~,p_jb] = jbtest(r2_n);
fprintf('jbtest for normalised radii is %f',p_jb)

m = mean(r2_n);
s = std(r2_n);

[n,bins] = hist(r2_n,100);

bar(bins,n/sum(n));
hold on
pdfs = normpdf(bins,m,s);
pdfs = pdfs/sum(pdfs);
plot(bins,pdfs,'-or');
hold off

%% NORMALISED 2ND RADII

% based on the success of matt's training, now trying radii normalised to
% the first timepoint

%% clean up and normalise

to_remove = any(radii_array_tp1==0,2) |  any(radii_array_tp2==0,2);


radii_array_tp1_n = radii_array_tp1(~to_remove,:);
radii_array_tp2_n = radii_array_tp2(~to_remove,:);
radii_array_tp2_n = radii_array_tp2_n./radii_array_tp1_n;

%% get stats

%% just small cells
threshold_size = 6;
radii_array_tp2_n_small =  radii_array_tp2_n(mean(radii_array_tp1_n,2)<6,:);

mean_radii_small = mean(radii_array_tp2_n_small);
cov_radii_small = cov(radii_array_tp2_n_small);

mean_radii = mean_radii_small;
cov_radii = cov_radii_small;

%% just large cells
threshold_size = 6;
radii_array_tp2_n_large =  radii_array_tp2_n(mean(radii_array_tp1_n,2)>=6,:);

mean_radii_large = mean(radii_array_tp2_n_large);
cov_radii_large = cov(radii_array_tp2_n_large);

mean_radii = mean_radii_large;
cov_radii = cov_radii_large;


%% sample
mvnrnd(mean_radii,cov_radii)

%% show probabilities

ps_small = mvnpdf(radii_array_tp2_n_small,mean_radii_small,cov_radii_small);
ps_large = mvnpdf(radii_array_tp2_n_large,mean_radii_large,cov_radii_large);

ps = cat(1,ps_small,ps_large);

hist(log(ps),300)

%% NON NORMALISED
% old(now) code when radii were paired into a 12 dimensional gaussian and
% not normalised.
%% pick or paired sets

paired_radii_array = [radii_array_tp1 radii_array_tp2];
paired_radii_array(any(paired_radii_array==0,2),:) = [];

%% just small cells
threshold_size = 6;
paired_radii_array_small =  paired_radii_array(mean(paired_radii_array(:,1:6),2)<6,:);


mean_radii_small = mean(paired_radii_array_small);
cov_radii_small = cov(paired_radii_array_small);

mean_radii = mean_radii_small;
cov_radii = cov_radii_small;

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


