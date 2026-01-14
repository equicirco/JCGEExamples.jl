# Equations
`prod.eqpy[BRD]`

$$
Y_{i} = b_{i} \cdot \prod_{h \in \mathcal{D}_{h}} {F_{h,i}}^{beta_h,i}
$$

Domain h in { CAP, LAB }

`prod.eqF[CAP,BRD]`

$$
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h}
$$

`prod.eqF[LAB,BRD]`

$$
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h}
$$

`prod.eqX[BRD,BRD]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[MLK,BRD]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqY[BRD]`

$$
Y_{i} = ay_{i} \cdot Z_{i}
$$

`prod.eqpzs[BRD]`

$$
pz_{i} = ay_{i} \cdot py_{i} + \sum_{j \in \mathcal{D}_{j}} ax_{j,i} \cdot pq_{j} + 0
$$

Domain j in { BRD, MLK }

`prod.eqpy[MLK]`

$$
Y_{i} = b_{i} \cdot \prod_{h \in \mathcal{D}_{h}} {F_{h,i}}^{beta_h,i}
$$

Domain h in { CAP, LAB }

`prod.eqF[CAP,MLK]`

$$
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h}
$$

`prod.eqF[LAB,MLK]`

$$
F_{h,i} = beta_{h,i} \cdot py_{i} \cdot Y_{i} / pf_{h}
$$

`prod.eqX[BRD,MLK]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqX[MLK,MLK]`

$$
X_{j,i} = ax_{j,i} \cdot Z_{i}
$$

`prod.eqY[MLK]`

$$
Y_{i} = ay_{i} \cdot Z_{i}
$$

`prod.eqpzs[MLK]`

$$
pz_{i} = ay_{i} \cdot py_{i} + \sum_{j \in \mathcal{D}_{j}} ax_{j,i} \cdot pq_{j} + 0
$$

Domain j in { BRD, MLK }

`factor_market.eqF[CAP]`

$$
\sum_{j \in \mathcal{D}_{j}} F_{h,j} = FF_{h}
$$

Domain j in { BRD, MLK }

`factor_market.eqF[LAB]`

$$
\sum_{j \in \mathcal{D}_{j}} F_{h,j} = FF_{h}
$$

Domain j in { BRD, MLK }

`government.eqTd`

$$
Td = tau\_d \cdot (\sum_{h \in \mathcal{D}_{h}} pf_{h} \cdot FF_{h} + \sum_{i \in \mathcal{D}_{i}} RT_{i} + 0)
$$

Domain h in { CAP, LAB }
Domain i in { BRD, MLK }

`government.eqTz[BRD]`

$$
Tz_{i} = {tau\_z}_{i} \cdot pz_{i} \cdot Z_{i}
$$

`government.eqTm[BRD]`

$$
Tm_{i} = {tau\_m}_{i} \cdot pm_{i} \cdot M_{i}
$$

`government.eqXg[BRD]`

$$
Xg_{i} = mu_{i} \cdot (Td + \sum_{j \in \mathcal{D}_{j}} Tz_{j} + \sum_{j \in \mathcal{D}_{j}} Tm_{j} - Sg) / pq_{i}
$$

Domain j in { BRD, MLK }
Domain j in { BRD, MLK }

`government.eqTz[MLK]`

$$
Tz_{i} = {tau\_z}_{i} \cdot pz_{i} \cdot Z_{i}
$$

`government.eqTm[MLK]`

$$
Tm_{i} = {tau\_m}_{i} \cdot pm_{i} \cdot M_{i}
$$

`government.eqXg[MLK]`

$$
Xg_{i} = mu_{i} \cdot (Td + \sum_{j \in \mathcal{D}_{j}} Tz_{j} + \sum_{j \in \mathcal{D}_{j}} Tm_{j} - Sg) / pq_{i}
$$

Domain j in { BRD, MLK }
Domain j in { BRD, MLK }

`government.eqSg`

$$
Sg = ssg \cdot (Td + \sum_{i \in \mathcal{D}_{i}} Tz_{i} + \sum_{i \in \mathcal{D}_{i}} Tm_{i})
$$

Domain i in { BRD, MLK }
Domain i in { BRD, MLK }

`private_saving.eqSp`

$$
Sp = ssp \cdot (\sum_{h \in \mathcal{D}_{h}} pf_{h} \cdot FF_{h} + \sum_{i \in \mathcal{D}_{i}} RT_{i} + 0)
$$

