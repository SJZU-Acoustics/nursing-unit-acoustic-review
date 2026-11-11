# Recording mode, clock coverage, documented locations and integration-window reporting by coverage.
source('code/helpers.R')
p <- 'output/numbers/'
mode_labels<-c(C='Continuous recording within sessions',S='Scheduled short or spot samples',E='Event or scenario selected recording',T='Controlled tests without ambient monitoring',U='Acquisition mode unclear')
coverage_labels<-c(F='Full day-night cycle described',W='Day/night windows; full cycle not established',D='Daytime or evening only',N='Overnight only',U='Clock coverage unclear',A='Ambient clock coverage not applicable')
stopifnot(all(codes$mode %in% names(mode_labels)),all(codes$coverage %in% names(coverage_labels)))
codes$mode_label<-unname(mode_labels[codes$mode]);codes$coverage_label<-unname(coverage_labels[codes$coverage])
# Multi-label explicitly documented locations; zero means not explicitly identified, not absent.
codes$patient_area<-grepl('P',codes$space);codes$staff_area<-grepl('S',codes$space);codes$microenvironment<-grepl('X',codes$space)
out(codes,paste0(p,'sampling_coding.csv'))
sg<-c(groups,setNames(lapply(unique(d$unit_type),function(u)d$unit_type==u),paste0('Setting: ',unique(d$unit_type))))
r<-list();k<-0
for(g in names(sg)) for(axis in c('mode_label','coverage_label','patient_area','staff_area','microenvironment','controlled')) {
 vals<-if(axis=='mode_label')unname(mode_labels) else if(axis=='coverage_label')unname(coverage_labels) else if(axis=='controlled')1 else TRUE
 for(v in vals){m<-sg[[g]]&codes[[axis]]==v;k<-k+1;r[[k]]<-data.frame(group=g,axis=axis,category=as.character(v),n=sum(m),denominator=sum(sg[[g]]),percent=pct(sum(m),sum(sg[[g]])),dataset_ids=ids(m))}
}
r<-do.call(rbind,r);out(r,paste0(p,'coverage_summary.csv'))
cross<-as.data.frame(table(mode=codes$mode_label,coverage=codes$coverage_label));stopifnot(sum(cross$Freq)==87);out(cross,paste0(p,'mode_by_coverage.csv'))
print(r[r$group=='All',1:6],row.names=FALSE)
# Sampling duration and integration time are distinct quantities.
rr<-list();j<-0
for(cov in names(coverage_labels)){
 m<-codes$coverage==cov;app<-m&d$integration!='Not applicable';j<-j+1
 rr[[j]]<-data.frame(coverage=coverage_labels[cov],n=sum(m),applicable=sum(app),full=sum(app&d$integration=='Full'),partial=sum(app&d$integration=='Partial'),absent=sum(app&d$integration=='Absent'),not_applicable=sum(m)-sum(app))
}
rr<-do.call(rbind,rr);stopifnot(all(rr$full+rr$partial+rr$absent==rr$applicable));out(rr,paste0(p,'coverage_and_integration.csv'));print(rr,row.names=FALSE)
