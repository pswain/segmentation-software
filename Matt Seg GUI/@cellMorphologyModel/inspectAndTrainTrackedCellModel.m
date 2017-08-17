function inspectAndTrainTrackedCellModel(cCellMorph)
% inspectAndTrainTrackedCellModel(cCellMorph)
% make some simple standard inspections of the radii data before training
% tracked cell model. 
% expect the data training data to already be populated
% (CELLMORPHOLOGYMODEL.EXTRACTTRAININGDATAFROMEXPERIMENT)
%
% shows 2 plots:
% 1- asymptotic p value for Jarque Bera test (JBTEST) of each radii
% individually after normalisation. Values should be low to have
% confidence that gaussian is a good model.
% 2- gaussian fit for each radii with data.
%
% my single timepoint data failed the Jarque Bera Test
%
% See also, JBTEST,CELLMORPHOLOGYMODEL.EXTRACTTRAININGDATAFROMEXPERIMENT
radii_array_tp1 = cCellMorph.radii_arrays{1};
radii_array_tp2 = cCellMorph.radii_arrays{2};

% remove any entries that don't have a cell at either timepoint.

to_remove = all(radii_array_tp1==0,2) | all(radii_array_tp2==0,2);

radii_array_tp1(to_remove,:) = [];
radii_array_tp2(to_remove,:) =[];

% reorder to longest first
% permutes each radii so that the longest radii is the first entry and the
% 2nd longest is the 2nd (i.e. reassigns first radii and changes order for
% regularity).

radii_array_tp1 = ACBackGroundFunctions.reorder_radii(radii_array_tp1);
radii_array_tp2 = ACBackGroundFunctions.reorder_radii(radii_array_tp2);

log_normed_radii_array = log(radii_array_tp2./radii_array_tp1);

mean_cell_radii = mean(radii_array_tp1,2);

% show mean/std change for cells of different radii

[bin_val,~,bin_adherence] = histcounts(mean_cell_radii(:));

mean_changes = zeros(size(bin_val));
average_radius = mean_changes;
std_in_changes = mean_changes;

for bi=1:length(bin_val)
    to_mean = mean(log_normed_radii_array(bin_adherence==bi,:));
    mean_changes(bi) = mean(to_mean(:));
    to_std = std(log_normed_radii_array(bin_adherence==bi,:));
    std_in_changes(bi) = std(to_std(:));
    average_radius(bi) = mean(mean_cell_radii(bin_adherence==bi));
    
end

figure;
errorbar(average_radius,mean_changes,std_in_changes);
hold on
mean_diff = zeros(1,(length(bin_val)-1));
for bi=1:length(bin_val)
    mean_diff(bi) = abs(nanmean(mean_changes(1:bi)) - nanmean(mean_changes((bi+1):end)));
end
[~,I] = max(mean_diff);
recommended_thresh_radius = mean(average_radius(I:(I+1)));
ax = gca;
plot(recommended_thresh_radius*[1,1],ax.YLim,'-r');
xlabel('cell radius at timepoint 1')
ylabel('average log ratio of radii')
legend({'average log ratio of radii','recommended threshold radius'})
hold off

thresh_radius = inputdlg(sprintf('please provide the threshold radius to distiguish small and large cells. The recommended value is %f',recommended_thresh_radius),...
    'large/small cell threshold radius',1,{num2str(recommended_thresh_radius)});
thresh_radius = str2double(thresh_radius);

cCellMorph.thresh_tracked_cell_model = thresh_radius;

% fit small cells
radii_array_to_use = log_normed_radii_array(mean_cell_radii<=thresh_radius,:);
plot_radii_to_use(radii_array_to_use,'(small cells)');
cCellMorph.mean_tracked_cell_model_small = mean(radii_array_to_use);
cCellMorph.cov_tracked_cell_model_small = cov(radii_array_to_use);

% fit large cells
radii_array_to_use = log_normed_radii_array(mean_cell_radii>thresh_radius,:);
plot_radii_to_use(radii_array_to_use,'(large cells)');
cCellMorph.mean_tracked_cell_model_large = mean(radii_array_to_use);
cCellMorph.cov_tracked_cell_model_large = cov(radii_array_to_use);


end

function plot_radii_to_use(radii_array_to_use,title_string)

p_vals = [];
h_vals = [];
num_radii = size(radii_array_to_use,2);

for ri = 1:num_radii
    [h_vals(ri),p_vals(ri)] = jbtest(radii_array_to_use(:,ri));
end

% show asymptotic p values of the JBtest results - should be high if the
% data is gaussian like.
figure;
bar(1:num_radii,p_vals);
title(['Jarqu-Bera asymptotic p value for each radii individually ',title_string])
ylabel('asymptotic p value');
xlabel('radii');
ylim([0,0.2])
hold on
ax = gca;
plot(ax.XLim,0.05*[1 1],'-r');
hold off

if all(p_vals<0.05)
    fprintf('\n\n data looks log normally distirbuted\n\n')
else
    fprintf('\n\n high asymptotic p values. Data may not be normally distributed. \n\n')
end


figure;
[s1,s2] = maxfactor(num_radii);
for ri = 1:num_radii
    ax = subplot(s1,s2,ri);
    [N,b] = hist(radii_array_to_use(:,ri));
    bar(b,N);
    hold on
    m = mean(radii_array_to_use(:,ri));
    s = std(radii_array_to_use(:,ri));
    xs = ax.XLim;
    xs = linspace(xs(1),xs(2),100);
    ys = normpdf(xs,m,s);
    ys = max(N)*ys/max(ys);
    plot(xs,ys)
    hold off
    xlabel('radii');
    ylabel('frequency');
    if ri==1
        legend({'training set','fitted gaussian'})
    end
end

end