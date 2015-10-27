function selectTrapTemplate(cCellVision,cTimelapse,cTrapFileName)

if nargin<3
    %% Select two cell traps from the first frame to use
    % select the center between the two rectangles, and the bb will extract the
    % rest of the image
    if cTimelapse.trapsPresent
        prompt={'bounding box width:', 'bounding box height:'};
        dlg_title = 'Trap bounding box dimensions';
        num_lines = 1;
        def = {'40','40'};
        options.Resize='on';
        options.WindowStyle='normal';
        answer = inputdlg(prompt,dlg_title,num_lines,def,options);
        cCellVision.cTrap.bb_width=str2double(answer{2});
        cCellVision.cTrap.bb_height=str2double(answer{1});
        cCellVision.cTrap.scaling=150;
        
        image=cTimelapse.returnSingleTimepoint(1);
        
        h=figure;set(gcf,'name','Select the center of a representative trap with  no cell','NumberTitle','off');imshow(image,[]);
        [x y]=getpts(gca);
        x=floor(x);y=floor(y);
        cCellVision.cTrap.trap1=image(y-cCellVision.cTrap.bb_height:y+cCellVision.cTrap.bb_height,x-cCellVision.cTrap.bb_width:x+cCellVision.cTrap.bb_width);
        close(h);
        figure;imshow(cCellVision.cTrap.trap1,[]);uiwait();
        
        
        h=figure;set(gcf,'name','Select the center of a representative trap with one cell','NumberTitle','off');imshow(image,[]);
        [x y]=getpts(gca);
        close(h);
        x=floor(x);y=floor(y);
        cc=normxcorr2(cCellVision.cTrap.trap1,image);
        cc=(imfilter(abs(cc),fspecial('disk',2)));
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
        figure;imshow(cCellVision.cTrap.trap2,[]);uiwait();
        %     figure(2);imshow(cCellVision.cTrap.trap2,[]);
        %     figure(1);imshow(cCellVision.cTrap.trap1,[])
        %     figure(3);imshow(cc,[])
        
        cCellVision.cTrap.scaling=cCellVision.cTrap.scaling;
        cCellVision.cTrap.Prior=.5;
        cCellVision.cTrap.thresh=.5;
        cCellVision.cTrap.thresh_first=.4;
    else
        errordlg('There are no traps in this timelapse');
        cCellVision.cTrap=[];
    end
    
else
    cCellVision.cTrap=load(cTrapFileName);
    cCellVision.cTrap.Prior=.5;
    cCellVision.cTrap.thresh=.5;
    cCellVision.cTrap.thresh_first=.4;
end


