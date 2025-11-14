%% Setup
% rng(0);
clc
close all
clearvars
addpath('src');

load data/input/EQN_data.mat                            % g acceleration detections -> smarthphones
load data/input/EQN_felt.mat                            % scalar acceleration detections -> smarthphones
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

%% EQN data filtering:
% filtering on: window time, distance, maximum acceleration, on a zone capture inside a squared area

% filtering on window time
L = EQN_shake_sub.data > event_info.date & EQN_shake_sub.data < event_info.date + seconds(10);
EQN_data_subset = EQN_shake_sub(L,:);

% filtering on distance
d = distdim(distance(event_info.latitude, event_info.longitude, EQN_data_subset.latitude, EQN_data_subset.longitude), 'deg', 'km');
L = d < data_radius;
EQN_data_subset = EQN_data_subset(L,:);

% filtering on the maximum acceleration
L = EQN_data_subset.max_acc < 5;
EQN_data_subset = EQN_data_subset(L,:);

% filtering on the zone
L = EQN_data_subset.longitude > 14 & EQN_data_subset.longitude < 14.21 & EQN_data_subset.latitude < 40.88;  % filtering on the zone
EQN_data_subset = EQN_data_subset(L,:);

% Remove duplicate latitude-longitude pairs
[~, uniqueIdx] = unique([EQN_data_subset.latitude, EQN_data_subset.longitude], 'rows');
EQN_data_subset = EQN_data_subset(uniqueIdx, :);

% Change name to PSA (peak smartphone accelearation) is already in [g]
EQN_data_subset.PSA = EQN_data_subset.max_acc;

%% EQN felt filtering:

% filtering on distance
d = distdim(distance(event_info.latitude, event_info.longitude, EQN_felt.latitude, EQN_felt.longitude), 'deg', 'km');
L = d < data_radius;
EQN_felt_subset = EQN_felt(L,:);

% filtering on the maximum intensity -> scalar value
L = EQN_felt_subset.intensity <= 12;
EQN_felt_subset = EQN_felt_subset(L,:);

% filtering on the zone
L = EQN_felt_subset.longitude > 14 & EQN_felt_subset.longitude < 14.21 & EQN_felt_subset.latitude < 40.88;  % filtering on the zone
EQN_felt_subset = EQN_felt_subset(L,:);

% Remove duplicate latitude-longitude pairs
[~, uniqueIdx] = unique([EQN_felt_subset.latitude, EQN_felt_subset.longitude], 'rows');
EQN_felt_subset = EQN_felt_subset(uniqueIdx, :);

% Calcolo della PGA in g secondo Faenza & Michelini (2010)
EQN_felt_subset.PSfA = 10.^((EQN_felt_subset.intensity - 1.68) / 2.58) / 981;


%% INGV data filtering
% filtering only on the radius
% stations have accurate accelerations

L = station_data.epi_separation <= data_radius;
station_data.latitude = station_data.latitude(L);
station_data.longitude = station_data.longitude(L);
station_data.pga = station_data.pga(L);
station_data.epi_separation = station_data.epi_separation(L);

%% After filtering the data

% Compute global latitude and longitude limits
all_lat = [station_data.latitude; EQN_data_subset.latitude; EQN_felt_subset.latitude; event_info.latitude];
all_lon = [station_data.longitude; EQN_data_subset.longitude; EQN_felt_subset.longitude; event_info.longitude];

lat_margin = 0.1 * (max(all_lat) - min(all_lat)); % 10% margin
lon_margin = 0.1 * (max(all_lon) - min(all_lon)); % 10% margin

lat_limits = [min(all_lat) - lat_margin, max(all_lat) + lat_margin];
lon_limits = [min(all_lon) - lon_margin, max(all_lon) + lon_margin];

figure
tiledlayout(2,3);

nexttile
gs1 = geoscatter(station_data.latitude, station_data.longitude, 'o', 'filled');
gs1.MarkerEdgeColor = [0 0 0];
gs1.MarkerFaceColor = [1 0 0]; % Red
hold on
geoscatter(event_info.latitude, event_info.longitude, 100, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'y', 'LineWidth', 1.5);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits); % Set uniform limits
title("Station recordings")
legend(["Stations", "Epicenter"], 'Location', 'northwest')

