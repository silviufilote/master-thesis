%% Setup
rng(1);
clc
close all
clearvars
addpath('src');

load data/input/EQN_data.mat                            % g acceleration detections -> smarthphones
load data/input/EQN_felt.mat                            % scalar acceleration detections -> smarthphones

% Information about the analyzed earthquake
event_info.date = datetime('2025-03-13 00:25:02');      % date of the earthquake
event_info.latitude = 40.82;                            % latitude of the earthquake
event_info.longitude = 14.15;                           % longitude of the earthquake
event_info.depth = 2.5;                                 % depth of the earthquake
event_info.magnitude = 4.4;                             % magnitude of the earthquake

R = 6371;                                               % Earth radius (don't take data that are too far from our area)
data_radius = 10;                                       % km


% Settings for graphs
fs = 10;       % font size
lw = 1.5;      % line width


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
            station_data.pga(counter,1) = pga / 100;                                                    % pga: peak graound acceleration [g] from cm/s^2 to m/s^2 100 factor
            station_data.epi_separation(counter,1) = stationlist.features(i).properties.distance;       % distance from epicenter
            station_data.latitude(counter,1) = stationlist.features(i).geometry.coordinates(2);         % latitude of the station
            station_data.longitude(counter,1) = stationlist.features(i).geometry.coordinates(1);        % longitude of the station
            counter = counter + 1;
        end
    end
end

%% EQN data filtering - smarthphones
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

% Change name to PSA (peak smartphone accelearation) is already in [%g] = cm
EQN_data_subset.PSA = EQN_data_subset.max_acc;

%% EQN felt filtering - felt reports

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

% Calcolo della PGA in g secondo Faenza & Michelini (2010) [%g]
EQN_felt_subset.CPGA = 10.^((EQN_felt_subset.intensity - 1.68) / 2.58) / 100;  % unit [%g]


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


%%%% II equation of the DCM model:
ground.Y{2} = log10(EQN_data_subset.PSA);        % 2nd log respose varible: smarthphones acceleration
ground.Y_name{2} = 'EQN PSA';
ground.coordinates{2} = [EQN_data_subset.latitude, EQN_data_subset.longitude];

ground.X_p{2} = ones(length(ground.Y{2}),1);    % covariate davanti alla latente costante
ground.X_p_name{2} = {'constant'};

x_distance_smartphones = distdim(distance(event_info.latitude, event_info.longitude,ground.coordinates{2}(:,1), ground.coordinates{2}(:,2)), 'deg', 'km');
x_distance_smartphones = sqrt(event_info.depth^2 + 4*R*(R - event_info.depth).*sin(x_distance_smartphones/(2*R)).^2);

% distance from the epicenter
ground.X_beta{2} = [ones(length(ground.Y{2}),1) x_distance_smartphones];        % covariates
ground.X_beta_name{2} = {'constant', 'distance'};


%%%% III equation of the DCM model:
ground.Y{3} = log10(EQN_felt_subset.CPGA);        % 2nd log respose varible: smarthphones acceleration
ground.Y_name{3} = 'EQN PSA felt';
ground.coordinates{3} = [EQN_felt_subset.latitude, EQN_felt_subset.longitude];

ground.X_p{3} = ones(length(ground.Y{3}),1);    % covariate davanti alla latente costante
ground.X_p_name{3} = {'constant'};

x_distance_smartphones_felt = distdim(distance(event_info.latitude, event_info.longitude,ground.coordinates{3}(:,1), ground.coordinates{3}(:,2)), 'deg', 'km');
x_distance_smartphones_felt = sqrt(event_info.depth^2 + 4*R*(R - event_info.depth).*sin(x_distance_smartphones_felt/(2*R)).^2);

% distance from the epicenter
ground.X_beta{3} = [ones(length(ground.Y{3}),1) x_distance_smartphones_felt];        % covariates
ground.X_beta_name{3} = {'constant', 'distance'};

%% Save subsets

EQN_data_filtered = EQN_data_subset;
EQN_data_filtered.constant = ones(length(ground.Y{2}),1);
EQN_data_filtered.distance = x_distance_smartphones;
save('filtering/PSA_subset.mat', 'EQN_data_filtered');


EQNF_subset = EQN_felt_subset;
EQNF_subset.constant = ones(length(ground.Y{3}), 1);
EQNF_subset.distance = x_distance_smartphones_felt;
save('filtering/EQNF_subset.mat', 'EQNF_subset');
clear EQNS_subset EQNF_subset

%% load filtered subset
load("filtering\PSA_filtered.mat")
load("filtering\CPGA_filtered.mat")

%%%% II equation of the DCM model:
ground.Y{2} = log10(PSA_filtered.PSA);        % 2nd log respose varible: smarthphones acceleration
ground.Y_name{2} = 'EQN PSA';
ground.coordinates{2} = [PSA_filtered.latitude, PSA_filtered.longitude];

ground.X_p{2} = PSA_filtered.constant;
ground.X_p_name{2} = {'constant'};

obj_stem_grid = stem_grid(ground.coordinates{2}, 'deg', 'sparse', 'point');
obj_stem_gridlist_p.add(obj_stem_grid);

x_distance_smartphones = distdim(distance(event_info.latitude, event_info.longitude,ground.coordinates{2}(:,1), ground.coordinates{2}(:,2)), 'deg', 'km');
x_distance_smartphones = sqrt(event_info.depth^2 + 4*R*(R - event_info.depth).*sin(x_distance_smartphones/(2*R)).^2);

% distance from the epicenter
ground.X_beta{2} = [PSA_filtered.constant PSA_filtered.distance];        % covariates
ground.X_beta_name{2} = {'constant', 'distance'};


%%%% III equation of the DCM model:
ground.Y{3} = log10(CPGA_filtered.CPGA);
ground.Y_name{3} = 'EQN PSA felt';
ground.coordinates{3} = [CPGA_filtered.latitude, CPGA_filtered.longitude];

ground.X_p{3} = CPGA_filtered.constant;
ground.X_p_name{3} = {'constant'};

obj_stem_grid = stem_grid(ground.coordinates{3}, 'deg', 'sparse', 'point');
obj_stem_gridlist_p.add(obj_stem_grid);

% distance from the epicenter
ground.X_beta{3} = [CPGA_filtered.constant CPGA_filtered.distance];        % covariates
ground.X_beta_name{3} = {'constant', 'distance'};



%% EDA 
eda.Y = {station_data.pga, PSA_filtered.PSA, CPGA_filtered.CPGA};
varNames = {'PGA', 'PSA', 'CPGA'};

% Basic descriptive statistics
for i = 1:3
    data = eda.Y{i};
    fprintf('\n--- Descriptive stats for %s ---\n', varNames{i});
    fprintf('Mean: %.4f\n', mean(data, 'omitnan'));
    fprintf('Std: %.4f\n', std(data, 'omitnan'));
    fprintf('Median: %.4f\n', median(data, 'omitnan'));
    fprintf('Min: %.4f\n', min(data));
    fprintf('Max: %.4f\n', max(data));
end

% Histograms + KDE with larger fonts
figure('Position',[0 0 1920 600])
for i = 1:3
    subplot(1,3,i)
    histogram(eda.Y{i}, 30, 'Normalization', 'pdf', 'FaceColor', [0.4 0.6 0.8])
    hold on
    [f, xi] = ksdensity(eda.Y{i});
    plot(xi, f, 'r-', 'LineWidth', 1.8)

    title(sprintf('Distribution of %s', varNames{i}), 'FontSize', 18)
    xlabel('Value', 'FontSize', 16)
    ylabel('Density', 'FontSize', 16)
    
    grid on
    set(gca, 'FontSize', 14)      % tick labels + axes
end

sgtitle('Distribution of Ground Motion Variables', 'FontSize', 20, 'FontWeight', 'bold')



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

num_total = height(CPGA_filtered);
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
% obj_stem_model.stem_data.standardize;

% Starting values
obj_stem_par.beta = obj_stem_model.get_beta0;
obj_stem_par.theta_p = 0.02;                                      % must be provided in [km] regardless of the unit of measure of the gri
obj_stem_par.v_p = [0.2930, 0.1852, 0.0161;
                    0.1852, 0.3552, 0.1051;
                    0.0161, 0.1051, 0.0388];                 % covariance matrix of the latents variables
obj_stem_par.sigma_eps = diag([0.28 0.40 0.90]);             % error variance one for the stations and one for the smarthphones
obj_stem_model.set_initial_values(obj_stem_par);
obj_stem_EM_options = stem_EM_options();
obj_stem_EM_options.exit_tol_par = 0.002;                          % EM algorithm stops if the maximum relative norm of the model parameters between two consecutive iterations EM is below this value
obj_stem_EM_options.max_iterations = 1000;                         % max iterations EM algorithm


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
statistics_md.beta = obj_stem_model.stem_EM_result.stem_par.beta;
statistics_md.v_p_cov = obj_stem_model.stem_EM_result.stem_par.v_p;
statistics_md.v_p_cor = corrcov(obj_stem_model.stem_par.v_p);
statistics_md.theta_p = obj_stem_model.stem_EM_result.stem_par.theta_p;

statistics_md.R2_t = obj_stem_model.stem_EM_result.R2;
statistics_md.R2_v = obj_stem_model.stem_validation_result{1}.cv_R2_s;
statistics_md.EM_iterations = obj_stem_model.stem_EM_result.iterations;
statistics_md.res = 10.^(obj_stem_model.stem_validation_result{1}.res);              % measure unit of the problem
statistics_md.RMSE_v = sqrt(mean(statistics_md.res.^2));
statistics_md.time_EM = time_EM;                                                    % tempo totale numero iterazioni

fprintf("Tempo totale EM: %.4f secondi\n", time_EM);


%% Residuals analysis
res_sta = statistics_md.res;
fitted = 10.^(obj_stem_model.stem_validation_result{1}.y_hat_back);

% Residual diagnostics
figure;

fs = 10;       % font size
lw = 1.5;      % line width

% 1) Autocorrelation function (ACF)
subplot(1,3,1);
autocorr(res_sta);
title('ACF of residuals – SM-LGP_3', 'FontSize', fs);
set(gca, 'FontSize', fs, 'LineWidth', lw);

