# Equations
`production.activity[agricult]`

$$
xd_{i} = ad_{i} \cdot \prod_{lc \in \mathcal{D}_{lc}} {l_{i,lc}}^{alphl_lc,i} \cdot {k_{i}}^{1-sum_lc∈{labor1,labor2,labor3}(alphl_lc,i)}
$$

Domain lc in { labor1, labor2 }
Domain lc in { labor1, labor2, labor3 }

`production.profitmax[agricult,labor1]`

$$
wa_{lc} \cdot wdist_{i,lc} \cdot l_{i,lc} = xd_{i} \cdot pva_{i} \cdot alphl_{lc,i}
$$

`production.profitmax[agricult,labor2]`

$$
wa_{lc} \cdot wdist_{i,lc} \cdot l_{i,lc} = xd_{i} \cdot pva_{i} \cdot alphl_{lc,i}
$$

`production.activity[industry]`

$$
xd_{i} = ad_{i} \cdot \prod_{lc \in \mathcal{D}_{lc}} {l_{i,lc}}^{alphl_lc,i} \cdot {k_{i}}^{1-sum_lc∈{labor1,labor2,labor3}(alphl_lc,i)}
$$

Domain lc in { labor2 }
Domain lc in { labor1, labor2, labor3 }

`production.profitmax[industry,labor2]`

$$
wa_{lc} \cdot wdist_{i,lc} \cdot l_{i,lc} = xd_{i} \cdot pva_{i} \cdot alphl_{lc,i}
$$

`production.activity[services]`

$$
xd_{i} = ad_{i} \cdot \prod_{lc \in \mathcal{D}_{lc}} {l_{i,lc}}^{alphl_lc,i} \cdot {k_{i}}^{1-sum_lc∈{labor1,labor2,labor3}(alphl_lc,i)}
$$

Domain lc in { labor2, labor3 }
Domain lc in { labor1, labor2, labor3 }

`production.profitmax[services,labor2]`

$$
wa_{lc} \cdot wdist_{i,lc} \cdot l_{i,lc} = xd_{i} \cdot pva_{i} \cdot alphl_{lc,i}
$$

`production.profitmax[services,labor3]`

$$
wa_{lc} \cdot wdist_{i,lc} \cdot l_{i,lc} = xd_{i} \cdot pva_{i} \cdot alphl_{lc,i}
$$

`labor_market.lmequil[labor1]`

$$
\sum_{i \in \mathcal{D}_{i}} l_{i,lc} = ls_{lc}
$$

Domain i in { agricult, industry, services }

`labor_market.lmequil[labor2]`

$$
\sum_{i \in \mathcal{D}_{i}} l_{i,lc} = ls_{lc}
$$

Domain i in { agricult, industry, services }

`labor_market.lmequil[labor3]`

$$
\sum_{i \in \mathcal{D}_{i}} l_{i,lc} = ls_{lc}
$$

Domain i in { agricult, industry, services }

`government_demand.gdeq[agricult]`

$$
gd_{i} = gles_{i} \cdot gdtot
$$

`government_demand.gdeq[industry]`

$$
gd_{i} = gles_{i} \cdot gdtot
$$

`government_demand.gdeq[services]`

$$
gd_{i} = gles_{i} \cdot gdtot
$$

`government_revenue.tariffdef`

$$
tariff = \sum_{i \in \mathcal{D}_{i}} tm_{i} \cdot m_{i} \cdot pwm_{i} \cdot er
$$

Domain i in { agricult, industry, services }

`government_revenue.indtaxdef`

$$
indtax = \sum_{i \in \mathcal{D}_{i}} itax_{i} \cdot px_{i} \cdot xd_{i}
$$

Domain i in { agricult, industry, services }

`government_revenue.netsubdef`

$$
netsub = \sum_{i \in \mathcal{D}_{i}} te_{i} \cdot e_{i} \cdot pwe_{i} \cdot er
$$

