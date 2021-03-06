function [obj, grad] = obj_RO(x,e_l,e_u,cost,penalty,epsilon,P)
% [obj, grad] = OBJ_RO(x,p_l,p_u,cost,penalty,nu)
% Calculates the objective function as in (4) from "First approach with RO"
% and its gradient.
% 
% Input:
%       x - n by m matrix           x(i,j) corresponds to the j's hour of
%                                   the i's day
%       e_l - 1 by m vector         e_l(j) is a lower bound on solar
%                                   radiance during the i's hour
%       e_r - 1 by m vector         e_r(j) is an upper bound on solar
%                                   radiance during the i's hour
%       cost - scalar               price for an energy unit
%       penalty - function handle   penalty function, should be able to
%                                   act on matrices
%       epsilon - pos. scalar << 1  defines the width of the no-penalty
%                                   interval [x(1-epsilon),x(1+epsilon)]
%       P - scalar                  nominal power of PV element
%
% Output:
%       obj - n by 1 vector         obj(i) = sum_j
%                                               F(x(i,j),e_l(j),e_r(j))
%       grad - n by 1 matrix        !!!works only for linear penalties!!!
%                                   grad(i) = sum_j
%                                               gradF(x(i,j),e_l(j),e_r(j))
%                                   With F from medium_objective
%% Calculation
[obj, grad] = medium_objective(x,e_l,e_u,cost,penalty,epsilon,P);
obj = sum(obj,2);
grad = sum(grad,2);
end

function [obj, grad] = medium_objective(x,e_l,e_u,cost,penalty,epsilon,P)
% [obj, grad] = MEDIUM_OBJECTIVE(x,e_l,e_u,cost,penalty,nu)
% Calculates the F(x,e_l,e_u) = max(f(x,e_l),f(x,e_u)) and it's gradient
% (where it does exist). This is a simple model of the 1d cost function for
% the robust optimization approach. 
%
% Input:
%       x - n by m matrix           x(i,j) corresponds to the j's hour of
%                                   the i's day
%       e_l - 1 by m vector         e_l(j) is a lower bound on solar
%                                   radiance during the i's hour
%       e_r - 1 by m vector         e_r(j) is an upper bound on solar
%                                   radiance during the i's hour
%       cost - scalar               price for an energy unit
%       penalty - function handle   penalty function, should be able to
%                                   act on matrices
%       epsilon - pos. scalar << 1  defines the width of the no-penalty
%                                   interval [x(1-epsilon),x(1+epsilon)]
%       P - scalar                  nominal power of PV element
%
% Output:
%       obj - n by m matrix         obj(i,j) = max(
%                                 cost*max(0,(1-epsilon)x(i,j)-e_l(j)) +
%                                 penalty(max(0,e_l(j)-(1+epsilon)x(i,j))),
%                                 cost*max(0,(1-epsilon)x(i,j)-e_u(j)) +
%                                 penalty(max(0,e_u(j)-(1+epsilon)x(i,j)))
%                                         )
%       grad - n by m matrix        !!!works only for linear penalties!!!
%                                   please see the last part of the code
%% Check the size of x and e
s = size(x);
if size(e_l,2) ~= s(2), error('Sizes of x and e_l do not match'); end
if size(e_u,2) ~= s(2), error('Sizes of x and e_r do not match'); end
%% Calculation
% Objective
obj_caseL = small_objective(x,e_l,cost,penalty,epsilon,P);
obj_caseU = small_objective(x,e_u,cost,penalty,epsilon,P);
obj = max(obj_caseL, obj_caseU);

% Gradient
x_opt = ...                                                                 % Is an intersection point of two lines:
        (penalty(e_u) + cost*e_l)/(cost*(1-epsilon) + penalty(1+epsilon));  % penalty*((1-epsilon)x-e_l) and cost*(e_u-(1+epsilon)x)
x1 = ones(s(1),1)*(e_u - epsilon*P);                                        % Is an intersection point of cost*(e_u-(x+epsilon*P) and the X-axis
x2 = ones(s(1),1)*(e_l + epsilon*P);                                        % Is an intersection point of penalty*((x-epsilon*P)-e_l) and the X-axis
grad = NaN(s);                                                              % Initialization of grad, it will remain NaN at the kinks of function
grad(x<x_opt & x<x1) = cost;                                                % The WC-scenario: we provide more then scheduled
grad(x1<x & x<x2) = 0;                                                      % Interval [e_l,e_r] is covered by the no-penalty interval
grad(x>x_opt & x>x2) = penalty(1);                                          % The WC-scenario: we provide less then scheduled
end

function obj = small_objective(x,e,cost,penalty,epsilon,P)
% obj = SMALL_OBJECTIVE(x,e,cost,penalty,epsilon)
% Calculates a simple 1d cost function f(x,e).
%
% Input:
%       x - n by m matrix           x(i,j) corresponds to the j's hour of
%                                   the i's day
%       e - 1 by m vector           e(j) is the solar radiance during the
%                                   i's hour
%       cost - scalar               price for an energy unit
%       penalty - function handle   penalty function, should be able to act
%                                   on matrices
%       epsilon - pos. scalar << 1  defines the width of the no-penalty
%                                   interval [x(1-epsilon),x(1+epsilon)]
%       P - scalar                  nominal power of PV element
%
% Output:
%       obj - n by m matrix         obj(i,j) =
%                                   cost*max(0,(1-epsilon)x(i,j)-e(j)) +
%                                   penalty(max(0,e(j)-(1+epsilon)x(i,j)))
%% Check the size of x and e
s = size(x);
if size(e,2) ~= s(2), error('Sizes of x and e do not match'); end
%% Calculation
E = ones(s(1),1) * e;                                                       % E is an n by m matrix with e in each column
obj = penalty(max(zeros(s), (x - epsilon*P) - E)) + ...
      max(zeros(s), E - (x + epsilon*P))*cost - E*cost;                     % just evaluating the formula
end