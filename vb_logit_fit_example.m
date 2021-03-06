% script demonstrating the use of bayes_logit_fit.m and
% bayes_logit_fit_ard.m
%
% Copyright (c) 2013, Jan Drugowitsch
% All rights reserved.
% See the file LICENSE for licensing information.

% dimensionality, number of data points
d = 3;
d_extra = 10;
N = 100;
N_cv = 100;


% random weight vector & predictions
w = randn(d, 1);
X = [ones(N, 1) randn(N, d-1)];
X_ext = [X randn(N, d_extra)];
X_cv = [ones(N_cv, 1) randn(N_cv, d+d_extra-1)];
y_no_noise = 2 * (X * w > 0) - 1;
p_y = 1 ./ (1 + exp(- X * w));
y = 2 * (rand(N, 1) < p_y) - 1;
y1 = (y == 1);
y_cv = 2 * (rand(N_cv, 1) < 1 ./ (1 + exp(- X_cv(:, 1:d) * w))) - 1;

% Fisher Linear Discriminant
w_LD = NaN(d, 1);
w_LD(2:end) = (cov(X(~y1, 2:end)) + cov(X(y1, 2:end))) \ ...
              (mean(X(y1, 2:end))' - mean(X(~y1, 2:end))');
w_LD(1) = - 0.5 * (mean(X(y1, 2:end)) + mean(X(~y1, 2:end))) * w_LD(2:end);
w_LD_ext = NaN(d + d_extra, 1);
w_LD_ext(2:end) = (cov(X_ext(~y1, 2:end)) + cov(X_ext(y1, 2:end))) \ ...
                  (mean(X_ext(y1, 2:end))' - mean(X_ext(~y1, 2:end))');
w_LD_ext(1) = - 0.5 * (mean(X_ext(y1, 2:end)) + mean(X_ext(~y1, 2:end))) * w_LD_ext(2:end);
y_LD = 2 * (X_ext * w_LD_ext > 0) - 1;
y_LD_cv = 2 * (X_cv * w_LD_ext > 0) - 1;


% weights and predictions by variational Bayes
[w_vb, V_vb, invV_vb, logdetV_vb, E_a_vb, L_vb] = vb_logit_fit(X_ext, y);
p_y_vb = vb_logit_pred(X_ext, w_vb, V_vb, invV_vb);
y_vb = 2 * (p_y_vb > 0.5) - 1;
p_y_vb_cv = vb_logit_pred(X_cv, w_vb, V_vb, invV_vb);
y_vb_cv = 2 * (p_y_vb_cv > 0.5) - 1;

% same with ARD
[w_vb_ard, V_vb, invV_vb, logdetV_vb, E_a_vb, L_vb] = vb_logit_fit_ard(X_ext, y);
p_y_vb_ard = vb_logit_pred(X_ext, w_vb_ard, V_vb, invV_vb);
y_vb_ard = 2 * (p_y_vb_ard > 0.5) - 1;
p_y_vb_ard_cv = vb_logit_pred(X_cv, w_vb_ard, V_vb, invV_vb);
y_vb_ard_cv = 2 * (p_y_vb_ard_cv > 0.5) - 1;

% plot data and discriminating hyperplane
figure;  hold on;
plot(X(~y1, 2), X(~y1, 3), 'b+');
plot(X(y1, 2), X(y1, 3), 'r+');
xlims = get(gca, 'XLim');
% discrimination at w(1) + x * w(2) + y * w(3) = 0
plot(xlims, -(w(1) + w(2) * xlims) / w(3), 'k-');
plot(xlims, -(w_LD(1) + w_LD(2) * xlims) / w_LD(3), 'g-');
plot(xlims, -(w_LD_ext(1) + w_LD_ext(2) * xlims) / w_LD_ext(3), 'g--');
plot(xlims, -(w_vb(1) + w_vb(2) * xlims) / w_vb(3), 'r-');
plot(xlims, -(w_vb_ard(1) + w_vb_ard(2) * xlims) / w_vb_ard(3), 'b-');
legend('y=0', 'y=1', 'true', 'LD', 'LD ext', 'vb ext', 'vb ext ard');
set(gca,'TickDir','out');
xlabel('x');
ylabel('y');

% print training set and cross-validated MAE
fprintf('MAEs:       training set     test set\n');
fprintf('LD          %7.5f          %7.5f\n', ...
        mean(abs(0.5*(y - y_LD))), mean(abs(0.5*(y_cv - y_LD_cv))));
fprintf('VB          %7.5f          %7.5f\n', ...
        mean(abs(0.5*(y - y_vb))), mean(abs(0.5*(y_cv - y_vb_cv))));
fprintf('VB (ARD)    %7.5f          %7.5f\n', ...
        mean(abs(0.5*(y - y_vb_ard))), mean(abs(0.5*(y_cv - y_vb_ard_cv))));
