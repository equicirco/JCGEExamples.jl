# TwoCountryCGE

## Reference
Chapter 10.3, Hosoe, N, Gasawa, K, and Hashimoto, H. Handbook of Computable General Equilibrium Modeling. University of Tokyo Press, Tokyo, Japan, 2004.

## Equations

Equations are an auto-generated dump from the model specification.

`prod.eqpy[BRD_JPN]`

```math
Y_{i} = b_{i} \cdot \prod_{h \in \mathcal{D}_{h}} {F_{h,i}}^{beta_h,i}
```

Domain h in { CAP_JPN, LAB_JPN }

`prod.eqF[CAP_JPN,BRD_JPN]`

```math
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h}
```

`prod.eqF[LAB_JPN,BRD_JPN]`

```math
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h}
```

`prod.eqX[BRD_JPN,BRD_JPN]`

```math
X_{j,i} = ax_{j,i} \cdot Z_{i}
```

`prod.eqX[MLK_JPN,BRD_JPN]`

```math
X_{j,i} = ax_{j,i} \cdot Z_{i}
```

`prod.eqY[BRD_JPN]`

```math
Y_{i} = ay_{i} \cdot Z_{i}
```

`prod.eqpzs[BRD_JPN]`

```math
pz_{i} = ay_{i} \cdot py_{i} + \sum_{j \in \mathcal{D}_{j}} ax_{j,i} \cdot pq_{j} + 0
```

Domain j in { BRD_JPN, MLK_JPN }

`prod.eqpy[MLK_JPN]`

```math
Y_{i} = b_{i} \cdot \prod_{h \in \mathcal{D}_{h}} {F_{h,i}}^{beta_h,i}
```

Domain h in { CAP_JPN, LAB_JPN }

`prod.eqF[CAP_JPN,MLK_JPN]`

```math
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h}
```

`prod.eqF[LAB_JPN,MLK_JPN]`

```math
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h}
```

`prod.eqX[BRD_JPN,MLK_JPN]`

```math
X_{j,i} = ax_{j,i} \cdot Z_{i}
```

`prod.eqX[MLK_JPN,MLK_JPN]`

```math
X_{j,i} = ax_{j,i} \cdot Z_{i}
```

`prod.eqY[MLK_JPN]`

```math
Y_{i} = ay_{i} \cdot Z_{i}
```

`prod.eqpzs[MLK_JPN]`

```math
pz_{i} = ay_{i} \cdot py_{i} + \sum_{j \in \mathcal{D}_{j}} ax_{j,i} \cdot pq_{j} + 0
```

Domain j in { BRD_JPN, MLK_JPN }

`prod.eqpy[BRD_USA]`

```math
Y_{i} = b_{i} \cdot \prod_{h \in \mathcal{D}_{h}} {F_{h,i}}^{beta_h,i}
```

Domain h in { CAP_USA, LAB_USA }

`prod.eqF[CAP_USA,BRD_USA]`

```math
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h}
```

`prod.eqF[LAB_USA,BRD_USA]`

```math
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h}
```

`prod.eqX[BRD_USA,BRD_USA]`

```math
X_{j,i} = ax_{j,i} \cdot Z_{i}
```

`prod.eqX[MLK_USA,BRD_USA]`

```math
X_{j,i} = ax_{j,i} \cdot Z_{i}
```

`prod.eqY[BRD_USA]`

```math
Y_{i} = ay_{i} \cdot Z_{i}
```

`prod.eqpzs[BRD_USA]`

```math
pz_{i} = ay_{i} \cdot py_{i} + \sum_{j \in \mathcal{D}_{j}} ax_{j,i} \cdot pq_{j} + 0
```

Domain j in { BRD_USA, MLK_USA }

`prod.eqpy[MLK_USA]`

```math
Y_{i} = b_{i} \cdot \prod_{h \in \mathcal{D}_{h}} {F_{h,i}}^{beta_h,i}
```

Domain h in { CAP_USA, LAB_USA }

`prod.eqF[CAP_USA,MLK_USA]`

```math
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h}
```

`prod.eqF[LAB_USA,MLK_USA]`

```math
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h}
```

`prod.eqX[BRD_USA,MLK_USA]`

```math
X_{j,i} = ax_{j,i} \cdot Z_{i}
```

`prod.eqX[MLK_USA,MLK_USA]`

```math
X_{j,i} = ax_{j,i} \cdot Z_{i}
```

`prod.eqY[MLK_USA]`

```math
Y_{i} = ay_{i} \cdot Z_{i}
```

`prod.eqpzs[MLK_USA]`

```math
pz_{i} = ay_{i} \cdot py_{i} + \sum_{j \in \mathcal{D}_{j}} ax_{j,i} \cdot pq_{j} + 0
```

Domain j in { BRD_USA, MLK_USA }

`factor_market.eqF[CAP_JPN]`

```math
\sum_{j \in \mathcal{D}_{j}} F_{h,j} = FF_{h}
```

Domain j in { BRD_JPN, MLK_JPN }

`factor_market.eqF[LAB_JPN]`

```math
\sum_{j \in \mathcal{D}_{j}} F_{h,j} = FF_{h}
```

Domain j in { BRD_JPN, MLK_JPN }

`factor_market.eqF[CAP_USA]`

```math
\sum_{j \in \mathcal{D}_{j}} F_{h,j} = FF_{h}
```

