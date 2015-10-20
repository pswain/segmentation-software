%% or straight from GUI
TI = 1;
TP =30;


gui = GenericStackViewingGUI;
A =disp.currentGUI.cTimelapse.returnSegmenationTrapsStack(TI,TP);
A = A{1};
figure(4);imshow(A(:,:,1),[])
gui.stack = A;
gui.LaunchGUI

%%

tic;[predicted_im decision_im filtered_image]=classifyImage2Stage(disp.cCellVision,A,false(size(A,1),size(A,2)));toc;
gui.stack =reshape(filtered_image(:),[size(A,1) size(A,2) numel(filtered_image)/(numel(A(:,:,1)))]);
gui.LaunchGUI;
figure;
imshow(OverlapGreyRed(A(:,:,1),decision_im<0),[])


