%% instantiate and parameterise

ttacObject = timelapseTrapsActiveContour(1);

SEGparameters = struct; %SegmentConsecutiveTimepoints parameters
ITparameters = struct;%image transformation parameters
ACparameters = struct; %active contour method parameters

SEGparameters.slice_size = 2;%slice of the timestack you look at in one go
SEGparameters.keepers = 1;%number of timpoints from that slice that you will keep (normally slice_size-1)
SEGparameters.SubImageSize = 61;
SEGparameters.OptPoints = 6;
SEGparameters.CellsToPlotGiven = true;

if false
SEGparameters.ImageTransformFunction = 'radial_gradient_DICangle_and_radialaddition';
ITparameters.DICangle = 135;
ITparameters.Rdiff = 3;
ITparameters.anglediff = 2*pi/40;
end

if true
    SEGparameters.ImageTransformFunction = 'radial_gradient';
    ITparameters.postprocessing = 'absolute';
end

ACparameters.alpha = 0.01;%weighs non image parts (none at the moment)
ACparameters.beta =100; %weighs difference between consecutive time points.
ACparameters.R_min = 5;%5;
ACparameters.R_max = 18;%30; %was initial radius of starting contour. Now it is the maximum size of the cell (must be larger than 5)
ACparameters.opt_points = SEGparameters.OptPoints;
ACparameters.visualise = 1; %degree of visualisation (0,1,2,3)
ACparameters.EVALS = 6000; %maximum number of iterations passed to fmincon
ACparameters.spread_factor = 2; %used in particle swarm optimisation. determines spread of initial particles.
ACparameters.spread_factor_prior = 0.5; %used in particle swarm optimisation. determines spread of initial particles.
ACparameters.seeds = 60;
ACparameters.TerminationEpoch = 150;%number of epochs of one unchanging point being the best before optimisation closes.


ttacObject.Parameters.ImageTransformation = ITparameters;
ttacObject.Parameters.ImageSegmentation = SEGparameters;
ttacObject.Parameters.ActiveContour = ACparameters;

%% establihing which is faster, matrices or structures

test = rand(61,61,100);
test2 = struct('name',zeros(61,61));
test2(1:100) = test2;

tic;
for i=1:100
test2(i).name = test(:,:,i);
end
toc

tic
test = num2cell(test,[1 2]);
[test2(:).name] = deal(test{:});
toc
test = rand(61,61,100);


for i=1:25
    
    figure(1);imshow(ImageStack(:,:,i),[]);

    figure(2);imshow(ImageStack3(:,:,i),[]);
    
    pause
    
end

for t=1:10
    fprintf('%d\n',t);
    imshow(full(ttacObject.TimelapseTraps.cTimepoint(t).trapInfo(1).cell(1).segmented),[])
    pause
end

%change filenames from e bakker to ebakker1
% 
% for i = 2:216
%     for c = 1
%         
%         disp.cTimelapse.cTimepoint(i).filename{c}(15) = [];
%         
%     end 
% end
%     

%display just one trap for cell identification 1:43
n=1;

ctrapDisplay(disp.cTimelapse,disp.cCellVision,false,1,n)
n = n+1;


%% run script in my absence

ttacObjectPOS3.SegmentConsecutiveTimePoints(1,216)
cTimelapse = ttacObjectPOS3.TimelapseTraps;
save('~/Documents/microscope_files_swain_microscope/PDR5/2013_02_06/PDR5GFPscGlc_2perc_00/pos3/cTimelapsePOS3_AC.mat','cTimelapse');
clear
load('~/Documents/microscope_files_swain_microscope/PDR5/2013_02_06/PDR5GFPscGlc_2perc_00/pos2/cTimelapsePOS2_UNMODIFIED.mat');
ttacObjectPOS2 = timelapseTrapsActiveContour(1);
ttacObjectPOS2.passTimelapseTraps(cTimelapse);
ttacObjectPOS2.getTrapImages(true);
ttacObjectPOS2.makeTrapPixelImage;
ttacObjectPOS2.findTrapLocation(1:216);
ttacObjectPOS2.SegmentConsecutiveTimePoints(1,216);
cTimelapse = ttacObjectPOS2.TimelapseTraps;
save('~/Documents/microscope_files_swain_microscope/PDR5/2013_02_06/PDR5GFPscGlc_2perc_00/pos2/cTimelapsePOS2_AC.mat','cTimelapse');


%% dangerous code to change filenames of cTimelapse object

for n= 1:124
    for i= 1:3
        cTimelapse.cTimepoint(n).filename{i} = ['/Users/ebakker/Documents/microscope_files_swain_microscope/matt_images/msn2 from mar 2/pos1/' cTimelapse.cTimepoint(n).filename{i}(end-18:end)];
    end
end

