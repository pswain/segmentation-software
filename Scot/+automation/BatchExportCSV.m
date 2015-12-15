classdef BatchExportCSV<automation.ScotAutomate
    properties
    end
    methods
        function obj=BatchExportCSV()
            
            obj.TargetType='file.sct';
            %obj.getTargetPaths;        
            obj.TargetPaths{1}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_01.sct';
            obj.TargetPaths{2}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_02.sct';
            obj.TargetPaths{3}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_03.sct';
            obj.TargetPaths{4}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_04.sct';
            obj.TargetPaths{5}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_05.sct';
            obj.TargetPaths{6}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_06.sct';
            obj.TargetPaths{7}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_07.sct';
            obj.TargetPaths{8}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_08.sct';
            obj.TargetPaths{9}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_09.sct';
            obj.TargetPaths{11}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_10.sct';
            obj.TargetPaths{10}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_11.sct';
            obj.TargetPaths{12}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_12.sct';
            obj.TargetPaths{13}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_13.sct';
            obj.TargetPaths{14}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_14.sct';
            obj.TargetPaths{15}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_15.sct';
            obj.TargetPaths{16}='/Volumes/cse/biology/ismb/swain/Swainlab/Cellasic data (Hille) for training/2_9_13/050313Hog1delGFPNaCl/050313_16.sct';

            obj.OutputPaths{1}=[pwd filesep 'ScotDataFile2.csv'];
            
        end
        
        function run(obj)
            % run --- Saves the .Data fields from several timelapses to a csv file
            %
            % Synopsis:  run (obj)
            %
            % Input:     obj = an object of class BatchExportCSV
            %
            % Output:    Written to .csv file
            
            % Notes:
            
            dataFile=fopen(obj.OutputPaths{1},'w');%Then can write to file later using fprintf(dataFile,'string goes here');
            fprintf(dataFile,'%s','Single Cells Over Time - data file');
            fprintf(dataFile,'\r\n');
            today=date;
            fprintf(dataFile,'%s',today);
            fprintf(dataFile,'\r\n');
            
            for n=1:length(obj.TargetPaths)
                data=load(obj.TargetPaths{n},'Data','-mat');
                data=data.Data;
                if n==1
                    allData=data;
                else
                    fieldNames=fields(data);
                    for f=1:length(fieldNames)
                        thisField=fieldNames{f};
                        allData.(thisField)(end+1:end+1+size(data.(thisField),1),:)=data.(thisField);
                    end
                end    
            end
            disp('stop');
            
            
        end
    end
end