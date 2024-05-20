classdef ClassAnnualCycle
    
    properties
        
        % inputs
        fileName
        varName
        start
        count
        
        period
        omega
        average
        amplitude
        phase
    end

    methods
        
        function obj=ClassAnnualCycle(fileName,varName,start,count)

            obj.fileName=fileName;
            obj.varName=varName;
            obj.start=start;
            obj.count=count;

            obj.period=ncread(fileName,'period');
            obj.omega=2*pi./obj.period;

            np=length(obj.period);
            
            obj.average=double(ncread(fileName,[varName '_average'],start,count));
            obj.amplitude=double(ncread(fileName,[varName '_amp'],[start 1],[count np]));
            obj.phase=double(ncread(fileName,[varName '_phase'],[start 1],[count np]));

            obj.phase=obj.phase*pi/180;
            
        end
        
        function A = annualSingleTime(obj,t)

            % single instance t:

            % use linear index representation for each harmonic
            n=prod(obj.count);
            nn=[1:n]';
            np=length(obj.period);
            A=obj.average;
            
            for kp=1:np
             %- kk: indices in multidim amp and phase corr to harmonics kp
             kk=n*(kp-1)+nn; 
             Ak=obj.amplitude(kk).*cos(obj.omega(kp)*t+obj.phase(kk));
             A=A+reshape(Ak,obj.count);
            end                   
            
        end 
        
        function A = annualMultipleTimes(obj,t)
            
            % multiple instances t, run a cycle for now
            disp('compute annual cycle fields for the entire time series...');
            
            n=prod(obj.count);
            nn=[1:n]';
            
            nt=length(t);
            A=zeros([obj.count nt]);
            
            for it=1:nt
             kk=n*(it-1)+nn;
             A(kk)=obj.annualSingleTime(t(it));   
            end
            
        end 
        
    end  % end methods
end % end classdef
        
        
        