function [ upDown ] = getUpDown( savefile )
%GETUPDOWN get a matrix where 1 means that whi5 is currently localised qand
%a 0 means that it is not
upDown=zeros(size(savefile.upslopes));
for i=1:length(savefile.upslopes(:,1))
    for j=1:length(savefile.upslopes(1,:))
        if savefile.upslopes(i,j)==1
            for k=j:length(savefile.upslopes(1,:))
                upDown(i,k)=1;
                if savefile.downslopes(i,k)==1;
                    break
                end
            end
        end
        
        if savefile.downslopes(i,j)==1
           for k=j:-1:1
                upDown(i,k)=1;
                if savefile.upslopes(i,k)==1;
                    break
                end
            end
        end
    end
end


end