Domain j in { BRD_USA, MLK_USA }

`factor_market.eqF[LAB_USA]`

```math
\sum_{j \in \mathcal{D}_{j}} F_{h,j} = FF_{h}
```

Domain j in { BRD_USA, MLK_USA }

`government.eqTd[JPN]`

```math
Td_{\text{JPN}} = tau\_d \cdot \sum_{h \in \mathcal{D}_{h}} pf_{h} \cdot FF_{h}
```

Domain h in { CAP_JPN, LAB_JPN }

`government.eqTz[BRD_JPN]`

```math
Tz_{i} = {tau\_z}_{i} \cdot pz_{i} \cdot Z_{i}
```

`government.eqTm[BRD_JPN]`

```math
Tm_{i} = {tau\_m}_{i} \cdot pm_{i} \cdot M_{i}
```

`government.eqXg[BRD_JPN]`

```math
Xg_{i} = mu_{i} \cdot (Td_{\text{JPN}} + \sum_{j \in \mathcal{D}_{j}} Tz_{j} + \sum_{j \in \mathcal{D}_{j}} Tm_{j} - Sg_{\text{JPN}}) / pq_{i}
```

Domain j in { BRD_JPN, MLK_JPN }
Domain j in { BRD_JPN, MLK_JPN }

`government.eqTz[MLK_JPN]`

```math
Tz_{i} = {tau\_z}_{i} \cdot pz_{i} \cdot Z_{i}
```

`government.eqTm[MLK_JPN]`

```math
Tm_{i} = {tau\_m}_{i} \cdot pm_{i} \cdot M_{i}
```

`government.eqXg[MLK_JPN]`

```math
Xg_{i} = mu_{i} \cdot (Td_{\text{JPN}} + \sum_{j \in \mathcal{D}_{j}} Tz_{j} + \sum_{j \in \mathcal{D}_{j}} Tm_{j} - Sg_{\text{JPN}}) / pq_{i}
```

Domain j in { BRD_JPN, MLK_JPN }
Domain j in { BRD_JPN, MLK_JPN }

`government.eqSg[JPN]`

```math
Sg_{\text{JPN}} = ssg \cdot (Td_{\text{JPN}} + \sum_{i \in \mathcal{D}_{i}} Tz_{i} + \sum_{i \in \mathcal{D}_{i}} Tm_{i})
```

Domain i in { BRD_JPN, MLK_JPN }
Domain i in { BRD_JPN, MLK_JPN }

`government.eqTd[USA]`

```math
Td_{\text{USA}} = tau\_d \cdot \sum_{h \in \mathcal{D}_{h}} pf_{h} \cdot FF_{h}
```

Domain h in { CAP_USA, LAB_USA }

`government.eqTz[BRD_USA]`

```math
Tz_{i} = {tau\_z}_{i} \cdot pz_{i} \cdot Z_{i}
```

`government.eqTm[BRD_USA]`

```math
Tm_{i} = {tau\_m}_{i} \cdot pm_{i} \cdot M_{i}
```

`government.eqXg[BRD_USA]`

```math
Xg_{i} = mu_{i} \cdot (Td_{\text{USA}} + \sum_{j \in \mathcal{D}_{j}} Tz_{j} + \sum_{j \in \mathcal{D}_{j}} Tm_{j} - Sg_{\text{USA}}) / pq_{i}
```

Domain j in { BRD_USA, MLK_USA }
Domain j in { BRD_USA, MLK_USA }

`government.eqTz[MLK_USA]`

```math
Tz_{i} = {tau\_z}_{i} \cdot pz_{i} \cdot Z_{i}
```

`government.eqTm[MLK_USA]`

```math
Tm_{i} = {tau\_m}_{i} \cdot pm_{i} \cdot M_{i}
```

`government.eqXg[MLK_USA]`

```math
Xg_{i} = mu_{i} \cdot (Td_{\text{USA}} + \sum_{j \in \mathcal{D}_{j}} Tz_{j} + \sum_{j \in \mathcal{D}_{j}} Tm_{j} - Sg_{\text{USA}}) / pq_{i}
```

Domain j in { BRD_USA, MLK_USA }
Domain j in { BRD_USA, MLK_USA }

`government.eqSg[USA]`

```math
Sg_{\text{USA}} = ssg \cdot (Td_{\text{USA}} + \sum_{i \in \mathcal{D}_{i}} Tz_{i} + \sum_{i \in \mathcal{D}_{i}} Tm_{i})
```

Domain i in { BRD_USA, MLK_USA }
Domain i in { BRD_USA, MLK_USA }

`private_saving.eqSp[JPN]`

```math
Sp_{\text{JPN}} = ssp \cdot \sum_{h \in \mathcal{D}_{h}} pf_{h} \cdot FF_{h}
```

Domain h in { CAP_JPN, LAB_JPN }

`investment.eqXv[BRD_JPN]`

```math
Xv_{i} = lambda_{i} \cdot (Sp_{\text{JPN}} + Sg_{\text{JPN}} + epsilon_{\text{JPN}} \cdot Sf) / pq_{i}
```

`investment.eqXv[MLK_JPN]`

```math
Xv_{i} = lambda_{i} \cdot (Sp_{\text{JPN}} + Sg_{\text{JPN}} + epsilon_{\text{JPN}} \cdot Sf) / pq_{i}
```

