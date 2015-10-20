function correctSkippedFramesInf(cExperiment,type)

%This doesn't seem to work properly ... was causing a bug in the lineage
%extraction code. Need to double check, could be removing cells by
%accident;

if nargin<2
    type='norm';
end

for nSkip=1:1
    for channel=1:length(cExperiment.cellInf)
        cellInf=cExperiment.cellInf(channel);
%         d=abs(diff(cExperiment.cellInf(channel).xloc,1,2));
%         dPre=d;dPre=padarray(dPre,[0 1],0,'post');
%         dPost=d;dPost=padarray(dPost,[0 1],0,'pre');
        
        if size(cExperiment.cellInf(channel).radius,1)~=size(cExperiment.cellInf(channel).xloc,1)
            len=size(cExperiment.cellInf(channel).radius);
            cExperiment.cellInf(channel).xloc=ones(len);
            cExperiment.cellInf(channel).yloc=ones(len);
        end

        dPre=cExperiment.cellInf(channel).mean(:,2:end)>0;
        dPre=padarray(dPre,[0 1],0,'post');
        dPost=cExperiment.cellInf(channel).mean(:,1:end-1)>0;
        dPost=padarray(dPost,[0 1],0,'pre');
        
        
        locSkipped=(dPost>0)&(dPre>0)& (cExperiment.cellInf(channel).mean==0);
        locSkippedPre=padarray(locSkipped,[0 nSkip],0,'post')>0;
        locSkippedPre=locSkippedPre(:,nSkip+1:end);
        locSkippedPost=padarray(locSkipped,[0 nSkip],0,'pre')>0;
        locSkippedPost=locSkippedPost(:,1:end-nSkip);

% % % % % % 
% % % % % %         d=abs(diff(cExperiment.cellInf(channel).mean,nSkip,2));
% % % % % %         dPre=d;dPre=padarray(dPre,[0 nSkip],0,'post');
% % % % % %         dPost=d;dPost=padarray(dPost,[0 nSkip],0,'pre');
% % % % % %         locSkipped=(dPost>0)&(dPre>0)& (cExperiment.cellInf(channel).mean==0);
% % % % % %         locSkipped=full(locSkipped>0);
% % % % % %         locSkippedPre=padarray(locSkipped,[0 nSkip],0,'post')>0;
% % % % % %         locSkippedPre=locSkippedPre(:,nSkip+1:end);
% % % % % %         locSkippedPost=padarray(locSkipped,[0 nSkip],0,'pre')>0;
% % % % % %         locSkippedPost=locSkippedPost(:,1:end-nSkip);

        temp=(cExperiment.cellInf(channel).radius(locSkippedPre)+cExperiment.cellInf(channel).radius(locSkippedPost))./2;
        b=full(cellInf.radius);
        b(locSkipped)=temp;
        cellInf.radius=sparse(b);
