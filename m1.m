%% Setup
rng(1);
clc
close all
clearvars
addpath('src');

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
title('ACF of residuals – SM-LGP_1', 'FontSize', fs);
set(gca, 'FontSize', fs, 'LineWidth', lw);

% 2) Time-series plot of residuals
subplot(1,3,2);
scatter(fitted, res_sta, 'filled');
title('Residuals vs Fitted – SM-LGP_1', 'FontSize', fs);
xlabel('Fitted values', 'FontSize', fs);
ylabel('Residuals', 'FontSize', fs);
set(gca, 'FontSize', fs, 'LineWidth', lw);
grid on;

% 3) QQ-plot
subplot(1,3,3);
qqplot(res_sta);
title('ACF – SM-LGP_1', 'Interpreter','tex', 'FontSize', fs);
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

%% PGA ShakeMap

lat_limits = [40.7782   40.8854];
lon_limits = [14.0275   14.2293];

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
c2.Label.String = "Estimated PGA (%g)"; % Label for the colorb
c2.Label.FontSize = 15; 
c2.LineWidth = 2;   
c2.Label.FontWeight = 'bold'; 
c2.TickLabelInterpreter = 'tex';
hold on
geoplot(italy, 'k', 'LineWidth', 2);  % 'k' = black line
title("Shakemap employing PGA spatial model")
geolimits(lat_limits, lon_limits)
hold on
geoscatter(event_info.latitude, event_info.longitude, 400, 'p', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', 'r', 'LineWidth', 2);
ax = gca;
ax.TickLabelFormat = 'dd';
ax.FontSize = 20;
ax.LatitudeLabel.String = '';
ax.LongitudeLabel.String = '';
set(gcf, 'Position', [100 100 1000 900]);
pos = ax.Position;  % posizione normalizzata dell'axes nella figura

annotation('rectangle', pos, ...
    'Color', 'k', ...      % colore bordo
    'LineWidth', 2);       % spessore bordo

save("worspaces tries\m1.mat")