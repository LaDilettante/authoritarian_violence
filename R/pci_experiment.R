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
  mutate(whether.north = ifelse(province %in% c_northprovinces, 1, 
                                ifelse(province %in% c_southprovinces, 0, NA))) %>%
  mutate(communication = ifelse(i_4_1=="Yes", 1, ifelse(i_4_1=="No", 0, NA))) %>%
  mutate(representation = ifelse(i_4_2=="Yes", 1, ifelse(i_4_2=="No", 0, NA)))
# ---- Check balance ----

MatchBalance(treat ~ a7_1 + a8_1,data = d_pci)

m_bal_comm <- MatchBalance(treat ~ a4 + a5_1 + a5_2 + a5_3 + a5_4 + a5_5 + 
                a7_1 + a8_1, data=filter(d_pci, !is.na(communication)))$BeforeMatching

with(d_pci, levels)
cbind.data.frame(c(levels(d_pci$a7_1)[-1], levels(d_pci$a8_1)[-1]),
  ldply(m_bal_comm, function(x) data.frame(mean.Tr=x$mean.Tr, mean.Co=x$mean.Co,
                                          p.value=x$p.value)))

mean.Tr mean.Co p.value qqsummary$meandiff / mediandiff maxdiff
# ---- Analyze treatment effect ----

d_exp <- d_pci %>% 
  select(treat, i_4_1, i_4_2, whether.north) %>%
  mutate(communication = ifelse(i_4_1=="Yes", 1, ifelse(i_4_1=="No", 0, NA))) %>%
  mutate(representation = ifelse(i_4_2=="Yes", 1, ifelse(i_4_2=="No", 0, NA)))

# Check balance of the people that responded
MatchBalance(treat ~ a7_1 + a8_1,
             data=na.omit(d_exp[ , c("treat", "communication")]))

summary(d_pci$i_4_1)
table(d_exp$communication)
summary(d_pci$i_4_2)

summary(glm(communication ~ treat, data=d_exp, family="binomial"))
summary(glm(representation ~ treat, data=d_exp, family="binomial"))

# ---- Heterogeneity analysis ----

m_whether.north <- glmer(representation ~ treat + (1 + treat | whether.north), 
                         data=d_exp, family="binomial")
display(m_whether.north)
summary(m_whether.north)

coef(m_whether.north)
fixef(m_whether.north)
ranef(m_whether.north)


VarCorr(m_whether.north)
