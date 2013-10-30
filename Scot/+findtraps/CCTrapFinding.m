classdef CCTrapFinding<findtraps.TrapFindingMethods
    methods
        function obj=CCTrapFinding(varargin)
            % LoopRegions --- constructor for LoopRegions, initialises timepoint segmethods object for: identify regions as binary image then loop through them, segmenting each in turn
            %
            % Synopsis:  loopregionsobj = LoopRegions()
            %            loopregionsobj = LoopRegions(parameters)
            %                        
            % Input:     parameters = cell array in standard matlab input format: {'Parameter1name',parameter1value,'Parameter2name',etc...
            %
            % Output:    loopregionsobj = object of class LoopRegions

            % Notes:     This constructor creates an object that can be
            %            used to segment cells within a single timepoint.
            %            It does not store data, only provides segmentation
            %            methods and stores parameters that the methods use
            obj.requiredFields={'TrapTemplate','TrapPrior','CurrentCC'};
            obj.parameters = struct;
            obj.parameters.threshmethod='Huang';%default region finding method
            obj.parameters.trapBBwidth=60;%default bounding box of trap width
            obj.parameters.trapBBheight=60;%default bounding box of trap height

            obj=obj.changeparams(varargin{:});
        end
        function timepointObj=initializeFields(obj, timepointObj)
            if size(obj.requiredFields,1)>0
                for f=1:size(obj.requiredFields,1)
                    switch char(obj.requiredFields(f))
                        case 'TrapTemplate'                            
                            if ~isfield (timepointObj.Timelapse.RequiredImages,'TrapTemplate')
                                
                                image=timepointObj.Target;
                                
                                figure(1);imshow(image,[]);title('Select the center of a representative trap with 1 cell')
                                [x y]=getpts(gca);
                                x=floor(x);y=floor(y);
                                timepointObj.Timelapse.RequiredImages.TrapTemplate.trap1=image(y-obj.parameters.trapBBheight:y+obj.parameters.trapBBheight,x-obj.parameters.trapBBwidth:x+obj.parameters.trapBBwidth);
                                %     figure(1);imshow(cCellVision.cTrap.trap1,[])
                                figure(1);imshow(image,[]);title('Select the center of a representative trap with several cells')
                                [x y]=getpts(gca);
                                x=floor(x);y=floor(y);
                                cc=normxcorr2(cCellVision.cTrap.trap1,image);
                                cc=(imfilter(abs(cc),fspecial('disk',2)));
                                cc=cc(obj.parameters.trapBBheight+1:end-obj.parameters.trapBBheight,obj.parameters.trapBBwidth+1:end-obj.parameters.trapBBwidth);
                                if x(1)<size(image,2) && x(1)>0
                                    bb=floor(obj.parameters.trapBBwidth/4);
                                    x=x+bb;
                                    y=y+bb;
                                    for i=1:size(x,1)
                                        bbimage=cc(y(i)-bb:y(i)+bb,x(i)-bb:x(i)+bb);
                                        [c, index]=max(bbimage(:));
                                        [bb_row_correction bb_column_correction]=ind2sub(size(bbimage),index);
                                        y(i)=y(i)+(bb_row_correction-bb-1);
                                        x(i)=x(i)+(bb_column_correction-bb-1);
                                    end
                                    
                                end
                                timepointObj.Timelapse.RequiredImages.TrapTemplate.trap2=image(y-obj.parameters.trapBBheight:y+obj.parameters.trapBBheight,x-obj.parameters.trapBBwidth:x+obj.parameters.trapBBwidth);

                            end
                        
                        case 'PreviousCC'
                            if ~isfield (timepointObj.Timelapse.RequiredImages,'TrapPrior')
                                %First create the Timepoint.Bin field by running a findregions method    
                                
                            end
                            
                        case 'CurrentCC'
                            timepoint_im=double(timepointObj.Target);
                            timepoint_im=timepoint_im*100/median(timepoint_im(:));
                            image_temp=padarray(timepoint_im,[obj.parameters.trapBBheight obj.parameters.trapBBwidth],median(timepoint_im(:)));
                            
                            cc=normxcorr2(timepointObj.Timelapse.RequiredImages.TrapTemplate.trap1,image_temp)+normxcorr2(timepointObj.Timelapse.RequiredImages.TrapTemplate.trap2,image_temp);
                            cc=cc(obj.parameters.trapBBheight+1:end-obj.parameters.trapBBheight,obj.parameters.trapBBwidth+1:end-obj.parameters.trapBBwidth);
                            cc_new=zeros(size(cc,1),size(cc,2));
                            cc_new(obj.parameters.trapBBheight*1.5:end-obj.parameters.trapBBheight*1.5,obj.parameters.trapBBwidth*1.5:end-obj.parameters.trapBBwidth*1.5)=cc(obj.parameters.trapBBheight*1.5:end-obj.parameters.trapBBheight*1.5,obj.parameters.trapBBwidth*1.5:end-obj.parameters.trapBBwidth*1.5);
                            cc=cc_new;
                            
                            cc=(imfilter(abs(cc),fspecial('disk',3)));
                            sigma=.1;
                            h(:,:,1) = fspecial('gaussian', 10, sigma);
                            h(:,:,2) = fspecial('gaussian', 10, 10*sigma);
                            for index=1:size(h,3)
                                g(:,:,index)=imfilter(cc,h(:,:,index),'replicate');
                            end
                            temp_im=abs(g(:,:,1)-g(:,:,2));
                            
                            cc=temp_im;
                            cc_original=temp_im;
%                             cTrapPrior.trap_mask=zeros(size(cc,1),size(cc,2));
%                             for r=1:length(cTrapPrior.xcenter)
%                                 cTrapPrior.trap_mask(cTrapPrior.ycenter(r)+obj.parameters.trapBBheight,cTrapPrior.xcenter(r)+obj.parameters.trapBBwidth)=1;
%                             end
%                             stemp=strel('disk',12);
%                             cTrapPrior.trap_mask=imdilate(cTrapPrior.trap_mask,stemp)>0;
%                             
                            if length(cTrapPrior.cc)
                                cTrapPrior.cc=imdilate(cTrapPrior.cc,strel('disk',7));
                                
                                cc(cTrapPrior.trap_mask)=cTrap.Prior*(cTrapPrior.cc(cTrapPrior.trap_mask))+cc(cTrapPrior.trap_mask);
                                cc(cTrapPrior.trap_mask)=cTrap.Prior*(cTrapPrior.cc(cTrapPrior.trap_mask))+cc(cTrapPrior.trap_mask);

                                
                            else
                                cTrapPrior.cc=zeros(size(cc,1),size(cc,1));
                            end
                            cc_withprior=cc;
                            
                            [max_im_cc, imax] = max(cc(:));
                            max_cc=max_im_cc;
                            trap_index=1;
                            cTrap.trap_mask=false(size(cc,1),size(cc,2));
                            
                            while max_cc> cTrap.thresh*max(cc_original(:)) | trap_index<=cTrapPrior.num_traps
                                [ypeak, xpeak] = ind2sub(size(cc),imax(1));
                                corr_offset = [ (ypeak+size(cTrap.trap1,1)/2) (xpeak+size(cTrap.trap1,2)/2) ];
                                cc(ypeak-obj.parameters.trapBBheight*1:ypeak+obj.parameters.trapBBheight*1,xpeak-obj.parameters.trapBBwidth*1:xpeak+obj.parameters.trapBBwidth*1)=0;
                                
                                %     cTimepoint.trap_mask(ypeak-obj.parameters.trapBBheight:ypeak+obj.parameters.trapBBheight,xpeak-obj.parameters.trapBBwidth:xpeak+obj.parameters.trapBBwidth)=logical(ones(size(cTrap.trap1,1),size(cTrap.trap1,2)));
                                %     cTrap(trap_index).image=image_temp(ypeak-obj.parameters.trapBBheight:ypeak+obj.parameters.trapBBheight,xpeak-obj.parameters.trapBBwidth:xpeak+obj.parameters.trapBBwidth);
                                xcenter=xpeak-obj.parameters.trapBBwidth;
                                ycenter=ypeak-obj.parameters.trapBBheight;
                                cTrap.xcenter(trap_index)=xcenter;
                                cTrap.ycenter(trap_index)=ycenter;
                                cTrap.trap_mask(ypeak-obj.parameters.trapBBheight:ypeak+obj.parameters.trapBBheight,xpeak-obj.parameters.trapBBwidth:xpeak+obj.parameters.trapBBwidth)=true(size(cTrap.trap1,1),size(cTrap.trap1,2));
                                %     figure(1);imshow(cc,[]);colormap(jet);pause(.5)
                                %     figure(2);imshow(cTimepoint.trap_mask,[]);pause(.5)
                                trap_index=trap_index+1;
                                [max_cc, imax] = max(cc(:));
                                
                            end
                            cTrapPrior.cc=cc_original;
                            cTrapPrior.num_traps=trap_index-1;
                            cTrap.trap_mask=cTrap.trap_mask(obj.parameters.trapBBheight+1:end-obj.parameters.trapBBheight,obj.parameters.trapBBwidth+1:end-obj.parameters.trapBBwidth);
                    end
                end
            end
        end
        function timepointObj=run(obj, timepointObj)
            % run --- run function for LoopRegions, segments cells by thresholding regions and looping through them.
            %
            % Synopsis:  timepointObj = run(obj,timepointObj)
            %                        
            % Input:     obj = an object of class LoopRegions
            %            timepointObj = an object of a Timepoint class
            %
            % Output:    timepointObj = an object of a Timepoint class

            % Notes:
            timepointObj.Timelapse.CurrentCell=1;
            
            %Get properties of the connected objects defined by timepointObj.Bin
            STATS=regionprops(timepointObj.Bin,'Area','BoundingBox', 'Solidity','Image');
            areas=vertcat(STATS.Area);
            objects=areas>=obj.parameters.minsize;
            STATS(objects==0)=[];
            boxes=vertcat(STATS.BoundingBox);
            numObjects=size(boxes,1);
            for n=1:numObjects%loop through the objects finding the pixels that represent cell interiors
                ulx=ceil(boxes(n,1));
                uly=ceil(boxes(n,2));%x and y coordinates of upper left corner of this object
                xlength=round(boxes(n,3));
                ylength=round(boxes(n,4));
                %create a region object using the bounding box just
                %defined. Use the new segmentation version of the region
                %constructor method. 
                disp(strcat('segmenting region',num2str(n)));%comment for speed
                region=Region3(timepointObj,timepointObj.Timelapse,[ulx uly xlength ylength]);
                timepointObj.Timelapse.showProgress(timepointObj.Target);
            end
        
            end
    end
end