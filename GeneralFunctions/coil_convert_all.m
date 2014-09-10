function coil_convert(output_filename,output_dir,file_input)
%small function to take a *.lif file and convert save each of the images
%separately as .png files (so in the way our microscope saves them). They
%are saved in a slected directory as 'output_filename_tp_DIC.png' and 'output_filename_tp_GFP.png'

%currently only works if each channel is present in each series and each
%timepoint. Could be easily ammended using regexp.
path_input = '';

if nargin<3
fprintf('please select microscope file to convert\n')
[file_input,path_input] = uigetfile({'*.*','All Files'},'select microscope file','All Files');
end
if nargin<2
fprintf('please select directory in which to store converted images\n')
output_dir = uigetdir([path_input file_input],'pick output directory');
end
if nargin==0
    output_filename =  inputdlg('please provide an output file identifier.\nThis will be used to construct the names of files produced'...
        ,'shared identifier for all output files',1,{'output_file'});
    output_filename = output_filename{1};
end

try
im = bfopen([path_input file_input]);
catch BFerror
    
    fprintf('\n \n problem with bfopen, probably you have not selected a supported file format \n \n')
    
    error(BFerror)
    
end

%number of channels in the image
NChannels = 0;

for seriesi = 1:size(im,1)%loop over image series
    
    fprintf('saving series %d of %d\n',seriesi,size(im,1))
    
    %get total number of timepoints
%     Tloc = regexp(im{1,1}{1,2},'T=.*/','end');
%     Tloc = Tloc(end);
%     TTotal = regexp(im{1,1}{1,2}((Tloc+1):end),'(\d)*','tokens');
%     TTotal = str2double(TTotal{1}{1});
TTotal= size(im{1},1);
    
    %number of channels
    
    NChannelsTEMP = size(im{seriesi,1},1)/TTotal;
    
    if NChannels~=NChannelsTEMP
        ProposedChannelNames = {};
        PromptChannelNames = {};
        NChannels = NChannelsTEMP;
        
        for channeli = 1:NChannels
            
            ProposedChannelNames{channeli} = ['CHAN' int2str(channeli-1)];
            PromptChannelNames{channeli} = ['Tag of channel ' int2str(channeli)];
            
        end
        
            ProposedChannelNames{1} = 'DIC';
            
        ChannelTags = inputdlg(PromptChannelNames,'channel tags for constructing file names',1,ProposedChannelNames);
        
    end
    
    %make directory
    mkdir(output_dir, ['pos' int2str(seriesi)]);
            
    for tpi = 1:TTotal%loope over timepoints
        for channeli = 1:NChannels
            
            %write files to the outputdir/pos(series number)/output_filename_tag.png
            imwrite(im{seriesi,1}{NChannels*(tpi-1)+channeli,1},[output_dir '/pos' int2str(seriesi) '/' output_filename '_' tp2str(tpi,3) '_'  ChannelTags{channeli} '.png'],'png')
            
        end
        
    end
end






end

function tp = tp2str(tp,final_string_length)
%convert timpoint digit to 'final_string_length' digit string

tp = int2str(tp);

tp = [repmat('0',1,(final_string_length-size(tp,2))) tp];

end