for i =1:86
figure(1);imshow(CellInfo(i).TransformedImage1,[]);
figure(2);imshow(CellInfo(i).TransformedImage2,[]);
%figure(2);imshow(trap_px_stack(:,:,i),[])
pause
end

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



