flag=zeros(256,512,3);
% flag([1:86 end-86:end],:,1)=1;
% flag(86:172,:,:)=1;
% figure;imshow(flag,[])
center=1;
for row=1:256
    if center<32 || center>480
        flag(row,[1:center+32 end-32:end],1:3)=1;
        flag(row,center+32:end-32,3)=1;
    else
        flag(row,[center-32:center+32 end-center-32:end-center+32],:)=1;
        flag(row,~[center-32:center+32 end-center-32:end-center+32],3)=1;
    end
    center = center+2;
end