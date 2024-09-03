% Define vector of x-values used for plotting
xvec = linspace(0,12,200);

% Part (b)
% Define true function
u = @(x) exp(x/2);
uvec = u(xvec);

% Define Taylor polynomial approximation
% Complete the code below
T4 = @(x) [complete here];
TaylorApprox = T4(xvec);

% Plot true function u along with the two approximations
figure
hold on
plot(xvec,uvec,'g')
plot(xvec,TaylorApprox,'b')
% Define Lagrange polynomial interpolant
P4 = @(x) [complete here]; 
LagrangeApprox = P4(xvec);
plot(xvec,LagrangeApprox,'r')
hold off

% Part (d)
% Define Taylor approximation error estimate
ET4 = @(x) [complete here]; 
TaylorErrorEstimate = ET4(xvec);
% Define Lagrange interpolation error estimate
EP4 = @(x) [complete here];
LagrangeErrorEstimate = EP4(xvec);
% Plot logs of error estimates
figure
hold on
plot(xvec,log(TaylorErrorEstimate),'b-.')
plot(xvec,log(LagrangeErrorEstimate),'r-.')
hold off

% Part (e)
% Plot logs of error estimates (again) and logs of actual errors
TaylorErrorActual = [complete here];
LagrangeErrorActual = [complete here];
figure
hold on
plot(xvec,log(TaylorErrorEstimate),'b-.')
plot(xvec,log(LagrangeErrorEstimate),'r-.')
plot(xvec,log(TaylorErrorActual),'b')
plot(xvec,log(LagrangeErrorActual),'r')
hold off
% Compute error ratios
TaylorRatio = [complete here]
LagrangeRatio = [complete here]