%         
%         temp=(cExperiment.cellInf(channel).xloc(locSkippedPre)+cExperiment.cellInf(channel).xloc(locSkippedPost))./2;
%         b=full(cellInf.xloc);
%         b(locSkipped)=temp;
%         cellInf.xloc=sparse(round(b));
%         
%                 temp=(cExperiment.cellInf(channel).yloc(locSkippedPre)+cExperiment.cellInf(channel).yloc(locSkippedPost))./2;
%         b=full(cellInf.yloc);
%         b(locSkipped)=temp;
%         cellInf.yloc=sparse(round(b));

        if strcmp(type,'norm')
            
            temp=((cExperiment.cellInf(channel).mean(locSkippedPre)+cExperiment.cellInf(channel).mean(locSkippedPost))./2);
            b=full(cellInf.mean);
            b(locSkipped)=temp;
            cellInf.mean=sparse(b);
            
            temp=((cExperiment.cellInf(channel).membraneMedian(locSkippedPre)+cExperiment.cellInf(channel).membraneMedian(locSkippedPost))./2);
            b=full(cellInf.membraneMedian);
            b(locSkipped)=temp;
            cellInf.membraneMedian=sparse(b);
            
                        temp=((cExperiment.cellInf(channel).membraneMax5(locSkippedPre)+cExperiment.cellInf(channel).membraneMax5(locSkippedPost))./2);
            b=full(cellInf.membraneMax5);
            b(locSkipped)=temp;
            cellInf.membraneMax5=sparse(b);


            
            temp=(cExperiment.cellInf(channel).median(locSkippedPre)+cExperiment.cellInf(channel).median(locSkippedPost))./2;
            b=full(cellInf.median);
            b(locSkipped)=temp;
            cellInf.median=sparse(b);
            
            temp=(cExperiment.cellInf(channel).max5(locSkippedPre)+cExperiment.cellInf(channel).max5(locSkippedPost))./2;
            b=full(cellInf.max5);
            b(locSkipped)=temp;
            cellInf.max5=sparse(b);
            
            temp=(cExperiment.cellInf(channel).std(locSkippedPre)+cExperiment.cellInf(channel).std(locSkippedPost))./2;
            b=full(cellInf.std);
            b(locSkipped)=temp;
            cellInf.std=sparse(b);
            
            
            
            temp=(cExperiment.cellInf(channel).smallmean(locSkippedPre)+cExperiment.cellInf(channel).smallmean(locSkippedPost))./2;
            b=full(cellInf.smallmean);
            b(locSkipped)=temp;
            cellInf.smallmean=sparse(b);
            
            temp=(cExperiment.cellInf(channel).smallmedian(locSkippedPre)+cExperiment.cellInf(channel).smallmedian(locSkippedPost))./2;
            b=full(cellInf.smallmedian);
            b(locSkipped)=temp;
            cellInf.smallmedian=sparse(b);
            
            temp=(cExperiment.cellInf(channel).smallmax5(locSkippedPre)+cExperiment.cellInf(channel).smallmax5(locSkippedPost))./2;
            b=full(cellInf.smallmax5);
            b(locSkipped)=temp;
            cellInf.smallmax5=sparse(b);
            
            temp=(cExperiment.cellInf(channel).min(locSkippedPre)+cExperiment.cellInf(channel).min(locSkippedPost))./2;
            b=full(cellInf.min);
            b(locSkipped)=temp;
            cellInf.min=sparse(b);
            
            temp=(cExperiment.cellInf(channel).imBackground(locSkippedPre)+cExperiment.cellInf(channel).imBackground(locSkippedPost))./2;
            b=full(cellInf.imBackground);
            b(locSkipped)=temp;
            cellInf.imBackground=sparse(b);
            
            if isfield(cellInf,'radiusFL')
                temp=(cExperiment.cellInf(channel).radiusFL(locSkippedPre)+cExperiment.cellInf(channel).radiusFL(locSkippedPost))./2;
                b=full(cellInf.radiusFL);
                b(locSkipped)=temp;
                cellInf.radiusFL=sparse(b);
            end
            if isfield(cellInf,'nuclearTagLoc')
                temp=(cExperiment.cellInf(channel).nuclearTagLoc(locSkippedPre)+cExperiment.cellInf(channel).nuclearTagLoc(locSkippedPost))./2;
                b=full(cellInf.nuclearTagLoc);
                b(locSkipped)=temp;
                cellInf.nuclearTagLoc=sparse(b);
            end
        end
        
        cExperiment.cellInf(channel)=cellInf;

    end
end
fprintf('Finished skipped frames \n');
% 
% for j=1:length(cExperiment.cellInf)
%     channel=j;
%     for nSkip=2:4;
%         d=abs(diff(cExperiment.cellInf(channel).mean,nSkip,2));
%         dPre=d;dPre=padarray(dPre,[0 nSkip],0,'post');
%         dPost=d;dPost=padarray(dPost,[0 nSkip],0,'pre');
%         
%         locSkipped=(dPost>0)&(dPre>0)& (cExperiment.cellInf(channel).mean==0);
%         [row col]=find(locSkipped);
%         
%         
%         for k=1:length(row)
%             k
%             l=k;
%             temp=cExperiment.cellInf(j).mean;
%             x=[1 nSkip*2+1]; xi=1:nSkip*2+1;
%             y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
%             temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
%             cExperiment.cellInf(j).mean=temp;
%             
%             temp=cExperiment.cellInf(j).median;
%             y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
%             temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
%             cExperiment.cellInf(j).median=temp;
%             
%             temp=cExperiment.cellInf(j).max5;
%             y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
%             temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
%             cExperiment.cellInf(j).max5=temp;
%             
%             temp=cExperiment.cellInf(j).std;
%             y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
%             temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
%             cExperiment.cellInf(j).std=temp;
%             
%             temp=cExperiment.cellInf(j).radius;
%             y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
%             temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
%             cExperiment.cellInf(j).radius=temp;
%             
%             
%             temp=cExperiment.cellInf(j).smallmean;
%             y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
%             temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
%             cExperiment.cellInf(j).smallmean=temp;
%             
%             temp=cExperiment.cellInf(j).smallmedian;
%             y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
%             temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
%             cExperiment.cellInf(j).smallmedian=temp;
%             
%             temp=cExperiment.cellInf(j).smallmax5;
%             y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
%             temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
%             cExperiment.cellInf(j).smallmax5=temp;
%             
%             temp=cExperiment.cellInf(j).min;
%             y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
%             temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
%             cExperiment.cellInf(j).min=temp;
%             
%             temp=cExperiment.cellInf(j).imBackground;
%             y=[temp(row(k),col(l)-nSkip) temp(row(k),col(l)+nSkip)];
%             temp(row(k),col(l)-nSkip:col(l)+nSkip)=interp1(x,y,xi);
%             cExperiment.cellInf(j).imBackground=temp;
%             
%             
%         end
%     end
% end