`private_saving.eqSp[USA]`

```math
Sp_{\text{USA}} = ssp \cdot \sum_{h \in \mathcal{D}_{h}} pf_{h} \cdot FF_{h}
```

Domain h in { CAP_USA, LAB_USA }

`investment.eqXv[BRD_USA]`

```math
Xv_{i} = lambda_{i} \cdot (Sp_{\text{USA}} + Sg_{\text{USA}} + epsilon_{\text{USA}} \cdot Sf) / pq_{i}
```

`investment.eqXv[MLK_USA]`

```math
Xv_{i} = lambda_{i} \cdot (Sp_{\text{USA}} + Sg_{\text{USA}} + epsilon_{\text{USA}} \cdot Sf) / pq_{i}
```

`household.eqXp[BRD_JPN,JPN]`

```math
Xp_{i} = alpha_{i} \cdot (\sum_{h \in \mathcal{D}_{h}} pf_{h} \cdot FF_{h} - Sp_{r} - Td_{r}) / pq_{i}
```

Domain h in { CAP_JPN, LAB_JPN }

`household.eqXp[MLK_JPN,JPN]`

```math
Xp_{i} = alpha_{i} \cdot (\sum_{h \in \mathcal{D}_{h}} pf_{h} \cdot FF_{h} - Sp_{r} - Td_{r}) / pq_{i}
```

Domain h in { CAP_JPN, LAB_JPN }

`household.eqXp[BRD_USA,USA]`

```math
Xp_{i} = alpha_{i} \cdot (\sum_{h \in \mathcal{D}_{h}} pf_{h} \cdot FF_{h} - Sp_{r} - Td_{r}) / pq_{i}
```

Domain h in { CAP_USA, LAB_USA }

`household.eqXp[MLK_USA,USA]`

```math
Xp_{i} = alpha_{i} \cdot (\sum_{h \in \mathcal{D}_{h}} pf_{h} \cdot FF_{h} - Sp_{r} - Td_{r}) / pq_{i}
```

Domain h in { CAP_USA, LAB_USA }

`prices.eqpe[BRD_JPN,JPN]`

```math
pe_{i} = epsilon_{r} \cdot pWe_{i}
```

`prices.eqpm[BRD_JPN,JPN]`

```math
pm_{i} = epsilon_{r} \cdot pWm_{i}
```

`prices.eqpe[MLK_JPN,JPN]`

```math
pe_{i} = epsilon_{r} \cdot pWe_{i}
```

`prices.eqpm[MLK_JPN,JPN]`

```math
pm_{i} = epsilon_{r} \cdot pWm_{i}
```

`prices.eqpe[BRD_USA,USA]`

```math
pe_{i} = epsilon_{r} \cdot pWe_{i}
```

`prices.eqpm[BRD_USA,USA]`

```math
pm_{i} = epsilon_{r} \cdot pWm_{i}
```

`prices.eqpe[MLK_USA,USA]`

```math
pe_{i} = epsilon_{r} \cdot pWe_{i}
```

`prices.eqpm[MLK_USA,USA]`

```math
pm_{i} = epsilon_{r} \cdot pWm_{i}
```

`bop.eqBOP`

```math
\sum_{i \in \mathcal{D}_{i}} pWe_{i} \cdot E_{i} + Sf = \sum_{i \in \mathcal{D}_{i}} pWm_{i} \cdot M_{i}
```

Domain i in { BRD_JPN, MLK_JPN }
Domain i in { BRD_JPN, MLK_JPN }

`bop.eqBOP`

```math
\sum_{i \in \mathcal{D}_{i}} pWe_{i} \cdot E_{i} + Sf = \sum_{i \in \mathcal{D}_{i}} pWm_{i} \cdot M_{i}
```

Domain i in { BRD_USA, MLK_USA }
Domain i in { BRD_USA, MLK_USA }

`world.eqpw[BRD,JPN,USA]`

```math
pWe_{\text{BRD\_JPN}} = pWm_{\text{BRD\_USA}}
```

`world.eqw[BRD,JPN,USA]`

```math
E_{\text{BRD\_JPN}} = M_{\text{BRD\_USA}}
```

`world.eqpw[BRD,USA,JPN]`

```math
pWe_{\text{BRD\_USA}} = pWm_{\text{BRD\_JPN}}
```

`world.eqw[BRD,USA,JPN]`

```math
E_{\text{BRD\_USA}} = M_{\text{BRD\_JPN}}
```

`world.eqpw[MLK,JPN,USA]`

```math
pWe_{\text{MLK\_JPN}} = pWm_{\text{MLK\_USA}}
```

`world.eqw[MLK,JPN,USA]`

```math
E_{\text{MLK\_JPN}} = M_{\text{MLK\_USA}}
```

`world.eqpw[MLK,USA,JPN]`

```math
pWe_{\text{MLK\_USA}} = pWm_{\text{MLK\_JPN}}
```

`world.eqw[MLK,USA,JPN]`

```math
E_{\text{MLK\_USA}} = M_{\text{MLK\_JPN}}
```

`armington.eqQ[BRD_JPN]`

```math
Q_{i} = gamma_{i} \cdot ({delta\_m}_{i} \cdot {M_{i}}^{eta_i} + {delta\_d}_{i} \cdot {D_{i}}^{eta_i})^{1/(eta_i)}
```

