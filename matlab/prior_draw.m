function pdraw = prior_draw(init,uniform) % --*-- Unitary tests --*--
% This function generate one draw from the joint prior distribution and
% allows sampling uniformly from the prior support (uniform==1 when called with init==1)
% 
% INPUTS 
%   o init             [integer]    scalar equal to: 
%                                       1: first call to set up persistent variables 
%                                             describing the prior
%                                       0: subsequent call to get prior
%                                               draw
%   o uniform          [integer]    scalar used in initialization (init=1), equal to:
%                                       1: sample uniformly from prior
%                                           support (overwrites prior shape used for sampling within this function)
%                                       0: sample from joint prior distribution
%    
% OUTPUTS 
%   o pdraw            [double]     1*npar vector, draws from the joint prior density.
%
%
% SPECIAL REQUIREMENTS
%   none
%
% NOTE 1. Input arguments 1 an 2 are only needed for initialization.
% NOTE 2. A given draw from the joint prior distribution does not satisfy BK conditions a priori.
% NOTE 3. This code relies on bayestopt_ as created in the base workspace
%           by the preprocessor (or as updated in subsequent pieces of code and handed to the base workspace)
% 
% Copyright (C) 2006-2015 Dynare Team
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

persistent p6 p7 p3 p4 lb ub
persistent uniform_index gaussian_index gamma_index beta_index inverse_gamma_1_index inverse_gamma_2_index
persistent uniform_draws gaussian_draws gamma_draws beta_draws inverse_gamma_1_draws inverse_gamma_2_draws


if nargin>0 && init
    p6 = evalin('base', 'bayestopt_.p6');
    p7 = evalin('base', 'bayestopt_.p7');
    p3 = evalin('base', 'bayestopt_.p3');
    p4 = evalin('base', 'bayestopt_.p4');
    bounds = evalin('base', 'prior_bounds(bayestopt_,options_)');
    lb = bounds.lb;
    ub = bounds.ub;
    number_of_estimated_parameters = length(p6);
    if nargin>1 && uniform
        prior_shape = repmat(5,number_of_estimated_parameters,1);
    else
        prior_shape = evalin('base', 'bayestopt_.pshape');
    end
    beta_index = find(prior_shape==1);
    if isempty(beta_index)
        beta_draws = 0;
    else
        beta_draws = 1;
    end
    gamma_index = find(prior_shape==2);
    if isempty(gamma_index)
        gamma_draws = 0;
    else
        gamma_draws = 1;
    end
    gaussian_index = find(prior_shape==3);
    if isempty(gaussian_index)
        gaussian_draws = 0;
    else
        gaussian_draws = 1;
    end
    inverse_gamma_1_index = find(prior_shape==4);
    if isempty(inverse_gamma_1_index)
        inverse_gamma_1_draws = 0;
    else
        inverse_gamma_1_draws = 1;
    end
    uniform_index = find(prior_shape==5);
    if isempty(uniform_index)
        uniform_draws = 0;
    else
        uniform_draws = 1;
    end
    inverse_gamma_2_index = find(prior_shape==6);
    if isempty(inverse_gamma_2_index)
        inverse_gamma_2_draws = 0;
    else
        inverse_gamma_2_draws = 1;
    end
    pdraw = NaN(number_of_estimated_parameters,1);
    return
end

if uniform_draws
    pdraw(uniform_index) = rand(length(uniform_index),1).*(p4(uniform_index)-p3(uniform_index)) + p3(uniform_index);  
    out_of_bound = find( (pdraw(uniform_index)'>ub(uniform_index)) | (pdraw(uniform_index)'<lb(uniform_index)));
    while ~isempty(out_of_bound),
        pdraw(uniform_index) = rand(length(uniform_index),1).*(p4(uniform_index)-p3(uniform_index)) + p3(uniform_index);
        out_of_bound = find( (pdraw(uniform_index)'>ub(uniform_index)) | (pdraw(uniform_index)'<lb(uniform_index)));
    end
end

