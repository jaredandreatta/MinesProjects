n_sims <- 10e5
n <- 30

# True parameters
mu <- 10
sigma_true <- 2    
sigma2_true <- sigma_true^2

# Derived Value of C
C <- 2/sqrt(2*pi)


gamma_sq_vals <- numeric(n_sims)  
sample_var_vals <- numeric(n_sims) 

# Main Monte Carlo loop
for (i in 1:n_sims) {
  
  # Generate a random sample of n=30 from Normal(10, 2^2)
  y <- rnorm(n, mean = mu, sd = sigma_true)
  
  # LAD-based estimate: hat(gamma)
  ybar <- mean(y)
  gamma_hat <- (1/(n*C)) * sum(abs(y - ybar)) 
  gamma_sq_vals[i] <- gamma_hat^2             
  
  # Usual sample variance: hat(sigma^2)
  sample_var_vals[i] <- var(y)  
}


# 1) For gamma^2
mean_gamma_sq <- mean(gamma_sq_vals)
bias_gamma_sq <- mean_gamma_sq - sigma2_true
var_gamma_sq <- var(gamma_sq_vals)
rmse_gamma_sq <- sqrt(mean((gamma_sq_vals - sigma2_true)^2))

# For sigma hat^2
mean_s_var <- mean(sample_var_vals)
bias_s_var <- mean_s_var - sigma2_true
var_s_var <- var(sample_var_vals)
rmse_s_var <- sqrt(mean((sample_var_vals - sigma2_true)^2))

cat("(hat(gamma)^2) \n")
cat("Bias:     ", bias_gamma_sq, "\n")
cat("Variance: ", var_gamma_sq,  "\n")
cat("RMSE:     ", rmse_gamma_sq, "\n\n")

cat("(hat(sigma^2)) \n")
cat("Bias:     ", bias_s_var, "\n")
cat("Variance: ", var_s_var,  "\n")
cat("RMSE:     ", rmse_s_var, "\n")