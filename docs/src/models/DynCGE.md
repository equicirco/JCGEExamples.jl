# DynCGE

## Reference
Recursive-dynamic model, Hosoe, N., Gasawa, K., Hashimoto, H. Textbook of Computable General Equilibrium Modeling: Programming and Simulations, 2nd Edition, University of Tokyo Press. (Japanese edition)

## Equations

Equations are an auto-generated dump from the model specification.

# Equations
`prod.eqpy[AGR]`

$$
Y_{i} = b_{i} \cdot \prod_{h \in \mathcal{D}_{h}} {F_{h,i}}^{beta_h,i}
$$

Domain h in { CAP, LAB }

`prod.eqF[CAP,AGR]`

$$
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h,i}
$$

`prod.eqF[LAB,AGR]`

$$
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h,i}
$$

`prod.eqX[AGR,AGR]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[LMN,AGR]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[HMN,AGR]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[SRV,AGR]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqY[AGR]`

$$
Y_{i} = ay_{i} \cdot Z_{i}
$$

`prod.eqpzs[AGR]`

$$
pz_{i} = ay_{i} \cdot py_{i} + \sum_{j \in \mathcal{D}_{j}} ax_{j,i} \cdot pq_{j}
$$

Domain j in { AGR, LMN, HMN, SRV }

`prod.eqpy[LMN]`

$$
Y_{i} = b_{i} \cdot \prod_{h \in \mathcal{D}_{h}} {F_{h,i}}^{beta_h,i}
$$

Domain h in { CAP, LAB }

`prod.eqF[CAP,LMN]`

$$
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h,i}
$$

`prod.eqF[LAB,LMN]`

$$
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h,i}
$$

`prod.eqX[AGR,LMN]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[LMN,LMN]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[HMN,LMN]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[SRV,LMN]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqY[LMN]`

$$
Y_{i} = ay_{i} \cdot Z_{i}
$$

`prod.eqpzs[LMN]`

$$
pz_{i} = ay_{i} \cdot py_{i} + \sum_{j \in \mathcal{D}_{j}} ax_{j,i} \cdot pq_{j}
$$

Domain j in { AGR, LMN, HMN, SRV }

`prod.eqpy[HMN]`

$$
Y_{i} = b_{i} \cdot \prod_{h \in \mathcal{D}_{h}} {F_{h,i}}^{beta_h,i}
$$

Domain h in { CAP, LAB }

`prod.eqF[CAP,HMN]`

$$
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h,i}
$$

`prod.eqF[LAB,HMN]`

$$
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h,i}
$$

`prod.eqX[AGR,HMN]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[LMN,HMN]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[HMN,HMN]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[SRV,HMN]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqY[HMN]`

$$
Y_{i} = ay_{i} \cdot Z_{i}
$$

`prod.eqpzs[HMN]`

$$
pz_{i} = ay_{i} \cdot py_{i} + \sum_{j \in \mathcal{D}_{j}} ax_{j,i} \cdot pq_{j}
$$

Domain j in { AGR, LMN, HMN, SRV }

`prod.eqpy[SRV]`

$$
Y_{i} = b_{i} \cdot \prod_{h \in \mathcal{D}_{h}} {F_{h,i}}^{beta_h,i}
$$

Domain h in { CAP, LAB }

`prod.eqF[CAP,SRV]`

$$
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h,i}
$$

`prod.eqF[LAB,SRV]`

$$
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h,i}
$$

`prod.eqX[AGR,SRV]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[LMN,SRV]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[HMN,SRV]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[SRV,SRV]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqY[SRV]`

$$
Y_{i} = ay_{i} \cdot Z_{i}
$$

`prod.eqpzs[SRV]`

$$
pz_{i} = ay_{i} \cdot py_{i} + \sum_{j \in \mathcal{D}_{j}} ax_{j,i} \cdot pq_{j}
$$

Domain j in { AGR, LMN, HMN, SRV }

`mobile_factor.eqpf1[LAB]`

$$
\sum_{j \in \mathcal{D}_{j}} F_{h,j} = FF_{h}
$$

Domain j in { AGR, LMN, HMN, SRV }

`mobile_factor.eqpf2[LAB,LMN]`

$$
pf_{h,j} = pf_{h,\text{AGR}}
$$

`mobile_factor.eqpf2[LAB,HMN]`

$$
pf_{h,j} = pf_{h,\text{AGR}}
$$

`mobile_factor.eqpf2[LAB,SRV]`

$$
pf_{h,j} = pf_{h,\text{AGR}}
$$

`capital.eqpf3[AGR]`

$$
F_{\text{CAP},j} = ror \cdot KK_{j}
$$

`capital.eqpf3[LMN]`

$$
F_{\text{CAP},j} = ror \cdot KK_{j}
$$

`capital.eqpf3[HMN]`

$$
F_{\text{CAP},j} = ror \cdot KK_{j}
$$

