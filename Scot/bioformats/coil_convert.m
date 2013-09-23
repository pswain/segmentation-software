function coil_convert(output_filename)
%small function to take a *.lif file and convert save each of the images
%separately as .png files (so in the way our microscope saves them). They
%are saved in a slected directory as 'output_filename_tp_DIC.png' and 'output_filename_tp_GFP.png'

fprintf('please select microscope file to convert\n')
[file_input,path_input] = uigetfile('*.lif','select microscope file');

fprintf('please select directory in which to store converted images\n')
output_dir = uigetdir;

im = bfopen([path_input file_input]);

for series = 1:size(im,1)%loop over image series
    mkdir(output_dir,['series' int2str(series)]);
    fprintf('converting image series %d \n',series);
    for tp = 1:(size(im{1,1},1)/2)%loope over timepoints
        
        %write GFP image
        imwrite(im{series,1}{2*tp,1},[output_dir '/series' int2str(series) '/' output_filename '_' tp2str(tp,6) '_DIC.png'],'png')
    
        %write DIC image
        imwrite(im{series,1}{2*tp-1,1},[output_dir '/series' int2str(series) '/' output_filename '_' tp2str(tp,6) '_GFP.png'],'png')
    
        
    end
end






end

function tp = tp2str(tp,final_string_length)
%convert timpoint digit to 3 digit string

tp = int2str(tp);

digits = size(tp,2);

zero_string = '';

for n = 1:(final_string_length-digits)

    zero_string = [zero_string '0'];
    
end

tp = [zero_string tp];


end