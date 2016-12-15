clear, clc
if count(py.sys.path,'') == 0
    insert(py.sys.path,int32(0),'');
end
clear classes; 
mod = py.importlib.import_module('scope');
% py.reload doesn't work even though this is mathworks
% recomended way to reload a module for python 2.7
%py.imp.reload(mod); 
%py.imp.reload(mod1);
%py.implib.reload(mod); 
%py.implib.reload(mod1);
%Note that matlab have to be restarted tp reload module.
py.reload(mod); 
k=0;
while not(mod.scope.ready)
   mod.scope.update();
   k = k+1;
   if k>20
       e=questdlg('No bitscope found, connect one and try again or abort', ...
                  'Cmmunication error',...
                  'Try again',...
                  'Abort',...
                  'Try again');
       switch e
           case 'Try again'
               k=0;
           case 'Abort'
               return
       end
   end         
end

scopeh = scope(mod.scope);
uiwait(scopeh);


