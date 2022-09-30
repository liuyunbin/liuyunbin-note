
## ��װ��
# install.packages("openxlsx")
# install.packages("ggplot2")
# install.packages("reshape2")
# install.packages("dplyr")

## ʹ�ÿ�
library(openxlsx)
library(ggplot2)
library(reshape2)
library(dplyr)

## ���ļ���ȡ����
setwd("D:/�ĵ�-���Ʊ�")
df = read.xlsx("ECI����.xlsx")

## �� year ��ת��Ϊ ���ڸ�ʽ
# df$year = as.Date(df$year,"%Y")

## �޸�����
df = rename(df,
 AH="����",
 BJ="����",
 CQ="����",
 FJ="����",
 GD="�㶫",
 GS="����",
 GX="����",
 GZ="����",
 HA="����",
 HB="����",
 HE="�ӱ�",
 HI="����",
 HL="������",
 HN="����",
 JL="����",
 JS="����",
 JX="����",
 LN="����",
 NM="���ɹ�",
 NX="����",
 QH="�ຣ",
 SC="�Ĵ�",
 SD="ɽ��",
 SH="�Ϻ�",
 SN="����",
 SX="ɽ��",
 TJ="���",
 XJ="�½�",
 XZ="����",
 YN="����",
 ZJ="�㽭")

## ������֯����
col_names = colnames(df) # ������

col_nums = ncol(df) # �еĸ���
row_nums = nrow(df) # �еĸ���, �� �����

### ���� �����Ŀ̶�����, ÿ n �� չʾһ�� 
n = 5
year_len = length(df[,1])
scale_x_names = vector(mode='character',length=year_len)
for (i in 1:year_len) {
	if (i %% n == 1) {
		scale_x_names[i] = year[i]
	}
}

### ���� �ݱ���Ŀ̶�����, ÿ n �� չʾһ�� 
n = 10
scale_y_names = vector(mode='character', length=31)
for (i in 1:31) {
	if (i %% n == 1) {
		scale_y_names[i] = as.character(32 - i)
	}
}

df = melt(df, id = "year", variable.name = "city", value.name = "data")

#df$data = factor(as.character(df$data))

## ��ͼ

# ggplot()     ��������
ggplot(data = df, 
       mapping = aes(x = year, 
                     y = data,
                     group=city,
                     colour=city)) +
geom_line() +                           # ����
geom_point(size=3, show.legend = TRUE)+                     # ����
theme_bw() +                            # ȥ������
theme(panel.grid=element_blank(),       # ȥ������
	axis.ticks.x = element_blank(),   # ȥ�� x ��Ŀ̶�
      axis.ticks.y = element_blank(),   # ȥ�� y ��Ŀ̶�
      panel.border = element_blank()    # ȥ����߿�    
      ) +
scale_x_discrete(breaks=c(2000,         # ����������Ҫչʾ�Ŀ̶ȱ�ǩ
                          2005,
                          2010,
                          2015,
                          2020),
                 expand=c(0.01,0)
                 )+
scale_y_continuous( breaks=c(1,11,21,31), # ���� ������Ҫչʾ�Ŀ̶ȱ�ǩ
			  labels=c("1"="31",
                             "11"="21",
                             "21"="11",
                             "31"="1"),
			  expand=c(0.01,0),
			  sec.axis=dup_axis(
                        name = NULL,
  				breaks = c(1:31),
                        labels=c(1:31)
  		#		labels = waiver(),
  		#		guide = waiver()
			  )
			)+
guides(
	colour = guide_legend(
		title = NULL, # ȥ��ͼ������
		ncol = 1,      # ͼ��ֻҪһ��
		keyheight = 0.7
	)
) +
coord_fixed(ratio=3/5)+ 
labs(
    	x = "Year",           # x ��
    	y = "Ranking(ECI)",   # y ��
   	title = "����")        # ����

ggsave("1.pdf")