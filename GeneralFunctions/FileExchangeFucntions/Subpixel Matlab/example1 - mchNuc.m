%%
load('/Users/mcrane2/OneDrive/timelapses/HOG_fitness_ramps_newdevice/Mar 16 - shortNoisy ramp - 2minSamples - 3strains wt-ste11-ssk1/cExperiment.mat')
%%
% cTimelapse=cExperiment.returnTimelapse(1);
load('/Users/mcrane2/OneDrive/timelapses/HOG_fitness_ramps_newdevice/Mar 16 - shortNoisy ramp - 2minSamples -3strains wt-ste11-ssk1/pos15cTimelapse.mat')

cTimelapse.extractNucAreaFL('mCherry');
%%
% close all
mChChannel=3;
dicCh=1;
% for tp=50:100
for tp=1:max(find(cTimelapse.timepointsProcessed));
    
    for trapIndex=1:length(cTimelapse.cTimepoint(tp).trapInfo);
        
        % im=cTimelapse.returnTrapsTimepoint(trapIndex,tp,dicCh,'sum');
        % figure(1);imshow(im,[],'InitialMagnification', 500);
        
        im=cTimelapse.returnTrapsTimepoint(trapIndex,tp,mChChannel,'sum');
        
        
        im=double(im);
        im=im/max(im(:))*255;
        image=im;
        % figure(2);imshow(image/255,'InitialMagnification', 500);
        
        % subpixel detection
        threshold = max(max(gradient(image)*.3));
        tic
        % image=medfilt2(image,true(2));
        edges = subpixelEdges(image, threshold, 'SmoothingIter', 1);
        toc
        % show edges
        visEdges(edges);
        
        %
        
        nK=length(cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell);
        
        bwStart=im2bw(image/255,graythresh(image/255)*1.3);
        bwl=bwlabel(bwStart);
        nK=max(bwl(:));
        
        locEdge=[edges.x edges.y];
        [kInd kCent]=kmeans(locEdge,nK);
        
        edgesPerCell=[];
        fieldN=fieldnames(edges);
        for cellInd=1:max(kInd)
            distToCentK=pdist2(kCent(cellInd,:),locEdge(kInd==cellInd,:));
            edgePts=distToCentK<median(distToCentK)*1.5;
            for fieldInd=1:length(fieldN)
                temp=edges.(fieldN{fieldInd})(kInd==cellInd);
                edgesPerCell(cellInd).(fieldN{fieldInd})=temp(edgePts);
            end
            edgesPerCell(cellInd).center=kCent(cellInd,:);
        end
        
        edgesPerCell(cellInd).center
        %
        %% compare to center
        cellMovementThresh=20;
        pt1=[edgesPerCell(:).center];
        pt1=reshape(pt1,length(pt1)/2,2)';
        pt2=[cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell(:).cellCenter];
        pt2=reshape(pt2,length(pt2)/2,2)';
        pt1=double(pt1);
        pt2=double(pt2);
        dist=pdist2(pt1,pt2);
        index=1;
        cellNum=1:size(pt2,1);
        actualCellNum=[];
        for i=1:size(dist,2)
            [val loc]=min(dist(:));
            [row col]=ind2sub(size(dist),loc);
            if val<cellMovementThresh
                %cell number update
                temp_val=cellNum(row);
                actualCellNum(index)=row;
                dist(:,col)=Inf;
                dist(row,:)=Inf;
                index=index+1;
            end
        end
        %%
        
        cellArea=[];
        for cellInd=1:length(edgesPerCell)
            cellCenter=edgesPerCell(cellInd).center;
            X=edgesPerCell(cellInd).x-cellCenter(1);
            Y=edgesPerCell(cellInd).y-cellCenter(2);
            [angles,radii] = cart2pol(X,Y);
            
            image_size=size(im);
            center=cellCenter;
            angles(angles<0)=angles(angles<0)+2*pi;
            
            
            pixel_diff = 0.05;
            angle_diff = pixel_diff/max(radii);
            steps = (0:angle_diff:(2.1*pi))';
            
            %order the angles vector (may not be necessary)
            [~,indices_angles] = sort(abs(angles),1);
            angles=angles(indices_angles);
            radii = radii(indices_angles);
            
            
            % to provide different break points for the spline fitting, and
            % hopefully determin the radii more accurately
            radii_full=[];
            for incSpline=2:1:6
                r_spline = splinefit([angles; angles(1:floor(length(angles)/3))],[radii;radii(1:floor(length(radii)/3))],[0 ;angles(1:incSpline:end); 2*pi],.5,'p',4);%make the spline
                temp=ppval(r_spline,steps);
                radii_full(end+1,:) = temp;
            end
            radii_full=median(radii_full)';
            %convert radial coords to x y coords
            px = round(center(1)+radii_full.*cos(steps));%radial cords
            py = round(center(2)+radii_full.*sin(steps));
            
            %check they are sensible
            px(px<1) = 1;
            px(px>image_size(2)) = image_size(2);
            
            py(py<1) = 1;
            py(py>image_size(1)) = image_size(1);
            
            I = (diff(px)|diff(py));
            px = px(I);
            py = py(I);
            
            imNew=im;
            newVal=max(im(:))*1.5;
            for i=1:length(px)
                imNew(py(i),px(i))=newVal;
            end
            %     figure;imshow(imNew,[]);
            
            X = (center(1)+radii_full.*cos(steps));%radial cords
            Y = (center(2)+radii_full.*sin(steps));
            cellArea(cellInd) = 1/2*abs(sum(X.*Y([2:end,1])-Y.*X([2:end,1])));
        end
        
        for cellInd=1:length(cellArea)
            temp_val=actualCellNum(cellInd);
            cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell(temp_val).nucArea=cellArea(cellInd);
            %     cTimelapse.cTimepoint(tp).trapInfo(trapIndex).cell(temp_val).nucRadius=sqrt(cellArea(cellInd)/pi);
        end
    end
end
