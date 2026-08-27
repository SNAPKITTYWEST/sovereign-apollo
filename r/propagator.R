# r/propagator.R — MEE equations of motion and RK4 propagator
# Sovereign Apollo — R astrodynamics reference library
# Nova Parr / GPT models contribution

# Source dependency (adjust path as needed when running standalone)
# source("elements.R")

# ---------------------------------------------------------------------------
# MEE right-hand side — Gauss variational equations
# mee              : named vector (p, f, g, h, k, L)
# acceleration_rsw : 3-vector in RSW (radial, along-track, cross-track) frame [km/s^2]
# mu               : gravitational parameter [km^3/s^2]
# Returns d/dt(mee) as 6-vector
# ---------------------------------------------------------------------------
kepler_mee_rhs <- function(mee, acceleration_rsw, mu = 398600.4418) {
  p <- mee["p"]; f <- mee["f"]; g <- mee["g"]
  h <- mee["h"]; k <- mee["k"]; L <- mee["L"]

  Fr <- acceleration_rsw[1]
  Fs <- acceleration_rsw[2]
  Fw <- acceleration_rsw[3]

  w  <- 1 + f * cos(L) + g * sin(L)
  s2 <- 1 + h^2 + k^2
  sqrt_p_mu <- sqrt(p / mu)

  dp <- (2 * p / w) * Fs * sqrt_p_mu

  df <- sqrt_p_mu * (
    Fr * sin(L) +
    Fs * ((w + 1) * cos(L) + f) / w -
    Fw * g * (h * sin(L) - k * cos(L)) / w
  )

  dg <- sqrt_p_mu * (
    -Fr * cos(L) +
     Fs * ((w + 1) * sin(L) + g) / w +
     Fw * f * (h * sin(L) - k * cos(L)) / w
  )

  dh <- sqrt_p_mu * s2 * cos(L) / (2 * w) * Fw

  dk <- sqrt_p_mu * s2 * sin(L) / (2 * w) * Fw

  dL <- sqrt(mu * p) * (w / p)^2 +
        sqrt_p_mu / w * (h * sin(L) - k * cos(L)) * Fw

  c(dp, df, dg, dh, dk, dL)
}

# ---------------------------------------------------------------------------
# RK4 propagator for MEE with arbitrary perturbation function
# mee0            : initial MEE state (p, f, g, h, k, L)
# dt              : total propagation time [s]
# mu              : gravitational parameter [km^3/s^2]
# acceleration_fun: function(time, state_cartesian, mee, mu) -> RSW acceleration [km/s^2]
#                   Pass NULL for unperturbed (pure two-body) propagation
# max_step        : maximum RK4 substep size [s] (default 60 s)
# Returns final MEE state after dt seconds
# ---------------------------------------------------------------------------
kepler_mee_propagate_rk4 <- function(mee0,
                                      dt,
                                      mu              = 398600.4418,
                                      acceleration_fun = NULL,
                                      max_step        = 60.0) {
  n_steps <- max(1L, ceiling(abs(dt) / max_step))
  h       <- dt / n_steps
  mee     <- mee0
  t       <- 0.0

  zero_accel <- c(0, 0, 0)

  for (step in seq_len(n_steps)) {
    get_accel <- function(t_cur, mee_cur) {
      if (is.null(acceleration_fun)) return(zero_accel)
      # Convert MEE to Cartesian for perturbation evaluation
      if (exists("kepler_mee_to_cartesian")) {
        cart <- kepler_mee_to_cartesian(mee_cur, mu)
      } else {
        return(zero_accel)
      }
      acceleration_fun(t_cur, cart, mee_cur, mu)
    }

    k1 <- kepler_mee_rhs(mee,          get_accel(t,         mee),          mu)
    k2 <- kepler_mee_rhs(mee + h/2*k1, get_accel(t + h/2,   mee + h/2*k1), mu)
    k3 <- kepler_mee_rhs(mee + h/2*k2, get_accel(t + h/2,   mee + h/2*k2), mu)
    k4 <- kepler_mee_rhs(mee + h*k3,   get_accel(t + h,     mee + h*k3),   mu)

    mee <- mee + (h / 6) * (k1 + 2*k2 + 2*k3 + k4)
    t   <- t + h
  }

  mee
}

# ---------------------------------------------------------------------------
# J2 perturbation acceleration in RSW frame
# time               : current time (unused for J2, included for interface parity)
# state              : Cartesian [x,y,z,vx,vy,vz] in ECI [km, km/s]
# mee                : current MEE state (used for frame transformation)
# mu                 : gravitational parameter [km^3/s^2]
# radius_equatorial  : equatorial radius [km]  (default Earth: 6378.137)
# j2                 : J2 zonal harmonic (default: 1.08263e-3)
# Returns acceleration in RSW frame [km/s^2]
# ---------------------------------------------------------------------------
kepler_j2_acceleration <- function(time,
                                    state,
                                    mee,
                                    mu                = 398600.4418,
                                    radius_equatorial = 6378.137,
                                    j2                = 1.08263e-3) {
  r_vec <- state[1:3]
  v_vec <- state[4:6]
  r     <- sqrt(sum(r_vec^2))

  x <- r_vec[1]; y <- r_vec[2]; z <- r_vec[3]
  Re <- radius_equatorial

  factor <- -3 * mu * j2 * Re^2 / (2 * r^5)

  # J2 acceleration in ECI
  ax_eci <- factor * x * (1 - 5 * z^2 / r^2)
  ay_eci <- factor * y * (1 - 5 * z^2 / r^2)
  az_eci <- factor * z * (3 - 5 * z^2 / r^2)
  a_eci  <- c(ax_eci, ay_eci, az_eci)

  # RSW unit vectors
  r_hat <- r_vec / r
  h_vec <- c(r_vec[2]*v_vec[3] - r_vec[3]*v_vec[2],
             r_vec[3]*v_vec[1] - r_vec[1]*v_vec[3],
             r_vec[1]*v_vec[2] - r_vec[2]*v_vec[1])
  w_hat <- h_vec / sqrt(sum(h_vec^2))
  s_hat <- c(w_hat[2]*r_hat[3] - w_hat[3]*r_hat[2],
             w_hat[3]*r_hat[1] - w_hat[1]*r_hat[3],
             w_hat[1]*r_hat[2] - w_hat[2]*r_hat[1])

  Fr <- sum(a_eci * r_hat)
  Fs <- sum(a_eci * s_hat)
  Fw <- sum(a_eci * w_hat)

  c(Fr, Fs, Fw)
}