`capital.eqpf3[SRV]`

$$
F_{\text{CAP},j} = ror \cdot KK_{j}
$$

`government.eqTz[AGR]`

$$
Tz_{i} = tauz_{i} \cdot pz_{i} \cdot Z_{i}
$$

`government.eqTm[AGR]`

$$
Tm_{i} = taum_{i} \cdot pm_{i} \cdot M_{i}
$$

`government.eqTz[LMN]`

$$
Tz_{i} = tauz_{i} \cdot pz_{i} \cdot Z_{i}
$$

`government.eqTm[LMN]`

$$
Tm_{i} = taum_{i} \cdot pm_{i} \cdot M_{i}
$$

`government.eqTz[HMN]`

$$
Tz_{i} = tauz_{i} \cdot pz_{i} \cdot Z_{i}
$$

`government.eqTm[HMN]`

$$
Tm_{i} = taum_{i} \cdot pm_{i} \cdot M_{i}
$$

`government.eqTz[SRV]`

$$
Tz_{i} = tauz_{i} \cdot pz_{i} \cdot Z_{i}
$$

`government.eqTm[SRV]`

$$
Tm_{i} = taum_{i} \cdot pm_{i} \cdot M_{i}
$$

`government.eqTd`

$$
Td = \sum_{i \in \mathcal{D}_{i}} pq_{i} \cdot Xg_{i} - \sum_{i \in \mathcal{D}_{i}} Tz_{i} - \sum_{i \in \mathcal{D}_{i}} Tm_{i}
$$

Domain i in { AGR, LMN, HMN, SRV }
Domain i in { AGR, LMN, HMN, SRV }
Domain i in { AGR, LMN, HMN, SRV }

`private_saving.eqSp`

$$
Sp = ssp \cdot (\sum_{h \in \mathcal{D}_{h}} \sum_{j \in \mathcal{D}_{j}} pf_{h,j} \cdot F_{h,j} - Td)
$$

Domain h in { CAP, LAB }
Domain j in { AGR, LMN, HMN, SRV }

`investment.eqXv[AGR]`

$$
Xv_{i} = lambda_{i} \cdot pk \cdot \sum_{j \in \mathcal{D}_{j}} II_{j} / pq_{i}
$$

Domain j in { AGR, LMN, HMN, SRV }

`investment.eqXv[LMN]`

$$
Xv_{i} = lambda_{i} \cdot pk \cdot \sum_{j \in \mathcal{D}_{j}} II_{j} / pq_{i}
$$

Domain j in { AGR, LMN, HMN, SRV }

`investment.eqXv[HMN]`

$$
Xv_{i} = lambda_{i} \cdot pk \cdot \sum_{j \in \mathcal{D}_{j}} II_{j} / pq_{i}
$$

Domain j in { AGR, LMN, HMN, SRV }

`investment.eqXv[SRV]`

$$
Xv_{i} = lambda_{i} \cdot pk \cdot \sum_{j \in \mathcal{D}_{j}} II_{j} / pq_{i}
$$

Domain j in { AGR, LMN, HMN, SRV }

`investment.eqIII`

$$
III = iota \cdot \prod_{i \in \mathcal{D}_{i}} {Xv_{i}}^{lambda_i}
$$

Domain i in { AGR, LMN, HMN, SRV }

`investment.eqpk`

$$
\sum_{j \in \mathcal{D}_{j}} II_{j} = III
$$

Domain j in { AGR, LMN, HMN, SRV }

`investment_alloc.eqII[AGR]`

$$
pk \cdot II_{j} = ({pf_{\text{CAP},j}}^{zeta} \cdot F_{\text{CAP},j} / \sum_{k \in \mathcal{D}_{k}} {pf_{\text{CAP},k}}^{zeta} \cdot F_{\text{CAP},k}) \cdot (Sp + epsilon \cdot Sf)
$$

Domain k in { AGR, LMN, HMN, SRV }

`investment_alloc.eqII[LMN]`

$$
pk \cdot II_{j} = ({pf_{\text{CAP},j}}^{zeta} \cdot F_{\text{CAP},j} / \sum_{k \in \mathcal{D}_{k}} {pf_{\text{CAP},k}}^{zeta} \cdot F_{\text{CAP},k}) \cdot (Sp + epsilon \cdot Sf)
$$

Domain k in { AGR, LMN, HMN, SRV }

`investment_alloc.eqII[HMN]`

$$
pk \cdot II_{j} = ({pf_{\text{CAP},j}}^{zeta} \cdot F_{\text{CAP},j} / \sum_{k \in \mathcal{D}_{k}} {pf_{\text{CAP},k}}^{zeta} \cdot F_{\text{CAP},k}) \cdot (Sp + epsilon \cdot Sf)
$$

Domain k in { AGR, LMN, HMN, SRV }

