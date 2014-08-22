allim=[]
for filter=40:70
    
    im=[];
    for i=1:512

        imCol=procd(((i-1)*512+1):i*512,filter);
        im=[im,imCol];
    end

    figure;imshow(im,[]);
end