Domain i in { agricult, industry, services }

`government_revenue.greq`

$$
gr = tariff - netsub + indtax + tothhtax
$$

`government_revenue.gruse`

$$
gr = \sum_{i \in \mathcal{D}_{i}} p_{i} \cdot gd_{i} + govsav
$$

Domain i in { agricult, industry, services }

`savings.depreq`

$$
deprecia = \sum_{i \in \mathcal{D}_{i}} depr_{i} \cdot pk_{i} \cdot k_{i}
$$

Domain i in { agricult, industry, services }

`savings.totsav`

$$
savings = hhsav + govsav + deprecia + fsav \cdot er
$$

`savings.prodinv[agricult]`

$$
pk_{i} \cdot dk_{i} = kio_{i} \cdot invest - kio_{i} \cdot \sum_{j \in \mathcal{D}_{j}} dst_{j} \cdot p_{j}
$$

Domain j in { agricult, industry, services }

`savings.prodinv[industry]`

$$
pk_{i} \cdot dk_{i} = kio_{i} \cdot invest - kio_{i} \cdot \sum_{j \in \mathcal{D}_{j}} dst_{j} \cdot p_{j}
$$

Domain j in { agricult, industry, services }

`savings.prodinv[services]`

$$
pk_{i} \cdot dk_{i} = kio_{i} \cdot invest - kio_{i} \cdot \sum_{j \in \mathcal{D}_{j}} dst_{j} \cdot p_{j}
$$

Domain j in { agricult, industry, services }

`savings.ieq[agricult]`

$$
id_{i} = \sum_{j \in \mathcal{D}_{j}} imat_{i,j} \cdot dk_{j}
$$

Domain j in { agricult, industry, services }

`savings.ieq[industry]`

$$
id_{i} = \sum_{j \in \mathcal{D}_{j}} imat_{i,j} \cdot dk_{j}
$$

Domain j in { agricult, industry, services }

`savings.ieq[services]`

$$
id_{i} = \sum_{j \in \mathcal{D}_{j}} imat_{i,j} \cdot dk_{j}
$$

Domain j in { agricult, industry, services }

`household_demand.cdeq[agricult]`

$$
p_{i} \cdot cd_{i} = \sum_{hh \in \mathcal{D}_{hh}} cles_{i,hh} \cdot (1 - mps_{hh}) \cdot yh_{hh} \cdot (1 - htax_{hh})
$$

Domain hh in { lab-hh, cap-hh }

`household_demand.cdeq[industry]`

$$
p_{i} \cdot cd_{i} = \sum_{hh \in \mathcal{D}_{hh}} cles_{i,hh} \cdot (1 - mps_{hh}) \cdot yh_{hh} \cdot (1 - htax_{hh})
$$

Domain hh in { lab-hh, cap-hh }

`household_demand.cdeq[services]`

$$
p_{i} \cdot cd_{i} = \sum_{hh \in \mathcal{D}_{hh}} cles_{i,hh} \cdot (1 - mps_{hh}) \cdot yh_{hh} \cdot (1 - htax_{hh})
$$

Domain hh in { lab-hh, cap-hh }

`household_demand.hhsaveq`

$$
hhsav = \sum_{hh \in \mathcal{D}_{hh}} mps_{hh} \cdot yh_{hh} \cdot (1 - htax_{hh})
$$

Domain hh in { lab-hh, cap-hh }

`household_income.labory[lab-hh]`

$$
yh_{\text{lab-hh}} = \sum_{lc \in \mathcal{D}_{lc}} wa_{lc} \cdot ls_{lc} + remit \cdot er
$$

Domain lc in { labor1, labor2, labor3 }

`household_income.capitaly[cap-hh]`

$$
yh_{\text{cap-hh}} = \sum_{i \in \mathcal{D}_{i}} pva_{i} \cdot xd_{i} - deprecia - \sum_{lc \in \mathcal{D}_{lc}} wa_{lc} \cdot ls_{lc} + fbor \cdot er + ypr
$$

