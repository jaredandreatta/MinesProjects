ps1_data <- read.csv("/Users/jayco/Desktop/EBGN590/Data Memos/Data/rural_atlas_merged.csv")

avg <- mean(ps1_data$PerCapitaInc, na.rm=TRUE)
std_dev <- sd(ps1_data$PerCapitaInc, na.rm=TRUE)
skew <- skewness(ps1_data$PerCapitaInc, na.rm=TRUE)
kurt <- kurtosis(ps1_data$PerCapitaInc, na.rm=TRUE)
size <- length(ps1_data$PerCapitaInc)

plot(ps1_data$UnempRate2013, ps1_data$PerCapitaInc,
ylab="Per Capita Income",
xlab="Unemployment Rate 2013 (in %)",
main="Unemployment Rate in 2013 vs. Per Capita Income")

plot(ps1_data$Metro2013, ps1_data$PerCapitaInc,
xlab="2013 Metro Population",
ylab="Per Capita Income",
main="2013 Metro Population vs. Per Capita Income")

pci_metro <- ps1_data$PerCapitaInc[which(ps1_data$Metro2013==1)]
pci_rural <- ps1_data$PerCapitaInc[which(ps1_data$Metro2013==0)]

metro_mean <- mean(pci_metro, na.rm=TRUE)
metro_std_dev <- sd(pci_metro, na.rm=TRUE)
metro_size <- length(pci_metro)

rural_mean <- mean(pci_rural, na.rm=TRUE)
rural_std_dev <- sd(pci_rural, na.rm=TRUE)
rural_size <- length(pci_rural)

print(metro_mean)
print(metro_std_dev)
print(metro_size)

print(rural_mean)
print(rural_std_dev)
print(rural_size)