Domain h in { CAP, LAB }
Domain i in { BRD, MLK }

`investment.eqXv[BRD]`

$$
Xv_{i} = lambda_{i} \cdot (Sp + Sg + epsilon \cdot Sf) / pq_{i}
$$

`investment.eqXv[MLK]`

$$
Xv_{i} = lambda_{i} \cdot (Sp + Sg + epsilon \cdot Sf) / pq_{i}
$$

`household.eqXp[BRD]`

$$
Xp_{i} = alpha_{i} \cdot (\sum_{h \in \mathcal{D}_{h}} pf_{h} \cdot FF_{h} - Sp - Td + \sum_{j \in \mathcal{D}_{j}} RT_{j} + 0) / pq_{i}
$$

Domain h in { CAP, LAB }
Domain j in { BRD, MLK }

`household.eqXp[MLK]`

$$
Xp_{i} = alpha_{i} \cdot (\sum_{h \in \mathcal{D}_{h}} pf_{h} \cdot FF_{h} - Sp - Td + \sum_{j \in \mathcal{D}_{j}} RT_{j} + 0) / pq_{i}
$$

Domain h in { CAP, LAB }
Domain j in { BRD, MLK }

`prices.eqpe[BRD]`

$$
pe_{i} = epsilon \cdot pWe_{i}
$$

`prices.eqpm[BRD]`

$$
pm_{i} = epsilon \cdot pWm_{i}
$$

`prices.eqpe[MLK]`

$$
pe_{i} = epsilon \cdot pWe_{i}
$$

`prices.eqpm[MLK]`

$$
pm_{i} = epsilon \cdot pWm_{i}
$$

`bop.eqBOP`

$$
\sum_{i \in \mathcal{D}_{i}} pWe_{i} \cdot E_{i} + Sf = \sum_{i \in \mathcal{D}_{i}} pWm_{i} \cdot M_{i}
$$

Domain i in { BRD, MLK }
Domain i in { BRD, MLK }

`armington.eqQ[BRD]`

$$
Q_{i} = gamma_{i} \cdot ({delta\_m}_{i} \cdot {M_{i}}^{eta_i} + {delta\_d}_{i} \cdot {D_{i}}^{eta_i})^{1/(eta_i)}
$$

`armington.eqM[BRD]`

$$
M_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_m}_{i} \cdot pq_{i} / (1 + 0 + {tau\_m}_{i}) \cdot pm_{i})^{1/(1-eta_i)} \cdot Q_{i}
$$

`armington.eqD[BRD]`

$$
D_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_d}_{i} \cdot pq_{i} / {pd\_scale}_{i} \cdot pd_{i})^{1/(1-eta_i)} \cdot Q_{i}
$$

`armington.eqQ[MLK]`

$$
Q_{i} = gamma_{i} \cdot ({delta\_m}_{i} \cdot {M_{i}}^{eta_i} + {delta\_d}_{i} \cdot {D_{i}}^{eta_i})^{1/(eta_i)}
$$

`armington.eqM[MLK]`

$$
M_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_m}_{i} \cdot pq_{i} / (1 + 0 + {tau\_m}_{i}) \cdot pm_{i})^{1/(1-eta_i)} \cdot Q_{i}
$$

`armington.eqD[MLK]`

$$
D_{i} = ({gamma_{i}}^{eta_i} \cdot {delta\_d}_{i} \cdot pq_{i} / {pd\_scale}_{i} \cdot pd_{i})^{1/(1-eta_i)} \cdot Q_{i}
$$

`transformation.eqZ[BRD]`

$$
Z_{i} = theta_{i} \cdot (xie_{i} \cdot {E_{i}}^{phi_i} + xid_{i} \cdot {D_{i}}^{phi_i})^{1/(phi_i)}
$$

`transformation.eqE[BRD]`

$$
E_{i} = ({theta_{i}}^{phi_i} \cdot xie_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pe_{i})^{1/(1-phi_i)} \cdot Z_{i}
$$

`transformation.eqDs[BRD]`

$$
D_{i} = ({theta_{i}}^{phi_i} \cdot xid_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pd_{i})^{1/(1-phi_i)} \cdot Z_{i}
$$

`transformation.eqZ[MLK]`

$$
Z_{i} = theta_{i} \cdot (xie_{i} \cdot {E_{i}}^{phi_i} + xid_{i} \cdot {D_{i}}^{phi_i})^{1/(phi_i)}
$$

