%% Setup
rng(1);
clc
close all
clearvars
addpath('src');

load data/output/anomaly_smartphones1_stations1.mat     % static covariate

% Information about the analyzed earthquake
event_info.date = datetime('2025-03-13 00:25:02');      % date of the earthquake
event_info.latitude = 40.82;                            % latitude of the earthquake
event_info.longitude = 14.15;                           % longitude of the earthquake
event_info.depth = 2.5;                                 % depth of the earthquake
event_info.magnitude = 4.4;                             % magnitude of the earthquake

R = 6371;                                               % Earth radius (don't take data that are too far from our area)
data_radius = 10;                                       % km


%% INGV stationlist file reading:
% filtering the specific detections associated to our selected event_idx
% from a json file based on the date we have collected before

file_name = ['data/input/stationlist', '.json'];
txt = fileread(file_name);

% create the matlab structure of the station_data file
stationlist = jsondecode(txt);
station_data.latitude = [];
station_data.longitude = [];
station_data.pga = [];                          % response variable im interested into
counter = 1;
for i = 1 : length(stationlist.features)
    pga = stationlist.features(i).properties.pga;
    epi_distance = stationlist.features(i).properties.distance;

    % filtering the accelerations that are about a threshold
    if isnumeric(pga)
        if pga > 0.01
            station_data.pga(counter,1) = pga / 100;                                                    % pga: peak graound acceleration
            station_data.epi_separation(counter,1) = stationlist.features(i).properties.distance;       % distance from epicenter
            station_data.latitude(counter,1) = stationlist.features(i).geometry.coordinates(2);         % latitude of the station
            station_data.longitude(counter,1) = stationlist.features(i).geometry.coordinates(1);        % longitude of the station
            counter = counter + 1;
        end
    end
end


%% INGV data filtering
% filtering only on the radius
% stations have accurate accelerations

L = station_data.epi_separation <= data_radius;
station_data.latitude = station_data.latitude(L);
station_data.longitude = station_data.longitude(L);
station_data.pga = station_data.pga(L);
station_data.epi_separation = station_data.epi_separation(L);

%% DCM estimation (only spatial)

obj_stem_gridlist_p = stem_gridlist();

%%%% I equation of the DCM model
ground.Y{1} = log10(station_data.pga);                                              % 1st log respose variable
ground.Y_name{1} = 'INGV PGA';
ground.coordinates{1} = [station_data.latitude, station_data.longitude];
ground.X_p{1} = ones(length(ground.Y{1}),1);                                      % costante davanti alla latente => non ho covariate quindi passo matrice di 1
ground.X_p_name{1} = {'constant'};

obj_stem_grid = stem_grid(ground.coordinates{1}, 'deg', 'sparse', 'point');
obj_stem_gridlist_p.add(obj_stem_grid);

% distance from the epicenter, which is based on the depth of the earthquake and
% the distance from the station
x_distance_stations = distdim(distance(event_info.latitude, event_info.longitude, ground.coordinates{1}(:,1), ground.coordinates{1}(:,2)), 'deg', 'km');
x_distance_stations = sqrt(event_info.depth^2 + 4*R*(R - event_info.depth).*sin(x_distance_stations/(2*R)).^2);

% covariate: costant, distance from the epicenter, aplification of the wave
ground.X_beta{1} = [ones(length(ground.Y{1}),1) x_distance_stations];
ground.X_beta_name{1} = {'constant', 'distance'};


%% Model

obj_stem_varset_p = stem_varset(ground.Y, ground.Y_name, [], [], ...
    ground.X_beta, ground.X_beta_name, ...
    [], [], ...
    ground.X_p, ground.X_p_name);

% Validation
val_clustering = {};
val_clustering.choosed = ones(6,2);
val_clustering.cluster_coordinates{1} = [9 22 23 7 20];
val_clustering.cluster_coordinates{2} = [4 3 19];
val_clustering.cluster_coordinates{3} = [29 8 28 16 33];
val_clustering.cluster_coordinates{4} = [1 5 6 11 12 14 15 17 30 31 32];
val_clustering.cluster_coordinates{5} = [18 2 34 24];
val_clustering.cluster_coordinates{6} = [27 10 25 21 26];
val_clustering.cluster_coordinates{7} = [13];    % only one point not going to include it into the validation 
clusters = 7;

S_val_sta = [];

for i = 1:clusters - 1
    cluster = val_clustering.cluster_coordinates{i};
    unique_items = unique(cluster); 
    num_to_select = round(size(cluster , 2)/2) - 1;
    
    if num_to_select > 0
        selected_indices = randperm(length(unique_items), num_to_select);
        selected_items = unique_items(selected_indices);
        S_val_sta = [S_val_sta selected_items];
        for k = 1:length(selected_items)
            idx = selected_items(k);
            val_clustering.choosed(end+1, :) = [station_data.latitude(idx), station_data.longitude(idx)];
        end
    end
end


% model definition
obj_stem_validation = stem_validation({'INGV PGA'}, {S_val_sta}, 0, {'point'});
obj_stem_datestamp = stem_datestamp('01-01-2024 00:00:00', '01-01-2024 00:00:00', 1);   % random date D-STEM wants it
obj_stem_modeltype = stem_modeltype('DCM');                                             % stem_data object creation
obj_stem_data = stem_data(obj_stem_varset_p, obj_stem_gridlist_p, [], [], obj_stem_datestamp, obj_stem_validation, obj_stem_modeltype);

% stem_par object creation
obj_stem_par_constraints = stem_par_constraints();
obj_stem_par = stem_par(obj_stem_data, 'exponential',obj_stem_par_constraints);

% obj_stem_model = SP_model_estimation(obj_stem_data, obj_stem_par);
obj_stem_model = stem_model(obj_stem_data, obj_stem_par);
% obj_stem_model.stem_data.standardize;

% Starting values
obj_stem_par.beta = obj_stem_model.get_beta0;                       % provides the initial values of the beta parameter
obj_stem_par.theta_p = 1;                                      % must be provided in [km] regardless of the unit of measure of the gri
obj_stem_par.v_p = 1;                                               % covariance matrix of the latents variables
obj_stem_par.sigma_eps = 1;                                              % error variance one for the stations and one for the smarthphones
obj_stem_model.set_initial_values(obj_stem_par);
obj_stem_EM_options = stem_EM_options();
obj_stem_EM_options.exit_tol_par = 0.002;                          % EM algorithm stops if the maximum relative norm of the model parameters between two consecutive iterations EM is below this value
obj_stem_EM_options.max_iterations = 1000;                          % max iterations EM algorithm

tic;    % avvia timer solo per l’EM
obj_stem_model.EM_estimate(obj_stem_EM_options);
time_EM = toc;   % tempo totale EM in secondi

obj_stem_model.set_varcov;                                         % variance-covariance matrix of the estimated model parameters (std)
obj_stem_model.print()
obj_stem_model.print_par()
% obj_stem_model.set_logL;

corrcov(obj_stem_model.stem_par.v_p)

%% Statistics

statistics_md = {};
statistics_md.sigma_eps = obj_stem_model.stem_EM_result.stem_par.sigma_eps;
statistics_md.v_p = obj_stem_model.stem_EM_result.stem_par.v_p;
statistics_md.theta_p = obj_stem_model.stem_EM_result.stem_par.theta_p;

statistics_md.R2_t = obj_stem_model.stem_EM_result.R2;
statistics_md.R2_v = obj_stem_model.stem_validation_result{1}.cv_R2_s;
statistics_md.EM_iterations = obj_stem_model.stem_EM_result.iterations;
statistics_md.res = obj_stem_model.stem_validation_result{1}.res_back;              % measure unit of the problem
statistics_md.RMSE_v = sqrt(mean(statistics_md.res.^2));
statistics_md.time_EM = time_EM;                                                    % tempo totale numero iterazioni

fprintf("Tempo totale EM: %.4f secondi\n", time_EM);

%% Residuals analysis
res_sta =  obj_stem_model.stem_validation_result{1}.res;

% Plot residuals
figure;
subplot(2,1,1); autocorr(res_sta); title('ACF of res\_sta');
subplot(2,1,2); plot(res_sta); title('Residuals: res\_sta');

% Autocorrelation test
[h_sta, p_sta] = lbqtest(res_sta);

% Test for ARCH effects (heteroscedasticity)
[h_arch_sta, p_arch_sta] = archtest(res_sta);

% Perform statistical tests
statistics_md.res_test_lbqtest = [h_sta, p_sta];
statistics_md.res_test_archtest = [h_arch_sta, p_arch_sta];
save("worspaces tries\m1.mat")