Domain i in { agricult, industry, services }
Domain lc in { labor1, labor2, labor3 }

`household_tax.hhtaxdef`

$$
tothhtax = \sum_{hh \in \mathcal{D}_{hh}} htax_{hh} \cdot yh_{hh}
$$

Domain hh in { lab-hh, cap-hh }

`household_sum.gdp`

$$
y = \sum_{hh \in \mathcal{D}_{hh}} yh_{hh}
$$

Domain hh in { lab-hh, cap-hh }

`trade_price.pmdef[agricult]`

$$
pm_{i} = pwm_{i} \cdot er \cdot (1 + tm_{i} + pr)
$$

`trade_price.pedef[agricult]`

$$
pe_{i} = pwe_{i} \cdot (1 + te_{i}) \cdot er
$$

`trade_price.pmdef[industry]`

$$
pm_{i} = pwm_{i} \cdot er \cdot (1 + tm_{i} + pr)
$$

`trade_price.pedef[industry]`

$$
pe_{i} = pwe_{i} \cdot (1 + te_{i}) \cdot er
$$

`trade_price.pmdef[services]`

$$
pm_{i} = pwm_{i} \cdot er \cdot (1 + tm_{i} + pr)
$$

`trade_price.pedef[services]`

$$
pe_{i} = pwe_{i} \cdot (1 + te_{i}) \cdot er
$$

`absorption.absorption[agricult]`

$$
p_{i} \cdot x_{i} = pd_{i} \cdot xxd_{i} + pm_{i} \cdot m_{i}
$$

`absorption.sales[agricult]`

$$
px_{i} \cdot xd_{i} = pd_{i} \cdot xxd_{i} + pe_{i} \cdot e_{i}
$$

`absorption.absorption[industry]`

$$
p_{i} \cdot x_{i} = pd_{i} \cdot xxd_{i} + pm_{i} \cdot m_{i}
$$

`absorption.sales[industry]`

$$
px_{i} \cdot xd_{i} = pd_{i} \cdot xxd_{i} + pe_{i} \cdot e_{i}
$$

`absorption.absorption[services]`

$$
p_{i} \cdot x_{i} = pd_{i} \cdot xxd_{i} + pm_{i} \cdot m_{i}
$$

`absorption.sales[services]`

$$
px_{i} \cdot xd_{i} = pd_{i} \cdot xxd_{i} + pe_{i} \cdot e_{i}
$$

`activity_price.actp[agricult]`

$$
px_{i} \cdot (1 - itax_{i}) = pva_{i} + \sum_{j \in \mathcal{D}_{j}} io_{j,i} \cdot p_{j}
$$

Domain j in { agricult, industry, services }

`activity_price.inteq[agricult]`

$$
int_{i} = \sum_{j \in \mathcal{D}_{j}} io_{i,j} \cdot xd_{j}
$$

Domain j in { agricult, industry, services }

`activity_price.actp[industry]`

$$
px_{i} \cdot (1 - itax_{i}) = pva_{i} + \sum_{j \in \mathcal{D}_{j}} io_{j,i} \cdot p_{j}
$$

Domain j in { agricult, industry, services }

`activity_price.inteq[industry]`

$$
int_{i} = \sum_{j \in \mathcal{D}_{j}} io_{i,j} \cdot xd_{j}
$$

Domain j in { agricult, industry, services }

`activity_price.actp[services]`

$$
px_{i} \cdot (1 - itax_{i}) = pva_{i} + \sum_{j \in \mathcal{D}_{j}} io_{j,i} \cdot p_{j}
$$

Domain j in { agricult, industry, services }

`activity_price.inteq[services]`

$$
int_{i} = \sum_{j \in \mathcal{D}_{j}} io_{i,j} \cdot xd_{j}
$$

Domain j in { agricult, industry, services }

