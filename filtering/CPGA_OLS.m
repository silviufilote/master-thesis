%% Setup
clc
close all
clearvars

rng(1)

% Load dataset
load("filtering/EQNF_subset.mat")

% Extract predictors and response
X = [EQNF_subset.constant, EQNF_subset.distance];
Y = EQNF_subset.CPGA;

n = size(X,1);

%% =====================================================
%  PART 1 — PERFORMANCE BEFORE OUTLIER FILTERING
%% =====================================================

% 1. Train/validation split (80/20)
idx = randperm(n);
train_ratio = 0.8;
n_train = round(train_ratio * n);

X_train = X(idx(1:n_train), :);
Y_train = Y(idx(1:n_train));
X_val   = X(idx(n_train+1:end), :);
Y_val   = Y(idx(n_train+1:end));

% 2. Fit model on training
mdl_before = fitlm(X_train, Y_train, 'Linear', 'Intercept', false);

% Training performance
Y_pred_train = predict(mdl_before, X_train);
resid_train = Y_train - Y_pred_train;
R2_train_before = 1 - sum(resid_train.^2) / sum((Y_train - mean(Y_train)).^2);
RMSE_train_before = sqrt(mean(resid_train.^2));

% Validation performance
Y_pred_val = predict(mdl_before, X_val);
resid_val = Y_val - Y_pred_val;
R2_val_before = 1 - sum(resid_val.^2) / sum((Y_val - mean(Y_val)).^2);
RMSE_val_before = sqrt(mean(resid_val.^2));

fprintf("\n--- PERFORMANCE BEFORE filtering ---\n");
fprintf("Training:   R² = %.4f | RMSE = %.4f\n", R2_train_before, RMSE_train_before);
fprintf("Validation: R² = %.4f | RMSE = %.4f\n", R2_val_before, RMSE_val_before);

%% HISTOGRAM BEFORE FILTERING
figure;
histogram(resid_train, 40, 'Normalization', 'pdf'); hold on;
title('Residuals BEFORE filtering (training)');
xlabel('Residual'); ylabel('PDF'); grid on;
hold off;

%% =====================================================
%  PART 2 — OUTLIER DETECTION ON FULL DATASET
%% =====================================================

% Fit model on ALL data
mdl_full = fitlm(X, Y, 'Linear', 'Intercept', false);

% Compute residuals on full dataset
Y_pred_all = predict(mdl_full, X);
resid_all  = Y - Y_pred_all;

% Define threshold 3σ
threshold = 3 * std(resid_all);

% Outlier mask
outlier_mask = abs(resid_all) > threshold;

fprintf("\nFull dataset: %d records\n", n);
fprintf('Outliers detected (FULL dataset): %d (%.2f%%)\n', ...
    sum(outlier_mask), 100 * sum(outlier_mask) / n);

% Filter data
X_filt = X(~outlier_mask, :);
Y_filt = Y(~outlier_mask);
CPGA_filtered = EQNF_subset(~outlier_mask, :);

fprintf('Remaining after filtering: %d records\n', length(Y_filt));

%% Histogram of full residuals BEFORE (with threshold)
figure;
histogram(resid_all, 40, 'Normalization', 'pdf'); hold on;
xline(threshold,  'r--', 'LineWidth', 2);
xline(-threshold, 'r--', 'LineWidth', 2);
title('Residuals BEFORE filtering (Full dataset, ±3σ)');
xlabel('Residual'); ylabel('PDF'); grid on;
hold off;

%% =====================================================
%  PART 3 — REPEAT TRAIN/VALID SPLIT AFTER FILTERING
%% =====================================================

n_filt = size(X_filt, 1);
idx2 = randperm(n_filt);
n_train2 = round(train_ratio * n_filt);

X_train_f = X_filt(idx2(1:n_train2), :);
Y_train_f = Y_filt(idx2(1:n_train2));
X_val_f   = X_filt(idx2(n_train2+1:end), :);
Y_val_f   = Y_filt(idx2(n_train2+1:end));

% Fit model on filtered training set
mdl_after = fitlm(X_train_f, Y_train_f, 'Linear', 'Intercept', false);

% Training performance AFTER
Y_pred_train_f = predict(mdl_after, X_train_f);
resid_train_f = Y_train_f - Y_pred_train_f;
R2_train_after = 1 - sum(resid_train_f.^2) / sum((Y_train_f - mean(Y_train_f)).^2);
RMSE_train_after = sqrt(mean(resid_train_f.^2));

% Validation performance AFTER
Y_pred_val_f = predict(mdl_after, X_val_f);
resid_val_f = Y_val_f - Y_pred_val_f;
R2_val_after = 1 - sum(resid_val_f.^2) / sum((Y_val_f - mean(Y_val_f)).^2);
RMSE_val_after = sqrt(mean(resid_val_f.^2));

fprintf("\n--- PERFORMANCE AFTER filtering ---\n");
fprintf("Training:   R² = %.4f | RMSE = %.4f\n", R2_train_after, RMSE_train_after);
fprintf("Validation: R² = %.4f | RMSE = %.4f\n", R2_val_after, RMSE_val_after);

%% Histogram AFTER filtering
figure;
histogram(resid_train_f, 40, 'Normalization', 'pdf'); hold on;
xline(3*std(resid_train_f),  'r--', 'LineWidth', 2);
xline(-3*std(resid_train_f), 'r--', 'LineWidth', 2);
title('Residuals AFTER filtering (training)');
xlabel('Residual'); ylabel('PDF'); grid on;
hold off;

%% Save filtered dataset
save("CPGA_filtered.mat", "CPGA_filtered");