`armington.eqM[BRD_JPN]`

```math
M_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_m}_{i} \cdot pq_{i} / (1 + 0 + {tau\_m}_{i}) \cdot pm_{i})^{1/(1-eta_i)} \cdot Q_{i}
```

`armington.eqD[BRD_JPN]`

```math
D_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_d}_{i} \cdot pq_{i} / 1 \cdot pd_{i})^{1/(1-eta_i)} \cdot Q_{i}
```

`armington.eqQ[MLK_JPN]`

```math
Q_{i} = gamma_{i} \cdot ({delta\_m}_{i} \cdot {M_{i}}^{eta_i} + {delta\_d}_{i} \cdot {D_{i}}^{eta_i})^{1/(eta_i)}
```

`armington.eqM[MLK_JPN]`

```math
M_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_m}_{i} \cdot pq_{i} / (1 + 0 + {tau\_m}_{i}) \cdot pm_{i})^{1/(1-eta_i)} \cdot Q_{i}
```

`armington.eqD[MLK_JPN]`

```math
D_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_d}_{i} \cdot pq_{i} / 1 \cdot pd_{i})^{1/(1-eta_i)} \cdot Q_{i}
```

`transformation.eqZ[BRD_JPN]`

```math
Z_{i} = theta_{i} \cdot (xie_{i} \cdot {E_{i}}^{phi_i} + xid_{i} \cdot {D_{i}}^{phi_i})^{1/(phi_i)}
```

`transformation.eqE[BRD_JPN]`

```math
E_{i} = ({theta_{i}}^{phi_i} \cdot xie_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pe_{i})^{1/(1-phi_i)} \cdot Z_{i}
```

`transformation.eqDs[BRD_JPN]`

```math
D_{i} = ({theta_{i}}^{phi_i} \cdot xid_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pd_{i})^{1/(1-phi_i)} \cdot Z_{i}
```

`transformation.eqZ[MLK_JPN]`

```math
Z_{i} = theta_{i} \cdot (xie_{i} \cdot {E_{i}}^{phi_i} + xid_{i} \cdot {D_{i}}^{phi_i})^{1/(phi_i)}
```

`transformation.eqE[MLK_JPN]`

```math
E_{i} = ({theta_{i}}^{phi_i} \cdot xie_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pe_{i})^{1/(1-phi_i)} \cdot Z_{i}
```

`transformation.eqDs[MLK_JPN]`

```math
D_{i} = ({theta_{i}}^{phi_i} \cdot xid_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pd_{i})^{1/(1-phi_i)} \cdot Z_{i}
```

`armington.eqQ[BRD_USA]`

```math
Q_{i} = gamma_{i} \cdot ({delta\_m}_{i} \cdot {M_{i}}^{eta_i} + {delta\_d}_{i} \cdot {D_{i}}^{eta_i})^{1/(eta_i)}
```

`armington.eqM[BRD_USA]`

```math
M_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_m}_{i} \cdot pq_{i} / (1 + 0 + {tau\_m}_{i}) \cdot pm_{i})^{1/(1-eta_i)} \cdot Q_{i}
```

`armington.eqD[BRD_USA]`

```math
D_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_d}_{i} \cdot pq_{i} / 1 \cdot pd_{i})^{1/(1-eta_i)} \cdot Q_{i}
```

`armington.eqQ[MLK_USA]`

```math
Q_{i} = gamma_{i} \cdot ({delta\_m}_{i} \cdot {M_{i}}^{eta_i} + {delta\_d}_{i} \cdot {D_{i}}^{eta_i})^{1/(eta_i)}
```

`armington.eqM[MLK_USA]`

```math
M_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_m}_{i} \cdot pq_{i} / (1 + 0 + {tau\_m}_{i}) \cdot pm_{i})^{1/(1-eta_i)} \cdot Q_{i}
```

`armington.eqD[MLK_USA]`

```math
D_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_d}_{i} \cdot pq_{i} / 1 \cdot pd_{i})^{1/(1-eta_i)} \cdot Q_{i}
```

`transformation.eqZ[BRD_USA]`

```math
Z_{i} = theta_{i} \cdot (xie_{i} \cdot {E_{i}}^{phi_i} + xid_{i} \cdot {D_{i}}^{phi_i})^{1/(phi_i)}
```

`transformation.eqE[BRD_USA]`

```math
E_{i} = ({theta_{i}}^{phi_i} \cdot xie_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pe_{i})^{1/(1-phi_i)} \cdot Z_{i}
```

`transformation.eqDs[BRD_USA]`

```math
D_{i} = ({theta_{i}}^{phi_i} \cdot xid_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pd_{i})^{1/(1-phi_i)} \cdot Z_{i}
```

`transformation.eqZ[MLK_USA]`

```math
Z_{i} = theta_{i} \cdot (xie_{i} \cdot {E_{i}}^{phi_i} + xid_{i} \cdot {D_{i}}^{phi_i})^{1/(phi_i)}
```

`transformation.eqE[MLK_USA]`

```math
E_{i} = ({theta_{i}}^{phi_i} \cdot xie_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pe_{i})^{1/(1-phi_i)} \cdot Z_{i}
```

`transformation.eqDs[MLK_USA]`