`capital_price.pkdef[agricult]`

$$
pk_{i} = \sum_{j \in \mathcal{D}_{j}} p_{j} \cdot imat_{j,i}
$$

Domain j in { agricult, industry, services }

`capital_price.pkdef[industry]`

$$
pk_{i} = \sum_{j \in \mathcal{D}_{j}} p_{j} \cdot imat_{j,i}
$$

Domain j in { agricult, industry, services }

`capital_price.pkdef[services]`

$$
pk_{i} = \sum_{j \in \mathcal{D}_{j}} p_{j} \cdot imat_{j,i}
$$

Domain j in { agricult, industry, services }

`premium_income.premium`

$$
ypr = \sum_{i \in \mathcal{D}_{i}} pwm_{i} \cdot m_{i} \cdot er \cdot pr
$$

Domain i in { agricult, industry, services }

`price_index.pindexdef`

$$
pindex = \sum_{i \in \mathcal{D}_{i}} p_{i} \cdot pwts_{i}
$$

Domain i in { agricult, industry, services }

`bop.caeq`

$$
\sum_{i \in \mathcal{D}_{i}} pwm_{i} \cdot M_{i} = \sum_{i \in \mathcal{D}_{i}} pwe_{i} \cdot E_{i} + fsav + remit + fbor
$$

Domain i in { agricult, industry, services }
Domain i in { agricult, industry, services }

`cet.cet[agricult]`

$$
xd_{i} = at_{i} \cdot (gamma_{i} \cdot {e_{i}}^{rhot_i} + (1 - gamma_{i}) \cdot {xxd_{i}}^{rhot_i})^{1/(rhot_i)}
$$

`cet.esupply[agricult]`

$$
e_{i} / xxd_{i} = (pe_{i} \cdot (1 - gamma_{i}) / pd_{i} \cdot gamma_{i})^{1/(rhot_i-1)}
$$

`cet.cet[industry]`

$$
xd_{i} = at_{i} \cdot (gamma_{i} \cdot {e_{i}}^{rhot_i} + (1 - gamma_{i}) \cdot {xxd_{i}}^{rhot_i})^{1/(rhot_i)}
$$

`cet.esupply[industry]`

$$
e_{i} / xxd_{i} = (pe_{i} \cdot (1 - gamma_{i}) / pd_{i} \cdot gamma_{i})^{1/(rhot_i-1)}
$$

`cet.cet[services]`

$$
xd_{i} = at_{i} \cdot (gamma_{i} \cdot {e_{i}}^{rhot_i} + (1 - gamma_{i}) \cdot {xxd_{i}}^{rhot_i})^{1/(rhot_i)}
$$

`cet.esupply[services]`

$$
e_{i} / xxd_{i} = (pe_{i} \cdot (1 - gamma_{i}) / pd_{i} \cdot gamma_{i})^{1/(rhot_i-1)}
$$

`armington.armington[agricult]`

$$
x_{i} = ac_{i} \cdot (delta_{i} \cdot {m_{i}}^{-rhoc_i} + (1 - delta_{i}) \cdot {xxd_{i}}^{-rhoc_i})^{-1/rhoc_i}
$$

`armington.costmin[agricult]`

$$
m_{i} / xxd_{i} = (pd_{i} \cdot delta_{i} / pm_{i} \cdot (1 - delta_{i}))^{1/(1+rhoc_i)}
$$

`armington.armington[industry]`

$$
x_{i} = ac_{i} \cdot (delta_{i} \cdot {m_{i}}^{-rhoc_i} + (1 - delta_{i}) \cdot {xxd_{i}}^{-rhoc_i})^{-1/rhoc_i}
$$

`armington.costmin[industry]`

$$
m_{i} / xxd_{i} = (pd_{i} \cdot delta_{i} / pm_{i} \cdot (1 - delta_{i}))^{1/(1+rhoc_i)}
$$

`armington.armington[services]`