if gaussian_draws
    pdraw(gaussian_index) = randn(length(gaussian_index),1).*p7(gaussian_index) + p6(gaussian_index);
    out_of_bound = find( (pdraw(gaussian_index)'>ub(gaussian_index)) | (pdraw(gaussian_index)'<lb(gaussian_index)));
    while ~isempty(out_of_bound),
        pdraw(gaussian_index(out_of_bound)) = randn(length(gaussian_index(out_of_bound)),1).*p7(gaussian_index(out_of_bound)) + p6(gaussian_index(out_of_bound));
        out_of_bound = find( (pdraw(gaussian_index)'>ub(gaussian_index)) | (pdraw(gaussian_index)'<lb(gaussian_index)));
    end
end

if gamma_draws
    pdraw(gamma_index) = gamrnd(p6(gamma_index),p7(gamma_index))+p3(gamma_index);
    out_of_bound = find( (pdraw(gamma_index)'>ub(gamma_index)) | (pdraw(gamma_index)'<lb(gamma_index)));
    while ~isempty(out_of_bound),
        pdraw(gamma_index(out_of_bound)) = gamrnd(p6(gamma_index(out_of_bound)),p7(gamma_index(out_of_bound)))+p3(gamma_index(out_of_bound));
        out_of_bound = find( (pdraw(gamma_index)'>ub(gamma_index)) | (pdraw(gamma_index)'<lb(gamma_index)));
    end
end

if beta_draws
    pdraw(beta_index) = (p4(beta_index)-p3(beta_index)).*betarnd(p6(beta_index),p7(beta_index))+p3(beta_index);
    out_of_bound = find( (pdraw(beta_index)'>ub(beta_index)) | (pdraw(beta_index)'<lb(beta_index)));
    while ~isempty(out_of_bound),
        pdraw(beta_index(out_of_bound)) = (p4(beta_index(out_of_bound))-p3(beta_index(out_of_bound))).*betarnd(p6(beta_index(out_of_bound)),p7(beta_index(out_of_bound)))+p3(beta_index(out_of_bound));
        out_of_bound = find( (pdraw(beta_index)'>ub(beta_index)) | (pdraw(beta_index)'<lb(beta_index)));
    end
end

if inverse_gamma_1_draws
    pdraw(inverse_gamma_1_index) = ...
        sqrt(1./gamrnd(p7(inverse_gamma_1_index)/2,2./p6(inverse_gamma_1_index)))+p3(inverse_gamma_1_index);
    out_of_bound = find( (pdraw(inverse_gamma_1_index)'>ub(inverse_gamma_1_index)) | (pdraw(inverse_gamma_1_index)'<lb(inverse_gamma_1_index)));
    while ~isempty(out_of_bound),
        pdraw(inverse_gamma_1_index(out_of_bound)) = ...
            sqrt(1./gamrnd(p7(inverse_gamma_1_index(out_of_bound))/2,2./p6(inverse_gamma_1_index(out_of_bound))))+p3(inverse_gamma_1_index(out_of_bound));
        out_of_bound = find( (pdraw(inverse_gamma_1_index)'>ub(inverse_gamma_1_index)) | (pdraw(inverse_gamma_1_index)'<lb(inverse_gamma_1_index)));
    end
end

if inverse_gamma_2_draws
    pdraw(inverse_gamma_2_index) = ...
        1./gamrnd(p7(inverse_gamma_2_index)/2,2./p6(inverse_gamma_2_index))+p3(inverse_gamma_2_index);
    out_of_bound = find( (pdraw(inverse_gamma_2_index)'>ub(inverse_gamma_2_index)) | (pdraw(inverse_gamma_2_index)'<lb(inverse_gamma_2_index)));
    while ~isempty(out_of_bound),
        pdraw(inverse_gamma_2_index(out_of_bound)) = ...
            1./gamrnd(p7(inverse_gamma_2_index(out_of_bound))/2,2./p6(inverse_gamma_2_index(out_of_bound)))+p3(inverse_gamma_2_index(out_of_bound));
        out_of_bound = find( (pdraw(inverse_gamma_2_index)'>ub(inverse_gamma_2_index)) | (pdraw(inverse_gamma_2_index)'<lb(inverse_gamma_2_index)));
    end
