function inspectAndTrainNewCellModel(cCellMorph,method)
% inspectAndTrainNewCellModel(cCellMorph,method)
% make some simple standard inspections of the radii data before training
% new cell model. 
% expect the data training data to already be populated
% (CELLMORPHOLOGYMODEL.EXTRACTTRAININGDATAFROMEXPERIMENT)
%
% method - a string defining which subset of the training data to use.
%          Either:
%           tp1 - uses all cells at timepoint 1.
%           new_only - uses cells at timepoint 2 that were not present at
%                      timepoint 1. May be better (closer to what we
%                      normally wish to detect) but requires a larger
%                      training set.
%
% shows 2 plots:
% 1- asymptotic p value for Jarque Bera test (JBTEST) of each radii
% individually. Values should be low to have confidence that gaussian is a
% good model. 
% 2- gaussian fit for each radii with data.
%
% my single timepoint data failed the Jarque Bera Test
%
% See also, JBTEST,CELLMORPHOLOGYMODEL.EXTRACTTRAININGDATAFROMEXPERIMENT
if nargin<2 || isempty(method)
    method = 'tp1';
end
possible_methods = {'tp1','new_only'};
if ~ismember(method,possible_methods)
    fprintf('ERROR: method must be one of:  ');
    fprintf('%s  \n',possible_methods{:});
    error();
end

radii_array_tp1 = cCellMorph.radii_arrays{1};
radii_array_tp2 = cCellMorph.radii_arrays{2};
absent_tp1 = all(radii_array_tp1==0,2);
switch method
    case 'tp1'
        radii_array_tp1(absent_tp1,:) = [];
        radii_array_to_use = radii_array_tp1;
    case 'new_only'
        radii_array_tp2(~absent_tp1,:) = [];
        radii_array_to_use = radii_array_tp2;
end
% reorder to longest first
% permutes each radii so that the longest radii is the first entry and the
% 2nd longest is the 2nd (i.e. reassigns first radii and changes order for
% regularity).
radii_array_to_use = ACBackGroundFunctions.reorder_radii(radii_array_to_use);

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
title('Jarqu-Bera asymptotic p value for each radii individually')
ylabel('asymptotic p value');
xlabel('radii');
ylim([0,0.2])
hold on
ax = gca;
plot(ax.XLim,0.05*[1 1],'-r');
hold off

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

% 'train' the model
cCellMorph.mean_new_cell_model = mean(radii_array_to_use);
cCellMorph.cov_new_cell_model = cov(radii_array_to_use); 
        

end

%%
