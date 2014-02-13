classdef BatchScotConvert<automation.ScotAutomate
   properties
       Channels%Cell array of channel identifiers - to be added to the image file list during conversion
   end
   
   methods
       function obj=BatchScotConvert
           obj.TargetPaths{1}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_01/cTimelapse-25 Sept.mat';
           obj.TargetPaths{2}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_02/cTimelapse-25 Sept.mat';
           obj.TargetPaths{3}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_03/cTimelapse-25 Sept.mat';
           obj.TargetPaths{4}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_04/cTimelapse-25 Sept.mat';
           obj.TargetPaths{5}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_05/cTimelapse-25 Sept.mat';
           obj.TargetPaths{6}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_06/cTimelapse-25 Sept.mat';
           obj.TargetPaths{7}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_07/cTimelapse-25 Sept.mat';
           obj.TargetPaths{8}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_08/cTimelapse-25 Sept.mat';
           obj.TargetPaths{9}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_09/cTimelapse-25 Sept.mat';
           obj.TargetPaths{10}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_10/cTimelapse-25 Sept.mat';
           obj.TargetPaths{11}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_11/cTimelapse-25 Sept.mat';
           obj.TargetPaths{12}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_12/cTimelapse-25 Sept.mat';
           obj.TargetPaths{13}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_13/cTimelapse-25 Sept.mat';
           obj.TargetPaths{14}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_14/cTimelapse-25 Sept.mat';
           obj.TargetPaths{15}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_15/cTimelapse-25 Sept.mat';
           obj.TargetPaths{16}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_16/cTimelapse-25 Sept.mat';

           obj.Channels={'PRJ'};
       end
       
       
       function run(obj)
       
           for n=1:length(obj.TargetPaths)
               load(obj.TargetPaths{n});
               %Convert to a Scot timelapse object
               tl=inputoutput.scotConvert(cTimelapse);
               k=strfind(cTimelapse.timelapseDir,'/');
               path=cTimelapse.timelapseDir(1:k(end));
               name=cTimelapse.timelapseDir(k(end)+1:end);
               disp (name);
               for ch=1:length(obj.Channels)
                   tl.addImageFileList(obj.Channels{ch},[path name],obj.Channels{ch},1);
               end
               obj.OutputPaths{n}=obj.setOutputPath(obj.TargetPaths{n});
               tl.saveTimelapse(path,[name '.sct']);
               disp(['Timelapse' name 'saved']);
               clear cTimelapse;
               clear tl;          
           end          
       end
   end
      methods (Static)
          function outputPath=setOutputPath(targetPath)
              
              k=regexp(targetPath,'.mat');
              outputPath=[targetPath(1:k-1) '.sct'];
          end
   end
   
    
    
    
end