`transformation.eqE[MLK]`

$$
E_{i} = ({theta_{i}}^{phi_i} \cdot xie_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pe_{i})^{1/(1-phi_i)} \cdot Z_{i}
$$

`transformation.eqDs[MLK]`

$$
D_{i} = ({theta_{i}}^{phi_i} \cdot xid_{i} \cdot (1 + {tau\_z}_{i}) \cdot pz_{i} / pd_{i})^{1/(1-phi_i)} \cdot Z_{i}
$$

`rent.eqRT[BRD]`

$$
RT_{i} = ((1 - eta_{i}) / eta_{i}) \cdot pd_{i} \cdot D_{i}
$$

`rent.eqRT[MLK]`

$$
RT_{i} = ((1 - eta_{i}) / eta_{i}) \cdot pd_{i} \cdot D_{i}
$$

`market.eqQ[BRD]`

$$
Q_{i} = Xp_{i} + Xg_{i} + Xv_{i} + \sum_{j \in \mathcal{D}_{j}} X_{i,j}
$$

Domain j in { BRD, MLK }

`market.eqQ[MLK]`

$$
Q_{i} = Xp_{i} + Xg_{i} + Xv_{i} + \sum_{j \in \mathcal{D}_{j}} X_{i,j}
$$

Domain j in { BRD, MLK }

`utility.objective` maximize Cobb-Douglas utility over Xp

`init.start[X_MLK_BRD]` start X_MLK_BRD = 17.0

`init.start[F_LAB_BRD]` start F_LAB_BRD = 5.0

`init.start[X_MLK_MLK]` start X_MLK_MLK = 9.0

`init.start[pd_MLK]` start pd_MLK = 1.0

`init.start[F_CAP_MLK]` start F_CAP_MLK = 16.909090909090907

`init.start[pz_MLK]` start pz_MLK = 1.0

`init.start[pz_BRD]` start pz_BRD = 1.0

`init.start[Xg_MLK]` start Xg_MLK = 14.0

`init.start[pm_BRD]` start pm_BRD = 1.0

`init.start[X_BRD_BRD]` start X_BRD_BRD = 21.0

`init.start[Tm_BRD]` start Tm_BRD = 1.0

`init.start[pd_BRD]` start pd_BRD = 1.0

`init.start[M_BRD]` start M_BRD = 13.0

`init.start[Td]` start Td = 23.0

`init.start[Tz_BRD]` start Tz_BRD = 5.0

`init.start[Sp]` start Sp = 17.0

`init.start[X_BRD_MLK]` start X_BRD_MLK = 8.0

`init.start[pe_MLK]` start pe_MLK = 1.0

`init.start[pq_MLK]` start pq_MLK = 1.0

`init.start[Y_MLK]` start Y_MLK = 30.999999999999993

`init.start[Tz_MLK]` start Tz_MLK = 4.0

`init.start[pq_BRD]` start pq_BRD = 1.0

`init.start[pf_CAP]` start pf_CAP = 1.0

`init.start[RT_BRD]` start RT_BRD = 23.333333333333336

`init.start[Xg_BRD]` start Xg_BRD = 19.0

`init.start[Xv_MLK]` start Xv_MLK = 15.0

`init.start[M_MLK]` start M_MLK = 11.0

`init.start[E_BRD]` start E_BRD = 8.0

`init.start[Xp_BRD]` start Xp_BRD = 20.0

`init.start[py_MLK]` start py_MLK = 1.0

`init.start[RT_MLK]` start RT_MLK = 24.000000000000007

`init.start[Z_BRD]` start Z_BRD = 49.666666666666664

`init.start[E_MLK]` start E_MLK = 4.0

`init.start[Tm_MLK]` start Tm_MLK = 2.0

`init.start[epsilon]` start epsilon = 1.0

`init.start[D_BRD]` start D_BRD = 46.666666666666664

`init.start[Q_BRD]` start Q_BRD = 84.0

`init.start[pm_MLK]` start pm_MLK = 1.0

`init.start[F_CAP_BRD]` start F_CAP_BRD = 6.666666666666666

`init.start[Sg]` start Sg = 2.0

`init.start[py_BRD]` start py_BRD = 1.0

`init.start[Q_MLK]` start Q_MLK = 85.0

`init.start[F_LAB_MLK]` start F_LAB_MLK = 14.090909090909088

`init.start[Xv_BRD]` start Xv_BRD = 16.0

