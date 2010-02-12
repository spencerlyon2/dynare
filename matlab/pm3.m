function pm3(n1,n2,ifil,B,tit1,tit2,tit3,tit_tex,names1,names2,name3,DirectoryName,var_type)

% Copyright (C) 2007-2009 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

global options_ M_ oo_

nn = 3;
MaxNumberOfPlotsPerFigure = nn^2; % must be square
varlist = names2;
if isempty(varlist)
    varlist = names1;
    SelecVariables = (1:M_.endo_nbr)';
    nvar = M_.endo_nbr;
else
    nvar = size(varlist,1);
    SelecVariables = [];
    for i=1:nvar
        if ~isempty(strmatch(varlist(i,:),names1,'exact'))
            SelecVariables = [SelecVariables;strmatch(varlist(i,:),names1,'exact')];
        end
    end
end
if options_.TeX
    % needs to be fixed
    varlist_TeX = [];
    for i=1:nvar
        varlist_TeX = strvcat(varlist_TeX,M_.endo_names_tex(SelecVariables(i),:));
    end
end
Mean = zeros(n2,nvar);
Median = zeros(n2,nvar);
Std = zeros(n2,nvar);
Distrib = zeros(9,n2,nvar);
HPD = zeros(2,n2,nvar);
fprintf(['MH: ' tit1 '\n']);
stock1 = zeros(n1,n2,B);
k = 0;
for file = 1:ifil
    load([DirectoryName '/' M_.fname var_type int2str(file)]);
    if size(size(stock),2) == 4
        stock = squeeze(stock(1,:,1:n2,:));
    end
    k = k(end)+(1:size(stock,3));
    stock1(:,:,k) = stock;
end
clear stock
tmp =zeros(B,1);
for i = 1:nvar
    for j = 1:n2
        [Mean(j,i),Median(j,i),Var(j,i),HPD(:,j,i),Distrib(:,j,i)] = ...
            posterior_moments(squeeze(stock1(SelecVariables(i),j,:)),0,options_.mh_conf_sig);
    end
end
clear stock1
for i = 1:nvar
    name = deblank(names1(SelecVariables(i),:));
    eval(['oo_.' name3 '.Mean.' name ' = Mean(:,i);']);
    eval(['oo_.' name3 '.Median.' name ' = Median(:,i);']);
    eval(['oo_.' name3 '.Var.' name ' = Var(:,i);']);
    eval(['oo_.' name3 '.Distribution.' name ' = Distrib(:,:,i);']);
    eval(['oo_.' name3 '.HPDinf.' name ' = HPD(1,:,i);']);
    eval(['oo_.' name3 '.HPDsup.' name ' = HPD(2,:,i);']);
end
%%
%% 	Finally I build the plots.
%%


% %%%%%%%%%   PARALLEL BLOCK % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% %%% The file .TeX! are not saved in parallel.


subplotnum = 0;

if options_.TeX
    fidTeX = fopen([M_.dname '/Output/' M_.fname '_' name3 '.TeX'],'w');
    fprintf(fidTeX,'%% TeX eps-loader file generated by Dynare.\n');
    fprintf(fidTeX,['%% ' datestr(now,0) '\n']);
    fprintf(fidTeX,' \n');
    
    for i=1:nvar
        NAMES = [];
        TEXNAMES = [];
        if max(abs(Mean(:,i))) > 10^(-6)
            subplotnum = subplotnum+1;
            name = deblank(varlist(i,:));
            NAMES = strvcat(NAMES,name);
            texname = deblank(varlist_TeX(i,:));
            TEXNAMES = strvcat(TEXNAMES,['$' texname '$']);
        end
        if subplotnum == MaxNumberOfPlotsPerFigure | i == nvar
            fprintf(fidTeX,'\\begin{figure}[H]\n');
            for jj = 1:size(TEXNAMES,1)
                fprintf(fidTeX,['\\psfrag{%s}[1][][0.5][0]{%s}\n'],deblank(NAMES(jj,:)),deblank(TEXNAMES(jj,:)));
            end
            fprintf(fidTeX,'\\centering \n');
            fprintf(fidTeX,['\\includegraphics[scale=0.5]{%s_' name3 '_%s}\n'],M_.fname,deblank(tit3(i,:)));
            fprintf(fidTeX,'\\label{Fig:%s:%s}\n',name3,deblank(tit3(i,:)));
            fprintf(fidTeX,'\\end{figure}\n');
            fprintf(fidTeX,' \n');
            subplotnum = 0;
        end
    end
    fprintf(fidTeX,'%% End of TeX file.\n');
    fclose(fidTeX);
end

% Store the variable mandatory for local/remote parallel computing.

localVars=[];

localVars.nvar=nvar;
localVars.tit1=tit1;
localVars.nn=nn;
localVars.n2=n2;
localVars.Distrib=Distrib;
localVars.varlist=varlist;
localVars.MaxNumberOfPlotsPerFigure=MaxNumberOfPlotsPerFigure;
localVars.name3=name3;
localVars.tit3=tit3;
localVars.Mean=Mean;

 if isnumeric(options_.parallel) || ceil(size(varlist,1)/MaxNumberOfPlotsPerFigure)<4,
    fout = pm3_core(localVars,1,nvar,0);
 
 else
    globalVars = struct('M_',M_, ...
      'options_', options_, ...
      'oo_', oo_);
     [fout, nBlockPerCPU, totCPU] = masterParallel(options_.parallel, 1, nvar, [],'pm3_core', localVars,globalVars);
 end

%%%%%%%%%  END PARALLEL BLOCK %% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fprintf(['MH: ' tit1 ', done!\n']);