```math
D_{i} = ({theta_{i}}^{phi_i} \cdot xid_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pd_{i})^{1/(1-phi_i)} \cdot Z_{i}
```

`market.eqQ[BRD_JPN]`

```math
Q_{i} = Xp_{i} + Xg_{i} + Xv_{i} + \sum_{j \in \mathcal{D}_{j}} X_{i,j}
```

Domain j in { BRD_JPN, MLK_JPN }

`market.eqQ[MLK_JPN]`

```math
Q_{i} = Xp_{i} + Xg_{i} + Xv_{i} + \sum_{j \in \mathcal{D}_{j}} X_{i,j}
```

Domain j in { BRD_JPN, MLK_JPN }

`market.eqQ[BRD_USA]`

```math
Q_{i} = Xp_{i} + Xg_{i} + Xv_{i} + \sum_{j \in \mathcal{D}_{j}} X_{i,j}
```

Domain j in { BRD_USA, MLK_USA }

`market.eqQ[MLK_USA]`

```math
Q_{i} = Xp_{i} + Xg_{i} + Xv_{i} + \sum_{j \in \mathcal{D}_{j}} X_{i,j}
```

Domain j in { BRD_USA, MLK_USA }

`utility.eqUU[JPN]`

```math
UU_{r} = \prod_{i \in \mathcal{D}_{i}} {Xp_{i}}^{alpha_i}
```

Domain i in { BRD_JPN, MLK_JPN }

`utility.eqUU[USA]`

```math
UU_{r} = \prod_{i \in \mathcal{D}_{i}} {Xp_{i}}^{alpha_i}
```

Domain i in { BRD_USA, MLK_USA }

`utility.objective` maximize social welfare

`init.start[Xv_BRD_JPN]` start Xv_BRD_JPN = 16.0

`init.start[pm_MLK_USA]` start pm_MLK_USA = 1.0

`init.start[F_CAP_USA_BRD_USA]` start F_CAP_USA_BRD_USA = 33.0

`init.start[F_CAP_USA_MLK_USA]` start F_CAP_USA_MLK_USA = 30.0

`init.start[Q_BRD_USA]` start Q_BRD_USA = 111.0

`init.start[pWe_MLK_JPN]` start pWe_MLK_JPN = 1.0

`init.start[Xp_MLK_JPN]` start Xp_MLK_JPN = 30.0

`init.start[Z_MLK_USA]` start Z_MLK_USA = 91.0

`init.start[M_MLK_JPN]` start M_MLK_JPN = 11.0

`init.start[Tz_BRD_JPN]` start Tz_BRD_JPN = 5.0

`init.start[pWe_MLK_USA]` start pWe_MLK_USA = 1.0

`init.start[Tm_MLK_JPN]` start Tm_MLK_JPN = 2.0

`init.start[Z_MLK_JPN]` start Z_MLK_JPN = 72.0

`init.start[Z_BRD_USA]` start Z_BRD_USA = 105.0

`init.start[Y_BRD_USA]` start Y_BRD_USA = 48.0

`init.start[pe_BRD_USA]` start pe_BRD_USA = 1.0

`init.start[pf_CAP_JPN]` start pf_CAP_JPN = 1.0

`init.start[Xv_MLK_USA]` start Xv_MLK_USA = 15.0

`init.start[F_CAP_JPN_BRD_JPN]` start F_CAP_JPN_BRD_JPN = 20.0

`init.start[pe_MLK_JPN]` start pe_MLK_JPN = 1.0

`init.start[pz_BRD_JPN]` start pz_BRD_JPN = 1.0

`init.start[Sg_JPN]` start Sg_JPN = 2.0

`init.start[Tz_BRD_USA]` start Tz_BRD_USA = 10.0

`init.start[E_MLK_JPN]` start E_MLK_JPN = 4.0

`init.start[Tz_MLK_JPN]` start Tz_MLK_JPN = 4.0

`init.start[py_MLK_JPN]` start py_MLK_JPN = 1.0

`init.start[Tm_BRD_USA]` start Tm_BRD_USA = 1.0

`init.start[D_BRD_USA]` start D_BRD_USA = 102.00000000000001

`init.start[pz_MLK_USA]` start pz_MLK_USA = 1.0

`init.start[pf_CAP_USA]` start pf_CAP_USA = 1.0

`init.start[M_MLK_USA]` start M_MLK_USA = 4.0

`init.start[Xg_MLK_JPN]` start Xg_MLK_JPN = 14.0

`init.start[X_BRD_JPN_MLK_JPN]` start X_BRD_JPN_MLK_JPN = 8.0

`init.start[pe_BRD_JPN]` start pe_BRD_JPN = 1.0

`init.start[Y_MLK_JPN]` start Y_MLK_JPN = 55.0

`init.start[Z_BRD_JPN]` start Z_BRD_JPN = 73.0

`init.start[pWm_BRD_JPN]` start pWm_BRD_JPN = 1.0

`init.start[Tz_MLK_USA]` start Tz_MLK_USA = 20.0

`init.start[Xg_BRD_JPN]` start Xg_BRD_JPN = 19.0

`init.start[X_BRD_JPN_BRD_JPN]` start X_BRD_JPN_BRD_JPN = 21.0

`init.start[F_CAP_JPN_MLK_JPN]` start F_CAP_JPN_MLK_JPN = 30.0

`init.start[py_MLK_USA]` start py_MLK_USA = 1.0