end

%@test:1
%$ %% Initialize required structures
%$ options_.prior_trunc=0;
%$ options_.initialize_estimated_parameters_with_the_prior_mode=0;
%$ 
%$ M_.dname='test';
%$ M_.param_names = 'alp';
%$ ndraws=100000;
%$ global estim_params_
%$ estim_params_.var_exo = [];
%$ estim_params_.var_endo = [];
%$ estim_params_.corrx = [];
%$ estim_params_.corrn = [];
%$ estim_params_.param_vals = [];
%$ estim_params_.param_vals = [1, NaN, (-Inf), Inf, 1, 0.356, 0.02, NaN, NaN, NaN ];
%$ 
%$ %% beta
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 1;%Shape
%$ estim_params_.param_vals(1,6)=0.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=NaN;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>1e-4 || abs(std(pdraw_vec)-estim_params_.param_vals(1,7))>1e-4 || any(pdraw_vec<0) || any(pdraw_vec>1)
%$     error('Beta prior wrong')
%$ end
%$ 
%$ 
%$ %% Gamma
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 2;%Shape 
%$ estim_params_.param_vals(1,6)=0.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=NaN;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>1e-4 || abs(std(pdraw_vec)-estim_params_.param_vals(1,7))>1e-4 || any(pdraw_vec<0)
%$     error('Gamma prior wrong')
%$ end
%$ 
%$ %% Normal
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 3;%Shape 
%$ estim_params_.param_vals(1,6)=0.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=NaN;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>1e-4 || abs(std(pdraw_vec)-estim_params_.param_vals(1,7))>1e-4
%$     error('Normal prior wrong')
%$ end
%$ 
%$ %% inverse gamma distribution (type 1)
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 4;%Shape 
%$ estim_params_.param_vals(1,6)=0.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=NaN;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>1e-4 || abs(std(pdraw_vec)-estim_params_.param_vals(1,7))>1e-4 || any(pdraw_vec<0)
%$     error('inverse gamma distribution (type 1) prior wrong')
%$ end
%$ 
%$ %% Uniform
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 5;%Shape 
%$ estim_params_.param_vals(1,6)=0.5;
%$ estim_params_.param_vals(1,7)=sqrt(12)^(-1)*(1-0);
%$ estim_params_.param_vals(1,8)=NaN;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>1e-2 || abs(std(pdraw_vec)-estim_params_.param_vals(1,7))>1e-3 || any(pdraw_vec<0) || any(pdraw_vec>1)
%$     error('Uniform prior wrong')
%$ end
%$ 
%$ %% inverse gamma distribution (type 2)
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 6;%Shape 
%$ estim_params_.param_vals(1,6)=0.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=NaN;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>1e-4 || abs(std(pdraw_vec)-estim_params_.param_vals(1,7))>1e-4 || any(pdraw_vec<0)
%$     error('inverse gamma distribution (type 2) prior wrong')
%$ end
%$ 
%$ 
%$ %%%%%%%%%%%%%%%%%%%%%% Generalized distributions %%%%%%%%%%%%%%%%%%%%%
%$ 
%$ %% beta
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 1;%Shape
%$ estim_params_.param_vals(1,6)=1.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=1;
%$ estim_params_.param_vals(1,9)=3;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>1e-4 || abs(std(pdraw_vec)-estim_params_.param_vals(1,7))>1e-4 || any(pdraw_vec<estim_params_.param_vals(1,3)) || any(pdraw_vec>estim_params_.param_vals(1,4))
%$     error('Beta prior wrong')
%$ end
%$ 
%$ %% Gamma
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 2;%Shape 
%$ estim_params_.param_vals(1,6)=1.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=1;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>1e-4 || abs(std(pdraw_vec)-estim_params_.param_vals(1,7))>1e-4 || any(pdraw_vec<estim_params_.param_vals(1,8))
%$     error('Gamma prior wrong')
%$ end
%$ 
%$ %% inverse gamma distribution (type 1)
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 4;%Shape 
%$ estim_params_.param_vals(1,6)=1.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=1;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>1e-4 || abs(std(pdraw_vec)-estim_params_.param_vals(1,7))>1e-4 || any(pdraw_vec<estim_params_.param_vals(1,8)) 
%$     error('inverse gamma distribution (type 1) prior wrong')
%$ end
%$ 
%$ %% Uniform
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 5;%Shape 
%$ estim_params_.param_vals(1,6)=1.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=NaN;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>1e-4 || abs(std(pdraw_vec)-estim_params_.param_vals(1,7))>1e-4 || any(pdraw_vec<estim_params_.param_vals(1,3)) || any(pdraw_vec>estim_params_.param_vals(1,4))
%$     error('Uniform prior wrong')
%$ end
%$ 
%$ %% inverse gamma distribution (type 2)
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 6;%Shape 
%$ estim_params_.param_vals(1,6)=1.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=1;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>1e-4 || abs(std(pdraw_vec)-estim_params_.param_vals(1,7))>1e-4 || any(pdraw_vec<estim_params_.param_vals(1,8)) 
%$     error('inverse gamma distribution (type 2) prior wrong')
%$ end
%$ 
%$ %%%%%%%%%%%% With prior truncation
%$ options_.prior_trunc=.4;
%$ 
%$ %% beta
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 1;%Shape
%$ estim_params_.param_vals(1,6)=1.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=1;
%$ estim_params_.param_vals(1,9)=3;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ bounds = prior_bounds(bayestopt_,options_)';
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>5e-3 || any(pdraw_vec<bounds.lb) || any(pdraw_vec>bounds.ub)
%$     error('Beta prior wrong')
%$ end
%$ 
%$ %% Gamma
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 2;%Shape 
%$ estim_params_.param_vals(1,6)=1.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=1;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ bounds = prior_bounds(bayestopt_,options_)';
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>5e-3 || any(pdraw_vec<bounds.lb) || any(pdraw_vec>bounds.ub)
%$     error('Gamma prior wrong')
%$ end
%$ 
%$ %% inverse gamma distribution (type 1)
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 4;%Shape 
%$ estim_params_.param_vals(1,6)=1.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=1;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ bounds = prior_bounds(bayestopt_,options_)';
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>5e-3 || any(pdraw_vec<bounds.lb) || any(pdraw_vec>bounds.ub)
%$     error('inverse gamma distribution (type 1) prior wrong')
%$ end
%$ 
%$ %% Uniform
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 5;%Shape 
%$ estim_params_.param_vals(1,6)=1.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=NaN;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ bounds = prior_bounds(bayestopt_,options_)';
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>5e-3 || any(pdraw_vec<bounds.lb) || any(pdraw_vec>bounds.ub)
%$     error('Uniform prior wrong')
%$ end
%$ 
%$ 
%$ %% inverse gamma distribution (type 2)
%$ estim_params_.param_vals(1,3)= -Inf;%LB
%$ estim_params_.param_vals(1,4)= +Inf;%UB
%$ estim_params_.param_vals(1,5)= 6;%Shape 
%$ estim_params_.param_vals(1,6)=1.5;
%$ estim_params_.param_vals(1,7)=0.01;
%$ estim_params_.param_vals(1,8)=1;
%$ estim_params_.param_vals(1,9)=NaN;
%$ 
%$ [xparam1, estim_params_, bayestopt_, lb, ub, M_]=set_prior(estim_params_, M_, options_);
%$ bounds = prior_bounds(bayestopt_,options_)';
%$ 
%$ pdraw = prior_draw(1,0);
%$ pdraw_vec=NaN(ndraws,1);
%$ for ii=1:ndraws
%$     pdraw_vec(ii)=prior_draw(0,0);
%$ end
%$ 
%$ if abs(mean(pdraw_vec)-estim_params_.param_vals(1,6))>5e-3 || any(pdraw_vec<bounds.lb) || any(pdraw_vec>bounds.ub)
%$     error('inverse gamma distribution (type 2) prior wrong')
%$ end
%$ 
%@eof:1
