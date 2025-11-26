%% Setup
clc
close all
clearvars
rng(1)

% Load dataset
load("filtering/PSA_subset.mat")

% Extract predictors and response
X = [EQN_data_filtered.constant, EQN_data_filtered.distance];
Y = EQN_data_filtered.PSA;

n = size(X,1);

%% =====================================================
%  PART 1 — PERFORMANCE PRIMA DEL FILTRAGGIO OUTLIERS
%% =====================================================

% Step 1: Split train (80%) e validation (20%)
idx = randperm(n);
train_ratio = 0.8;
n_train = round(train_ratio * n);

X_train = X(idx(1:n_train), :);
Y_train = Y(idx(1:n_train));
X_val   = X(idx(n_train+1:end), :);
Y_val   = Y(idx(n_train+1:end));

% Step 2: Primo modello
mdl_before = fitlm(X_train, Y_train, 'Linear', 'Intercept', false);

% Step 3: Training performance
Y_pred_train = predict(mdl_before, X_train);
resid_train = Y_train - Y_pred_train;
R2_train_before  = 1 - sum(resid_train.^2) / sum((Y_train - mean(Y_train)).^2);
RMSE_train_before = sqrt(mean(resid_train.^2));

% Step 4: Validation performance
Y_pred_val = predict(mdl_before, X_val);
resid_val = Y_val - Y_pred_val;
R2_val_before  = 1 - sum(resid_val.^2) / sum((Y_val - mean(Y_val)).^2);
RMSE_val_before = sqrt(mean(resid_val.^2));

fprintf("\n--- PERFORMANCE BEFORE OUTLIER FILTERING ---\n")
fprintf("Training:   R² = %.4f | RMSE = %.4f\n", R2_train_before, RMSE_train_before)
fprintf("Validation: R² = %.4f | RMSE = %.4f\n", R2_val_before, RMSE_val_before)

%% =====================================================
%  PART 2 — OUTLIER DETECTION SU TUTTO IL DATASET
%% =====================================================

% Fit modello su TUTTO il dataset
mdl_full = fitlm(X, Y, 'Linear', 'Intercept', false);

% Residui su tutto il dataset
Y_pred_all = predict(mdl_full, X);
resid_all = Y - Y_pred_all;

% Threshold outlier: 3*std residui
threshold = 3 * std(resid_all);
outlier_mask = abs(resid_all) > threshold;

fprintf("\nFull dataset: %d records\n", n)
fprintf("Outliers detected: %d (%.2f%%)\n", sum(outlier_mask), 100*sum(outlier_mask)/n)

% Dataset filtrato
X_filt = X(~outlier_mask, :);
Y_filt = Y(~outlier_mask);

n_filt = size(X_filt, 1);
fprintf("Remaining after filtering: %d records\n", n_filt)

%% =====================================================
%  PART 3 — RIFACCIO TRAIN/VALIDATION DOPO FILTRAGGIO
%% =====================================================

idx2 = randperm(n_filt);
n_train2 = round(train_ratio * n_filt);

X_train_f = X_filt(idx2(1:n_train2), :);
Y_train_f = Y_filt(idx2(1:n_train2));
X_val_f   = X_filt(idx2(n_train2+1:end), :);
Y_val_f   = Y_filt(idx2(n_train2+1:end));

% Refit modello
mdl_after = fitlm(X_train_f, Y_train_f, 'Linear', 'Intercept', false);

% Performance training AFTER
Y_pred_train_f = predict(mdl_after, X_train_f);
resid_train_f = Y_train_f - Y_pred_train_f;
R2_train_after  = 1 - sum(resid_train_f.^2) / sum((Y_train_f - mean(Y_train_f)).^2);
RMSE_train_after = sqrt(mean(resid_train_f.^2));

% Performance validation AFTER
Y_pred_val_f = predict(mdl_after, X_val_f);
resid_val_f = Y_val_f - Y_pred_val_f;
R2_val_after  = 1 - sum(resid_val_f.^2) / sum((Y_val_f - mean(Y_val_f)).^2);
RMSE_val_after = sqrt(mean(resid_val_f.^2));

fprintf("\n--- PERFORMANCE AFTER OUTLIER FILTERING ---\n")
fprintf("Training:   R² = %.4f | RMSE = %.4f\n", R2_train_after, RMSE_train_after)
fprintf("Validation: R² = %.4f | RMSE = %.4f\n", R2_val_after, RMSE_val_after)

%% Save filtered dataset
PSA_filtered = EQN_data_filtered(~outlier_mask, :);
save("PSA_filtered.mat", "PSA_filtered");