`init.start[pWe_BRD_USA]` start pWe_BRD_USA = 1.0

`init.start[pWm_BRD_USA]` start pWm_BRD_USA = 1.0

`init.start[Sp_JPN]` start Sp_JPN = 17.0

`init.start[X_MLK_JPN_MLK_JPN]` start X_MLK_JPN_MLK_JPN = 9.0

`init.start[pm_BRD_USA]` start pm_BRD_USA = 1.0

`init.start[Y_MLK_USA]` start Y_MLK_USA = 61.0

`init.start[F_LAB_JPN_BRD_JPN]` start F_LAB_JPN_BRD_JPN = 15.0

`init.start[pWm_MLK_JPN]` start pWm_MLK_JPN = 1.0

`init.start[Td_JPN]` start Td_JPN = 23.0

`init.start[Sp_USA]` start Sp_USA = 20.0

`init.start[X_BRD_USA_MLK_USA]` start X_BRD_USA_MLK_USA = 1.0

`init.start[Q_BRD_JPN]` start Q_BRD_JPN = 84.0

`init.start[pq_MLK_USA]` start pq_MLK_USA = 1.0

`init.start[X_MLK_JPN_BRD_JPN]` start X_MLK_JPN_BRD_JPN = 17.0

`init.start[pd_MLK_USA]` start pd_MLK_USA = 1.0

`init.start[py_BRD_JPN]` start py_BRD_JPN = 1.0

`init.start[Sg_USA]` start Sg_USA = 27.0

`init.start[pq_MLK_JPN]` start pq_MLK_JPN = 1.0

`init.start[D_BRD_JPN]` start D_BRD_JPN = 70.0

`init.start[F_LAB_JPN_MLK_JPN]` start F_LAB_JPN_MLK_JPN = 25.0

`init.start[X_MLK_USA_BRD_USA]` start X_MLK_USA_BRD_USA = 17.0

`init.start[Xg_BRD_USA]` start Xg_BRD_USA = 20.0

`init.start[pe_MLK_USA]` start pe_MLK_USA = 1.0

`init.start[pd_BRD_JPN]` start pd_BRD_JPN = 1.0

`init.start[F_LAB_USA_MLK_USA]` start F_LAB_USA_MLK_USA = 31.0

`init.start[Q_MLK_JPN]` start Q_MLK_JPN = 85.0

`init.start[pm_MLK_JPN]` start pm_MLK_JPN = 1.0

`init.start[M_BRD_JPN]` start M_BRD_JPN = 13.0

`init.start[E_BRD_USA]` start E_BRD_USA = 13.0

`init.start[E_MLK_USA]` start E_MLK_USA = 11.0

`init.start[D_MLK_JPN]` start D_MLK_JPN = 72.0

`init.start[Tm_MLK_USA]` start Tm_MLK_USA = 1.0

`init.start[pWe_BRD_JPN]` start pWe_BRD_JPN = 1.0

`init.start[pd_MLK_JPN]` start pd_MLK_JPN = 1.0

`init.start[X_BRD_USA_BRD_USA]` start X_BRD_USA_BRD_USA = 40.0

`init.start[pf_LAB_USA]` start pf_LAB_USA = 1.0

`init.start[Xv_BRD_USA]` start Xv_BRD_USA = 20.0

`init.start[pq_BRD_JPN]` start pq_BRD_JPN = 1.0

`init.start[pz_BRD_USA]` start pz_BRD_USA = 1.0

`init.start[D_MLK_USA]` start D_MLK_USA = 100.00000000000001

`init.start[Y_BRD_JPN]` start Y_BRD_JPN = 35.0

`init.start[Tm_BRD_JPN]` start Tm_BRD_JPN = 1.0

`init.start[Xp_MLK_USA]` start Xp_MLK_USA = 30.0

`init.start[Q_MLK_USA]` start Q_MLK_USA = 105.0

`init.start[pf_LAB_JPN]` start pf_LAB_JPN = 1.0

`init.start[Xg_MLK_USA]` start Xg_MLK_USA = 14.0

`init.start[Xp_BRD_JPN]` start Xp_BRD_JPN = 20.0

`init.start[F_LAB_USA_BRD_USA]` start F_LAB_USA_BRD_USA = 15.0

`init.start[M_BRD_USA]` start M_BRD_USA = 8.0

`init.start[pq_BRD_USA]` start pq_BRD_USA = 1.0

`init.start[Xp_BRD_USA]` start Xp_BRD_USA = 30.0

`init.start[epsilon_JPN]` start epsilon_JPN = 1.0

`init.start[E_BRD_JPN]` start E_BRD_JPN = 8.0

`init.start[pd_BRD_USA]` start pd_BRD_USA = 1.0

`init.start[Xv_MLK_JPN]` start Xv_MLK_JPN = 15.0

`init.start[pz_MLK_JPN]` start pz_MLK_JPN = 1.0

`init.start[epsilon_USA]` start epsilon_USA = 1.0

`init.start[pm_BRD_JPN]` start pm_BRD_JPN = 1.0

`init.start[py_BRD_USA]` start py_BRD_USA = 1.0

`init.start[X_MLK_USA_MLK_USA]` start X_MLK_USA_MLK_USA = 29.0

`init.start[pWm_MLK_USA]` start pWm_MLK_USA = 1.0

