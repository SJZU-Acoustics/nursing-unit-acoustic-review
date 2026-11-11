# Joint reporting of related measurement parameters, for all datasets and by research purpose.
source('code/helpers.R')
p <- 'output/numbers/'
rows<-list();patterns<-list();k<-0;j<-0
for(g in names(groups)) for(pair in names(pairs)) {
 m<-groups[[g]];a<-d[[pairs[[pair]][1]]];b<-d[[pairs[[pair]][2]]];app<-m&a!='Not applicable'&b!='Not applicable';den<-sum(app)
 full<-app&a=='Full'&b=='Full';present<-app&a!='Absent'&b!='Absent';absent<-app&(a=='Absent'|b=='Absent')
 k<-k+1;rows[[k]]<-data.frame(group=g,pair=pair,group_n=sum(m),applicable=den,not_applicable=sum(m)-den,both_full=sum(full),both_at_least_partial=sum(present),at_least_one_absent=sum(absent),both_full_percent=pct(sum(full),den),full_ids=ids(full),absent_ids=ids(absent))
 stopifnot(sum(present)+sum(absent)==den)
 for(sa in c('Full','Partial','Absent','Not applicable')) for(sb in c('Full','Partial','Absent','Not applicable')) {
  mm<-m&a==sa&b==sb;j<-j+1;patterns[[j]]<-data.frame(group=g,pair=pair,status_a=sa,status_b=sb,n=sum(mm),dataset_ids=ids(mm))
 }
}
r<-do.call(rbind,rows);t<-do.call(rbind,patterns)
for(g in names(groups))for(pa in names(pairs))stopifnot(sum(t$n[t$group==g&t$pair==pa])==sum(groups[[g]]))
out(r,paste0(p,'joint_summary.csv'));out(t,paste0(p,'joint_patterns.csv'))
print(r[r$group %in% c('All','U-E','U-F','U-G'),1:9],row.names=FALSE)