`investment_alloc.eqII[SRV]`

$$
pk \cdot II_{j} = ({pf_{\text{CAP},j}}^{zeta} \cdot F_{\text{CAP},j} / \sum_{k \in \mathcal{D}_{k}} {pf_{\text{CAP},k}}^{zeta} \cdot F_{\text{CAP},k}) \cdot (Sp + epsilon \cdot Sf)
$$

Domain k in { AGR, LMN, HMN, SRV }

`household.eqXp[AGR]`

$$
Xp_{i} = alpha_{i} \cdot (\sum_{h \in \mathcal{D}_{h}} \sum_{j \in \mathcal{D}_{j}} pf_{h,j} \cdot F_{h,j} - Sp - Td) / pq_{i}
$$

Domain h in { CAP, LAB }
Domain j in { AGR, LMN, HMN, SRV }

`household.eqXp[LMN]`

$$
Xp_{i} = alpha_{i} \cdot (\sum_{h \in \mathcal{D}_{h}} \sum_{j \in \mathcal{D}_{j}} pf_{h,j} \cdot F_{h,j} - Sp - Td) / pq_{i}
$$

Domain h in { CAP, LAB }
Domain j in { AGR, LMN, HMN, SRV }

`household.eqXp[HMN]`

$$
Xp_{i} = alpha_{i} \cdot (\sum_{h \in \mathcal{D}_{h}} \sum_{j \in \mathcal{D}_{j}} pf_{h,j} \cdot F_{h,j} - Sp - Td) / pq_{i}
$$

Domain h in { CAP, LAB }
Domain j in { AGR, LMN, HMN, SRV }

`household.eqXp[SRV]`

$$
Xp_{i} = alpha_{i} \cdot (\sum_{h \in \mathcal{D}_{h}} \sum_{j \in \mathcal{D}_{j}} pf_{h,j} \cdot F_{h,j} - Sp - Td) / pq_{i}
$$

Domain h in { CAP, LAB }
Domain j in { AGR, LMN, HMN, SRV }

`prices.eqpe[AGR]`

$$
pe_{i} = epsilon \cdot pWe_{i}
$$

`prices.eqpm[AGR]`

$$
pm_{i} = epsilon \cdot pWm_{i}
$$

`prices.eqpe[LMN]`

$$
pe_{i} = epsilon \cdot pWe_{i}
$$

`prices.eqpm[LMN]`

$$
pm_{i} = epsilon \cdot pWm_{i}
$$

`prices.eqpe[HMN]`

$$
pe_{i} = epsilon \cdot pWe_{i}
$$

`prices.eqpm[HMN]`

$$
pm_{i} = epsilon \cdot pWm_{i}
$$

`prices.eqpe[SRV]`

$$
pe_{i} = epsilon \cdot pWe_{i}
$$

`prices.eqpm[SRV]`

$$
pm_{i} = epsilon \cdot pWm_{i}
$$

`price_level.eqPRICE`

$$
PRICE = \sum_{i \in \mathcal{D}_{i}} pq_{i} \cdot w_{i}
$$

Domain i in { AGR, LMN, HMN, SRV }

`bop.eqBOP`

$$
\sum_{i \in \mathcal{D}_{i}} pWe_{i} \cdot E_{i} + Sf = \sum_{i \in \mathcal{D}_{i}} pWm_{i} \cdot M_{i}
$$

Domain i in { AGR, LMN, HMN, SRV }
Domain i in { AGR, LMN, HMN, SRV }

`armington.eqQ[AGR]`

$$
Q_{i} = gamma_{i} \cdot ({delta\_m}_{i} \cdot {M_{i}}^{eta_i} + {delta\_d}_{i} \cdot {D_{i}}^{eta_i})^{1/(eta_i)}
$$

`armington.eqM[AGR]`

$$
M_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_m}_{i} \cdot pq_{i} / (1 + 0 + {tau\_m}_{i}) \cdot pm_{i})^{1/(1-eta_i)} \cdot Q_{i}
$$

`armington.eqD[AGR]`

$$
D_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_d}_{i} \cdot pq_{i} / 1 \cdot pd_{i})^{1/(1-eta_i)} \cdot Q_{i}
$$

`armington.eqQ[LMN]`

$$
Q_{i} = gamma_{i} \cdot ({delta\_m}_{i} \cdot {M_{i}}^{eta_i} + {delta\_d}_{i} \cdot {D_{i}}^{eta_i})^{1/(eta_i)}
$$

`armington.eqM[LMN]`

$$
M_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_m}_{i} \cdot pq_{i} / (1 + 0 + {tau\_m}_{i}) \cdot pm_{i})^{1/(1-eta_i)} \cdot Q_{i}
$$

`armington.eqD[LMN]`

$$
D_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_d}_{i} \cdot pq_{i} / 1 \cdot pd_{i})^{1/(1-eta_i)} \cdot Q_{i}
$$