$$
x_{i} = ac_{i} \cdot (delta_{i} \cdot {m_{i}}^{-rhoc_i} + (1 - delta_{i}) \cdot {xxd_{i}}^{-rhoc_i})^{-1/rhoc_i}
$$

`armington.costmin[services]`

$$
m_{i} / xxd_{i} = (pd_{i} \cdot delta_{i} / pm_{i} \cdot (1 - delta_{i}))^{1/(1+rhoc_i)}
$$

`inventory.dsteq[agricult]`

$$
dst_{i} = dstr_{i} \cdot xd_{i}
$$

`inventory.dsteq[industry]`

$$
dst_{i} = dstr_{i} \cdot xd_{i}
$$

`inventory.dsteq[services]`

$$
dst_{i} = dstr_{i} \cdot xd_{i}
$$

`market.equil[agricult]`

$$
x_{i} = int_{i} + cd_{i} + gd_{i} + id_{i} + dst_{i}
$$

`market.equil[industry]`

$$
x_{i} = int_{i} + cd_{i} + gd_{i} + id_{i} + dst_{i}
$$

`market.equil[services]`

$$
x_{i} = int_{i} + cd_{i} + gd_{i} + id_{i} + dst_{i}
$$

`objective.objective`

$$
omega = \prod_{i \in \mathcal{D}_{i}} {cd_{i}}^{alpha_i}
$$

Domain i in { agricult, industry, services }

`init.start[er]` start er = 1.0

`init.start[x_industry]` start x_industry = 930.3509

`init.start[gr]` start gr = 194.0449

`init.start[l_services_labor1]` start l_services_labor1 = 0.0

`init.start[yh_lab-hh]` start yh_lab-hh = 548.7478

`init.start[dk_services]` start dk_services = 92.3023

`init.start[wa_labor1]` start wa_labor1 = 0.074

`init.start[id_agricult]` start id_agricult = 0.0

`init.start[m_agricult]` start m_agricult = 69.9406

`init.start[dk_agricult]` start dk_agricult = 20.6884

`init.start[wa_labor3]` start wa_labor3 = 0.152

`init.start[pm_industry]` start pm_industry = 1.0

`init.start[k_agricult]` start k_agricult = 657.5754

`init.start[pe_industry]` start pe_industry = 1.0

`init.start[invest]` start invest = 159.1419

`init.start[indtax]` start indtax = 65.2754

`init.start[l_agricult_labor2]` start l_agricult_labor2 = 442.643

`init.start[tm_agricult]` start tm_agricult = 0.1

`init.start[y]` start y = 1123.5941

`init.start[fbor]` start fbor = 58.759

`init.start[pe_agricult]` start pe_agricult = 1.0

`init.start[govsav]` start govsav = 52.893

`init.start[l_agricult_labor1]` start l_agricult_labor1 = 2515.9

`init.start[xd_services]` start xd_services = 515.4296

`init.start[l_services_labor2]` start l_services_labor2 = 355.568

`init.start[ls_labor1]` start ls_labor1 = 2515.9

`init.start[xd_industry]` start xd_industry = 840.05

`init.start[p_industry]` start p_industry = 1.0

`init.start[e_agricult]` start e_agricult = 15.6639

`init.start[l_industry_labor3]` start l_industry_labor3 = 0.0

`init.start[fsav]` start fsav = 39.1744

`init.start[cd_services]` start cd_services = 202.0416

`init.start[px_agricult]` start px_agricult = 1.0

`init.start[deprecia]` start deprecia = 0.0

`init.start[pk_industry]` start pk_industry = 1.0

`init.start[pva_agricult]` start pva_agricult = 0.737

`init.start[mps_cap-hh]` start mps_cap-hh = 0.06

`init.start[netsub]` start netsub = 0.0

`init.start[l_services_labor3]` start l_services_labor3 = 948.1

`init.start[pd_industry]` start pd_industry = 1.0

