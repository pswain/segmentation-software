function distance= alternativeDist(cTimelapse,pt1,pt2)
%Returns a 2x2 matrix of the distances between all the cells tracked in pt1&pt2
%Rows denote previous timeframe cells, collumns denote current timeframe
%cells
if ~isempty(pt1) && ~isempty(pt2)
    dist=[];
    for i=1:size(pt1,2)
        b=pt2(:,i);
        a=pt1(:,i);
        b=b';
        anew= repmat(a,1,size(b,2));
        bnew= repmat(b,size(a,1),1);
        temp=(((bnew-anew)));
        dist(:,:,i) = temp;
    end
    temp=dist(:,:,3);
    temp2=dist(:,:,3);
    
    %if cells grow by one, don't punish at all
    if find(temp2==1)
        loc=temp2>1;
        temp(loc)=0;
    end
    
    if find(temp<0)
        %If cell shrinks, then penalize a lot
        loc=temp<0;
        tempFracShrink=(bnew-anew)./bnew;
        tempFracShrink=(tempFracShrink)*10;

%         temp(loc)=temp(loc).^2;
%         temp(loc)=(temp(loc).^2)*1.5;
        temp(loc)=(tempFracShrink(loc).^1.8);%*1.5;

    end
    if find(temp2>1)
        %if a cell grow a lot, penalize it
        tempFracGrow=(bnew-anew)./bnew;
        tempFracGrow=(tempFracGrow)*10;

        loc=temp2>1;
%         temp(loc)=temp(loc).^1.5;
        
        temp(loc)=tempFracGrow(loc).^1.1;
    end
    dist(:,:,3)=temp;
    
    distance=sqrt(sum(dist.^2,3));
else
    distance=[];
end
end