function addRemoveCells(cTimelapse,cCellVision,timepoint,trap,selection,pt, method, channel)
% addRemoveCells(cTimelapse,cCellVision,timepoint,trap,selection,pt, method, channel)
%
% cTimelapse        :   object of the timelapseTraps class
% cCellVision       :   object of the cellVision class
% timepoint         :   the timepoint at which a cell should be added or
%                       removed
% trap              :   index of the trap from which a cell should be added
%                       or removed
% selection         :   string. a type of selection -
%                       add,remove,addPlot or removePlot
% pt                :   the point 'clicked' in [x y] format.
% method            :   string. Passed to identifyCellObjects method of
%                       timelapseTraps. default 'hough'
% channel           :   index of channel. passed to identifyCellObjects method of
%                       timelapseTraps. default is 1.
%
% if selection is 'remove', the cell with its centre nearest to pt is
% identified and removed from the
% cTimelapse.cTimepoint(timpoint).trapInfo(trap) 
% If selection is 'add' a small area around pt is passed as a binary to
% identifyCellObjects method of cTimelapse and this finds the most likely
% centre in this area, its radius, and adds it to cTimelapse at the
% appropriate trap and timepoint. 


if nargin<7
    method='hough';
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
        
        loc = cTimelapse.ReturnNearestCellCentre(timepoint,trap,pt);
        
        if ~isempty(loc)
            
            
            if length(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell)>1
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(loc)=[];
                if loc<=length(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel)
                    % if a cell was added by GUI, it will be added to the
                    % end and not have a cellLabel
                    cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel(loc)=[];
                    
                end
            elseif length(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell)==1
                
                data_template= cTimelapse.defaultTrapDataTemplate;
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell = cTimelapse.cellInfoTemplate;
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell.segmented = data_template;
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellsPresent = false;
                cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel=[];
                
                
                
            end
            
        else %no cells close to click, just make sure fields are as they should be for an empty trap
            data_template= cTimelapse.defaultTrapDataTemplate;
            cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell = cTimelapse.cellInfoTemplate;
            cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell.segmented = data_template;
            cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellsPresent = false;
            cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellLabel=[];
        end
        
        
        %%%%%%%%%%%%%%  Elco : don't think these two are used anymore
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
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%
end