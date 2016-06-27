classdef FlowInTrap
    %FLOWINTRAP cell moves differently in different part of the trap based
    %on physicaly constraints and fluid flow.
    
    % divides radius min to max into 5 bins.
    % makes a gaussian for 
    
    properties
        flowLookUpTable
        sizeLookUpTable
        locMap
        radius_bins
    end
    
    methods
        function self = FlowInTrap(cTimelapse, cCellVision)

            %size look up
            bin_number = 6;
            self.radius_bins = linspace(cCellVision.radiusSmall,cCellVision.radiusLarge,bin_number);
            jump_size = linspace(cCellVision.radiusSmall,0.3*cCellVision.radiusLarge,(bin_number-1));
            prior_size = cTimelapse.ACParams.CrossCorrelation.ProspectiveImageSize;
            self.sizeLookUpTable = zeros([prior_size prior_size (bin_number-1)]);
            for ri = 1:(bin_number-1)
                prior = fspecial('gaussian',[prior_size prior_size],jump_size(ri)); 
                prior = prior./max(prior(:));
                self.sizeLookUpTable(:,:,ri) = prior;
            end
            
            %flowLookUp
            downstream_jump = 2*cCellVision.radiusSmall;
            centre_jump = cCellVision.radiusSmall;
            upstream_jump = 2*cCellVision.radiusSmall;
            
            self.locMap = self.processTrapOutline(cCellVision.cTrap.trapOutline,cCellVision.radiusSmall);
            
            prior_1 = fspecial('gaussian',prior_size,downstream_jump);
            [~,angle] = ACBackGroundFunctions.radius_and_angle_matrix([prior_size,prior_size]);
            prior_1 = prior_1.*cos(angle);
            prior_1(:,1:(floor(prior_size/2))) = 0;
            prior_1 = prior_1./max(prior_1(:));
            
            prior_2 = fspecial('gaussian',prior_size,centre_jump);
            prior_2 = prior_2./max(prior_2(:));
            
            prior_3 = fspecial('gaussian',prior_size,upstream_jump);
            [~,angle] = ACBackGroundFunctions.radius_and_angle_matrix([prior_size,prior_size]);
            prior_3 = -1*prior_3.*cos(angle);
            prior_3(:,(ceil(prior_size/2)):end) = 0;
            prior_3 = prior_3./max(prior_3(:));
            
            self.flowLookUpTable = cat(3, prior_1, prior_2, prior_3);
            
        end
        
        function locMap = processTrapOutline(self,trapOutline,r_min)
            % makes a map: 1 downtream, 2 in middle, 3 upstream
            locMap = ones(size(trapOutline));
            middle_x = any(trapOutline,1);
            last_x = find(middle_x,1,'first');
            first_x = find(middle_x,1,'last') - r_min;
            locMap(:,1:last_x) = 3;
            locMap(:,last_x:first_x) = 2;
            locMap(:,first_x:end) = 1;
            
            
            
            
        end
        
        
        function prior_array = returnPrior(self,cell_loc,cell_radius)
           %prior_array = returnPrior(self,cell_loc,cell_radius)
            cell_loc_index = self.locMap(cell_loc(2), cell_loc(1));
            loc_prior = self.flowLookUpTable(:,:,cell_loc_index);

            size_index = find(self.radius_bins(1:(end-1))<=cell_radius & self.radius_bins(2:(end))>cell_radius);
            size_prior = self.sizeLookUpTable(:,:,size_index);
            
            prior_array =  (size_prior+loc_prior)/2;
     
        end
    end
    
end

