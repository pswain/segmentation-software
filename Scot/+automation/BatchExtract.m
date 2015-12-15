classdef BatchExtract<automation.ScotAutomate
    properties
        Mothers%Cell array (vector) of double vectors, cell numbers of mother cells to extract data from. Rows = timelapse datasets, Columns=cellnumbers of mother cells
    end
    methods
        function obj=BatchExtract()
            obj.TargetPaths{1}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_01.sct';
            obj.TargetPaths{2}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_02.sct';
            obj.TargetPaths{3}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_03.sct';
            obj.TargetPaths{4}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_04.sct';
            obj.TargetPaths{5}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_05.sct';
            obj.TargetPaths{6}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_06.sct';
            obj.TargetPaths{7}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_07.sct';
            obj.TargetPaths{8}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_08.sct';
            obj.TargetPaths{9}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_09.sct';
            obj.TargetPaths{10}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_10.sct';
            obj.TargetPaths{11}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_11.sct';
            obj.TargetPaths{12}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_12.sct';
            obj.TargetPaths{13}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_13.sct';
            obj.TargetPaths{14}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_14.sct';
            obj.TargetPaths{15}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_15.sct';
            obj.TargetPaths{16}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_16.sct';

            obj.OutputPaths=obj.TargetPaths;%By default will save to the original .sct file
            
            obj.Mothers=[];
            obj.TargetType='file.sct';
            
            obj.MethodStruct(1).methodname='SimpleSpotFind';
            obj.MethodStruct(1).packagename='extractdata';
            obj.MethodStruct(2).methodname='CycleTime';
            obj.MethodStruct(2).packagename='extractdata';
            obj.MethodStruct(3).methodname='CellSize';
            obj.MethodStruct(3).packagename='extractdata';
            obj.MethodStruct(1).parameters.channel='GFP';
            obj.MethodStruct(1).parameters.chidentifier='PRJ';
            obj.MethodStruct(1).parameters.sections=1;
            obj.MethodStruct(1).parameters.measuredsections=1;
            obj.MethodStruct(1).parameters.interval=5;
            obj.MethodStruct(1).parameters.minarea=20;
            obj.MethodStruct(1).parameters.maxarea=200;
        end
        
        function run(obj)
            data=struct;
            for n=1:length(obj.TargetPaths)
                disp(obj.TargetPaths{n});
                tl=Timelapse1.loadTimelapse(obj.TargetPaths{n});
                tl.Data=[];
                a=strfind(tl.Moviedir,filesep);
                tl.Name=tl.Moviedir(a(end)+1:end);
                
                for m=1:length(obj.MethodStruct)
                    
                    %Create an object with the correct parameters - use
                    %setMethodObjField                    
                    obj.MethodStruct(m).methodObj=tl.getobj(obj.MethodStruct(m).packagename,obj.MethodStruct(m).methodname);
                    if ~isempty(obj.MethodStruct(m).parameters)
                        paramNames=fields(obj.MethodStruct(m).parameters);
                        for p=1:length(fields(obj.MethodStruct(m).parameters))
                            param=paramNames{p};
                            tl.setMethodObjField(obj.MethodStruct(m).methodObj.ObjectNumber, param, obj.MethodStruct(m).parameters.(param),true)
                        end
                    end
                    
                    %Run data extraction
                    tl=obj.MethodStruct(m).methodObj.run(tl);
                    %create an additional field in tl.Data showing data
                    %from only the mother cells.
                    %Get the defined mother cells
               
                    if ~isempty(obj.Mothers)
                        if~isempty(obj.Mothers{n})
                            thisTlMothers=obj.Mothers{n};
                            thisTlMothers(isnan(thisTlMothers))=[];
                            tl.Data.([obj.MethodStruct(m).datafield 'mothers'])=tl.Data.(obj.MethodStruct(m).datafield)(thisTlMothers,:);       
                        end
                    end
                end
                %Save the timelapse with the extracted data
                tl.saveTimelapse(obj.OutputPaths{n});
                
                clear tl;
            end
            
        end
        function outputPath=setOutputPath(targetPath)              
              k=regexp(targetPath,'.sct');
              outputPath=[targetPath(1:k-1) 'extr.sct'];
        end
    end
end