`armington.eqQ[HMN]`

$$
Q_{i} = gamma_{i} \cdot ({delta\_m}_{i} \cdot {M_{i}}^{eta_i} + {delta\_d}_{i} \cdot {D_{i}}^{eta_i})^{1/(eta_i)}
$$

`armington.eqM[HMN]`

$$
M_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_m}_{i} \cdot pq_{i} / (1 + 0 + {tau\_m}_{i}) \cdot pm_{i})^{1/(1-eta_i)} \cdot Q_{i}
$$

`armington.eqD[HMN]`

$$
D_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_d}_{i} \cdot pq_{i} / 1 \cdot pd_{i})^{1/(1-eta_i)} \cdot Q_{i}
$$

`armington.eqQ[SRV]`

$$
Q_{i} = gamma_{i} \cdot ({delta\_m}_{i} \cdot {M_{i}}^{eta_i} + {delta\_d}_{i} \cdot {D_{i}}^{eta_i})^{1/(eta_i)}
$$

`armington.eqM[SRV]`

$$
M_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_m}_{i} \cdot pq_{i} / (1 + 0 + {tau\_m}_{i}) \cdot pm_{i})^{1/(1-eta_i)} \cdot Q_{i}
$$

`armington.eqD[SRV]`

$$
D_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_d}_{i} \cdot pq_{i} / 1 \cdot pd_{i})^{1/(1-eta_i)} \cdot Q_{i}
$$

`transformation.eqZ[AGR]`

$$
Z_{i} = theta_{i} \cdot (xie_{i} \cdot {E_{i}}^{phi_i} + xid_{i} \cdot {D_{i}}^{phi_i})^{1/(phi_i)}
$$

`transformation.eqE[AGR]`

$$
E_{i} = ({theta_{i}}^{phi_i} \cdot xie_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pe_{i})^{1/(1-phi_i)} \cdot Z_{i}
$$

`transformation.eqDs[AGR]`

$$
D_{i} = ({theta_{i}}^{phi_i} \cdot xid_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pd_{i})^{1/(1-phi_i)} \cdot Z_{i}
$$

`transformation.eqZ[LMN]`

$$
Z_{i} = theta_{i} \cdot (xie_{i} \cdot {E_{i}}^{phi_i} + xid_{i} \cdot {D_{i}}^{phi_i})^{1/(phi_i)}
$$

`transformation.eqE[LMN]`

$$
E_{i} = ({theta_{i}}^{phi_i} \cdot xie_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pe_{i})^{1/(1-phi_i)} \cdot Z_{i}
$$

`transformation.eqDs[LMN]`

$$
D_{i} = ({theta_{i}}^{phi_i} \cdot xid_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pd_{i})^{1/(1-phi_i)} \cdot Z_{i}
$$

`transformation.eqZ[HMN]`

$$
Z_{i} = theta_{i} \cdot (xie_{i} \cdot {E_{i}}^{phi_i} + xid_{i} \cdot {D_{i}}^{phi_i})^{1/(phi_i)}
$$

`transformation.eqE[HMN]`

$$
E_{i} = ({theta_{i}}^{phi_i} \cdot xie_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pe_{i})^{1/(1-phi_i)} \cdot Z_{i}
$$

`transformation.eqDs[HMN]`

$$
D_{i} = ({theta_{i}}^{phi_i} \cdot xid_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pd_{i})^{1/(1-phi_i)} \cdot Z_{i}
$$

`transformation.eqZ[SRV]`

$$
Z_{i} = theta_{i} \cdot (xie_{i} \cdot {E_{i}}^{phi_i} + xid_{i} \cdot {D_{i}}^{phi_i})^{1/(phi_i)}
$$

`transformation.eqE[SRV]`

$$
E_{i} = ({theta_{i}}^{phi_i} \cdot xie_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pe_{i})^{1/(1-phi_i)} \cdot Z_{i}
$$

`transformation.eqDs[SRV]`

$$
D_{i} = ({theta_{i}}^{phi_i} \cdot xid_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pd_{i})^{1/(1-phi_i)} \cdot Z_{i}
$$

`market.eqQ[AGR]`

$$
Q_{i} = Xp_{i} + Xg_{i} + Xv_{i} + \sum_{j \in \mathcal{D}_{j}} X_{i,j}
$$

Domain j in { AGR, LMN, HMN, SRV }

`market.eqQ[LMN]`

$$
Q_{i} = Xp_{i} + Xg_{i} + Xv_{i} + \sum_{j \in \mathcal{D}_{j}} X_{i,j}
$$

Domain j in { AGR, LMN, HMN, SRV }

`market.eqQ[HMN]`

$$
Q_{i} = Xp_{i} + Xg_{i} + Xv_{i} + \sum_{j \in \mathcal{D}_{j}} X_{i,j}
$$

