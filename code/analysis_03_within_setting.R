# Integration-window and paired-parameter reporting within the three largest nursing-unit types.
source('code/helpers.R')
p <- 'output/numbers/'
r<-list();k<-0
for(u in c('Adult ICU','NICU','Adult general ward'))for(g in c('All','U-E','U-F','U-G')) {
 m<-d$unit_type==u&groups[[g]];app<-m&d$integration!='Not applicable'
 k<-k+1;r[[k]]<-data.frame(setting=u,purpose=g,measure='integration',group_n=sum(m),applicable=sum(app),full=sum(app&d$integration=='Full'),partial=sum(app&d$integration=='Partial'),absent=sum(app&d$integration=='Absent'),not_applicable=sum(m)-sum(app),full_percent=pct(sum(app&d$integration=='Full'),sum(app)),dataset_ids=ids(m))
 for(pa in names(pairs)){
  a<-d[[pairs[[pa]][1]]];b<-d[[pairs[[pa]][2]]];app<-m&a!='Not applicable'&b!='Not applicable';full<-app&a=='Full'&b=='Full';abs<-app&(a=='Absent'|b=='Absent')
  k<-k+1;r[[k]]<-data.frame(setting=u,purpose=g,measure=pa,group_n=sum(m),applicable=sum(app),full=sum(full),partial=sum(app)-sum(full)-sum(abs),absent=sum(abs),not_applicable=sum(m)-sum(app),full_percent=pct(sum(full),sum(app)),dataset_ids=ids(m))
 }
}
r<-do.call(rbind,r);stopifnot(all(r$full+r$partial+r$absent==r$applicable),all(r$applicable+r$not_applicable==r$group_n));out(r,paste0(p,'within_setting.csv'));print(r[r$measure=='integration',1:10],row.names=FALSE)
