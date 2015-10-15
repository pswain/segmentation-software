function obj=calculatebin(obj)
    % calculatebin --- Creates binary image defining regions
    %
    % Synopsis:  obj=calculatebin(obj) 
    %                    
    % Input:     obj = object of a timepoint class
    %
    % Output:    obj = object of a timepoint class

    % Notes:     MIJ must be initiated before calling this method. 
    %            Additional methods can be added here. Currently method 1
    %            seems good for Y channel images, method 4 is best for
    %            images in which cells are tightly packed and there is
    %            little intracellular detail (eg from Cellasic device)
    %            
   switch obj.ThreshMethod
        case 1%thresholded by Huang method 
            MIJ.createImage(obj.EntropyFilt);
            MIJ.run('Auto Threshold', 'method=Huang white');
            huang=MIJ.getCurrentImage;
            obj.Bin=false(size(obj.InputImage));
            obj.Bin(huang==255)=1;
            MIJ.run('Close All')
        case 2%simple global threshold in MATLAB
            t=graythresh(obj.EntropyFilt);
            obj.Bin=im2bw(obj.EntropyFilt,t);
        case 3%Shanbhag thresholding (ImageJ) followed by calculating the image holes
            MIJ.createImage(obj.EntropyFilt);
            MIJ.run('Auto Threshold', 'method=Shanbhag white');
            threshed=MIJ.getCurrentImage;
            threshed2=false(size(threshed));
            threshed2(threshed==255)=1;                    
            %Flood fill to set background pixels to white. Cell
            %interiors will be black
            %For flood fill - need to know the pixel
            %coordinates having the minimum value in
            %obj.EntropyFilt.
            minent=min(obj.EntropyFilt(:));
            minimg=obj.EntropyFilt==minent;
            %To avoid repeated flood fills on touching coordinates, reduce
            %this to a smaller number of positions (the centroids
            %of the objects in minimg
            mincents=regionprops(minimg,'Centroid');
            %flood fill loop
            for n=1:size(mincents,1)
               %if statement - only flood fill if the centroid is
               %white - otherwise a waste of time
               cent=round(mincents(n).Centroid);
               cent=fliplr(cent);
               if minimg(cent(1), cent(2))==1
                    threshed3=imfill(threshed2,cent,8);
               end
            end
            bin=false(size(threshed3));
            bin(threshed3==0)=1;
            bin=imopen(bin,strel('disk',3));
            obj.Bin=imdilate(bin,strel('disk',3));
            MIJ.run('Close All');
       case 4%rangefilt on filled abs image - more of a global segmentation method - useful for tightly packed cells
           %Threshold first using method 2 - used to remove objects outside the group of cells 
           t=graythresh(obj.EntropyFilt);
           thresh2=im2bw(obj.EntropyFilt,t);
           thresh2=imfill(thresh2,'holes');
           %then perform abs + rangefilt
           absimg=localabs(obj.InputImage,30);%Play with this parameter - lower means more holes in cells but more likely to get objects in the background
           filled=imfill(absimg);
           ranged=rangefilt(filled);
           res=false(size(ranged));
           res(ranged==0)=1;
           res=bwareaopen(res,30);
           res(thresh2==0)=0;
           obj.Bin=imfill(res,'holes');
   end 
   obj.Bin=imfill(obj.Bin,'holes');
end