`init.start[Td_USA]` start Td_USA = 29.0

`init.lower[Xv_BRD_JPN]` lower Xv_BRD_JPN = 1.0e-5

`init.lower[pm_MLK_USA]` lower pm_MLK_USA = 1.0e-5

`init.lower[F_CAP_USA_BRD_USA]` lower F_CAP_USA_BRD_USA = 1.0e-5

`init.lower[F_CAP_USA_MLK_USA]` lower F_CAP_USA_MLK_USA = 1.0e-5

`init.lower[Q_BRD_USA]` lower Q_BRD_USA = 1.0e-5

`init.lower[pWe_MLK_JPN]` lower pWe_MLK_JPN = 1.0e-5

`init.lower[Xp_MLK_JPN]` lower Xp_MLK_JPN = 1.0e-5

`init.lower[Z_MLK_USA]` lower Z_MLK_USA = 1.0e-5

`init.lower[M_MLK_JPN]` lower M_MLK_JPN = 1.0e-5

`init.lower[Tz_BRD_JPN]` lower Tz_BRD_JPN = 0.0

`init.lower[pWe_MLK_USA]` lower pWe_MLK_USA = 1.0e-5

`init.lower[Tm_MLK_JPN]` lower Tm_MLK_JPN = 0.0

`init.lower[Z_MLK_JPN]` lower Z_MLK_JPN = 1.0e-5

`init.lower[Z_BRD_USA]` lower Z_BRD_USA = 1.0e-5

`init.lower[Y_BRD_USA]` lower Y_BRD_USA = 1.0e-5

`init.lower[pe_BRD_USA]` lower pe_BRD_USA = 1.0e-5

`init.lower[pf_CAP_JPN]` lower pf_CAP_JPN = 1.0e-5

`init.lower[Xv_MLK_USA]` lower Xv_MLK_USA = 1.0e-5

`init.lower[F_CAP_JPN_BRD_JPN]` lower F_CAP_JPN_BRD_JPN = 1.0e-5

`init.lower[pe_MLK_JPN]` lower pe_MLK_JPN = 1.0e-5

`init.lower[pz_BRD_JPN]` lower pz_BRD_JPN = 1.0e-5

`init.lower[Sg_JPN]` lower Sg_JPN = 1.0e-5

`init.lower[Tz_BRD_USA]` lower Tz_BRD_USA = 0.0

`init.lower[E_MLK_JPN]` lower E_MLK_JPN = 1.0e-5

`init.lower[Tz_MLK_JPN]` lower Tz_MLK_JPN = 0.0

`init.lower[py_MLK_JPN]` lower py_MLK_JPN = 1.0e-5

`init.lower[Tm_BRD_USA]` lower Tm_BRD_USA = 0.0

`init.lower[D_BRD_USA]` lower D_BRD_USA = 1.0e-5

`init.lower[pz_MLK_USA]` lower pz_MLK_USA = 1.0e-5

`init.lower[pf_CAP_USA]` lower pf_CAP_USA = 1.0e-5

`init.lower[M_MLK_USA]` lower M_MLK_USA = 1.0e-5

`init.lower[Xg_MLK_JPN]` lower Xg_MLK_JPN = 1.0e-5

`init.lower[X_BRD_JPN_MLK_JPN]` lower X_BRD_JPN_MLK_JPN = 1.0e-5

`init.lower[pe_BRD_JPN]` lower pe_BRD_JPN = 1.0e-5

`init.lower[Y_MLK_JPN]` lower Y_MLK_JPN = 1.0e-5

`init.lower[Z_BRD_JPN]` lower Z_BRD_JPN = 1.0e-5

`init.lower[pWm_BRD_JPN]` lower pWm_BRD_JPN = 1.0e-5

`init.lower[Tz_MLK_USA]` lower Tz_MLK_USA = 0.0

`init.lower[Xg_BRD_JPN]` lower Xg_BRD_JPN = 1.0e-5

`init.lower[X_BRD_JPN_BRD_JPN]` lower X_BRD_JPN_BRD_JPN = 1.0e-5

`init.lower[F_CAP_JPN_MLK_JPN]` lower F_CAP_JPN_MLK_JPN = 1.0e-5

`init.lower[py_MLK_USA]` lower py_MLK_USA = 1.0e-5

`init.lower[pWe_BRD_USA]` lower pWe_BRD_USA = 1.0e-5

`init.lower[pWm_BRD_USA]` lower pWm_BRD_USA = 1.0e-5

`init.lower[Sp_JPN]` lower Sp_JPN = 1.0e-5

`init.lower[X_MLK_JPN_MLK_JPN]` lower X_MLK_JPN_MLK_JPN = 1.0e-5

`init.lower[pm_BRD_USA]` lower pm_BRD_USA = 1.0e-5

`init.lower[Y_MLK_USA]` lower Y_MLK_USA = 1.0e-5

`init.lower[F_LAB_JPN_BRD_JPN]` lower F_LAB_JPN_BRD_JPN = 1.0e-5

`init.lower[pWm_MLK_JPN]` lower pWm_MLK_JPN = 1.0e-5

`init.lower[Td_JPN]` lower Td_JPN = 1.0e-5

`init.lower[Sp_USA]` lower Sp_USA = 1.0e-5

`init.lower[X_BRD_USA_MLK_USA]` lower X_BRD_USA_MLK_USA = 1.0e-5