Domain j in { AGR, LMN, HMN, SRV }

`market.eqQ[SRV]`

$$
Q_{i} = Xp_{i} + Xg_{i} + Xv_{i} + \sum_{j \in \mathcal{D}_{j}} X_{i,j}
$$

Domain j in { AGR, LMN, HMN, SRV }

`utility.eqCC`

$$
CC = a \cdot \prod_{i \in \mathcal{D}_{i}} {Xp_{i}}^{alpha_i}
$$

Domain i in { AGR, LMN, HMN, SRV }

`utility.objective` maximize CC

`init.start[X_LMN_SRV]` start X_LMN_SRV = 18597.27

`init.start[py_LMN]` start py_LMN = 1.0

`init.start[pf_LAB_SRV]` start pf_LAB_SRV = 1.0

`init.start[CC]` start CC = 297675.969

`init.start[pz_SRV]` start pz_SRV = 1.0

`init.start[pe_LMN]` start pe_LMN = 1.0

`init.start[F_CAP_AGR]` start F_CAP_AGR = 5082.506

`init.start[X_LMN_AGR]` start X_LMN_AGR = 1485.854

`init.start[pz_LMN]` start pz_LMN = 1.0

`init.start[D_SRV]` start D_SRV = 634872.4670000001

`init.start[Tz_HMN]` start Tz_HMN = 9418.058

`init.start[py_SRV]` start py_SRV = 1.0

`init.start[II_HMN]` start II_HMN = 25270.585200000005

`init.start[Tz_LMN]` start Tz_LMN = 4068.616

`init.start[Tm_SRV]` start Tm_SRV = 8.575

`init.start[pf_LAB_AGR]` start pf_LAB_AGR = 1.0

`init.start[F_LAB_LMN]` start F_LAB_LMN = 8942.365

`init.start[Y_LMN]` start Y_LMN = 15985.062

`init.start[X_HMN_HMN]` start X_HMN_HMN = 113390.269

`init.start[X_HMN_SRV]` start X_HMN_SRV = 48734.424

`init.start[KK_HMN]` start KK_HMN = 421176.42

`init.start[Z_LMN]` start Z_LMN = 50033.466

`init.start[Xp_LMN]` start Xp_LMN = 32220.169

`init.start[M_AGR]` start M_AGR = 2092.569

`init.start[X_LMN_HMN]` start X_LMN_HMN = 15330.764

`init.start[D_LMN]` start D_LMN = 52905.557

`init.start[Y_HMN]` start Y_HMN = 63568.944

`init.start[pe_AGR]` start pe_AGR = 1.0

`init.start[Xg_HMN]` start Xg_HMN = -36101.90325423198

`init.start[M_HMN]` start M_HMN = 30982.559

`init.start[Td]` start Td = -67361.26300000004

`init.start[Xp_AGR]` start Xp_AGR = 3563.257

`init.start[M_LMN]` start M_LMN = 23796.669

`init.start[Z_HMN]` start Z_HMN = 243041.294

`init.start[pf_CAP_HMN]` start pf_CAP_HMN = 1.0

`init.start[Sp]` start Sp = 241534.91200000007

`init.start[Xv_SRV]` start Xv_SRV = 160889.65017006418

`init.start[py_HMN]` start py_HMN = 1.0

`init.start[II_AGR]` start II_AGR = 6099.007200000002

`init.start[Z_AGR]` start Z_AGR = 12720.721000000001

`init.start[Q_LMN]` start Q_LMN = 79569.079

`init.start[KK_SRV]` start KK_SRV = 3.26090792e6

`init.start[KK_LMN]` start KK_LMN = 140853.94

`init.start[Sf]` start Sf = -6059.608

`init.start[F_LAB_SRV]` start F_LAB_SRV = 222732.7

`init.start[X_HMN_AGR]` start X_HMN_AGR = 1071.954

`init.start[pm_SRV]` start pm_SRV = 1.0

`init.start[pm_AGR]` start pm_AGR = 1.0

`init.start[pf_CAP_LMN]` start pf_CAP_LMN = 1.0

`init.start[pq_HMN]` start pq_HMN = 1.0

`init.start[Xp_SRV]` start Xp_SRV = 234243.865

`init.start[pe_SRV]` start pe_SRV = 1.0

`init.start[pz_AGR]` start pz_AGR = 1.0

`init.start[Y_SRV]` start Y_SRV = 385778.096

`init.start[F_CAP_LMN]` start F_CAP_LMN = 7042.697

`init.start[Xp_HMN]` start Xp_HMN = 27648.678

`init.start[pf_LAB_HMN]` start pf_LAB_HMN = 1.0

`init.start[pd_SRV]` start pd_SRV = 1.0

`init.start[X_AGR_AGR]` start X_AGR_AGR = 1643.017

`init.start[Xg_SRV]` start Xg_SRV = 8986.95282993582

