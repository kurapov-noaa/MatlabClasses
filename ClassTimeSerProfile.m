classdef ClassTimeSerProfile
 
 properties
  z
  t
  Hz
  value
 end
    
 methods
        
  function obj = ClassTimeSerProfile(pID)
   % note: sort all the profiles: bottom to top !!!
   
   obj.value={};        
   
   switch pID

    case 'NH10_Craig'
     % note: 'TSVel_NH10_1997_2021_V6' was used in our 2022 paper
     [obj.t,z,u,v]=read_nh10_uv('TSVel_NH10_1997_2021_V6');
     [obj.z,isort]=sort(z);
     
     obj.value{'u'}=u(isort,:);
     obj.value{'v'}=v(isort,:);
    
    case 'NH10_Brandy_2023'
     [obj.t,obj.z,obj.value{'u'},obj.value{'v'}]=read_nh10_uv('NH10_Brandy_2023');
     
    case 'NH10_WCOFS'
     wcofsDir='C:/Users/Alexander.Kurapov/Documents/Workspace/WCOFS'
     modelFile=[wcofsDir '/Exp42/STATS/uvts_avg_profile_561.1336_Exp42.nc'];
     grdfile=[wcofsDir '/Prm/grd_wcofs_large_visc200.nc'];
     dSTR='01-Oct-2008';
     dEND='31-Dec-2018';
     
     sc.Vtransform=2;
     sc.Vstretching=4;
     sc.theta_s=7;     % parameter for stretching near surface
     sc.theta_b=4;     % parameter for stretching near bottom
     sc.Tcline=50;     % thermocline depth
     sc.N=40; 

     % note: read_wcofs_uvProfileTimeSeries rotates u, v components to 
     % the true East-North direction
     [obj.t,obj.z,obj.Hz,u,v]=...
      read_wcofs_uvProfileTimeSeries(dSTR,dEND,modelFile,grdfile,sc);
     obj.value{'u'}=double(u);
     obj.value{'v'}=double(v);
  
    otherwise 
     error(['unknown profile ID: ' pID]);            
    end
    
    obj.Hz=getHz(obj);
    
  end
  
  function Hz=getHz(obj)
   z12=0.5*(obj.z(1:end-1)+obj.z(2:end));
   Hz=diff(z12);
   Hz=[Hz(1);Hz;Hz(end)];
  end
  
  function dave = depthAve(obj,varName,depthRange)
   nt=length(obj.t);   
   in_z=findin(obj.z,depthRange);
   hz1=obj.Hz(in_z);
   H=sum(hz1);
   dave=(1/H)*sum(obj.value{varName}(in_z,:).*repmat(hz1,[1 nt]),1);
  end
  
 end 
end