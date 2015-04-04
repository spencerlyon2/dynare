function [results_cell] = execute_prior_posterior_function(posterior_function_name,M_,options_,oo_,estim_params_,bayestopt_,dataset_,dataset_info,type)
%[results_cell] = execute_prior_posterior_function(functionhandle,M_,options_,oo_,dataset_,estim_params_,bayestopt_,type)% This function executes a given function on draws of the posterior or prior distribution 
% Executes user provided function on prior or posterior draws
% 
% INPUTS
%   functionhandle               Handle to the function to be executed
%   M_           [structure]     Matlab's structure describing the Model (initialized by dynare, see @ref{M_}).
%   options_     [structure]     Matlab's structure describing the options (initialized by dynare, see @ref{options_}).
%   oo_          [structure]     Matlab's structure gathering the results (initialized by dynare, see @ref{oo_}).
%   estim_params_[structure]     Matlab's structure describing the estimated_parameters (initialized by dynare, see @ref{estim_params_}).
%   bayestopt_   [structure]     Matlab's structure describing the parameter options (initialized by dynare, see @ref{bayestopt_}).
%   dataset_     [structure]     Matlab's structure storing the dataset
%   dataset_info [structure]     Matlab's structure storing the information about the dataset
%   type         [string]        'prior' or 'posterior'
%
%
% OUTPUTS
%   results_cell    [cell]     ndrawsx1 cell array storing the results
%                                of the prior/posterior computations

% Copyright (C) 2013 Dynare Team
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

[directory,basename,extension] = fileparts(posterior_function_name);
if isempty(extension)
    extension = '.m';
end
fullname = [basename extension];
if ~strcmp(extension,'.m') %if not m-file
    error('The Posterior Function is not an m-file.')
elseif ~exist(fullname,'file') %if m-file, but does not exist
    error(['The Posterior Function ', fullname ,' was not found. Check the spelling.']);
end
%Create function handle
functionhandle=str2func(posterior_function_name);

% Get informations about the _posterior_draws files.
if strcmpi(type,'posterior')
    %% discard first mh_drop percent of the draws:
    CutSample(M_, options_, estim_params_);
    %% initialize metropolis draws
    [error_flag,junk,options_]= metropolis_draw(1,options_,estim_params_,M_);
    if error_flag
        error('EXECUTE_POSTERIOR_FUNCTION: The draws could not be initialized')
    end
    n_draws=options_.sub_draws;
elseif strcmpi(type,'prior')
    prior_draw(1);
    n_draws=options_.prior_draws;
else
    error('EXECUTE_POSTERIOR_FUNCTION: Unknown type!')
end

%get draws for later use
first_draw=GetOneDraw(type);
parameter_mat=NaN(n_draws,length(first_draw));
parameter_mat(1,:)=first_draw;
for draw_iter=2:n_draws
    parameter_mat(draw_iter,:) = GetOneDraw(type);
end

% get output size
try
    junk=functionhandle(parameter_mat(1,:),M_,options_,oo_,estim_params_,bayestopt_,dataset_,dataset_info);
catch err
    fprintf('\nEXECUTE_POSTERIOR_FUNCTION: Execution of prior/posterior function led to an error. Execution cancelled.\n')
    rethrow(err)
end

%initialize cell with number of columns
results_cell=cell(n_draws,size(junk,2));

%% compute function on draws
for draw_iter = 1:n_draws
    M_ = set_all_parameters(parameter_mat(draw_iter,:),estim_params_,M_);
    [results_cell(draw_iter,:)]=functionhandle(parameter_mat(draw_iter,:),M_,options_,oo_,estim_params_,bayestopt_,dataset_,dataset_info);
end