`init.lower[Q_BRD_JPN]` lower Q_BRD_JPN = 1.0e-5

`init.lower[pq_MLK_USA]` lower pq_MLK_USA = 1.0e-5

`init.lower[X_MLK_JPN_BRD_JPN]` lower X_MLK_JPN_BRD_JPN = 1.0e-5

`init.lower[pd_MLK_USA]` lower pd_MLK_USA = 1.0e-5

`init.lower[py_BRD_JPN]` lower py_BRD_JPN = 1.0e-5

`init.lower[Sg_USA]` lower Sg_USA = 1.0e-5

`init.lower[pq_MLK_JPN]` lower pq_MLK_JPN = 1.0e-5

`init.lower[D_BRD_JPN]` lower D_BRD_JPN = 1.0e-5

`init.lower[F_LAB_JPN_MLK_JPN]` lower F_LAB_JPN_MLK_JPN = 1.0e-5

`init.lower[X_MLK_USA_BRD_USA]` lower X_MLK_USA_BRD_USA = 1.0e-5

`init.lower[Xg_BRD_USA]` lower Xg_BRD_USA = 1.0e-5

`init.lower[pe_MLK_USA]` lower pe_MLK_USA = 1.0e-5

`init.lower[pd_BRD_JPN]` lower pd_BRD_JPN = 1.0e-5

`init.lower[F_LAB_USA_MLK_USA]` lower F_LAB_USA_MLK_USA = 1.0e-5

`init.lower[Q_MLK_JPN]` lower Q_MLK_JPN = 1.0e-5

`init.lower[pm_MLK_JPN]` lower pm_MLK_JPN = 1.0e-5

`init.lower[M_BRD_JPN]` lower M_BRD_JPN = 1.0e-5

`init.lower[E_BRD_USA]` lower E_BRD_USA = 1.0e-5

`init.lower[E_MLK_USA]` lower E_MLK_USA = 1.0e-5

`init.lower[D_MLK_JPN]` lower D_MLK_JPN = 1.0e-5

`init.lower[Tm_MLK_USA]` lower Tm_MLK_USA = 0.0

`init.lower[pWe_BRD_JPN]` lower pWe_BRD_JPN = 1.0e-5

`init.lower[pd_MLK_JPN]` lower pd_MLK_JPN = 1.0e-5

`init.lower[X_BRD_USA_BRD_USA]` lower X_BRD_USA_BRD_USA = 1.0e-5

`init.lower[pf_LAB_USA]` lower pf_LAB_USA = 1.0e-5

`init.lower[Xv_BRD_USA]` lower Xv_BRD_USA = 1.0e-5

`init.lower[pq_BRD_JPN]` lower pq_BRD_JPN = 1.0e-5

`init.lower[pz_BRD_USA]` lower pz_BRD_USA = 1.0e-5

`init.lower[D_MLK_USA]` lower D_MLK_USA = 1.0e-5

`init.lower[Y_BRD_JPN]` lower Y_BRD_JPN = 1.0e-5

`init.lower[Tm_BRD_JPN]` lower Tm_BRD_JPN = 0.0

`init.lower[Xp_MLK_USA]` lower Xp_MLK_USA = 1.0e-5

`init.lower[Q_MLK_USA]` lower Q_MLK_USA = 1.0e-5

`init.lower[pf_LAB_JPN]` lower pf_LAB_JPN = 1.0e-5

`init.lower[Xg_MLK_USA]` lower Xg_MLK_USA = 1.0e-5

`init.lower[Xp_BRD_JPN]` lower Xp_BRD_JPN = 1.0e-5

`init.lower[F_LAB_USA_BRD_USA]` lower F_LAB_USA_BRD_USA = 1.0e-5

`init.lower[M_BRD_USA]` lower M_BRD_USA = 1.0e-5

`init.lower[pq_BRD_USA]` lower pq_BRD_USA = 1.0e-5

`init.lower[Xp_BRD_USA]` lower Xp_BRD_USA = 1.0e-5

`init.lower[epsilon_JPN]` lower epsilon_JPN = 1.0e-5

`init.lower[E_BRD_JPN]` lower E_BRD_JPN = 1.0e-5

`init.lower[pd_BRD_USA]` lower pd_BRD_USA = 1.0e-5

`init.lower[Xv_MLK_JPN]` lower Xv_MLK_JPN = 1.0e-5

`init.lower[pz_MLK_JPN]` lower pz_MLK_JPN = 1.0e-5

`init.lower[epsilon_USA]` lower epsilon_USA = 1.0e-5

`init.lower[pm_BRD_JPN]` lower pm_BRD_JPN = 1.0e-5

`init.lower[py_BRD_USA]` lower py_BRD_USA = 1.0e-5

`init.lower[X_MLK_USA_MLK_USA]` lower X_MLK_USA_MLK_USA = 1.0e-5

`init.lower[pWm_MLK_USA]` lower pWm_MLK_USA = 1.0e-5

`init.lower[Td_USA]` lower Td_USA = 1.0e-5

`init.fixed[pf_LAB_JPN]` fixed pf_LAB_JPN = 1.0

`init.fixed[epsilon_USA]` fixed epsilon_USA = 1.0

`init.fixed[pf_LAB_USA]` fixed pf_LAB_USA = 1.0