nexttile
gs1 = geoscatter(station_data.latitude, station_data.longitude, 'o', 'filled');
gs1.MarkerEdgeColor = [0 0 0];
gs1.MarkerFaceColor = [1 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 100, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'y', 'LineWidth', 1.5);
hold on
gs2 = geoscatter(EQN_data_subset.latitude, EQN_data_subset.longitude, '*', 'filled');
gs2.MarkerEdgeColor = [0 0 1];
gs2.MarkerFaceColor = [0 0 1];
geobasemap("streets-light")
geolimits(lat_limits, lon_limits); % Set uniform limits
title("Station recordings + smartphones")
legend(["Stations", "Epicenter", "Smartphone"], 'Location', 'northwest')

nexttile
gs1 = geoscatter(station_data.latitude, station_data.longitude, 'o', 'filled');
gs1.MarkerEdgeColor = [0 0 0];
gs1.MarkerFaceColor = [1 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 100, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'y', 'LineWidth', 1.5);
hold on
gs2 = geoscatter(EQN_felt_subset.latitude, EQN_felt_subset.longitude, '*', 'filled');
gs2.MarkerEdgeColor = [0 0 1];
gs2.MarkerFaceColor = [0 0 1];
geobasemap("streets-light")
geolimits(lat_limits, lon_limits); % Set uniform limits
title("Station recordings + smartphones felt")
legend(["Stations", "Epicenter", "Smartphone felt"], 'Location', 'northwest')

nexttile
gs2 = geoscatter(station_data.latitude, station_data.longitude, 50, station_data.pga, 'o', 'filled');
gs2.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 100, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'y', 'LineWidth', 1.5);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits); % Set uniform limits
title("Stations' pga")
colormap('parula');
colorbar;
c2 = colorbar;
c2.Label.String = "Stations' pga";

nexttile
gs2 = geoscatter(EQN_data_subset.latitude, EQN_data_subset.longitude, 50, EQN_data_subset.max_acc, 'o', 'filled');
gs2.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 100, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'y', 'LineWidth', 1.5);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits); % Set uniform limits
title("Smartphones' pga")
colormap('parula');
colorbar;
c2 = colorbar;
c2.Label.String = "Smartphones' pga";

