function imagehandle=trapVideo(cExperiment, num, channel, videoName)
%cellSequence plots the corresponding segmented cell cellnum

%imagehandle= figure();

if(nargin<4)
    videoName='tempVideo.avi'
end
    
replacementimg=[];
segTrapNum=cExperiment.cellInf(channel).trapNum(num);
segCellNum=cExperiment.cellInf(channel).cellNum(num);
segPosNum=cExperiment.cellInf(channel).posNum(num);
cTimelapse=cExperiment.returnTimelapse(segPosNum);

shapeInserter = vision.ShapeInserter('Shape','Circles', 'Fill', 1);
for i= 1: size(cTimelapse.cTimepoint,2);
   
     
    
    
       %subplot(20,   15, i);
       %for a given trap, there is a total number of cells in all
       %timepoints. if the cell is the same in different timepoints, it
       %will have the same label in each timepoint. but the cell may be
       %missing in each timepoint. therefore, the cell with label 2 will
       %be call number 1 in one timepoint and cell 3 in another one.
       %therefore we need to get the array number from the cell label,
       %which is segCellNum.
 positionInArray= find(cTimelapse.cTimepoint(i).trapInfo(segTrapNum).cellLabel==segCellNum);

   if (i==1)
 
       replacementimg= uint16(repmat(0, size(double(cTimelapse.returnSingleTrapTimepoint(segTrapNum,i,channel)),1), size(double(cTimelapse.returnSingleTrapTimepoint(segTrapNum,i,channel)),2)));
   myvideo=uint16(repmat(0, size(replacementimg,1), size(replacementimg,2),1,size(cTimelapse.cTimepoint,2)));
   end
 img=cTimelapse.returnSingleTrapTimepoint(segTrapNum,i,channel) ;
 img1=cTimelapse.returnSingleTrapTimepoint(segTrapNum,i,1)*.008 ;
 img2=cTimelapse.returnSingleTrapTimepoint(segTrapNum,i,2) ;
 img3=cTimelapse.returnSingleTrapTimepoint(segTrapNum,i,3) ;
 %img= uint8(double(img)/max(max(double(img)))*255);
 
   xyr=  [cTimelapse.cTimepoint(i).trapInfo(segTrapNum).cell(positionInArray).cellCenter cTimelapse.cTimepoint(i).trapInfo(segTrapNum).cell(positionInArray).cellRadius];
    
       
          try
cellimg=img(round(xyr(2))-round(xyr(3)): round(xyr(2))+round(xyr(3)) , round(xyr(1))-round(xyr(3)): round(xyr(1))+round(xyr(3)));

catch
    continue
          end

          
      %img= step(shapeInserter, img, xyr);   
       
       myvideo(:,:,1,i)=replacementimg;
       myvideo(:,:,1,i)=img;
       myvideostack(:,:,1,i)=[img1; img2;img3];
       %imshow( img, []); 
      % viscircles([xyr(2) xyr(1)],xyr(3), 'DrawBackgroundCircle', 0, 'EdgeColor', 'red', 'LineWidth', 1);
end


   v=implay(uint16(double(myvideo)./max(max(max(double(myvideo))))*65535));
   video=VideoWriter(videoName);
   open(video);
   writeVideo(video, double(double(myvideo)./max(max(max(double(myvideo))))));
   close(video);
   videostack=VideoWriter('tempStack.avi');
   open(videostack);
   writeVideo(videostack, double(double(myvideostack)./max(max(max(double(myvideostack))))));
   close(videostack);
  
   end