`init.start[F_CAP_HMN]` start F_CAP_HMN = 21058.821

`init.start[X_AGR_HMN]` start X_AGR_HMN = 237.841

`init.start[Tz_AGR]` start Tz_AGR = 433.854

`init.start[F_CAP_SRV]` start F_CAP_SRV = 163045.396

`init.start[pq_AGR]` start pq_AGR = 1.0

`init.start[Q_HMN]` start Q_HMN = 230107.78000000003

`init.start[Tm_HMN]` start Tm_HMN = 1749.385

`init.start[X_SRV_AGR]` start X_SRV_AGR = 2002.38

`init.start[KK_AGR]` start KK_AGR = 101650.12

`init.start[FF_LAB]` start FF_LAB = 275620.198

`init.start[D_HMN]` start D_HMN = 197375.836

`init.start[E_SRV]` start E_SRV = 17426.156

`init.start[PRICE]` start PRICE = 1.0

`init.start[epsilon]` start epsilon = 1.0

`init.start[III]` start III = 235475.30400000003

`init.start[X_AGR_SRV]` start X_AGR_SRV = 1409.202

`init.start[E_HMN]` start E_HMN = 55083.516

`init.start[py_AGR]` start py_AGR = 1.0

`init.start[E_LMN]` start E_LMN = 1196.525

`init.start[pe_HMN]` start pe_HMN = 1.0

`init.start[pm_HMN]` start pm_HMN = 1.0

`init.start[X_SRV_LMN]` start X_SRV_LMN = 11406.26

`init.start[pk]` start pk = 1.0

`init.start[M_SRV]` start M_SRV = 10837.256

`init.start[Tm_LMN]` start Tm_LMN = 2866.853

`init.start[Tz_SRV]` start Tz_SRV = 20103.917

`init.start[pm_LMN]` start pm_LMN = 1.0

`init.start[pf_CAP_AGR]` start pf_CAP_AGR = 1.0

`init.start[Y_AGR]` start Y_AGR = 6517.5160000000005

`init.start[FF_CAP]` start FF_CAP = 196229.42

`init.start[X_AGR_LMN]` start X_AGR_LMN = 7560.896

`init.start[X_LMN_LMN]` start X_LMN_LMN = 10803.527

`init.start[D_AGR]` start D_AGR = 13092.111

`init.start[Xv_LMN]` start Xv_LMN = 1629.8928650473717

`init.start[II_LMN]` start II_LMN = 8451.236400000002

`init.start[X_HMN_LMN]` start X_HMN_LMN = 4277.721

`init.start[pq_SRV]` start pq_SRV = 1.0

`init.start[Tm_AGR]` start Tm_AGR = 149.278

`init.start[Xv_HMN]` start Xv_HMN = 71086.63725423197

`init.start[F_LAB_HMN]` start F_LAB_HMN = 42510.123

`init.start[X_SRV_SRV]` start X_SRV_SRV = 177675.714

`init.start[Q_AGR]` start Q_AGR = 15333.958

`init.start[II_SRV]` start II_SRV = 195654.47520000007

`init.start[Xv_AGR]` start Xv_AGR = 1869.123710656506

`init.start[Xg_AGR]` start Xg_AGR = -949.3787106565061

`init.start[Xg_LMN]` start Xg_LMN = -498.3978650473718

`init.start[F_LAB_AGR]` start F_LAB_AGR = 1435.01

`init.start[pd_HMN]` start pd_HMN = 1.0

`init.start[X_SRV_HMN]` start X_SRV_HMN = 50513.476

`init.start[Z_SRV]` start Z_SRV = 632194.706

`init.start[pq_LMN]` start pq_LMN = 1.0

`init.start[pd_AGR]` start pd_AGR = 1.0

`init.start[pf_CAP_SRV]` start pf_CAP_SRV = 1.0

`init.start[E_AGR]` start E_AGR = 62.464

`init.start[pz_HMN]` start pz_HMN = 1.0

`init.start[pf_LAB_LMN]` start pf_LAB_LMN = 1.0

`init.start[pd_LMN]` start pd_LMN = 1.0

`init.start[Q_SRV]` start Q_SRV = 645718.2980000001

`init.lower[X_LMN_SRV]` lower X_LMN_SRV = 1.0e-5

`init.lower[py_LMN]` lower py_LMN = 1.0e-5

`init.lower[pf_LAB_SRV]` lower pf_LAB_SRV = 1.0e-5

`init.lower[CC]` lower CC = 1.0e-5

`init.lower[pz_SRV]` lower pz_SRV = 1.0e-5

`init.lower[pe_LMN]` lower pe_LMN = 1.0e-5

`init.lower[F_CAP_AGR]` lower F_CAP_AGR = 1.0e-5

`init.lower[X_LMN_AGR]` lower X_LMN_AGR = 1.0e-5

