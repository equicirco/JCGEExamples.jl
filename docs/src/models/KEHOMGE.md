# KEHOMGE

## Reference
Multiple equilibria model in MPSGE, Kehoe, T, A Numerical Investigation of the Multiplicity of Equilibria. Mathematical Programming Study 23 (1985), 240-258.

## Equations

Equations are an auto-generated dump from the model specification.

`activity.eqX[G1,S1]`

```math
X_{g,s} = {a\_in}_{g,s} \cdot Y_{s}
```

`activity.eqZ[G1,S1]`

```math
Z_{g,s} = {a\_out}_{g,s} \cdot Y_{s}
```

`activity.eqX[G1,S2]`

```math
X_{g,s} = {a\_in}_{g,s} \cdot Y_{s}
```

`activity.eqZ[G1,S2]`

```math
Z_{g,s} = {a\_out}_{g,s} \cdot Y_{s}
```

`activity.eqX[G2,S1]`

```math
X_{g,s} = {a\_in}_{g,s} \cdot Y_{s}
```

`activity.eqZ[G2,S1]`

```math
Z_{g,s} = {a\_out}_{g,s} \cdot Y_{s}
```

`activity.eqX[G2,S2]`

```math
X_{g,s} = {a\_in}_{g,s} \cdot Y_{s}
```

`activity.eqZ[G2,S2]`

```math
Z_{g,s} = {a\_out}_{g,s} \cdot Y_{s}
```

`activity.eqX[G3,S1]`

```math
X_{g,s} = {a\_in}_{g,s} \cdot Y_{s}
```

`activity.eqZ[G3,S1]`

```math
Z_{g,s} = {a\_out}_{g,s} \cdot Y_{s}
```

`activity.eqX[G3,S2]`

```math
X_{g,s} = {a\_in}_{g,s} \cdot Y_{s}
```

`activity.eqZ[G3,S2]`

```math
Z_{g,s} = {a\_out}_{g,s} \cdot Y_{s}
```

`activity.eqX[G4,S1]`

```math
X_{g,s} = {a\_in}_{g,s} \cdot Y_{s}
```

`activity.eqZ[G4,S1]`

```math
Z_{g,s} = {a\_out}_{g,s} \cdot Y_{s}
```

`activity.eqX[G4,S2]`

```math
X_{g,s} = {a\_in}_{g,s} \cdot Y_{s}
```

`activity.eqZ[G4,S2]`

```math
Z_{g,s} = {a\_out}_{g,s} \cdot Y_{s}
```

`activity.eqZP[S1]`

```math
\sum_{g \in \mathcal{D}_{g}} pq_{g} \cdot {a\_out}_{g,s} = \sum_{g \in \mathcal{D}_{g}} pq_{g} \cdot {a\_in}_{g,s}
```

Domain g in { G1, G2, G3, G4 }
Domain g in { G1, G2, G3, G4 }

`activity.eqZP[S2]`

```math
\sum_{g \in \mathcal{D}_{g}} pq_{g} \cdot {a\_out}_{g,s} = \sum_{g \in \mathcal{D}_{g}} pq_{g} \cdot {a\_in}_{g,s}
```

Domain g in { G1, G2, G3, G4 }
Domain g in { G1, G2, G3, G4 }

`consumers.eqY[C1]`

```math
Y_{c} = \sum_{g \in \mathcal{D}_{g}} pq_{g} \cdot endowment_{g,c}
```

Domain g in { G1, G2, G3, G4 }

`consumers.eqY[C2]`

```math
Y_{c} = \sum_{g \in \mathcal{D}_{g}} pq_{g} \cdot endowment_{g,c}
```

Domain g in { G1, G2, G3, G4 }

`consumers.eqY[C3]`

```math
Y_{c} = \sum_{g \in \mathcal{D}_{g}} pq_{g} \cdot endowment_{g,c}
```

Domain g in { G1, G2, G3, G4 }

`consumers.eqY[C4]`

```math
Y_{c} = \sum_{g \in \mathcal{D}_{g}} pq_{g} \cdot endowment_{g,c}
```

Domain g in { G1, G2, G3, G4 }

`consumers.eqXp[G1,C1]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G1,C2]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G1,C3]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G1,C4]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G2,C1]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G2,C2]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G2,C3]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G2,C4]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G3,C1]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G3,C2]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G3,C3]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G3,C4]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G4,C1]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G4,C2]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G4,C3]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`consumers.eqXp[G4,C4]`

```math
Xp_{g,c} = alpha_{g,c} \cdot Y_{c} / pq_{g}
```

`markets.eqMC[G1]`

```math
\sum_{s \in \mathcal{D}_{s}} Z_{g,s} + \sum_{c \in \mathcal{D}_{c}} endowment_{g,c} = \sum_{s \in \mathcal{D}_{s}} X_{g,s} + \sum_{c \in \mathcal{D}_{c}} Xp_{g,c}
```

Domain s in { S1, S2 }
Domain c in { C1, C2, C3, C4 }
Domain s in { S1, S2 }
Domain c in { C1, C2, C3, C4 }

`markets.eqMC[G2]`

```math
\sum_{s \in \mathcal{D}_{s}} Z_{g,s} + \sum_{c \in \mathcal{D}_{c}} endowment_{g,c} = \sum_{s \in \mathcal{D}_{s}} X_{g,s} + \sum_{c \in \mathcal{D}_{c}} Xp_{g,c}
```

Domain s in { S1, S2 }
Domain c in { C1, C2, C3, C4 }
Domain s in { S1, S2 }
Domain c in { C1, C2, C3, C4 }

`markets.eqMC[G3]`

```math
\sum_{s \in \mathcal{D}_{s}} Z_{g,s} + \sum_{c \in \mathcal{D}_{c}} endowment_{g,c} = \sum_{s \in \mathcal{D}_{s}} X_{g,s} + \sum_{c \in \mathcal{D}_{c}} Xp_{g,c}
```

Domain s in { S1, S2 }
Domain c in { C1, C2, C3, C4 }
Domain s in { S1, S2 }
Domain c in { C1, C2, C3, C4 }

`markets.eqMC[G4]`

```math
\sum_{s \in \mathcal{D}_{s}} Z_{g,s} + \sum_{c \in \mathcal{D}_{c}} endowment_{g,c} = \sum_{s \in \mathcal{D}_{s}} X_{g,s} + \sum_{c \in \mathcal{D}_{c}} Xp_{g,c}
```

Domain s in { S1, S2 }
Domain c in { C1, C2, C3, C4 }
Domain s in { S1, S2 }
Domain c in { C1, C2, C3, C4 }

`numeraire.numeraire` numeraire fixed