`init.start[Xp_MLK]` start Xp_MLK = 30.0

`init.start[pf_LAB]` start pf_LAB = 1.0

`init.start[D_MLK]` start D_MLK = 48.0

`init.start[Z_MLK]` start Z_MLK = 47.99999999999999

`init.start[Y_BRD]` start Y_BRD = 11.666666666666666

`init.start[pe_BRD]` start pe_BRD = 1.0

`init.lower[X_MLK_BRD]` lower X_MLK_BRD = 1.0e-5

`init.lower[F_LAB_BRD]` lower F_LAB_BRD = 1.0e-5

`init.lower[X_MLK_MLK]` lower X_MLK_MLK = 1.0e-5

`init.lower[pd_MLK]` lower pd_MLK = 1.0e-5

`init.lower[F_CAP_MLK]` lower F_CAP_MLK = 1.0e-5

`init.lower[pz_MLK]` lower pz_MLK = 1.0e-5

`init.lower[pz_BRD]` lower pz_BRD = 1.0e-5

`init.lower[Xg_MLK]` lower Xg_MLK = 1.0e-5

`init.lower[pm_BRD]` lower pm_BRD = 1.0e-5

`init.lower[X_BRD_BRD]` lower X_BRD_BRD = 1.0e-5

`init.lower[Tm_BRD]` lower Tm_BRD = 0.0

`init.lower[pd_BRD]` lower pd_BRD = 1.0e-5

`init.lower[Td]` lower Td = 1.0e-5

`init.lower[M_BRD]` lower M_BRD = 1.0e-5

`init.lower[Tz_BRD]` lower Tz_BRD = 0.0

`init.lower[Sp]` lower Sp = 1.0e-5

`init.lower[X_BRD_MLK]` lower X_BRD_MLK = 1.0e-5

`init.lower[pe_MLK]` lower pe_MLK = 1.0e-5

`init.lower[pq_MLK]` lower pq_MLK = 1.0e-5

`init.lower[Y_MLK]` lower Y_MLK = 1.0e-5

`init.lower[Tz_MLK]` lower Tz_MLK = 0.0

`init.lower[pq_BRD]` lower pq_BRD = 1.0e-5

`init.lower[pf_CAP]` lower pf_CAP = 1.0e-5

`init.lower[RT_BRD]` lower RT_BRD = 1.0e-5

`init.lower[Xg_BRD]` lower Xg_BRD = 1.0e-5

`init.lower[Xv_MLK]` lower Xv_MLK = 1.0e-5

`init.lower[M_MLK]` lower M_MLK = 1.0e-5

`init.lower[E_BRD]` lower E_BRD = 1.0e-5

`init.lower[Xp_BRD]` lower Xp_BRD = 1.0e-5

`init.lower[py_MLK]` lower py_MLK = 1.0e-5

`init.lower[RT_MLK]` lower RT_MLK = 1.0e-5

`init.lower[Z_BRD]` lower Z_BRD = 1.0e-5

`init.lower[E_MLK]` lower E_MLK = 1.0e-5

`init.lower[Tm_MLK]` lower Tm_MLK = 0.0

`init.lower[epsilon]` lower epsilon = 1.0e-5

`init.lower[D_BRD]` lower D_BRD = 1.0e-5

`init.lower[Q_BRD]` lower Q_BRD = 1.0e-5

`init.lower[pm_MLK]` lower pm_MLK = 1.0e-5

`init.lower[F_CAP_BRD]` lower F_CAP_BRD = 1.0e-5

`init.lower[Sg]` lower Sg = 1.0e-5

`init.lower[py_BRD]` lower py_BRD = 1.0e-5

`init.lower[Q_MLK]` lower Q_MLK = 1.0e-5

`init.lower[F_LAB_MLK]` lower F_LAB_MLK = 1.0e-5

`init.lower[Xv_BRD]` lower Xv_BRD = 1.0e-5

`init.lower[Xp_MLK]` lower Xp_MLK = 1.0e-5

`init.lower[pf_LAB]` lower pf_LAB = 1.0e-5

`init.lower[D_MLK]` lower D_MLK = 1.0e-5

`init.lower[Z_MLK]` lower Z_MLK = 1.0e-5

`init.lower[Y_BRD]` lower Y_BRD = 1.0e-5

`init.lower[pe_BRD]` lower pe_BRD = 1.0e-5

`numeraire.numeraire` numeraire fixed