`init.lower[pz_LMN]` lower pz_LMN = 1.0e-5

`init.lower[D_SRV]` lower D_SRV = 1.0e-5

`init.lower[Tz_HMN]` lower Tz_HMN = 0.0

`init.lower[py_SRV]` lower py_SRV = 1.0e-5

`init.lower[II_HMN]` lower II_HMN = 1.0e-5

`init.lower[Tz_LMN]` lower Tz_LMN = 0.0

`init.lower[Tm_SRV]` lower Tm_SRV = 0.0

`init.lower[pf_LAB_AGR]` lower pf_LAB_AGR = 1.0e-5

`init.lower[F_LAB_LMN]` lower F_LAB_LMN = 1.0e-5

`init.lower[Y_LMN]` lower Y_LMN = 1.0e-5

`init.lower[X_HMN_HMN]` lower X_HMN_HMN = 1.0e-5

`init.lower[X_HMN_SRV]` lower X_HMN_SRV = 1.0e-5

`init.lower[KK_HMN]` lower KK_HMN = 1.0e-5

`init.lower[Z_LMN]` lower Z_LMN = 1.0e-5

`init.lower[Xp_LMN]` lower Xp_LMN = 1.0e-5

`init.lower[M_AGR]` lower M_AGR = 1.0e-5

`init.lower[X_LMN_HMN]` lower X_LMN_HMN = 1.0e-5

`init.lower[D_LMN]` lower D_LMN = 1.0e-5

`init.lower[Y_HMN]` lower Y_HMN = 1.0e-5

`init.lower[pe_AGR]` lower pe_AGR = 1.0e-5

`init.lower[Td]` lower Td = -1.0e12

`init.lower[M_HMN]` lower M_HMN = 1.0e-5

`init.lower[Xg_HMN]` lower Xg_HMN = -1.0e12

`init.lower[Xp_AGR]` lower Xp_AGR = 1.0e-5

`init.lower[M_LMN]` lower M_LMN = 1.0e-5

`init.lower[Z_HMN]` lower Z_HMN = 1.0e-5

`init.lower[pf_CAP_HMN]` lower pf_CAP_HMN = 1.0e-5

`init.lower[Sp]` lower Sp = 1.0e-5

`init.lower[Xv_SRV]` lower Xv_SRV = 1.0e-5

`init.lower[py_HMN]` lower py_HMN = 1.0e-5

`init.lower[II_AGR]` lower II_AGR = 1.0e-5

`init.lower[Z_AGR]` lower Z_AGR = 1.0e-5

`init.lower[Q_LMN]` lower Q_LMN = 1.0e-5

`init.lower[KK_SRV]` lower KK_SRV = 1.0e-5

`init.lower[KK_LMN]` lower KK_LMN = 1.0e-5

`init.lower[Sf]` lower Sf = -1.0e12

`init.lower[F_LAB_SRV]` lower F_LAB_SRV = 1.0e-5

`init.lower[X_HMN_AGR]` lower X_HMN_AGR = 1.0e-5

`init.lower[pm_SRV]` lower pm_SRV = 1.0e-5

`init.lower[pm_AGR]` lower pm_AGR = 1.0e-5

`init.lower[pf_CAP_LMN]` lower pf_CAP_LMN = 1.0e-5

`init.lower[pq_HMN]` lower pq_HMN = 1.0e-5

`init.lower[Xp_SRV]` lower Xp_SRV = 1.0e-5

`init.lower[pe_SRV]` lower pe_SRV = 1.0e-5

`init.lower[pz_AGR]` lower pz_AGR = 1.0e-5

`init.lower[Y_SRV]` lower Y_SRV = 1.0e-5

`init.lower[F_CAP_LMN]` lower F_CAP_LMN = 1.0e-5

`init.lower[Xp_HMN]` lower Xp_HMN = 1.0e-5

`init.lower[pf_LAB_HMN]` lower pf_LAB_HMN = 1.0e-5

`init.lower[pd_SRV]` lower pd_SRV = 1.0e-5

`init.lower[X_AGR_AGR]` lower X_AGR_AGR = 1.0e-5

`init.lower[Xg_SRV]` lower Xg_SRV = -1.0e12

`init.lower[F_CAP_HMN]` lower F_CAP_HMN = 1.0e-5

`init.lower[X_AGR_HMN]` lower X_AGR_HMN = 1.0e-5

`init.lower[Tz_AGR]` lower Tz_AGR = 0.0

`init.lower[F_CAP_SRV]` lower F_CAP_SRV = 1.0e-5

`init.lower[pq_AGR]` lower pq_AGR = 1.0e-5

`init.lower[Q_HMN]` lower Q_HMN = 1.0e-5

`init.lower[Tm_HMN]` lower Tm_HMN = 0.0

`init.lower[X_SRV_AGR]` lower X_SRV_AGR = 1.0e-5

