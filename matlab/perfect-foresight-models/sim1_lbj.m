function oo_ = sim1_lbj(options_, M_, oo_)
% function sim1_lbj
% performs deterministic simulations with lead or lag on one period
% using the historical LBJ algorithm
%
% INPUTS
%   ...
% OUTPUTS
%   ...
% ALGORITHM
%   Laffargue, Boucekkine, Juillard (LBJ)
%   see Juillard (1996) Dynare: A program for the resolution and
%   simulation of dynamic models with forward variables through the use
%   of a relaxation algorithm. CEPREMAP. Couverture Orange. 9602.
%
% SPECIAL REQUIREMENTS
%   None.

% Copyright (C) 1996-2015 Dynare Team
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

lead_lag_incidence = M_.lead_lag_incidence;

ny = size(oo_.endo_simul,1) ;
nyp = nnz(lead_lag_incidence(1,:)) ;
nyf = nnz(lead_lag_incidence(3,:)) ;
nrs = ny+nyp+nyf+1 ;
nrc = nyf+1 ;
iyf = find(lead_lag_incidence(3,:)>0) ;
iyp = find(lead_lag_incidence(1,:)>0) ;
isp = [1:nyp] ;
is = [nyp+1:ny+nyp] ;
isf = iyf+nyp ;
isf1 = [nyp+ny+1:nyf+nyp+ny+1] ;
stop = 0 ;
iz = [1:ny+nyp+nyf];

verbose = options_.verbosity;

if verbose
    printline(56)
    disp(['MODEL SIMULATION :'])
    skipline()
end

it_init = M_.maximum_lag+1 ;

h1 = clock ;
for iter = 1:options_.simul.maxit
    h2 = clock ;
    
    if options_.terminal_condition == 0
        c = zeros(ny*options_.periods,nrc) ;
    else
        c = zeros(ny*(options_.periods+1),nrc) ;
    end
    
    it_ = it_init ;
    z = [oo_.endo_simul(iyp,it_-1) ; oo_.endo_simul(:,it_) ; oo_.endo_simul(iyf,it_+1)] ;
    [d1,jacobian] = feval([M_.fname '_dynamic'],z,oo_.exo_simul, M_.params, oo_.steady_state,it_);
    jacobian = [jacobian(:,iz) -d1] ;
    ic = [1:ny] ;
    icp = iyp ;
    c (ic,:) = jacobian(:,is)\jacobian(:,isf1) ;
    for it_ = it_init+(1:options_.periods-1)
        z = [oo_.endo_simul(iyp,it_-1) ; oo_.endo_simul(:,it_) ; oo_.endo_simul(iyf,it_+1)] ;
        [d1,jacobian] = feval([M_.fname '_dynamic'],z,oo_.exo_simul, ...
                              M_.params, oo_.steady_state, it_);
        jacobian = [jacobian(:,iz) -d1] ;
        jacobian(:,[isf nrs]) = jacobian(:,[isf nrs])-jacobian(:,isp)*c(icp,:) ;
        ic = ic + ny ;
        icp = icp + ny ;
        c (ic,:) = jacobian(:,is)\jacobian(:,isf1) ;
    end
    
    if options_.terminal_condition == 1
        s = eye(ny) ;
        s(:,isf) = s(:,isf)+c(ic,1:nyf) ;
        ic = ic + ny ;
        c(ic,nrc) = s\c(ic,nrc) ;
        c = bksup1(c,ny,nrc,iyf,options_.periods) ;
        c = reshape(c,ny,options_.periods+1) ;
        oo_.endo_simul(:,it_init+(0:options_.periods)) = oo_.endo_simul(:,it_init+(0:options_.periods))+options_.slowc*c ;
    else
        c = bksup1(c,ny,nrc,iyf,options_.periods) ;
        c = reshape(c,ny,options_.periods) ;
        oo_.endo_simul(:,it_init+(0:options_.periods-1)) = oo_.endo_simul(:,it_init+(0:options_.periods-1))+options_.slowc*c ;
    end
    
    err = max(max(abs(c./options_.scalv')));

    if verbose
        str = sprintf('Iter: %s,\t err. = %s, \t time = %s',num2str(iter),num2str(err), num2str(etime(clock,h2)));
        disp(str);
    end
    
    if err < options_.dynatol.f
        stop = 1 ;
        if verbose
            skipline()
            disp(sprintf('Total time of simulation: %s', num2str(etime(clock,h1))))
        end
        oo_.deterministic_simulation.status = 1;% Convergency obtained.
        oo_.deterministic_simulation.error = err;
        oo_.deterministic_simulation.iterations = iter;
        break
    end
end

if ~stop
    if verbose
        disp(sprintf('Total time of simulation: %s.', num2str(etime(clock,h1))))
        disp('Maximum number of iterations is reached (modify option maxit).')
    end
    oo_.deterministic_simulation.status = 0;% more iterations are needed.
    oo_.deterministic_simulation.error = err;
    oo_.deterministic_simulation.errors = c/abs(err);    
    oo_.deterministic_simulation.iterations = options_.simul.maxit;
end

if verbose
    if stop
        printline(56)
    else
        printline(62)
    end
    skipline()
end
