# ---- Set up workspace ----
rm(list=ls())
# Load external functions
source("./R/functions.R")
# Load packages
packs <- c("arm", "foreign", "snow", "Matching", "xtable", "stargazer", "plyr", "dplyr")
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
d_distance <- read.csv("./data/public/distance_from_hanoi.csv")

d_pci <- d_pci %>% 
  mutate(treat = ifelse(form=="B", 1, 0)) %>%
  mutate(whether.north = as.factor(ifelse(province %in% c_northprovinces, 1, 
                                          ifelse(province %in% c_southprovinces, 0, NA)))) %>%
  mutate(communication = ifelse(i_4_1=="Yes", 1, ifelse(i_4_1=="No", 0, NA))) %>%
  mutate(representation = ifelse(i_4_2=="Yes", 1, ifelse(i_4_2=="No", 0, NA))) %>%
  mutate(responded.comm = ifelse(!is.na(communication), 1, 0)) %>%
  mutate(responded.rep = ifelse(!is.na(representation), 1, 0)) %>%
  inner_join(d_distance, by=c("province")) %>%
  rename(distance.from.hn = distance) %>%
  mutate(province = as.factor(province))

# ---- Constant ----
c_rownames <- c("Limited Liability", "Joint Stock", "Partnership", "Other form of ownership",
              "Manufacturing", "Construction", "Service", "Agriculture", "Mining",
              "Revenue (0.5-1 billion VND)", "Revenue (1-5 billion VND)", "Revenue (5-10 billion VND)",
              "Revenue (10-50 billion VND)", "Revenue (50-200 billion VND)",
              "Revenue (200-500 billion VND)", "Revenue (above 500 billion VND)",
              "Size (5-9 people)", "Size (10-49 people)", "Size (50-199 people)",
              "Size (200-299 people)", "Size (300-499 people)", "Size (500-1000 people)",
              "Size (more than 1000 people)",
              "Main customer (State)", "Main customer (Private)", "Main customer (Foreign in VN)",
              "Main customer (Foreign, direct)", "Main customer (Foreign, indirect)",
              "Equitized local state-owned enterprise",
              "Equitized central state-owned enterprise", 
              "Firm with some state-owned equities",
              "Firm that was formerly household business",
              "Firm with shares listed",
              "Firm owner graduated from university",
              "Firm owner with MBA",
              "Firm owner was a leader of a State agency",
              "Firm owner was a military officer",
              "Firm owner was a manager of SOE",
              "Firm owner was an employee at SOE")

# ---- Check balance ----


c_balance_vars <- c("a4", "a5_1", "a5_2", "a5_3", "a5_4", "a5_5", "a7_1", "a8_1", "a11",
                    "a13_1", "a13_2", "a13_3", "a13_4", "a13_5", "a14_1", "a14_2", "a14_3", "a14_4", 
                    "a14_5", "a14_6")
fm_balance <- as.formula(paste("treat ~", paste(c_balance_vars, collapse=" + ")))

# Balance among those responded to communication question
m_bal_comm <- MatchBalance(fm_balance,
                           data=filter(d_pci, !is.na(communication)))$BeforeMatching

tmp <- f_create_balancetable(df=d_pci, balance_vars=c_balance_vars, bal_result=m_bal_comm) %>%
  select(`Mean treated`=mean.Tr, `Mean control`=mean.Co, `p-value`=p.value, ` `=stars)
rownames(tmp) <- c_rownames
# colnames(tmp) <- c("Covariate", "Mean treated", "Mean control", "p-value")
t_comm <- xtable(tmp)
digits(t_comm) <- 2
print(t_comm)

fm_balance_rescomm <- as.formula(paste("responded.comm ~", paste(c_balance_vars, collapse=" + ")))
m_bal_rescomm <- MatchBalance(fm_balance_rescomm, data=d_pci)$BeforeMatching
tmp <- f_create_balancetable(df=d_pci, balance_vars=c_balance_vars, bal_result=m_bal_rescomm) %>%
  select(`Mean treated`=mean.Tr, `Mean control`=mean.Co, `p-value`=p.value, ` `=stars)
rownames(tmp) <- c_rownames
t_comm <- xtable(tmp)
digits(t_comm) <- 2
print(t_comm)

m1 <- glm(communication ~ treat, data=d_pci, family="binomial")
stargazer(m1, title="Treatment effect in Survey experiment", label="tab:survey_result",
          covariate.labels=c("Treatment prompt"),
          dep.var.labels=c("Contacting the National Assembly is effective"))
summary(glm(communication ~ treat, data=d_pci, family="binomial"))
summary(glm(communication ~ treat + whether.north + treat:whether.north, data=d_pci, family="binomial"))
