clc
clearvars

R = 6371;

addpath('C:\Users\franc\stat Dropbox\Francesco Finazzi\D-STEM_dev\Src');

load data/input/EQN_data.mat
load data/input/event_list.mat

data_radius = 10; %km

flag_smartphones=[0 1 1];
flag_stations=[1 0 1];

for k=1:length(flag_smartphones)
    all_stations_lat=[];
    all_stations_lon=[];
    all_smartphones_lat=[];
    all_smartphones_lon=[];

    anomaly_input_data=cell(height(event_list)-1,1);
    anomaly_output_data=cell(height(event_list)-1,1);
    for z=2:height(event_list)
        clear station_data

        eq_latitude = event_list.latitude(z);
        eq_longitude = event_list.longitude(z);
        eq_depth = event_list.depth(z);
        eq_date = event_list.date(z);
        eq_magnitude = event_list.magnitude(z);

        %% INGV stationlist file reading
        if flag_stations(k)
            file_name = datestr(eq_date,"yyyy_mm_dd_HH_MM_SS");
            file_name = ['data/input/INGV_stationlist/stationlist_',file_name,'.json'];

            txt = fileread(file_name);

            stationlist = jsondecode(txt);
            eventid = str2double(stationlist.metadata.eventid);
            if not(eventid==event_list.eventid(z))
                error('Wrong stationlist file');
            end

            station_data.latitude=[];
            station_data.longitude=[];
            station_data.pga=[];
            counter=1;
            idx=[];
            for i=1:length(stationlist.features)
                pga = stationlist.features(i).properties.pga;
                epi_distance = stationlist.features(i).properties.distance;

                if isnumeric(pga)
                    if pga>0.01
                        station_data.pga(counter,1)=pga/100;
                        station_data.epi_separation(counter,1)=stationlist.features(i).properties.distance;
                        station_data.latitude(counter,1)=stationlist.features(i).geometry.coordinates(2);
                        station_data.longitude(counter,1)=stationlist.features(i).geometry.coordinates(1);

                        counter=counter+1;
                    end
                end
            end
            %% data selection
            L=station_data.epi_separation<=data_radius;
            station_data.latitude=station_data.latitude(L);
            station_data.longitude=station_data.longitude(L);
            station_data.pga=station_data.pga(L);
            station_data.epi_separation=station_data.epi_separation(L);

            all_stations_lat=cat(1,all_stations_lat,station_data.latitude);
            all_stations_lon=cat(1,all_stations_lon,station_data.longitude);
        end

        %% EQN data filtering
        if flag_smartphones(k)
            L=EQN_data.date>eq_date & EQN_data.date<eq_date+seconds(10);
            EQN_data_subset = EQN_data(L,:);
            anomaly_stacked = distdim(distance(eq_latitude,eq_longitude,EQN_data_subset.latitude,EQN_data_subset.longitude),'deg','km');
            L = anomaly_stacked<data_radius;
            EQN_data_subset=EQN_data_subset(L,:);
            L=EQN_data_subset.psma<5;
            EQN_data_subset=EQN_data_subset(L,:);
            L=EQN_data_subset.longitude>14&EQN_data_subset.longitude<14.21&EQN_data_subset.latitude<40.88;
            EQN_data_subset=EQN_data_subset(L,:);

            EQN_data_subset.psma = EQN_data_subset.psma/9.81;

            all_smartphones_lat=cat(1,all_smartphones_lat,EQN_data_subset.latitude);
            all_smartphones_lon=cat(1,all_smartphones_lon,EQN_data_subset.longitude);
        end

        if flag_smartphones(k) && flag_stations(k)
            anomaly_input_data{z-1}.EQN_data=EQN_data_subset;
            anomaly_input_data{z-1}.INGV_data=struct2table(station_data);
            anomaly_input_data{z-1}.eventid=eventid;
            anomaly_input_data{z-1}.eq_latitude=eq_latitude;
            anomaly_input_data{z-1}.eq_longitude=eq_longitude;
            anomaly_input_data{z-1}.eq_depth=eq_depth;
            anomaly_input_data{z-1}.eq_magnitude=eq_magnitude;
        end

        %% Model estimation
        obj_stem_gridlist_p = stem_gridlist();

        if flag_stations(k)
            ground.Y{1} = log(station_data.pga);
            ground.Y_name{1} = 'INGV PGA';
            ground.coordinates{1} = [station_data.latitude, station_data.longitude];
            ground.X_p{1} = ones(length(ground.Y{1}),1);
            ground.X_p_name{1} = {'constant'};
            obj_stem_grid = stem_grid(ground.coordinates{1}, 'deg', 'sparse', 'point');
            obj_stem_gridlist_p.add(obj_stem_grid);
            x_distance_stations = distdim(distance(eq_latitude, eq_longitude,ground.coordinates{1}(:,1),ground.coordinates{1}(:,2)),'deg','km');
            x_distance_stations = sqrt(eq_depth^2 + 4*R*(R - eq_depth).*sin(x_distance_stations/(2*R)).^2);

            ground.X_beta{1} = [ones(length(ground.Y{1}),1) x_distance_stations];
            ground.X_beta_name{1} = {'constant','distance'};

            if flag_smartphones(k)
                ground.Y{2} = log(EQN_data_subset.psma);
                ground.Y_name{2} = 'EQN PSmA';
                ground.coordinates{2} = [EQN_data_subset.latitude, EQN_data_subset.longitude];

                ground.X_p{2} = ones(length(ground.Y{2}),1);
                ground.X_p_name{2} = {'constant'};
                obj_stem_grid = stem_grid(ground.coordinates{2}, 'deg', 'sparse', 'point');
                obj_stem_gridlist_p.add(obj_stem_grid);

                x_distance_smartphones = distdim(distance(eq_latitude,eq_longitude,ground.coordinates{2}(:,1),ground.coordinates{2}(:,2)),'deg','km');
                x_distance_smartphones = sqrt(eq_depth^2 + 4*R*(R - eq_depth).*sin(x_distance_smartphones/(2*R)).^2);

                ground.X_beta{2} = [ones(length(ground.Y{2}),1) x_distance_smartphones];
                ground.X_beta_name{2} = {'constant','distance'};
            end
        else
            ground.Y{1} = log(EQN_data_subset.psma);
            ground.Y_name{1} = 'EQN PSmA';
            ground.coordinates{1} = [EQN_data_subset.latitude, EQN_data_subset.longitude];

            ground.X_p{1} = ones(length(ground.Y{1}),1);
            ground.X_p_name{1} = {'constant'};
            obj_stem_grid = stem_grid(ground.coordinates{1}, 'deg', 'sparse', 'point');
            obj_stem_gridlist_p.add(obj_stem_grid);

            x_distance_smartphones = distdim(distance(eq_latitude,eq_longitude,ground.coordinates{1}(:,1),ground.coordinates{1}(:,2)),'deg','km');
            x_distance_smartphones = sqrt(eq_depth^2 + 4*R*(R - eq_depth).*sin(x_distance_smartphones/(2*R)).^2);

            ground.X_beta{1} = [ones(length(ground.Y{1}),1) x_distance_smartphones];
            ground.X_beta_name{1} = {'constant','distance'};
        end

        obj_stem_varset_p = stem_varset(ground.Y, ground.Y_name, [], [], ...
            ground.X_beta, ground.X_beta_name, ...
            [], [], ...
            ground.X_p,ground.X_p_name);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        %      Model building     %
        %%%%%%%%%%%%%%%%%%%%%%%%%%%
        obj_stem_datestamp = stem_datestamp('01-01-2009 00:00', '01-01-2009 00:00', 1);

        %stem_data object creation
        obj_stem_modeltype = stem_modeltype('DCM');

        obj_stem_data = stem_data(obj_stem_varset_p, obj_stem_gridlist_p, ...
            [], [], obj_stem_datestamp, [], obj_stem_modeltype);

        %stem_par object creation
        obj_stem_par_constraints=stem_par_constraints();
        obj_stem_par = stem_par(obj_stem_data, 'exponential',obj_stem_par_constraints);
        %stem_model object creation
        obj_stem_model = stem_model(obj_stem_data, obj_stem_par);

        %obj_stem_model.stem_data.standardize;

        %Starting values
        obj_stem_par.beta = obj_stem_model.get_beta0;
        obj_stem_par.theta_p = 0.015;

        if flag_stations(k) && flag_smartphones(k)
            obj_stem_par.v_p=[1 0.99;0.99 1];
            obj_stem_par.sigma_eps = diag([0.03 0.03]);
        else
            if flag_stations(k)
                obj_stem_par.v_p=1;
                obj_stem_par.sigma_eps = 0.03;
            else
                obj_stem_par.v_p=0.7;
                obj_stem_par.sigma_eps = 0.03;
            end
        end

        obj_stem_model.set_initial_values(obj_stem_par);

        %Model estimation
        obj_stem_EM_options = stem_EM_options();
        obj_stem_EM_options.exit_tol_par=0.001;
        obj_stem_EM_options.max_iterations=200;

        obj_stem_model.EM_estimate(obj_stem_EM_options);

        lat = 40.77:0.0001799:40.91;
        lon = 14.00:0.0002376:14.25;

        [LON,LAT] = meshgrid(lon,lat);
        krig_coordinates = [LAT(:) LON(:)];

        obj_stem_krig_grid = stem_grid(krig_coordinates, 'deg',...
            'regular','pixel',size(LAT),'square',0.0001799,0.0002376);

        X_const = ones(length(krig_coordinates),1);
        X_distance = distdim(distance(eq_latitude,eq_longitude,krig_coordinates(:,1),krig_coordinates(:,2)),'deg','km');
        X_distance = sqrt(eq_depth^2 + 4*R*(R - eq_depth).*sin(X_distance/(2*R)).^2);

        X_krig = [X_const, X_distance];

        obj_stem_krig_data = stem_krig_data(obj_stem_krig_grid,X_krig,{'constant','distance'});
        obj_stem_krig = stem_krig(obj_stem_model,obj_stem_krig_data);

        obj_stem_krig_options = stem_krig_options();
        obj_stem_krig_options.block_size = 400;

        obj_stem_krig_result = obj_stem_krig.kriging(obj_stem_krig_options);

        anomaly_output_data{z-1}.anomaly = obj_stem_krig_result{1}.E_wp_y1;
        anomaly_var = reshape(obj_stem_krig_result{1}.diag_Var_wp_y1,size(obj_stem_krig_result{1}.E_wp_y1));
        anomaly_output_data{z-1}.anomaly_var = anomaly_var;
    end

    
    anomaly_stacked=[];
    anomaly_var_stacked=[];
    for i=1:length(anomaly_output_data)
        anomaly_stacked=cat(3,anomaly_stacked,anomaly_output_data{i}.anomaly);
        anomaly_var_stacked=cat(3,anomaly_var_stacked,anomaly_output_data{i}.anomaly_var);
    end
    anomaly_std_stacked=sqrt(anomaly_var_stacked);

    mean_anomaly=zeros(size(LAT));
    for i=1:size(mean_anomaly,1)
        for j=1:size(mean_anomaly,2)
            weights=1./squeeze(anomaly_std_stacked(i,j,:));
            mean_anomaly(i,j)=(squeeze(anomaly_stacked(i,j,:))'*weights)/sum(weights);
        end
    end

    anomaly.mean_anomaly=mean_anomaly;
    anomaly.LAT=LAT;
    anomaly.LON=LON;

    mean_anomaly_std=mean(anomaly_std_stacked,3);
    mean_anomaly_upper=anomaly.mean_anomaly+mean_anomaly_std;
    mean_anomaly_lower=anomaly.mean_anomaly-mean_anomaly_std;

    mean_anomaly_significant=nan(size(anomaly.mean_anomaly));
    mean_anomaly_significant(mean_anomaly_lower>0)=1;
    mean_anomaly_significant(mean_anomaly_upper<0)=-1;

    anomaly.mean_anomaly_significant=mean_anomaly_significant;
    anomaly.mean_anomaly_std=mean_anomaly_std;
    if flag_stations(k)
        anomaly.all_stations_lat=all_stations_lat;
        anomaly.all_stations_lon=all_stations_lon;
    end
    if flag_smartphones(k)
        anomaly.all_smartphones_lat=all_smartphones_lat;
        anomaly.all_smartphones_lon=all_smartphones_lon;
    end

    if flag_smartphones(k) && flag_stations(k)
        save data/output/anomaly_input_data.mat anomaly_input_data
    end

    save(['data/output/anomaly_smartphones',num2str(flag_smartphones(k)),'_stations',num2str(flag_stations(k))],'anomaly');
end
