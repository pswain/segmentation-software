function addRemoveCells(cTimelapse,cCellVision,timepoint,trap,selection,pt, method, channel)

%pt = [x y] selection
%selection = 'add' or 'remove'
%

if nargin<7
    method='hough'
end

if nargin<8
    channel=1;
end


cellPt=pt;

switch selection
    case 'add'
        if cTimelapse.magnification<100
            bw=zeros(size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented));
            bw(pt(1,2),pt(1,1))=1;
            bw=imdilate(bw,strel('disk',3));
            cTimelapse.identifyCellObjects(cCellVision,timepoint,trap,channel,method,bw);
        else
            bw=zeros(size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented));
            bw(pt(1,2),pt(1,1))=1;
            bw=imdilate(bw,strel('disk',10));
            cTimelapse.identifyCellObjects(cCellVision,timepoint,trap,channel,method,bw);
        end
    case 'remove'
        try
            pts=[];
            
            circen=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).cellCenter];
            circen=reshape(circen,2,length(circen)/2)';
            pts=double(circen);
            if size(pts,1)
                aPointMatrix = repmat(cellPt,size(pts,1),1);
                D = (sum(((aPointMatrix-pts).^2), 2)).^0.5;
%                 D = pdist2(pts,cellPt,'euclidean');
                [minval loc]=min(D);
                
                if length(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell)>1
                    cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(loc)=[];
                else
                    cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(1).cellCenter=[];
                    cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(1).cellRadius=[];
                    cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(1).segmented=sparse(zeros(size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(1).segmented))>0);
                    cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellsPresent = false;
                end
                %                 cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellRadius(loc)=[];
                %                 if size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented,3)>1
                %                     cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented(:,:,loc)=[];
                %                 else
                %                     cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented=zeros(size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented(:,:,1)))>1;
                %                 end
            else
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented=zeros(size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented(:,:,1)))>1;
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(1).cellCenter=[];
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(1).cellRadius=[];
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(1).segmented=sparse(zeros(size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(1).segmented))>0);
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellsPresent = false;
            end
%         catch
%             cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented=zeros(size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented(:,:,1)))>1;
%             cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellCenters=[];
%             cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellRadius=[];
        end
        
    case 'addPlot'
        bw=zeros(size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented(:,:,1)));
        bw(pt(1,2),pt(1,1))=1;
        bw=imdilate(bw,strel('disk',3));
        cTimelapse.identifyCellObjects(cCellVision,timepoint,trap,channel,method,bw)             
    case 'removePlot'
        try
            pts=[];
            pts(:,1)=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellCenters(:,1)];
            pts(:,2)=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellCenters(:,2)];
            if size(pts,1)
                aPointMatrix = repmat(cellPt,size(pts,1),1);
                D = (sum(((aPointMatrix-pts).^2), 2)).^0.5;
%                 D = pdist2(pts,cellPt,'euclidean');
                [minval loc]=min(D);
                
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellCenters(loc,:)=[];
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellRadius(loc)=[];
                if size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented,3)>1
                    cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented(:,:,loc)=[];
                else
                    cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented=zeros(size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented(:,:,1)))>1;
                end
            else
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented=zeros(size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented(:,:,1)))>1;
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellCenters=[];
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellRadius=[];
            end
        catch
            cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented=zeros(size(cTimelapse.cTimepoint(timepoint).trapInfo(trap).segmented(:,:,1)))>1;
            cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellCenters=[];
            cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellRadius=[];
        end
end