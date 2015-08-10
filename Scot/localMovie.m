function localMovie(tl,cellnumber,directory)
    for t=1:tl.TimePoints
        cellnumbers=[tl.TrackingData(t).cells.cellnumber];
        trackno=cellnumbers==cellnumber;
        if ~isempty(trackno)
           DIC=imread([tl.ImageFileList(1).directory filesep tl.ImageFileList(1).file_details(t).timepoints.name]);
           GFP=zeros(512,512,3);
           for n=1:3%3 GFP sections
               GFPall(:,:,n)=imread([tl.ImageFileList(2).directory filesep tl.ImageFileList(2).file_details(t).timepoints(n).name]);
           end
           GFP=max(GFPall,[],3);%Maximum projection;
           region=tl.TrackingData(t).cells(trackno).region;
           DICregion=DIC(region(2):region(2)+region(4)-1,region(1):region(1)+region(3)-1);
           GFPregion=GFP(region(2):region(2)+region(4)-1,region(1):region(1)+region(3)-1);
           GFPs1=GFPall(region(2):region(2)+region(4)-1,region(1):region(1)+region(3)-1,1);
           GFPs2=GFPall(region(2):region(2)+region(4)-1,region(1):region(1)+region(3)-1,2);
           GFPs3=GFPall(region(2):region(2)+region(4)-1,region(1):region(1)+region(3)-1,3);

           
           GFPregion=im2uint8(GFPregion./max(GFPregion(:)));
           

           
           
           imwrite(DICregion,[directory filesep 'DIC' num2str(t),'.tif']);
           imwrite(GFPregion,[directory filesep 'GFP' num2str(t),'.tif']);
           
           imwrite(GFPs1,[directory filesep 'GFPs1' num2str(t),'.tif']);
           imwrite(GFPs2,[directory filesep 'GFPs2' num2str(t),'.tif']);
           imwrite(GFPs3,[directory filesep 'GFPs3' num2str(t),'.tif']);

            
        end
    end



end