% 2) Time-series plot of residuals
subplot(1,3,2);
scatter(fitted, res_sta, 'filled');
title('Residuals vs Fitted – SM-LGP_3', 'FontSize', fs);
xlabel('Fitted values', 'FontSize', fs);
ylabel('Residuals', 'FontSize', fs);
set(gca, 'FontSize', fs, 'LineWidth', lw);
grid on;

% 3) QQ-plot
subplot(1,3,3);
qqplot(res_sta);
title('ACF – SM-LGP_3', 'Interpreter','tex', 'FontSize', fs);
set(gca, 'FontSize', fs, 'LineWidth', lw);
set(gcf, 'Position', [100 100 1200 300]);

% Statistical tests
[h_sta, p_sta] = lbqtest(res_sta);              % Ljung–Box
[h_arch_sta, p_arch_sta] = archtest(res_sta);   % ARCH test
[h_sw, p_sw, W_sw] = swtest(res_sta, 0.05);     % Shapiro–Wilk

statistics_md.res_test_lbqtest   = [h_sta, p_sta];
statistics_md.res_test_archtest  = [h_arch_sta, p_arch_sta];
statistics_md.res_test_shapiroW  = [h_sw, p_sw, W_sw];


%% PGA mapping
lat = 40.73:(0.001/3):40.91;
lon = 14:(0.002/3):14.26;

