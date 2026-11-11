# Independent recount of the joint-reporting, within-setting and sampling tables,
# and a check of the headline counts stated in the paper. Stops on the first mismatch.
source('code/helpers.R')
a<-read.csv('output/numbers/joint_summary.csv',check.names=FALSE)
t<-read.csv('output/numbers/joint_patterns.csv',check.names=FALSE)
v<-read.csv('output/numbers/within_setting.csv',check.names=FALSE)
checks<-list();check<-function(name,condition){stopifnot(condition);checks[[length(checks)+1]]<<-data.frame(check=name,passed=condition)}
check('87 unique dataset records with sampling codes',nrow(d)==87&&nrow(codes)==87)
for(i in seq_len(nrow(a))){
 x<-a[i,];m<-groups[[x$group]];pa<-pairs[[x$pair]];aa<-d[[pa[1]]];bb<-d[[pa[2]]]
 tab<-table(factor(aa[m],levels=c('Full','Partial','Absent','Not applicable')),factor(bb[m],levels=c('Full','Partial','Absent','Not applicable')))
 check(paste(x$group,x$pair,'independent contingency'),tab['Full','Full']==x$both_full&&sum(tab[1:3,1:3])==x$applicable&&sum(tab[1:2,1:2])==x$both_at_least_partial)
 yy<-t[t$group==x$group&t$pair==x$pair,]
 check(paste(x$group,x$pair,'all sixteen cells'),all(mapply(function(aa,bb,n)tab[aa,bb]==n,yy$status_a,yy$status_b,yy$n)))
}
for(i in seq_len(nrow(v))){
 x<-v[i,];m<-d$unit_type==x$setting&groups[[x$purpose]]
 if(x$measure=='integration') statuses<-matrix(d$integration[m],ncol=1) else statuses<-as.matrix(d[m,pairs[[x$measure]],drop=FALSE])
 full<-sum(apply(statuses,1,function(z)all(z=='Full')));app<-sum(apply(statuses,1,function(z)!any(z=='Not applicable')))
 check(paste(x$setting,x$purpose,x$measure),x$full==full&&x$applicable==app)
}
b<-read.csv('output/numbers/coverage_summary.csv')
check('Sampling modes exhaustive',sum(b$n[b$group=='All'&b$axis=='mode_label'])==87)
check('Clock categories exhaustive',sum(b$n[b$group=='All'&b$axis=='coverage_label'])==87)
check('Paper counts: joint reporting',identical(as.integer(a$both_full[a$group=='All']),c(25L,20L,18L)))
check('Paper counts: sampling',all(table(factor(codes$mode,levels=c('C','S','E','T','U')))==c(69,9,2,2,5))&&all(table(factor(codes$coverage,levels=c('F','W','D','N','U','A')))==c(59,12,5,5,5,1)))
check('Paper counts: full-cycle integration window',all(table(factor(d$integration[codes$coverage=='F'],levels=c('Full','Partial','Absent')))==c(23,15,4)))
out(do.call(rbind,checks),'output/numbers/validation_checks.csv')
cat('VALIDATION:',length(checks),'checks pass\n')