`init.start[wa_labor2]` start wa_labor2 = 0.14

`init.start[k_industry]` start k_industry = 338.7076

`init.start[p_services]` start p_services = 1.0

`init.start[mps_lab-hh]` start mps_lab-hh = 0.06

`init.start[int_services]` start int_services = 156.2598

`init.start[gd_services]` start gd_services = 128.4482

`init.start[int_agricult]` start int_agricult = 256.645

`init.start[dst_agricult]` start dst_agricult = 0.0

`init.start[tm_services]` start tm_services = 0.08084

`init.start[l_agricult_labor3]` start l_agricult_labor3 = 0.0

`init.start[int_industry]` start int_industry = 464.1656

`init.start[tothhtax]` start tothhtax = 100.1122

`init.start[tariff]` start tariff = 28.6572

`init.start[dst_industry]` start dst_industry = 0.0

`init.start[id_industry]` start id_industry = 148.4488

`init.start[x_services]` start x_services = 497.4428

`init.start[id_services]` start id_services = 10.6931

`init.start[p_agricult]` start p_agricult = 1.0

`init.start[savings]` start savings = 159.1419

`init.start[px_services]` start px_services = 1.0

`init.start[gd_agricult]` start gd_agricult = 2.823

`init.start[ypr]` start ypr = 0.0

`init.start[px_industry]` start px_industry = 1.0

`init.start[xxd_industry]` start xxd_industry = 812.2222

`init.start[xd_agricult]` start xd_agricult = 657.3677

`init.start[ls_labor2]` start ls_labor2 = 1565.987

`init.start[pe_services]` start pe_services = 1.0

`init.start[pindex]` start pindex = 1.0

`init.start[pk_agricult]` start pk_agricult = 1.0

`init.start[e_services]` start e_services = 23.3988

`init.start[pm_services]` start pm_services = 1.0

`init.start[cd_agricult]` start cd_agricult = 452.1765

`init.start[pm_agricult]` start pm_agricult = 1.0

`init.start[gd_industry]` start gd_industry = 9.8806

`init.start[gdtot]` start gdtot = 141.1519

`init.start[pr]` start pr = 0.0

`init.start[e_industry]` start e_industry = 27.8278

`init.start[k_services]` start k_services = 1548.5192

`init.start[ls_labor3]` start ls_labor3 = 948.1

`init.start[tm_industry]` start tm_industry = 0.22751

`init.start[pd_services]` start pd_services = 1.0

`init.start[l_industry_labor1]` start l_industry_labor1 = 0.0

`init.start[pk_services]` start pk_services = 1.0

`init.start[m_industry]` start m_industry = 118.1287

`init.start[xxd_services]` start xxd_services = 492.0307

`init.start[m_services]` start m_services = 5.412

`init.start[l_industry_labor2]` start l_industry_labor2 = 767.776

`init.start[x_agricult]` start x_agricult = 711.6443

`init.start[dk_industry]` start dk_industry = 46.1511

`init.start[pd_agricult]` start pd_agricult = 1.0

`init.start[dst_services]` start dst_services = 0.0

`init.start[yh_cap-hh]` start yh_cap-hh = 574.8463

`init.start[xxd_agricult]` start xxd_agricult = 641.7037

`init.start[hhsav]` start hhsav = 61.4089

`init.start[remit]` start remit = 0.0

`init.start[pva_services]` start pva_services = 0.6625

`init.start[pva_industry]` start pva_industry = 0.2911

`init.start[cd_industry]` start cd_industry = 307.8561

`init.lower[l_agricult_labor1]` lower l_agricult_labor1 = 0.01

`init.lower[p_industry]` lower p_industry = 0.01

`init.lower[xd_industry]` lower xd_industry = 0.01

`init.lower[l_services_labor2]` lower l_services_labor2 = 0.01

`init.lower[int_industry]` lower int_industry = 0.01

`init.lower[x_industry]` lower x_industry = 0.01

