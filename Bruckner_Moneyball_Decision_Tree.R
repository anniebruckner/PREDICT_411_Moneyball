# Moneyball Decision Tree
# Reference: http://www.rdatamining.com/examples/decision-tree

install.packages("party")
library(party)

# Read in file.
moneyball <- read.csv(file.path("/Users/annie/Desktop/Northwestern/PREDICT_411/SASUniversityEdition/myfolders/PREDICT_411/Moneyball","moneyball.csv"),sep=",")

str(moneyball)

# Check summary statistics.
summary(moneyball)

# Create decision tree.
moneyball_ctree <- ctree(TARGET_WINS ~ 
                      TEAM_BATTING_H + 
                      TEAM_BATTING_2B + 
                      TEAM_BATTING_3B +
                      TEAM_BATTING_HR +
                      TEAM_BATTING_BB +
                      TEAM_BATTING_SO +
                      TEAM_BASERUN_SB +
                      TEAM_BASERUN_CS +
                      TEAM_BATTING_HBP +
                      TEAM_PITCHING_H +
                      TEAM_PITCHING_HR +
                      TEAM_PITCHING_BB +
                      TEAM_PITCHING_SO +
                      TEAM_FIELDING_E +
                      TEAM_FIELDING_DP, data = moneyball)

print(moneyball_ctree)

# Plot decision tree.
plot(moneyball_ctree)

plot(moneyball_ctree, type="simple")

# Export tree to png.
png("moneyball_ctree.png", res=100, height=2500, width=5000) 
plot(moneyball_ctree, type="simple") 
dev.off()