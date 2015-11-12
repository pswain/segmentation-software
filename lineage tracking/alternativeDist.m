function distance= alternativeDist(pt1,pt2)
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
    if find(temp<0)
        loc=temp<0;
%         temp(loc)=temp(loc).^2;
        temp(loc)=temp(loc).^2*1;

    end
    dist(:,:,3)=temp;
    
    distance=sqrt(sum(dist.^2,3));
else
    distance=[];
end
end