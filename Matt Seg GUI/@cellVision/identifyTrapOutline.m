function identifyTrapOutline(cCellVision)
% identifyTrapOutline(cCellVision)
% extracts the outline of the trap from cCellVision.cTrap.trap1.
%
% each feature is selected by user interface and the active contour method
% used to detect the outline. The user is then invited to edit the outline
% for that feature until they are satisfied. In the end, the masks for the
% two features are combined and this is becomes the property.
%       cCellVision.cTrap.trapOutline
%
% This is a function that is reasonably swain-lab specific. If your traps
% have more than 2 features, or are concave, this function will have to be
% modified or replaced.
%
% See also ACBACKGROUNDFUNCTIONS.EDIT_AC_MANUAL

if ~isempty(cCellVision.cTrap)
    im = cCellVision.cTrap.trap1;
    imflat = false([size(im) 2]);
    
    for i=1:2
        
        h = figure;
        imshow(im,[]);

        if i==1
            fprintf('please select the centre of one of the two traps\n')
        else
            fprintf('please select the centre of the other trap\n')
        end
        
        [loc(1), loc(2)]=ginput(1);
        PntX = loc(1);
        PntY = loc(2);
        close(h);
        
        % this is a paired down version of the active contour procedure
        % used on cells.
        
        % THese parameters were chosen as being ok. Could certainly be
        % improved but doesn't seem worth it given the rarity with which
        % this needs to be done.
        ImageTransformParameters = struct('postprocessing','invert');
        ACparameters = struct('alpha',0.1,'beta',0,'R_min',3,'R_max',max(size(im)),'opt_points',25,...
            'visualise',0,'EVALS',3000,'spread_factor',1,'spread_factor_prior',0.05,'seeds_for_PSO',30,'seeds',100,'TerminationEpoch',500,'MaximumRadiusChange',Inf);
        
        TrapImage = double(cCellVision.cTrap.trap1);
        TrapImage = TrapImage/median(TrapImage(:));
        ForcingImage = ACBackGroundFunctions.get_cell_image(TrapImage,min(size(TrapImage),[],2),[PntX PntY]);
        
        %[RadiiRes,AngleRes] = ACMethods.PSORadialTimeStack(ForcingImage,ACparameters,ceil(size(ForcingImage)/2));
        
        RadiiRes = 5*ones(1,ACparameters.opt_points);
        AngleRes = linspace(0,2*pi,ACparameters.opt_points+1);
        AngleRes = AngleRes(1:ACparameters.opt_points);
        
        fprintf('please edit the outline by clicking on the image and press enter when you are satisfied\n ')
        
        [RadiiRes,AngleRes] = ACBackGroundFunctions.edit_AC_manual(TrapImage,[PntX PntY],RadiiRes',AngleRes');
        
        SegmentationBinary = ACBackGroundFunctions.get_outline_from_radii(RadiiRes,AngleRes,[PntX PntY],size(TrapImage));
        
        
        imflat(:,:,i) = SegmentationBinary;
        
    end
    imflat=max(imflat,[],3);
    cCellVision.cTrap.contour=imflat;
    
    imflat=imfill(imflat,'holes');
    
    
    h=figure;
    imshow(OverlapGreyRed(im,imflat,[],[],true),[]);
    fprintf('\nDisplayed is the final trap outline. Please close when ready\n\n')
    title('Final Trap Outline - close when ready');
    uiwait(h);
    cCellVision.cTrap.trapOutline=imflat>0;
    cCellVision.se.trap = [];
    % this field is a slightly mysterious structure added by matt that has
    % blurry edge pixels in it. Setting it to zero causes it to be
    % reconstructed
    %TODO - get rid of the above line?
    
else
    errordlg('There are no traps in this timelapse');
end




