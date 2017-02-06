function correctCellShapeTrapByTrap(cTimelapseOut)

for tp=1:length(cTimelapseOut.cTimepoint)
    
    for trap=1:length(cTimelapseOut.cTimepoint(tp).trapInfo)
        trap_im=cTimelapseOut.returnSegmenationTrapsStack(trap,tp);
        im=min(trap_im{1}(:,:,3),[],3);
        
        temp_im=im;
        bwIm=zeros(size(temp_im))>0;
        if cTimelapseOut.cTimepoint(tp).trapInfo(trap).cellsPresent
            for cellInd=1:length(cTimelapseOut.cTimepoint(tp).trapInfo(trap).cell)
                nseg=8;
                cirrad=cTimelapseOut.cTimepoint(tp).trapInfo(trap).cell(cellInd).cellRadius;
                circen=cTimelapseOut.cTimepoint(tp).trapInfo(trap).cell(cellInd).cellCenter;
                
                temp_im=zeros(size(temp_im))>0;
                x=circen(1,1);y=circen(1,2);r=cirrad(1);
                x=double(x);y=double(y);r=double(r);
                if r<11
                    theta = 0 : (2 * pi / nseg) : (2 * pi);
                elseif r<18
                    theta = 0 : (2 * pi / nseg/1.3) : (2 * pi);
                else
                    theta = 0 : (2 * pi / nseg/1.8) : (2 * pi);
                end
                pline_x = round(r * cos(theta) + x);
                pline_y = round(r * sin(theta) + y);
                loc=find(pline_x>size(temp_im,2) | pline_x<1 | pline_y>size(temp_im,1) | pline_y<1);
                pline_x(loc)=[];pline_y(loc)=[];
                
                %                 [pline_x' pline_y']
                segPts=[];
                [segR segC]=find(cTimelapseOut.cTimepoint(tp).trapInfo(trap).cell(cellInd).segmented>0);
                segLoc=[segC segR];
                for i=1:length(pline_x)
                    pt=[pline_x(i) pline_y(i)];
                    [d ]=pdist2(pt,segLoc,'euclidean');
                    [v loc]=min(d);
                    segPts(i,:)=segLoc(loc(1),:);
                end
%                 for i=1:length(pline_x)
%                     temp_im(pline_y(i),pline_x(i),1)=1;
%                 end
                
                figure(1);imshow(im,[],'InitialMagnification',300);pause(.1);
                title(['Timepoint - ' num2str(tp) ' Trap - ' num2str(trap) ' cell - ' num2str(cellInd)]);
                h = impoly(gca, segPts);
                wait(h);
                bwMask=createMask(h);
                bwEdge=bwmorph(bwMask,'remove');
                cTimelapseOut.cTimepoint(tp).trapInfo(trap).cell(cellInd).segmented=sparse(bwEdge>0);
                bwIm=bwIm|bwEdge;
            end
            figure(2);imshow(bwIm,[]);
        end
    end
end