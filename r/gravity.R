# r/gravity.R — Spherical harmonic gravity model
# Sovereign Apollo — R astrodynamics reference library
# Nova Parr / GPT models contribution

# ---------------------------------------------------------------------------
# Unnormalized associated Legendre polynomials P_nm(u)
# u     : sin(latitude) in [-1, 1]
# n_max : maximum degree
# Returns matrix P[(n+1) x (n+1)] where P[n+1, m+1] = P_nm(u)
# Recurrence: Montenbruck & Gill (2000) §3.2
# ---------------------------------------------------------------------------
kepler_associated_legendre <- function(u, n_max) {
  P <- matrix(0.0, nrow = n_max + 1, ncol = n_max + 1)

  P[1, 1] <- 1.0          # P_00 = 1
  if (n_max < 1) return(P)

  sqrt1u2 <- sqrt(1 - u^2)

  # Diagonal (sectorial) terms: P_nn
  for (n in 1:n_max) {
    P[n+1, n+1] <- -(2*n - 1) * sqrt1u2 * P[n, n]
  }

  # Sub-diagonal: P_{n,n-1}
  for (n in 1:n_max) {
    P[n+1, n] <- (2*n - 1) * u * P[n, n]
  }

  # General recurrence for m < n-1
  if (n_max >= 2) {
    for (n in 2:n_max) {
      for (m in 0:(n-2)) {
        P[n+1, m+1] <- ((2*n - 1) * u * P[n, m+1] - (n + m - 1) * P[n-1, m+1]) / (n - m)
      }
    }
  }

  P
}

# ---------------------------------------------------------------------------
# Zonal harmonic acceleration (J2, J3, J4, ...) in ECI frame
# position          : 3-vector [x, y, z] in km (ECI)
# mu                : gravitational parameter [km^3/s^2]
# radius_equatorial : equatorial radius [km]
# zonals            : numeric vector c(J2, J3, J4, ...) — first element is J2
# Returns acceleration 3-vector in ECI [km/s^2]
# ---------------------------------------------------------------------------
kepler_zonal_acceleration <- function(position,
                                       mu,
                                       radius_equatorial,
                                       zonals) {
  x <- position[1]; y <- position[2]; z <- position[3]
  r <- sqrt(x^2 + y^2 + z^2)
  Re <- radius_equatorial
  sinlat <- z / r

  n_max <- length(zonals) + 1   # J2 = degree 2 → n_max = length+1

  P <- kepler_associated_legendre(sinlat, n_max)

  a_r  <- 0.0
  a_lat <- 0.0

  for (j in seq_along(zonals)) {
    n  <- j + 1
    Jn <- zonals[j]
    Re_r_n1 <- (Re / r)^n

    # Radial component contribution
    a_r   <- a_r   - mu/r^2 * (n+1) * Jn * Re_r_n1 * P[n+1, 1]

    # Latitudinal component
    # dP_n0/d(sinlat) handled by the n=m+1 recursion row
    if (n >= 1) {
      # P_{n,1} used for latitudinal gradient
      dPn0 <- P[n+1, 2] / sqrt(1 - sinlat^2 + .Machine$double.eps)
      a_lat <- a_lat + mu/r^2 * Jn * Re_r_n1 * dPn0
    }
  }

  # Convert (a_r, a_lat) in spherical to Cartesian ECI
  rxy   <- sqrt(x^2 + y^2)
  coslat <- rxy / r
  coslon <- if (rxy > 1e-12) x / rxy else 1.0
  sinlon <- if (rxy > 1e-12) y / rxy else 0.0

  ax <- a_r * coslon * coslat - a_lat * coslon * sinlat
  ay <- a_r * sinlon * coslat - a_lat * sinlon * sinlat
  az <- a_r * sinlat          + a_lat * coslat

  c(ax, ay, az)
}

# ---------------------------------------------------------------------------
# Gravity model constructor
# Returns a list (closure) that can be called as model$acceleration(position, mu)
# mu                : gravitational parameter [km^3/s^2]
# radius_equatorial : equatorial radius [km]
# C, S              : coefficient matrices (n_max+1 x n_max+1), row = degree, col = order
# normalization     : "unnormalized" or "fully_normalized"
# ---------------------------------------------------------------------------
kepler_gravity_model <- function(mu,
                                  radius_equatorial,
                                  C,
                                  S,
                                  normalization = "fully_normalized") {
  stopifnot(is.matrix(C), is.matrix(S))
  stopifnot(nrow(C) == ncol(C), nrow(S) == ncol(S))
  stopifnot(nrow(C) == nrow(S))
  stopifnot(normalization %in% c("unnormalized", "fully_normalized"))

  n_max <- nrow(C) - 1

  acceleration <- function(position) {
    x <- position[1]; y <- position[2]; z <- position[3]
    r <- sqrt(x^2 + y^2 + z^2)
    Re <- radius_equatorial
    sinlat <- z / r
    rxy <- sqrt(x^2 + y^2)

    lam <- atan2(y, x)
    P   <- kepler_associated_legendre(sinlat, n_max)

    a_x <- 0.0; a_y <- 0.0; a_z <- 0.0

    for (n in 2:n_max) {
      Re_r_n2 <- (Re / r)^n * (mu / r^2)
      for (m in 0:n) {
        cosml <- cos(m * lam)
        sinml <- sin(m * lam)

        Cnm <- C[n+1, m+1]
        Snm <- S[n+1, m+1]

        Pnm  <- P[n+1, m+1]
        Pnm1 <- if (m < n) P[n+1, m+2] else 0.0

        # Partial derivatives — Gottlieb formulation (1993)
        dU_dr  <- -(n+1) / r * Pnm * (Cnm * cosml + Snm * sinml)
        dU_dlat <- (Pnm1 - m * sinlat / sqrt(1 - sinlat^2 + 1e-300) * Pnm) *
                   (Cnm * cosml + Snm * sinml)
        dU_dlon <- m * Pnm * (-Cnm * sinml + Snm * cosml)

        a_x <- a_x + Re_r_n2 * (dU_dr * x/r  - dU_dlat * x*z/(r^2 * max(rxy, 1e-12)) - dU_dlon * y / max(rxy^2, 1e-20))
        a_y <- a_y + Re_r_n2 * (dU_dr * y/r  - dU_dlat * y*z/(r^2 * max(rxy, 1e-12)) + dU_dlon * x / max(rxy^2, 1e-20))
        a_z <- a_z + Re_r_n2 * (dU_dr * z/r  + dU_dlat * rxy / r^2)
      }
    }

    c(a_x, a_y, a_z)
  }

  list(
    mu                = mu,
    radius_equatorial = radius_equatorial,
    n_max             = n_max,
    normalization     = normalization,
    C                 = C,
    S                 = S,
    acceleration      = acceleration
  )
}