[LON,LAT] = meshgrid(lon,lat);
krig_coordinates = [LAT(:) LON(:)];

obj_stem_krig_grid = stem_grid(krig_coordinates, 'deg','regular','pixel',size(LAT),'square', 0.001799/3,0.002376/3);

X_const = ones(length(krig_coordinates),1);
X_distance = distdim(distance(event_info.latitude, event_info.longitude, krig_coordinates(:,1), krig_coordinates(:,2)), 'deg', 'km');
X_distance = sqrt(event_info.depth^2 + 4*R*(R - event_info.depth).*sin(X_distance/(2*R)).^2);

X_krig = [X_const, X_distance];

obj_stem_krig_data = stem_krig_data(obj_stem_krig_grid, X_krig, {'constant','distance'});
obj_stem_krig = stem_krig(obj_stem_model, obj_stem_krig_data);

obj_stem_krig_options = stem_krig_options();
obj_stem_krig_options.block_size = 500;

obj_stem_krig_result = obj_stem_krig.kriging(obj_stem_krig_options);
save("worspaces tries\m3ns.mat")

%% PGA ShakeMap
pga_spatial_prediction = obj_stem_krig_result{1};
pga = pga_spatial_prediction.y_hat;
var_pga = pga_spatial_prediction.diag_Var_y_hat;

% PGA and its variance (uncertainty) are backtransformed and masked
pga_shakemap.pga = 10.^(pga + var_pga/2);
% pga_shakemap.pga = exp(pga + sqrt(var_pga));
pga_shakemap.var_pga = (10.^(var_pga)-1) .* 10.^(2*pga+var_pga);
pga_shakemap.var_pga_logscale = var_pga;
pga_shakemap.lat = LAT;
pga_shakemap.lon = LON;

% Shapefiles of napoli - use geoplot to create borders
borders = readgeotable("maps\napoli.shp");
italy = borders(strcmp(borders.reg_name, 'Campania'), :);

figure                                             
gs1 = geoscatter(LAT(:), LON(:), 10, pga_shakemap.pga(:));
alpha(0.6); % Transparency so coastlines and borders are visible
geobasemap("streets-light") % Set basemap
colormap('parula');  % Apply cool colormap here
colorbar;
c2 = colorbar;
c2.Label.String = "Estimated PGA (g)"; % Label for the colorb
c2.Label.FontSize = 10;    
c2.Label.FontWeight = 'bold'; 
c2.TickLabelInterpreter = 'tex';
hold on
geoplot(italy, 'k', 'LineWidth', 2);  % 'k' = black line
title("Shakemap employing PGA + PSA + CPGA spatial model")
geolimits(lat_limits, lon_limits)
hold on
geoscatter(event_info.latitude, event_info.longitude, 100, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'y', 'LineWidth', 1.5);
ax = gca;
ax.TickLabelFormat = 'dd';
ax.FontSize = fs;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';
set(gcf, 'Position', [100 100 600 500]);

save("worspaces tries\prova m3.mat")
