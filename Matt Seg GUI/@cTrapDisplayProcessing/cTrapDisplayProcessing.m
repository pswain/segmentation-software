classdef cTrapDisplayProcessing<handle
    % cTrapDisplayProcessing 
    %
    % a GUI (though with no user interaction) that segments a cTimelapse
    % and shows the result at each iteration. This is the way all
    % segmentation by Matts method is carried out. Applies the
    %
    %       timelapseTraps.identifyCellCentersTrap
    %
    % method to find a decision image and uses the
    %       
    %       timelapseTraps.identifyCellObjects
    %
    % method to use this to identify cell centres and outlines. This object
    % then displays the results on an image of each trap. 
    % As each timepoint is processed the cTimelapse.timepointsProcessed
    % field is updated (true for processed timepoints)
    %
    % Resets the trapInfo field and populates the segCentres sparse logical
    % array (2D array of cell centre regions) which are used in the
    % identifyCellObjects code.
    %
    % note if magnification for cCellVision and cTimelapse is different
    % these will be scaled.
    
    properties
        figure = []; % the figure in which the GUI is displayed
        subImage = []; % array to hold the image handles for each trap image
        subAxes=[]; % array to hold the handles for each sub axis created by subplot
        cTimelapse=[] % cTimelapse object being segmented
        traps=[]; % array of indices of traps to be segmented
        channel=[] % channe; used for display (no necessarily that used in segmentation)
    end % properties

    methods
        function cDisplay=cTrapDisplayProcessing(cTimelapse,cCellVision,timepoints,traps,channel,gui_name)
            % cDisplay=cTrapDisplayProcessing(cTimelapse,cCellVision,timepoints,traps,channel,gui_name)
            %
            % cTimelapse    : object of the timelapseTraps class being
            %                 segmented
            % cCellVision   : object of the cellVision class encoding the
            %                 SVM being used for the segmentation
            % timepoints    : optional. array of timepoints to segment.
            %                 Default is cTimelapse.timepointsToProcess
            % traps         : optional. array of indices traps to segment.
            %                 Default is all traps at timepoint
            %                 timepoints(1).
            % channel       : optional. Index of channel to show, not
            %                 necessarily the one used for the
            %                 segmentation. default is 1.
            % gui_name      : optional. string used to make the name of the
            %                 figure.
            if nargin<3 || isempty(timepoints)
                timepoints=cTimelapse.timepointsToProcess;
            end
            
            if (nargin<4 || isempty(traps)) && cTimelapse.trapsPresent
                traps=1:length(cTimelapse.cTimepoint(timepoints(1)).trapLocations);
            elseif (nargin<4 || isempty(traps)) && ~cTimelapse.trapsPresent
                traps=1;
            end
            
            if nargin<5 || isempty(channel)
                channel=1;
            end
            
            if nargin<6 || isempty(gui_name)
                gui_name='';
            end
            
            cTimelapse=cTimelapse;
            cDisplay.traps=traps;
            cTrap=cTimelapse.cTrapSize;
            cDisplay.figure=figure('MenuBar','none');
            
            dis_w=ceil(sqrt(length(traps)));
            dis_h=max(ceil(length(traps)/dis_w),1);
            trap_images=cTimelapse.returnTrapsTimepoint(traps,timepoints(1),channel);
            trap_images = double(trap_images);
            
            t_width=.9/dis_w;
            t_height=.9/dis_h;
            bb=.1/max([dis_w dis_h+1]);
            index=1;
            for i=1:dis_w
                for j=1:dis_h
                    if index>length(traps)
                        break; end
                    
                    cDisplay.subAxes(index)=subplot('Position',...
                        [(t_width+bb)*(i-1)+bb/2 (t_height+bb)*(j-1)+bb*2 t_width t_height]);

                    cDisplay.subImage(index)=subimage(trap_images(:,:,index)/max(max(trap_images(:,:,index))));
                    
                    set(cDisplay.subAxes(index),'xtick',[],'ytick',[])
                    
                    index=index+1;
                    
                end
                
            end
            pause(.001);
            
            if isempty(cTimelapse.magnification)
                error('\nset the magnification in cTimelapse class\n')
            end

            % just to get an image of the appropriate size - also used
            % later.
            identification_image_stacks = cTimelapse.returnSegmenationTrapsStack(traps,timepoints(1),cCellVision.method);
            d_imCenters = zeros([size(identification_image_stacks{1},1) size(identification_image_stacks{1},2) length(identification_image_stacks)]);
            
            % identifyCellCentres resizes the image if magnification do not
            % match, so need to do the same here.
            %MAGNIFICATION
            if cCellVision.magnification/cTimelapse.magnification ~= 1
                d_imCenters=imresize(d_imCenters,cCellVision.magnification/cTimelapse.magnification);
            end
            trapsProcessed=0;
            tic
            for i=1:length(timepoints)
                timepoint=timepoints(i);
                set(cDisplay.figure,'Name',['Timepoint ' int2str(timepoint),' of ', num2str(max(timepoints))]);
                
                if i>1
                    set(cDisplay.figure,'Name',[gui_name ' Timepoint ' int2str(timepoint-1),' of ', num2str(max(timepoints)),' (',timePerTrap, 's /trap )']);
                    drawnow;
                    
                    trap_images=cTimelapse.returnTrapsTimepoint(traps,timepoints(i),channel);
                    trap_images=double(trap_images);
                    trap_images=trap_images/max(trap_images(:))*.75;
                end
                
                % calculate the decision images used to find segmentation
                % results.
                if i>1 % if i==1 the decision image was retrieved already.
                    identification_image_stacks = cTimelapse.returnSegmenationTrapsStack(traps,timepoint,cCellVision.method);
                end
                [d_imCenters, d_imEdges]=cTimelapse.identifyCellCentersTrap(cCellVision,timepoint,traps,identification_image_stacks,d_imCenters);
                
                % use this decision image  and the
                %       cTimelapse.cTimepoint(timepoint).trapInfo.segCenters
                % field populated by above method to find cell objects
                % (i.e. actually identify centres and outlines)
                cTimelapse.identifyCellObjects(cCellVision,timepoint,traps,channel,'edgeACSnake',[],identification_image_stacks,d_imCenters,d_imEdges);

                
                for j=1:length(traps)
                    trap = traps(j);
                    
                    % create an RGB z stack for the trap
                    image=trap_images(:,:,j);
                    image=double(image);
                    image=image/max(image(:))*.75;
                    image=repmat(image,[1 1 3]);
                    
                    if cTimelapse.cTimepoint(timepoint).trapInfo(trap).cellsPresent
                        seg_areas=[cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell(:).segmented];
                        seg_areas=full(seg_areas);
                        seg_areas=reshape(seg_areas,[size(image,1) size(image,2) length(cTimelapse.cTimepoint(timepoint).trapInfo(trap).cell)]);
                        seg_areas=max(seg_areas,[],3);
                    else
                        seg_areas=false([size(image,1) size(image,2)]);
                    end
                    
                    % make the edge pixels, given by seg_areas, red.
                    t_im=image(:,:,1);
                    t_im(seg_areas)=1;
                    image(:,:,1)=t_im;
                    
                    temp_image{j}=image;
                end

                for j=1:length(traps)
                    image=temp_image{j};
                    set(cDisplay.subImage(j),'CData',image);
                    set(cDisplay.subAxes(j),'CLimMode','manual');
                    set(cDisplay.subAxes(j),'CLim',[min(image(:)) max(image(:))]);
                    
                    trapsProcessed=1+trapsProcessed;
                end
                drawnow;
                
                p_time=toc;
                timePerTrap=num2str(p_time/sum(trapsProcessed),2);
                
                
                cTimelapse.timepointsProcessed(timepoint)=1;
                
            end
            close(cDisplay.figure);
        end
    end
end