`init.lower[pm_agricult]` lower pm_agricult = 0.01

`init.lower[e_agricult]` lower e_agricult = 0.01

`init.lower[px_agricult]` lower px_agricult = 0.01

`init.lower[e_industry]` lower e_industry = 0.01

`init.lower[wa_labor1]` lower wa_labor1 = 0.01

`init.lower[pk_industry]` lower pk_industry = 0.01

`init.lower[x_services]` lower x_services = 0.01

`init.lower[m_agricult]` lower m_agricult = 0.01

`init.lower[pd_services]` lower pd_services = 0.01

`init.lower[wa_labor3]` lower wa_labor3 = 0.01

`init.lower[p_agricult]` lower p_agricult = 0.01

`init.lower[pd_industry]` lower pd_industry = 0.01

`init.lower[pk_services]` lower pk_services = 0.01

`init.lower[pm_industry]` lower pm_industry = 0.01

`init.lower[m_industry]` lower m_industry = 0.01

`init.lower[px_services]` lower px_services = 0.01

`init.lower[m_services]` lower m_services = 0.01

`init.lower[xxd_services]` lower xxd_services = 0.01

`init.lower[wa_labor2]` lower wa_labor2 = 0.01

`init.lower[l_industry_labor2]` lower l_industry_labor2 = 0.01

`init.lower[x_agricult]` lower x_agricult = 0.01

`init.lower[l_services_labor3]` lower l_services_labor3 = 0.01

`init.lower[pd_agricult]` lower pd_agricult = 0.01

`init.lower[p_services]` lower p_services = 0.01

`init.lower[px_industry]` lower px_industry = 0.01

`init.lower[xxd_industry]` lower xxd_industry = 0.01

`init.lower[xd_agricult]` lower xd_agricult = 0.01

`init.lower[xxd_agricult]` lower xxd_agricult = 0.01

`init.lower[l_agricult_labor2]` lower l_agricult_labor2 = 0.01

`init.lower[int_services]` lower int_services = 0.01

`init.lower[y]` lower y = 0.01

`init.lower[pk_agricult]` lower pk_agricult = 0.01

`init.lower[pm_services]` lower pm_services = 0.01

`init.lower[int_agricult]` lower int_agricult = 0.01

`init.lower[xd_services]` lower xd_services = 0.01

`init.lower[e_services]` lower e_services = 0.01

`init.fixed[ls_labor1]` fixed ls_labor1 = 2515.9

`init.fixed[er]` fixed er = 1.0

`init.fixed[l_agricult_labor3]` fixed l_agricult_labor3 = 0.0

`init.fixed[gdtot]` fixed gdtot = 141.1519

`init.fixed[l_industry_labor3]` fixed l_industry_labor3 = 0.0

`init.fixed[fsav]` fixed fsav = 39.1744

`init.fixed[l_services_labor1]` fixed l_services_labor1 = 0.0

`init.fixed[k_services]` fixed k_services = 1548.5192

`init.fixed[ls_labor3]` fixed ls_labor3 = 948.1

`init.fixed[tm_industry]` fixed tm_industry = 0.22751

`init.fixed[mps_cap-hh]` fixed mps_cap-hh = 0.06

`init.fixed[l_industry_labor1]` fixed l_industry_labor1 = 0.0

`init.fixed[k_agricult]` fixed k_agricult = 657.5754

`init.fixed[k_industry]` fixed k_industry = 338.7076

`init.fixed[mps_lab-hh]` fixed mps_lab-hh = 0.06

`init.fixed[remit]` fixed remit = 0.0

`init.fixed[ls_labor2]` fixed ls_labor2 = 1565.987

`init.fixed[tm_agricult]` fixed tm_agricult = 0.1

`init.fixed[pindex]` fixed pindex = 1.0

`init.fixed[fbor]` fixed fbor = 58.759

`init.fixed[tm_services]` fixed tm_services = 0.08084