nexttile
gs2 = geoscatter(EQN_felt_subset.latitude, EQN_felt_subset.longitude, 50, EQN_felt_subset.PSfA, 'o', 'filled');
gs2.MarkerEdgeColor = [0 0 0];
hold on
geoscatter(event_info.latitude, event_info.longitude, 100, 'p', ...
    'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'y', 'LineWidth', 1.5);
geobasemap("streets-light")
geolimits(lat_limits, lon_limits); % Set uniform limits
title("Smartphones' felt pga")
colormap('parula');
colorbar;
c2 = colorbar;
c2.Label.String = "Smartphones' felt pga";


%% DCM estimation (only spatial)

obj_stem_gridlist_p = stem_gridlist();

%%%% I equation of the DCM model
ground.Y{1} = log(station_data.pga);                                              % 1st log respose variable
ground.Y_name{1} = 'INGV PGA';
ground.coordinates{1} = [station_data.latitude, station_data.longitude];
ground.X_p{1} = ones(length(ground.Y{1}),1);                                      % costante davanti alla latente => non ho covariate quindi passo matrice di 1
ground.X_p_name{1} = {'constant'};

obj_stem_grid = stem_grid(ground.coordinates{1}, 'deg', 'sparse', 'point');
obj_stem_gridlist_p.add(obj_stem_grid);

% for each station is going to take the closer anomaly
% anomaly: how much the seismic wave is amplified in that spatial site
% ~ we dont need the output but just the index
anomaly_stations = zeros(length(station_data.pga),1);
for i=1:length(station_data.pga)
    [~,lat_idx] = min(abs(station_data.latitude(i) - anomaly.LAT(:,1)));
    [~,lon_idx] = min(abs(station_data.longitude(i) - anomaly.LON(1,:)));

    anomaly_stations(i)=anomaly.mean_anomaly(lat_idx,lon_idx);
end

% distance from the epicenter, which is based on the depth of the earthquake and
% the distance from the station
x_distance_stations = distdim(distance(event_info.latitude, event_info.longitude, ground.coordinates{1}(:,1), ground.coordinates{1}(:,2)), 'deg', 'km');
x_distance_stations = sqrt(event_info.depth^2 + 4*R*(R - event_info.depth).*sin(x_distance_stations/(2*R)).^2);

% covariate: costant, distance from the epicenter, aplification of the wave
ground.X_beta{1} = [ones(length(ground.Y{1}),1) x_distance_stations anomaly_stations];
ground.X_beta_name{1} = {'constant', 'distance', 'anomaly'};


%%%% II equation of the DCM model:
ground.Y{2} = log(EQN_data_subset.PSA);        % 2nd log respose varible: smarthphones acceleration
ground.Y_name{2} = 'EQN PSA';
ground.coordinates{2} = [EQN_data_subset.latitude, EQN_data_subset.longitude];

ground.X_p{2} = ones(length(ground.Y{2}),1);    % covariate davanti alla latente costante
ground.X_p_name{2} = {'constant'};

obj_stem_grid = stem_grid(ground.coordinates{2}, 'deg', 'sparse', 'point');
obj_stem_gridlist_p.add(obj_stem_grid);

x_distance_smartphones = distdim(distance(event_info.latitude, event_info.longitude,ground.coordinates{2}(:,1), ground.coordinates{2}(:,2)), 'deg', 'km');
x_distance_smartphones = sqrt(event_info.depth^2 + 4*R*(R - event_info.depth).*sin(x_distance_smartphones/(2*R)).^2);

% for each smarthphone is going to take the closer anomaly
% ~ we dont need the output but just the index
anomaly_smartphones = zeros(height(EQN_data_subset),1);
for i=1:height(EQN_data_subset)
    [~,lat_idx] = min(abs(EQN_data_subset.latitude(i)-anomaly.LAT(:,1)));
    [~,lon_idx] = min(abs(EQN_data_subset.longitude(i)-anomaly.LON(1,:)));
    anomaly_smartphones(i)=anomaly.mean_anomaly(lat_idx,lon_idx);
end

% distance from the epicenter
ground.X_beta{2} = [ones(length(ground.Y{2}),1) x_distance_smartphones anomaly_smartphones];        % covariates
ground.X_beta_name{2} = {'constant', 'distance', 'anomaly'};


%%%% III equation of the DCM model:
ground.Y{3} = log(EQN_felt_subset.PSfA);        % 2nd log respose varible: smarthphones acceleration
ground.Y_name{3} = 'EQN PSA felt';
ground.coordinates{3} = [EQN_felt_subset.latitude, EQN_felt_subset.longitude];

ground.X_p{3} = ones(length(ground.Y{3}),1);    % covariate davanti alla latente costante
ground.X_p_name{3} = {'constant'};

x_distance_smartphones_felt = distdim(distance(event_info.latitude, event_info.longitude,ground.coordinates{3}(:,1), ground.coordinates{3}(:,2)), 'deg', 'km');
x_distance_smartphones_felt = sqrt(event_info.depth^2 + 4*R*(R - event_info.depth).*sin(x_distance_smartphones_felt/(2*R)).^2);

% for each smarthphone is going to take the closer anomaly
% ~ we dont need the output but just the index
anomaly_smartphones_felt = zeros(height(EQN_felt_subset),1);
for i=1:height(EQN_felt_subset)
    [~,lat_idx] = min(abs(EQN_felt_subset.latitude(i)-anomaly.LAT(:,1)));
    [~,lon_idx] = min(abs(EQN_felt_subset.longitude(i)-anomaly.LON(1,:)));
    anomaly_smartphones_felt(i)=anomaly.mean_anomaly(lat_idx,lon_idx);
end

% distance from the epicenter
ground.X_beta{3} = [ones(length(ground.Y{3}),1) x_distance_smartphones_felt anomaly_smartphones_felt];        % covariates
ground.X_beta_name{3} = {'constant', 'distance', 'anomaly'};

%% Save subsets

EQNF_subset = EQN_felt_subset;
EQNF_subset.constant = ones(length(ground.Y{3}), 1);
EQNF_subset.distance = x_distance_smartphones_felt;
EQNF_subset.anomaly = anomaly_smartphones_felt;
save('filtering/EQNF_subset.mat', 'EQNF_subset');
clear EQNS_subset EQNF_subset

%% load filtered subset

load("data\input\EQNF_subset_fitered.mat")

%%%% III equation of the DCM model:
ground.Y{3} = log(EQNF_subset_fitered.PSfA);
ground.Y_name{3} = 'EQN PSA felt';
ground.coordinates{3} = [EQNF_subset_fitered.latitude, EQNF_subset_fitered.longitude];

ground.X_p{3} = EQNF_subset_fitered.constant;
ground.X_p_name{3} = {'constant'};

obj_stem_grid = stem_grid(ground.coordinates{3}, 'deg', 'sparse', 'point');
obj_stem_gridlist_p.add(obj_stem_grid);

% distance from the epicenter
ground.X_beta{3} = [EQNF_subset_fitered.constant EQNF_subset_fitered.distance EQNF_subset_fitered.anomaly];        % covariates
ground.X_beta_name{3} = {'constant', 'distance', 'anomaly'};

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

num_total = height(EQN_data_subset);
S_val_sma = randperm(num_total, 1);

num_total = height(EQNF_subset_fitered);
S_val_felt = randperm(num_total, 1);


% model definition
obj_stem_validation = stem_validation({'INGV PGA', 'EQN PSA', 'EQN PSA felt'}, {S_val_sta, S_val_sma, S_val_felt}, 0, {'point','point','point'});
obj_stem_datestamp = stem_datestamp('01-01-2024 00:00:00', '01-01-2024 00:00:00', 1);   % random date D-STEM wants it
obj_stem_modeltype = stem_modeltype('DCM');                                             % stem_data object creation
obj_stem_data = stem_data(obj_stem_varset_p, obj_stem_gridlist_p, [], [], obj_stem_datestamp, obj_stem_validation, obj_stem_modeltype);

% stem_par object creation
obj_stem_par_constraints = stem_par_constraints();
obj_stem_par = stem_par(obj_stem_data, 'exponential',obj_stem_par_constraints);

% obj_stem_model = SP_model_estimation(obj_stem_data, obj_stem_par);
obj_stem_model = stem_model(obj_stem_data, obj_stem_par);
obj_stem_model.stem_data.standardize;

% Starting values
% obj_stem_par.beta = obj_stem_model.get_beta0;                      % provides the initial values of the beta parameter

beta0_est =  [0.0004, -0.9087, 0.1073, -0.2235, -0.6492, 0.0718, 0.0239, -0.4372, 0.0892]';
obj_stem_par.beta = beta0_est;
obj_stem_par.theta_p = 0.0179;                                      % must be provided in [km] regardless of the unit of measure of the gri
obj_stem_par.v_p = [0.2930, 0.1852, 0.0161;
                    0.1852, 0.3552, 0.1051;
                    0.0161, 0.1051, 0.0388];                         % covariance matrix of the latents variables
obj_stem_par.sigma_eps = diag([0.000014 0.3933 0.7847]);             % error variance one for the stations and one for the smarthphones
obj_stem_model.set_initial_values(obj_stem_par);
obj_stem_EM_options = stem_EM_options();
obj_stem_EM_options.exit_tol_par = 0.002;                          % EM algorithm stops if the maximum relative norm of the model parameters between two consecutive iterations EM is below this value
obj_stem_EM_options.max_iterations = 500;                            % max iterations EM algorithm
obj_stem_model.EM_estimate(obj_stem_EM_options);            
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

save("worspaces tries\m3.mat")