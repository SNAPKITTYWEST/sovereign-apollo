import Lake
open Lake DSL

package sovereignApollo where
  leanOptions := #[⟨`autoImplicit, false⟩]

lean_lib SovereignApollo where
  srcDir := "."
