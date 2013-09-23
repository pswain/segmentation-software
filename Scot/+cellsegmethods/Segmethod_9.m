%ELCO's METHOD 9 - NEEDS WORK TO BE USEFUL
% classdef Segmethod_9<cellsegmethods.Segmethods    
%     methods
%         function obj=Segmethod_9()
%             % Segmethod_9 --- constructor for Segmethod_9, initialises cellsegmethods object for: tophat, sobel, open, fill, distance transform, watershed,
%             %
%             % Synopsis:  Segmethod_9obj = Segmethod_9()
%             %                        
%             % Input:     
%             %
%             % Output:    Segmethod_9obj = object of class Segmethod_9
% 
%             % Notes:     This constructor defines the requiredFields
%             %            property. In this case there are no OneCell fields
%             %            to be initialised but the region object needs to
%             %            be sent to the run function.
%             obj.requiredFields={'Region'};           
%         end
%         function result=run(obj, oneCellObj, regionObj)
%             % run --- run function for Segmethod_9, creates result for tophat, sobel, open, fill, distance transform, watershed
%             %
%             % Synopsis:  result = run(obj, oneCellObj, regionObj)
%             %                        
%             % Input:     obj = an object of class Segmethod_9
%             %            oneCellObj = an object of a OneCell class
%             %            regionObj = an object of a Region class
%             %
%             % Output:    result = 2d logical matrix, shows segmentation result
% 
%             % Notes:     Elco's method - intended to be good for pictures 
%             %            with out of focus cells that should be ignored.
%             %            Best run on its own since defaults.depth is best
%             %            set to zeros for this method (for now).
%             result=obj.method_9(oneCellObj.CatchmentBasin, regionObj.Target, regionObj.Watershed);
%             if any(result(:))
%                 result=imopen(result,oneCellObj.SE);
%             end
%         end
%     end
%     methods (Static)
%         function result = method_9(catchmentBasin, reg_target, reg_watershed)
%             % method9 --- applies segmentation method 9 to the cell: tophat, sobel, open, fill, distance transform, watershed,run function for Segmethod_9, creates result for tophat, sobel, open, fill, distance transform, watershed
%             %
%             % Synopsis:  result = method9(catchmentBasin, reg_target, reg_watershed)
%             %                        
%             % Input:     catchmentBasin - integer, the catchment basin on which segmentation is being attempted.
%             %            reg_target = the target image (eg DIC) for the current region
%             %            reg_watershed = the watershed image for the current region
%             %
%             % Output:    result = 2d logical matrix, shows segmentation result
% 
%             % Notes:     Elco's method - intended to be good for pictures 
%             %            with out of focus cells that should be ignored.
%             %            Best run on its own since defaults.depth is best
%             %            set to zeros for this method (for now).
%                        
%             s = strel('disk',2,4);
%             s2 = strel('disk',6,4);
%             img = imtophat(reg_target,s);%tophat on DIC image of region to segment - smooths out global brightness differences.
%             img = padarray(img, [10 10],median(reshape(img,[],1))); %padding with median value of img.
%             %padding ensures that later dilation does not connect cells
%             %to edge of the region. median used since this was thought to 
%             %correspont to a background pixel and would prevent the edge of
%             %the region being identified as the edge of an object.                                                                  
%             edg = edge(img,'sobel',0.0017); %sobel was found to ignore out of focus cells - threshold picked by trial and error
%             props = regionprops(edg,'Area','PixelIdxList');
%             T = vertcat(props([props(:).Area]<=20).PixelIdxList);%all pixels belonging to objects smaller than 20 pixels are removed
%             %This is an attempt to remove left over parts of out of focus cells.   
%             edg(T) = false;%remove all ojects less than 10 pixels          
%             m9watershed = imdilate(edg,s2);%try and fill gaps between broken cell boundaries with dilate
%             m9watershed = imfill(m9watershed,'holes'); %fill in holes to try and maintain complete cells
%             m9watershed = imerode(m9watershed,s2);%returns filled in cells to their original size.
%             m9watershed=1-m9watershed;
%             m9watershed=bwdist(m9watershed);
%             m9watershed=imhmin(1-m9watershed,0.5);%3 steps above are the steps taken by Ivan to make a bw distance transform that is used to make a watershed.
%             m9watershed(logical(imdilate(imregionalmin(m9watershed),s)))=min(min(m9watershed));
%             %this step is designed to fuse minima that are within 4 pixels of each other
%             %can be handy since mess of overlapping cells produces minima
%             %close to each other                                                                                                             
%             m9watershed=watershed(m9watershed);
%             basin = false(size(reg_watershed));
%             if ~isempty(catchmentBasin)
%             %if there is only one catchment basin then the
%             %catchmentBasin is empty and the whole of reg_watershed
%             %is equal to 1. This basin object is used to pick out which
%             %catchment basin in m9watershed corresponds to the
%             %catchment basin we are investigating in this run of onecell.
%                 basin(reg_watershed == catchmentBasin) = true;
%             else
%                 basin(reg_watershed == 1) = true;
%             end
%             %now basin is either 1 everywhere or 1 in the catchment
%             %basin we are investigating.              
%             centr_basin = regionprops(basin,'Centroid');
%             centr_basin = fliplr(round(centr_basin.Centroid +[10 10]));
%             result=false(size(reg_target));
%             if m9watershed(centr_basin) ~= 0;               
%                 cell_edg = false(size(edg));
%                 cell_edg(edg & (m9watershed == m9watershed(centr_basin(1,1),centr_basin(1,2)))) = true;
%                 %pick out just the edges in edg that are in the catchment
%                 %basin of m9watershed which we want.
%                 if sum(sum(cell_edg,1),2)>0
%                     convexprops=regionprops(double(cell_edg),'ConvexImage','BoundingBox'); 
%                     %cell edg needs to be converted to a double to ensure
%                     %convexprops reads all the disconnect objects (the bits
%                     %of edge) as one object.
%                     convhull=convexprops(1).ConvexImage;
%                     boxs=vertcat(convexprops.BoundingBox);
%                     topleftx=ceil(boxs(1,1)) - 10;
%                     toplefty=ceil(boxs(1,2)) - 10;
%                     lengthx=boxs(1,3)-1;
%                     lengthy=boxs(1,4)-1;
%                     if (topleftx>0 && toplefty>0 ) && (topleftx+lengthx<=size(result,2) && toplefty+lengthy <= size(result,1))
%                         %ensure that the object is contained in the actual
%                         %region if interest and doesn't spill over to the
%                         %padding area we added to do the dilation and
%                         %filling earlier.
%                         result(toplefty:toplefty+lengthy,topleftx:topleftx+lengthx)=convhull;                        
%                         s3 = strel('disk',4,4);
%                         result = imerode(result, s3); %attempt to exclude cell wall from final result.                        
%                         props = regionprops(result,'Area','PixelIdxList');
%                         T = vertcat(props([props(:).Area]<=100).PixelIdxList);%all pixels belonging to objects smaller than 10 pixels
%                         result(T) = false;%remove all ojects less than 100 pixels
%                         %below last effort to smooth cell boundaries.
%                         d = 5;
%                         edg = padarray(result,[2*d+1,2*d+1]);
%                         sd =  strel('disk',d,4);
%                         edg = imclose(edg,sd);
%                         result = edg((2*d+2):(2*d+1 +size(result,1)),(2*d+2):(2*d+1 +size(result,2)));                               
%                     end
%                 end
%             end
%         end
%     end
% end