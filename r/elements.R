# r/elements.R — Orbital element conversion layer
# Sovereign Apollo — R astrodynamics reference library
# Nova Parr / GPT models contribution

# ---------------------------------------------------------------------------
# Cartesian state vector [x,y,z,vx,vy,vz] -> classical Keplerian elements
# Returns named vector: a, e, i, RAAN, omega, nu (all angles in radians)
# mu in km^3/s^2
# ---------------------------------------------------------------------------
kepler_cartesian_to_keplerian <- function(state, mu = 398600.4418) {
  r_vec <- state[1:3]
  v_vec <- state[4:6]

  r <- sqrt(sum(r_vec^2))
  v <- sqrt(sum(v_vec^2))

  h_vec <- c(
    r_vec[2]*v_vec[3] - r_vec[3]*v_vec[2],
    r_vec[3]*v_vec[1] - r_vec[1]*v_vec[3],
    r_vec[1]*v_vec[2] - r_vec[2]*v_vec[1]
  )
  h <- sqrt(sum(h_vec^2))

  K <- c(0, 0, 1)
  N_vec <- c(K[2]*h_vec[3] - K[3]*h_vec[2],
             K[3]*h_vec[1] - K[1]*h_vec[3],
             K[1]*h_vec[2] - K[2]*h_vec[1])
  N <- sqrt(sum(N_vec^2))

  e_vec <- ((v^2 - mu/r) * r_vec - sum(r_vec * v_vec) * v_vec) / mu
  e <- sqrt(sum(e_vec^2))

  E_mech <- v^2/2 - mu/r
  a <- if (abs(e - 1) > 1e-10) -mu / (2 * E_mech) else Inf

  i <- acos(h_vec[3] / h)

  RAAN <- if (N > 1e-12) {
    ang <- acos(N_vec[1] / N)
    if (N_vec[2] < 0) 2*pi - ang else ang
  } else 0.0

  omega <- if (N > 1e-12 && e > 1e-10) {
    ang <- acos(pmax(-1, pmin(1, sum(N_vec * e_vec) / (N * e))))
    if (e_vec[3] < 0) 2*pi - ang else ang
  } else 0.0

  nu <- if (e > 1e-10) {
    ang <- acos(pmax(-1, pmin(1, sum(e_vec * r_vec) / (e * r))))
    if (sum(r_vec * v_vec) < 0) 2*pi - ang else ang
  } else {
    ang <- acos(pmax(-1, pmin(1, sum(N_vec * r_vec) / (N * r))))
    if (r_vec[3] < 0) 2*pi - ang else ang
  }

  c(a = a, e = e, i = i, RAAN = RAAN, omega = omega, nu = nu)
}

# ---------------------------------------------------------------------------
# Classical Keplerian elements -> Cartesian state [x,y,z,vx,vy,vz]
# elements: named vector with a, e, i, RAAN, omega, nu (radians)
# ---------------------------------------------------------------------------
kepler_keplerian_to_cartesian <- function(elements, mu = 398600.4418) {
  a     <- elements["a"]
  e     <- elements["e"]
  i     <- elements["i"]
  RAAN  <- elements["RAAN"]
  omega <- elements["omega"]
  nu    <- elements["nu"]

  p <- a * (1 - e^2)
  r <- p / (1 + e * cos(nu))

  # Perifocal frame
  r_pf <- c(r * cos(nu), r * sin(nu), 0)
  v_pf <- c(-sin(nu), e + cos(nu), 0) * sqrt(mu / p)

  # Rotation matrices
  R3_RAAN  <- rbind(c( cos(RAAN),  sin(RAAN), 0),
                    c(-sin(RAAN),  cos(RAAN), 0),
                    c(0,           0,         1))
  R1_i     <- rbind(c(1,  0,      0    ),
                    c(0,  cos(i), sin(i)),
                    c(0, -sin(i), cos(i)))
  R3_omega <- rbind(c( cos(omega),  sin(omega), 0),
                    c(-sin(omega),  cos(omega), 0),
                    c(0,            0,          1))

  Q <- t(R3_RAAN) %*% t(R1_i) %*% t(R3_omega)

  r_eci <- Q %*% r_pf
  v_eci <- Q %*% v_pf

  c(r_eci, v_eci)
}

# ---------------------------------------------------------------------------
# Cartesian state -> Modified Equinoctial Elements (p, f, g, h, k, L)
# ---------------------------------------------------------------------------
kepler_cartesian_to_mee <- function(state, mu = 398600.4418) {
  kep <- kepler_cartesian_to_keplerian(state, mu)
  a     <- kep["a"]
  e     <- kep["e"]
  i     <- kep["i"]
  RAAN  <- kep["RAAN"]
  omega <- kep["omega"]
  nu    <- kep["nu"]

  p <- a * (1 - e^2)
  f <- e * cos(omega + RAAN)
  g <- e * sin(omega + RAAN)
  h <- tan(i/2) * cos(RAAN)
  k <- tan(i/2) * sin(RAAN)
  L <- RAAN + omega + nu

  c(p = p, f = f, g = g, h = h, k = k, L = L)
}

# ---------------------------------------------------------------------------
# Modified Equinoctial Elements (p, f, g, h, k, L) -> Cartesian state
# ---------------------------------------------------------------------------
kepler_mee_to_cartesian <- function(mee, mu = 398600.4418) {
  p <- mee["p"]; f <- mee["f"]; g <- mee["g"]
  h <- mee["h"]; k <- mee["k"]; L <- mee["L"]

  alpha2 <- h^2 - k^2
  s2     <- 1 + h^2 + k^2
  w      <- 1 + f * cos(L) + g * sin(L)
  r      <- p / w
  sqrt_mu_p <- sqrt(mu / p)

  r_vec <- (r / s2) * c(
    cos(L) + alpha2 * cos(L) + 2*h*k*sin(L),
    sin(L) - alpha2 * sin(L) + 2*h*k*cos(L),
    2*(h*sin(L) - k*cos(L))
  )

  v_vec <- (-1/s2) * sqrt_mu_p * c(
     sin(L) + alpha2*sin(L) - 2*h*k*cos(L) + g - 2*f*h*k + alpha2*g,
    -cos(L) + alpha2*cos(L) + 2*h*k*sin(L) - f + 2*g*h*k + alpha2*f,
    -2*(h*cos(L) + k*sin(L) + f*h + g*k)
  )

  c(r_vec, v_vec)
}
