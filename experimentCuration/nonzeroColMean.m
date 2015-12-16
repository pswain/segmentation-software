function result=nonZeroColMean(matrix)

matrix=arrayfun(@na2zero, full(matrix));
for i= 1:size(matrix,2)
    
    result(i)= mean(matrix(find(matrix(:,i)~=0), i));
    
end

end