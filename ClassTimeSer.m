% 2023/01/11: 
% (1) Exclude repository ??
% (2) Provide full path in the template
% (3) account for the case where wildcards are used not only in the file
% name but also in the directories (e.g.  ../$YYY/fname_$YYYY$M.nc)

classdef ClassTimeSer
 
     properties 
         % inputs to initialize the time series object
         fileNameTemplate % full path included
         varName
         start
         count
         timeName
         
         % derived properties:
         fileList
         snapsPerFile
         time  % original time converted to days
         timeMatlab
         units
         refDate         

         dims
     end
 
     methods
         
         function obj=ClassTimeSer(fnameTemplate,varName,start,count,...
                                   timeName)
        
             obj.fileNameTemplate=fnameTemplate;
             obj.varName=varName;
             obj.start=start;
             obj.count=count;
             obj.timeName=timeName;

             disp('Get obj.fileList...');             
             obj.fileList=obj.getFileList;
             
             disp('Get number of snapshots per file...');
             obj.snapsPerFile=obj.getNumberSnapshotsPerFile;             

             disp('Get obj.time...'); 
             obj.time=obj.getTime;
         
             units=obj.timeUnits;
            
             if ~isempty(strfind(units,'seconds'))
              obj.time=obj.time/24/3600;
             end
             obj.refDate=obj.getRefDate;
             
             if contains(fnameTemplate,'BOA_Argo')
              % hand fix since the units stamp is messed up in BOA_Argo
              obj.timeMatlab=obj.time;
             else
              obj.timeMatlab=obj.time+datenum(obj.refDate);
             end
             
             disp('Get dimensions');                          
             obj.dims=obj.getDims;
             
         end
              
         function [flist]=getFileList(obj)
             
             fWildCard=replace(obj.fileNameTemplate,'$YYY','*');
             fWildCard=replace(fWildCard,'$NNN','*');
             fWildCard=replace(fWildCard,'$M','*');
             fWildCard=replace(fWildCard,'$D','*');
             
             %- exclude repetitions of *
             fWildCard=replace(fWildCard,'****','*');
             fWildCard=replace(fWildCard,'***','*');
             fWildCard=replace(fWildCard,'**','*');
             
             a=dir(fWildCard); % => a(:) where each entry is a structure 
             
             nf=length(a);
             
             for k=1:nf
                 fname=[a(k).folder '/' a(k).name];
                 fname=replace(fname,'\','/');
                 n1=length(fname);
                 flist(k,1:n1)=fname;
             end

         end
         
         function [d]=getDims(obj)
             flist=obj.fileList;    
             fname=flist(1,:);
             a=ncinfo(fname,obj.varName);
             d=obj.count;
             i_1=find(d==-1);
             d(i_1)=a.Size(i_1)-obj.start(i_1)+1;
         end
         
         function [dimNames]=getDimNames(obj)
             % returns the dimension names as a structure (space only, time excluded)
             flist=obj.fileList;    
             fname=flist(1,:);
             a=ncinfo(fname,obj.varName);
             dimNames={};
             for k=1:length(obj.dims)
              dimNames{k}=a.Dimensions(k).Name;
             end
         end
         
         function [snaps]=getNumberSnapshotsPerFile(obj)
             flist=obj.fileList;
             nf=size(flist,1);
             snaps=zeros(nf,1);
             for k=1:nf
              if mod(k,100)==0
               disp([int2str(k) ' out of ' int2str(nf)]);
              end
              a=ncinfo(flist(k,:),obj.timeName);
              snaps(k)=a.Size;
              %t=ncread(flist(k,:),obj.timeName);
              %snaps(k)=length(t);
             end
         end
         
         function [t]=getTime(obj)
             flist=obj.fileList;
             snaps=obj.snapsPerFile;
             nt=sum(snaps);
             t=nan*zeros(nt,1);
             nf=size(flist,1);
             i1=1;
             for kf=1:nf
              if mod(kf,100)==0
               disp([int2str(kf) ' out of ' int2str(nf)]);
              end
              i2=i1+snaps(kf)-1;
              t(i1:i2)=ncread(flist(kf,:),obj.timeName,1,snaps(kf));
              i1=i2+1;
             end
         end
         
%          function [lon,lat]=lonlat(obj)
%              flist=obj.fileList;
%              dims=obj.dims;
%              str=obj.start;
%              % - find the total length of the time series (assume there
%              % might be more than one time instance in a file)
%              lon=ncread(flist(1,:),obj.lonName);
%              lat=ncread(flist(1,:),obj.latName);
%              lon=lon(str(1)+[1:dims(1)]-1);
%              lat=lat(str(2)+[1:dims(2)]-1);
%              [lat,lon]=meshgrid(lat,lon);
%          end
%          
         function units=timeUnits(obj)
             flist=obj.fileList;
             units=ncreadatt(flist(1,:),obj.timeName,'units');
         end
         
         function ref=getRefDate(obj)
             ref=recognize_time_stamp(obj.timeUnits);
         end
         
         function f=field(obj,it)  % it: index in the whole time series
             flist=obj.fileList;
             snaps=obj.snapsPerFile;
             cs=cumsum(snaps);
             kf=min(find(cs-it>=0)); % file number from where snapshot is read
             it1=snaps(kf)-(cs(kf)-it); % index in file kf
             disp(flist(kf,:));
             f=ncread(flist(kf,:),obj.varName,[obj.start it1],[obj.dims 1]);
             f=double(f);
         end

% DEPRESSIATED
%          function f=fields(obj,dateSTR,dateEND)  % it: index in the whole time series
% 
%              t1=datenum(dateSTR);
%              t2=datenum(dateEND);
%               
%              itList=find(obj.timeMatlab>=t1 & obj.timeMatlab<=t2);
%              nt=length(itList);
%              
%              flist=obj.fileList;
%              snaps=obj.snapsPerFile;
%              dim1=obj.dims;
%              cs=cumsum(snaps);
%              
%              f=nan*zeros([obj.dims nt]);
% 
%              for k=1:nt
%               it=itList(k);
%               kf=min(find(cs-it>=0)); % file number from where snapshot is read
%               it1=snaps(kf)-(cs(kf)-it); % index in file kf
%               disp(flist(kf,:));
%               % since we may use dims of different sizes (1d, 2d, 3d) 
%               % use 1d representation to assign the field to array f ([dims
%               % + time])
%               f(prod([dim1 k-1])+[1:prod(dim1)])=...
%                   ncread(flist(kf,:),obj.varName,[obj.start it1],[obj.dims 1]);
%              end
%              
%              f=double(f);
%          end
          
% New fields method, no use of dateSTR, dateEND, reading 
% all the snapshots
% if a subset is needed, use clip

         function f=fields(obj)  % it: index in the whole time series
% all the snapshots if a subset is needed, use clip
              
             nt=length(obj.timeMatlab);
             
             flist=obj.fileList;
             snaps=obj.snapsPerFile;
             dim1=obj.dims;
             cs=cumsum(snaps);
             
             f=nan*zeros([obj.dims nt]);

             for it=1:nt
              kf=min(find(cs-it>=0)); % file number from where snapshot is read
              it1=snaps(kf)-(cs(kf)-it); % index in file kf
              disp([obj.varName ' ...' flist(kf,end-50:end) ', ' int2str(it1)]); 
              % since we may use dims of different sizes (1d, 2d, 3d) 
              % use 1d representation to assign the field to array f ([dims
              % + time])
              f(prod([dim1 it-1])+[1:prod(dim1)])=...
                  ncread(flist(kf,:),obj.varName,[obj.start it1],[obj.dims 1]);
             end
             
             f=double(f);
         end
     
         function timeSer1 = clip(obj,dSTR,dEND)
           
           % For now, do not allow an option to cut thru the file (ie all
           % time instances in a given file are either in or out)
           
           tSTR=datenum(dSTR);
           tEND=datenum(dEND);
           
           nf = size(obj.fileList,1);
           nt = length(obj.timeMatlab);
           
           files_in=zeros(nf,1);
           times_in=zeros(nt,1);
           
           t_count=0;
           for k=1:nf
            itt=t_count+[1:obj.snapsPerFile(k)]';
            tt=obj.timeMatlab(itt);
            if all(tt>=tSTR & tt<=tEND)
             files_in(k)=1;
             times_in(itt)=1;
            end
            t_count=t_count+obj.snapsPerFile(k);
           end
           
           files_in=find(files_in);
           times_in=find(times_in);
           
           timeSer1=obj;
           timeSer1.fileList = timeSer1.fileList(files_in,:);
           timeSer1.snapsPerFile = timeSer1.snapsPerFile(files_in);
           timeSer1.time = timeSer1.time(times_in);
           timeSer1.timeMatlab = timeSer1.timeMatlab(times_in);
           
         end
         
     end % methods
     
end % end classdef
