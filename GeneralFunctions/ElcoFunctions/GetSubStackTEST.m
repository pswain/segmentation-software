%GetSubStackTest
%%
Stack = rand(10,10,5);


%%  test inside range
[ SubStackCell ] = GetSubStack( Stack,[4 4 3],[3 3 3],12 );

TrueSubStack = Stack(3:5,3:5,2:4);

if any(TrueSubStack(:)~= SubStackCell{1}(:))
    fprintf('test fail\n')
    return
end

fprintf('success!!\n')

%% test outside

[ SubStackCell ] = GetSubStack( Stack,[10 10 5],[3 3 3],12 );

TrueSubStack = Stack(9:10,9:10,4:5);

if any(any(any(TrueSubStack~= SubStackCell{1}(1:2,1:2,1:2))))
    fprintf('test fail\n')
    return
end

if any(any( SubStackCell{1}(3,:,:) ~=12)) | any( any(SubStackCell{1}(:,:,3)~=12)) | any(any(SubStackCell{1}(:,3,:)~=12))
    fprintf('test fail\n')
    return
end


fprintf('success!!\n')


%%
Stack = rand(10,10);


%%  test inside range
[ SubStackCell ] = GetSubStack( Stack,[4 4],[3 3],12 );

TrueSubStack = Stack(3:5,3:5);

if any(TrueSubStack(:)~= SubStackCell{1}(:))
    fprintf('test fail\n')
    return
end

fprintf('success!!\n')

%% test outside

[ SubStackCell ] = GetSubStack( Stack,[10 10],[3 3],12 );

TrueSubStack = Stack(9:10,9:10);

if (any(any(TrueSubStack~= SubStackCell{1}(1:2,1:2))))
    fprintf('test fail\n')
    return
end

if(any( SubStackCell{1}(3,:) ~=12)) |  (any(SubStackCell{1}(:,3)~=12))
    fprintf('test fail\n')
    return
end


fprintf('success!!\n')

