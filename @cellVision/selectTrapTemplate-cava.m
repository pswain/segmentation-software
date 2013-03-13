function selectTrapTemplate(cCellVision,cTimelapse,cTrapFileName)

if nargin<3
    %% Select two cell traps from the first frame to use
    % select the center between the two rectangles, and the bb will extract the
    % rest of the image
    cCellVision.cTrap.bb_width=40;
    cCellVision.cTrap.bb_height=40;
    cCellVision.cTrap.scaling=150;
    
    image=cTimelapse.returnSingleTimepoint(1);
    
    figure(1);imshow(image,[]);title('Select the center of a representative trap with 1 cell')
    [x y]=getpts(gca);
    x=floor(x);y=floor(y);
    cCellVision.cTrap.trap1=image(y-cCellVision.cTrap.bb_height:y+cCellVision.cTrap.bb_height,x-cCellVision.cTrap.bb_width:x+cCellVision.cTrap.bb_width);
%     figure(1);imshow(cCellVision.cTrap.trap1,[])
    figure(1);imshow(image,[]);title('Select the center of a representative trap with several cells')
    [x y]=getpts(gca);
    x=floor(x);y=floor(y);
    cc=normxcorr2(cCellVision.cTrap.trap1,image);
    cc=(imfilter(abs(cc),fspecial('disk',5)));
    cc=cc(cCellVision.cTrap.bb_height+1:end-cCellVision.cTrap.bb_height,cCellVision.cTrap.bb_width+1:end-cCellVision.cTrap.bb_width);
    bw_image=zeros(size(image,1),size(image,2));
    brightpix=1.5;
    if x(1)<size(image,2) && x(1)>0
        bb=floor(cCellVision.cTrap.bb_width/4);
        x=x+bb;
        y=y+bb;
        %     temp_image=padarray(image,[bb bb]);
        for i=1:size(x,1)
            bbimage=cc(y(i)-bb:y(i)+bb,x(i)-bb:x(i)+bb);
            [c, index]=max(bbimage(:));
            [bb_row_correction bb_column_correction]=ind2sub(size(bbimage),index);
            y(i)=y(i)+(bb_row_correction-bb-1);
            x(i)=x(i)+(bb_column_correction-bb-1);
        end
        
    end
    
    
    
    cCellVision.cTrap.trap2=image(y-cCellVision.cTrap.bb_height:y+cCellVision.cTrap.bb_height,x-cCellVision.cTrap.bb_width:x+cCellVision.cTrap.bb_width);
    % cCellVision.cTrap.trap2=cCellVision.cTrap.trap1;
%     figure(2);imshow(cCellVision.cTrap.trap2,[]);
%     figure(1);imshow(cCellVision.cTrap.trap1,[])
%     figure(3);imshow(cc,[])
    
    cCellVision.cTrap.scaling=cCellVision.cTrap.scaling;
    
else
    cCellVision.cTrap=load(cTrapFileName);
end
cCellVision.cTrap.Prior=.5;
cCellVision.cTrap.thresh=.5;
cCellVision.cTrap.thresh_first=.4;

