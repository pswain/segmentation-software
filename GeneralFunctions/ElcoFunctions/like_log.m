function [ output ] = like_log( input, thresh )
%function [ output ] = like_log( input, thresh ) logs input setting
%everything below thresh to thresh before logging. Default thresh is the
%lowest positive value of input.

if nargin<2 || isempty(thresh)
    thresh = min(input(input>0));
end

output = input;
if ~isempty(output)
    output(output<thresh) = thresh;
    output = log(output);
end

end