`init.lower[KK_AGR]` lower KK_AGR = 1.0e-5

`init.lower[FF_LAB]` lower FF_LAB = 1.0e-5

`init.lower[D_HMN]` lower D_HMN = 1.0e-5

`init.lower[E_SRV]` lower E_SRV = 1.0e-5

`init.lower[PRICE]` lower PRICE = 1.0e-5

`init.lower[epsilon]` lower epsilon = 1.0e-5

`init.lower[III]` lower III = 1.0e-5

`init.lower[X_AGR_SRV]` lower X_AGR_SRV = 1.0e-5

`init.lower[E_HMN]` lower E_HMN = 1.0e-5

`init.lower[py_AGR]` lower py_AGR = 1.0e-5

`init.lower[E_LMN]` lower E_LMN = 1.0e-5

`init.lower[pe_HMN]` lower pe_HMN = 1.0e-5

`init.lower[pm_HMN]` lower pm_HMN = 1.0e-5

`init.lower[X_SRV_LMN]` lower X_SRV_LMN = 1.0e-5

`init.lower[pk]` lower pk = 1.0e-5

`init.lower[M_SRV]` lower M_SRV = 1.0e-5

`init.lower[Tm_LMN]` lower Tm_LMN = 0.0

`init.lower[Tz_SRV]` lower Tz_SRV = 0.0

`init.lower[pm_LMN]` lower pm_LMN = 1.0e-5

`init.lower[pf_CAP_AGR]` lower pf_CAP_AGR = 1.0e-5

`init.lower[Y_AGR]` lower Y_AGR = 1.0e-5

`init.lower[FF_CAP]` lower FF_CAP = 1.0e-5

`init.lower[X_AGR_LMN]` lower X_AGR_LMN = 1.0e-5

`init.lower[X_LMN_LMN]` lower X_LMN_LMN = 1.0e-5

`init.lower[D_AGR]` lower D_AGR = 1.0e-5

`init.lower[Xv_LMN]` lower Xv_LMN = 1.0e-5

`init.lower[II_LMN]` lower II_LMN = 1.0e-5

`init.lower[X_HMN_LMN]` lower X_HMN_LMN = 1.0e-5

`init.lower[pq_SRV]` lower pq_SRV = 1.0e-5

`init.lower[Tm_AGR]` lower Tm_AGR = 0.0

`init.lower[Xv_HMN]` lower Xv_HMN = 1.0e-5

`init.lower[F_LAB_HMN]` lower F_LAB_HMN = 1.0e-5

`init.lower[X_SRV_SRV]` lower X_SRV_SRV = 1.0e-5

`init.lower[Q_AGR]` lower Q_AGR = 1.0e-5

`init.lower[II_SRV]` lower II_SRV = 1.0e-5

`init.lower[Xv_AGR]` lower Xv_AGR = 1.0e-5

`init.lower[Xg_AGR]` lower Xg_AGR = -1.0e12

`init.lower[Xg_LMN]` lower Xg_LMN = -1.0e12

`init.lower[F_LAB_AGR]` lower F_LAB_AGR = 1.0e-5

`init.lower[pd_HMN]` lower pd_HMN = 1.0e-5

`init.lower[X_SRV_HMN]` lower X_SRV_HMN = 1.0e-5

`init.lower[Z_SRV]` lower Z_SRV = 1.0e-5

`init.lower[pq_LMN]` lower pq_LMN = 1.0e-5

`init.lower[pd_AGR]` lower pd_AGR = 1.0e-5

`init.lower[pf_CAP_SRV]` lower pf_CAP_SRV = 1.0e-5

`init.lower[E_AGR]` lower E_AGR = 1.0e-5

`init.lower[pz_HMN]` lower pz_HMN = 1.0e-5

`init.lower[pf_LAB_LMN]` lower pf_LAB_LMN = 1.0e-5

`init.lower[pd_LMN]` lower pd_LMN = 1.0e-5

`init.lower[Q_SRV]` lower Q_SRV = 1.0e-5

`init.fixed[Xg_HMN]` fixed Xg_HMN = -36101.90325423198

`init.fixed[KK_AGR]` fixed KK_AGR = 101650.12

`init.fixed[FF_LAB]` fixed FF_LAB = 275620.198

`init.fixed[Xg_AGR]` fixed Xg_AGR = -949.3787106565061

`init.fixed[Xg_LMN]` fixed Xg_LMN = -498.3978650473718

`init.fixed[PRICE]` fixed PRICE = 1.0

`init.fixed[Sf]` fixed Sf = -6059.608

`init.fixed[KK_LMN]` fixed KK_LMN = 140853.94

`init.fixed[KK_SRV]` fixed KK_SRV = 3.26090792e6

`init.fixed[KK_HMN]` fixed KK_HMN = 421176.42

`init.fixed[Xg_SRV]` fixed Xg_SRV = 8986.95282993582
