function [T, P, cost, penalty, epsilon, C, SOC_0, t, mu, sigma, lambda] = init_parameters

%T = 1 + 24*1;       % one hour schedule (works for RO and start_SO_closed, for the latter only with long running time)
%T = 3;              % for start_SO_closed with an acceptable runtime
%T = 1440;           % every-minute schedule (required for start_SO_discretization and start_SO_discretization_battery when using PVdata2)
T = 96;              % 15min-schedule (required for start_SO_discretization and start_SO_discretization_battery when using sample_normal_independent)
         
P = 3.8;             % nominal power of the PV element
epsilon = 0.05;
cost = 1;
penalty = @(x) x.^2;  % quadratic penalty
C = 2.6;              % battery capacity
SOC_0 = 0.25;         % state of charge (SOC) at day break
t = linspace(0,24,T);

pd = makedist('Normal');
mu = P*(0.2 + pdf(pd,(t-12)/sqrt(12)));
sigma = 0.2*ones(1,T);
lambda = 1.96;
