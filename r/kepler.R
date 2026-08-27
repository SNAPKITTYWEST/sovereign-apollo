# r/kepler.R — Kepler orbital mechanics layer
# Sovereign Apollo — R astrodynamics reference library
# Nova Parr / GPT models contribution

# ---------------------------------------------------------------------------
# Stumpff functions C(z) and S(z), vectorized over z
# Returns list(C = ..., S = ...)
# ---------------------------------------------------------------------------
kepler_stumpff_cs <- function(z) {
  n <- length(z)
  C <- numeric(n)
  S <- numeric(n)

  for (i in seq_along(z)) {
    zi <- z[i]
    if (zi > 1e-6) {
      sq <- sqrt(zi)
      C[i] <- (1 - cos(sq)) / zi
      S[i] <- (sq - sin(sq)) / (zi * sq)
    } else if (zi < -1e-6) {
      sq <- sqrt(-zi)
      C[i] <- (1 - cosh(sq)) / zi
      S[i] <- (sinh(sq) - sq) / ((-zi) * sq)
    } else {
      # Taylor series around z = 0
      C[i] <- 0.5 - zi / 24.0 + zi^2 / 720.0 - zi^3 / 40320.0
      S[i] <- 1.0/6.0 - zi / 120.0 + zi^2 / 5040.0 - zi^3 / 362880.0
    }
  }
  list(C = C, S = S)
}

# ---------------------------------------------------------------------------
# Scalar Kepler equation solver — Newton + bisection hybrid
# Solves E - e*sin(E) = M for eccentric anomaly E
# Returns eccentric anomaly in radians
# ---------------------------------------------------------------------------
solve_kepler_elliptic_scalar <- function(mean_anomaly,
                                          eccentricity,
                                          semi_major_axis,
                                          tolerance     = 1e-12,
                                          max_iterations = 50) {
  stopifnot(eccentricity >= 0, eccentricity < 1)
  stopifnot(semi_major_axis > 0)

  M <- mean_anomaly %% (2 * pi)

  # Initial guess: Danby (1992) starter
  E <- M + eccentricity * sin(M) * (1.0 + eccentricity * cos(M))

  # Bisection fallback bounds
  lo <- M - pi
  hi <- M + pi

  for (iter in seq_len(max_iterations)) {
    fE  <- E - eccentricity * sin(E) - M
    fpE <- 1 - eccentricity * cos(E)

    if (abs(fpE) < .Machine$double.eps * 10) {
      # Degenerate derivative — fall back to bisection step
      E_new <- (lo + hi) / 2
    } else {
      E_new <- E - fE / fpE
    }

    # Keep bisection bracket tight
    f_new <- E_new - eccentricity * sin(E_new) - M
    if (fE * f_new < 0) hi <- E_new else lo <- E_new

    if (abs(E_new - E) < tolerance) return(E_new)
    E <- E_new
  }

  warning(sprintf(
    "solve_kepler_elliptic_scalar: did not converge in %d iterations (M=%.6g, e=%.6g)",
    max_iterations, mean_anomaly, eccentricity
  ))
  E
}

# ---------------------------------------------------------------------------
# Universal-variable multi-satellite propagator using Stumpff C(z)/S(z)
# state0 : matrix (n x 6), each row [x, y, z, vx, vy, vz] in km / km*s^-1
# dt     : scalar propagation time in seconds
# mu     : gravitational parameter km^3/s^2 (default Earth)
# Returns updated state matrix (n x 6)
# ---------------------------------------------------------------------------
kepler_propagate_many <- function(state0,
                                   dt,
                                   mu = 398600.4418) {
  if (is.vector(state0) && length(state0) == 6) {
    state0 <- matrix(state0, nrow = 1)
  }

  n <- nrow(state0)
  result <- matrix(0, nrow = n, ncol = 6)

  for (i in seq_len(n)) {
    r0vec <- state0[i, 1:3]
    v0vec <- state0[i, 4:6]

    r0 <- sqrt(sum(r0vec^2))
    v0 <- sqrt(sum(v0vec^2))
    vr0 <- sum(r0vec * v0vec) / r0

    alpha <- (2 / r0) - (v0^2 / mu)   # reciprocal semi-major axis

    # Initial guess for universal variable chi
    if (alpha > 1e-6) {
      # Ellipse
      chi0 <- sqrt(mu) * dt * alpha
    } else if (alpha < -1e-6) {
      # Hyperbola
      a_hyp <- 1 / alpha
      chi0 <- sign(dt) * sqrt(-a_hyp) *
                log((-2 * mu * alpha * dt) /
                    (r0 * vr0 + sign(dt) * sqrt(-mu * a_hyp) * (1 - r0 * alpha)))
    } else {
      # Parabola
      h <- sqrt(sum(crossprod(
        matrix(r0vec), matrix(v0vec)
      )))
      p <- h^2 / mu
      s <- 0.5 * atan2(1, 3 * sqrt(mu / p^3) * dt)
      w <- atan(tan(s)^(1/3))
      chi0 <- sqrt(2 * p) / tan(2 * w)
    }

    # Halley iteration on universal Kepler equation
    chi <- chi0
    for (iter in seq_len(50)) {
      z  <- alpha * chi^2
      cs <- kepler_stumpff_cs(z)
      Cz <- cs$C; Sz <- cs$S

      t_chi <- (r0 * vr0 / sqrt(mu)) * chi^2 * Cz +
               (1 - r0 * alpha) * chi^3 * Sz +
               r0 * chi
      dt_dchi <- (r0 * vr0 / sqrt(mu)) * chi * (1 - alpha * chi^2 * Sz) +
                 (1 - r0 * alpha) * chi^2 * Cz +
                 r0

      f_val <- t_chi - sqrt(mu) * dt
      if (abs(f_val) < 1e-10 * abs(sqrt(mu) * dt) + 1e-12) break
      chi <- chi - f_val / dt_dchi
    }

    z  <- alpha * chi^2
    cs <- kepler_stumpff_cs(z)
    Cz <- cs$C; Sz <- cs$S

    f_lag  <- 1 - (chi^2 / r0) * Cz
    g_lag  <- dt - (chi^3 / sqrt(mu)) * Sz

    r1vec  <- f_lag * r0vec + g_lag * v0vec
    r1     <- sqrt(sum(r1vec^2))

    fd_lag <- (sqrt(mu) / (r1 * r0)) * chi * (alpha * chi^2 * Sz - 1)
    gd_lag <- 1 - (chi^2 / r1) * Cz

    v1vec  <- fd_lag * r0vec + gd_lag * v0vec

    result[i, ] <- c(r1vec, v1vec)
  }

  result
}
