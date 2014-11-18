# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("foreign", "Matching", "lme4", "plyr", "dplyr")
f_install_and_load(packs)

# ---- Constants ----
c_northprovinces <- c("Ha Giang", "Cao Bang", "Lai Chau", "Lao Cai", "Yen Bai", 
                      "Tuyen Quang", "Bac Kan", "Thai Nguyen", "Lang Son",
                      "Son La", "Phu Tho", "Vinh Phuc", "Ha Noi", "Bac Ninh", 
                      "Bac Giang", "Quang Ninh", "Hai Phong", "Hai Duong", "Ha Nam", 
                      "Nam Dinh", "Thai Binh", "Ninh Binh")
c_southprovinces <- c("Lam Dong", "Ninh Thuan", "Binh Thuan", "Tay Ninh", "Binh Phuoc",
                      "Binh Duong", "TP HCM", "Dong Nai", "BRVT", "Long An", "Dong Thap",
                      "Tien Giang", "Ben Tre", "Tra Vinh", "Vinh Long", "An Giang", "Can Tho",
                      "Soc Trang", "Bac Lieu", "Ca Mau", "Kien Giang")

# ---- Load data ----

d_pci <- read.dta("./data/private/PCI2014_DDI_cleanJ.dta")
d_lab <- f_stata_to_df(d_pci)

d_pci <- d_pci %>% 
  mutate(treat = ifelse(form=="B", 1, 0)) %>%
  mutate(whether.north = as.factor(ifelse(province %in% c_northprovinces, 1, 
                                ifelse(province %in% c_southprovinces, 0, NA)))) %>%
  mutate(communication = ifelse(i_4_1=="Yes", 1, ifelse(i_4_1=="No", 0, NA))) %>%
  mutate(representation = ifelse(i_4_2=="Yes", 1, ifelse(i_4_2=="No", 0, NA))) %>%
  mutate(responded.comm = ifelse(!is.na(communication), 1, 0)) %>%
  mutate(responded.rep = ifelse(!is.na(representation), 1, 0))
           

# ---- Check balance ----

c_balance_vars <- c("a4", "a5_1", "a5_2", "a5_3", "a5_4", "a5_5", "a7_1", "a8_1",
                    "a13_1", "a13_2", "a13_3", "a14_1", "a14_2", "a14_3", "a14_4", 
                    "a14_5", "a14_6", "whether.north")
fm_balance <- as.formula(paste("treat ~", paste(c_balance_vars, collapse=" + ")))

# Balance among those responded to communication question
m_bal_comm <- MatchBalance(fm_balance,
                data=filter(d_pci, !is.na(communication)))$BeforeMatching
f_create_balancetable(df=d_pci, balance_vars=c_balance_vars, bal_result=m_bal_comm)

# Balance among those responded to the representation question
m_bal_rep <- MatchBalance(fm_balance,
                data=filter(d_pci, !is.na(representation)))$BeforeMatching
f_create_balancetable(df=d_pci, balance_vars=c_balance_vars, bal_result=m_bal_rep)

# Balance between those responded and not responded
fm_balance_rescomm <- as.formula(paste("responded.comm ~", paste(c_balance_vars, collapse=" + ")))
fm_balance_resrep <- as.formula(paste("responded.rep ~", paste(c_balance_vars, collapse=" + ")))

m_bal_rescomm <- MatchBalance(fm_balance_rescomm, data=d_pci)$BeforeMatching
f_create_balancetable(d_pci, c_balance_vars, m_bal_rescomm)

m_bal_resrep <- MatchBalance(fm_balance_resrep, data=d_pci)$BeforeMatching
f_create_balancetable(d_pci, c_balance_vars, m_bal_resrep)

# ---- Analyze treatment effect ----

summary(glm(communication ~ treat, data=d_pci, family="binomial"))

summary(glm(communication ~ treat + a13_2 + a13_2:treat, data=d_pci, family="binomial"))
summary(glm(communication ~ treat + a13_2 + a13_2:treat + a7_3, data=d_pci, family="binomial")) # Central SOE equitized

summary(glm(a13_2 ~ a7_3, data = d_pci, family="binomial"))

with(d_pci, prop.table(table(a7_3, a13_2), margin=2))\
with(d_pci, prop.table(table(a8_3, a13_2), margin=2))

m <- matrix(1:4, 2)
margin.table(m, 1)
margin.table(m, 2)

summary(glm(communication ~ treat + a14_5 + a14_5:treat, data=d_pci, family="binomial"))
summary(glm(communication ~ treat + a14_6 + a14_6:treat, data=d_pci, family="binomial"))
summary(glm(communication ~ treat + whether.north + whether.north:treat, data=d_pci, family="binomial"))

summary(glm(representation ~ treat, data=d_pci, family="binomial"))
summary(glm(representation ~ treat + whether.north + treat:whether.north, data=d_pci, family="binomial"))

# ---- Heterogeneity analysis ----

m_whether.north <- glmer(representation ~ treat + (1 + treat | whether.north), 
                         data=d_exp, family="binomial")
display(m_whether.north)
summary(m_whether.north)

coef(m_whether.north)
fixef(m_whether.north)
ranef(m_whether.north)


VarCorr(m_whether.north)
