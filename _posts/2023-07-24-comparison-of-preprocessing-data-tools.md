---
layout: post
comments: true
title: "من چطوری دیتا رو پردازش میکنم ؟"
date: 2023-07-24
categories: development
image: assets/article_images/data-pre-processing/data-preparation-process.jpg
toc: true
---

### مقدمه

یکی از کارهایی که که تو زیرساخت به تناوب تکرار میشه گزارش گیری و مقایسه منابع هستش مخصوصا زمانی که replication داریم و یا میخوایم از دیتامون بکاپ داشته باشیم یا تحلیل لاگ webserver برای پیدا کردن خطا ...

از پراستفاده ترین مدل این مقایسه ها میشه به 
* union(full join) 
* intersection(inner join) 
* complement(right or left join) 

اشاره کرد. 

![](assets/article_images/data-pre-processing/sqljoins.jpg "sql joins")

در ادامه میخوام درمورد ابزارهایی که برای پردازش این دیتا استفاده میکنم صحبت کنم 

### awk
ساده ترین نوع مقایسه این مجموعه ها اینه که تو unix از `awk` برای گزارش های خودمون استفاده کنیم که ابزار خوب و ساده و سریعیه و میتونه میلیون ها رکورد روبه سرعت مقایسه کنه اما استفاده از `awk` ضعف هایی هم داره مخصوصا زمانی که حجم داده یا منطق کد پیچیده تر میشه
* awk برای مقایسه field ها character های اون ها رو باهم مقایسه میکنه و از hash map و الگوریتم های membership checking یا دیتا استراکچری مثل [binray tree](https://en.wikipedia.org/wiki/Binary_tree) استفاده نمیکنه این به خودی خودش ضعف محسوب نمیشه ولی وقتی حجم و پیچیدگی دیتا از یه حدی بیشتر میشه سرعت پردازش رو خیلی کاهش میده یا مصرف حافظه رو به حدی بالا میبره که باعث میشه سیستم عامل برنامه awk ما رو Kill کنه 

* برای استفاده موثر از awk باید از ابزار های دیگه unix مثل `uniq` و `sort` برای مرتب کردن دیتا استفاده کرد که خوانایی کد رو پایین میاره و نیازمند تکراره( به دلیل همون مسئله ای که بالاگفتم چون awk کاراکتر ها رو باهم مقایسه میکنه اگه فایل ما sort شده باشه سرعت این مقایسه بیشتر میشه ) 

### python
راه حل جایگزین دیگه استفاده از پایتون ( یا هر زبان برنامه نویسی دیگه ای ) هستش
اما پایتون هم با وجود قدرت و انعطاف پذیری که داره محدودیت هایی برای ما داره همون طوری که میدونید پایتون یه زبان سطح بالا هستش که object ها رو تو memory ذخیره میکنه و اگه ما خودمون به صورت منطقی این memory managment رو انجام ندیم احتمال اینکه برنامه ما برای رکورد های حجیم توسط OOM سیستم عامل kill بشه بالا است. و این کار یعنی memory managment هم ساده نیست و نیازه که منطق کد تغییر کنه

مورد دیگه اینه که پایتون به خودی خودش به صورت بهینه از تمامی منابع سیستم استفاده نمیکنه و تو حالت عادی single thread هستش و برای استفاده بهینه از منابع باید از روش های پیچیده تر استفاده کرد 

اما استفاده از پایتون مزیت هایی هم داره: 

* برای سناریو هایی که لازمه دیتا از منابع مختلف جمع آوری بشه و منطق برنامه پیچیده تره 
* ایجاد وب سرویس به سادگی برای پردازش دیتا ورودی و خروجی 

### SQL databases
راه حل سوم و پیشنهادی برای دیتای حجیم و پیچیده استفاده از database engine ها برای اینکار هستش به چند دلیل

* این نرم افزارهای عموما DBMS برای کار با دیتا حجیم ساخته شدن و بحث memory managment موقع طراحی نرم افزار اعمال شده

* زبان Query که استفاده میشه معمولا sql هستش و این زبان قدرتمند این قابلیت رو به ما میده که از operator های این زبان برای مجموعه ها استفاده کنیم.

* برای عملیات های پیچیده با شروط مختلف که نیازمند درنظر گرفتن پارامتر های زیادی هستش میشه از کوئری های تودرتو استفاده کرد

* برای بهینه کردن کوئری های SQL خود DBMS ها ابزارهای مفیدی دارن که آنالیز کوئری رو راحت میکنه 

* برنامه های DBMS از دهه شصت میلادی به این سو وجود داشتن و همواره درحال بهبود و بهتر شدن بودن طبیعیه که سرعت و دقت و مصرف منابعشون به شدت بهینه تر باشه 

* اکثریت DBMS های مدرن امکان sharding و replication رو به ما میدن که برای پردازش حجم بسیار زیادی از داده دست ما رو باز میزاره 

برای درک بهتر این مسئله میریم سراغ یه مثال و بعدش راه حل های مختلفی که این سه ابزار یعنی awk و python و sqlite3 جلوی ما میزارن

### گزارش گیری از اشتراک دو مجموعه

موردی که من باهاش مواجه شدم بحث گزارش گیری از دو storage account مختلف روی azure بود و من این کار رو به وسیله ابزار [rclone](https://rclone.org/) انجام دادم که به مراتب سریع تر از [cmdlet](https://learn.microsoft.com/en-us/powershell/module/az.storage/get-azstorageblob?view=azps-10.1.0) های خود مایکروسافت هستش.

سوای اینکه چطور میشه از object هایی که روی cloud هست گزارش گرفت بحث اصلی مقایسه این دوتا دیتاست هستش که درادامه سعی میکنم ابتدا دیتایی مشابه(sample data) رو ایجاد کنم و بعدش روش های مختلفی که میشه این دوتا رو باهم مقایسه کرد رو برسی کنیم

برای اینکه sample data رو بسازیم به سه شرط احتیاج داریم
* دیتا یکتا در مبدا (source)
* دیتا یکتا در مقصد(destination)
* دیتا مشترک بین source و destination

اینجوری ما یه مجموعه(set) خواهیم داشت که باهم یه سری اعضا رو به اشتراک گذاشته ان.

برای ساختن دیتا sample روی bash

```
#creating source objects

for i in {0..10000000}
do
  echo "object$i" >> source.txt
done

# creating destination objects

 for i in {5000000..15000000}
do
  echo "object$i" >> dest.txt
done

```
با کامند بالا حالا ما دوتا فایل `source.txt` و `dest.txt`داریم که 5 میلیون آبجکت مشترک دارند

#### گزارش گیری به وسیله awk

برای اینکه اشتراک بین دوتا مجموعه رو به دست بیاریم باید column های این دوتا فایل رو باهم مقایسه کنیم
خوندن [این مقاله](https://www.cs.princeton.edu/courses/archive/spr04/cos333/03awk) رو برای فهمیدن اجزای مختلف کامند های AWK توصیه میکنم ولی اگر کد پایین رو بشکونیم ما چند تا منطق رو داریم
* `FNR==NR` به این معنی هستش که آخرین رکوردی[^1]  که `AWK` محاسبه میکنه به تعداد خطوطی که تو فایل اول یعنی `source.txt` وجود داره علت این مسئله هم برمیگرده به رفتار awk که تا زمانی که NR بزرگ میشه به کارش ادامه میده. تو حالت عادی NR مجموع تعداد خطوطی هستش که تو دوتا فایل وجود داره ولی وقتی ما `FNR=NR` قرار میدیم `NR` برابر با تعداد خطوط فایل اول یعنی `source.txt` میشه. 

* مرحله دوم ریختن مقدار اولین field لاگ ما یعنی `object[ID]` تو یه متغیر به اسم `found` هستش

* مرحله بعدی مقایسه این متغیر با اولین field فایل دوم یعنی `dest.txt` هستش
```
awk 'FNR==NR{found[$1]++; next} $1 in found' source.txt dest.txt
```

اجرا شدن این کد روی سیستم من حدود 5 ثانیه وقت گرفت که میتونه به نسبت کامپیوتر و میزان فضای پردازشی شما متفاوت باشه ولی برای یه گزارش گیری سریع محسوب میشه و به نظرم روش های بعدی براش overkill محسوب میشن پس سعی میکنم حجم داده و پیچیدگیش رو کمی بیشتر کنم تا محدودیت ها خودش رو بیشتر نشون بده.



#### گزارش گیری به وسیله python

همون طور که [بالا](#python) به اون اشاره کردم روش های زیادی برای کار با دیتا تو پایتون وجود داره و معمولا رابطه مستقیمی بای این داره که حجم و پیچیدگی دیتا شما به چه صورت هستش مثلا برای دیتا بالا که به وسیله awk پردازشش کردیم کد مشابه پایتونی میتونه به این صورت و به وسیله set که builtin datastrucure خود پایتون هست انجام بشه 
```
import sys
import csv

sourceblobs = frozenset(line.strip() for line in open("source.txt").readlines())
destinationblobs = frozenset(line.strip() for line in open("dest.txt").readlines())
# get the size of sets
print("size of the source blob", sys.getsizeof(sourceblobs))
print("size of the destination blob", sys.getsizeof(destinationblobs))

#sharedobject = frozenset( sourceblobs & destinationblobs )
intersection = sourceblobs & destinationblobs

with open('report.csv', 'w') as f:
    write = csv.writer(f)
    write.writerow(['Filename'])
    for item in intersection:
        write.writerow([item])

```

##### ولی اگه حجم دیتا از یه حدی بیشتر بود چی؟ 

خب برای ساختن دیتاست بزرگتر bash نمیتونه ابزار خوبی باشه چون while به اندازه کافی سرعت مناسبی رو نداره پس دست به دامن python میشیم برای ساختن دیتاست خودمون. 
> برای ساختن دیتاست شبیه به دنیای واقعی مثل آدرس و اسم و بقیه رکورد های معمول بهتره که از ابزارهایی که برای این کار موجوده مثل [faker](https://faker.readthedocs.io/en/master/) استفاده کرد 

```
def create_huge_log(outputfile_location,start_range,end_range):
    with open(outputfile_location, 'a') as outfile:
        for item in range(start_range,end_range):
            outfile.write("object" + str(item) + '\n')

create_huge_log("./source_huge",1,100000000)
create_huge_log("./dest_huge",50000000,150000000)

```

با اجرا کردن همون کامند awk اگه میزان رم سیستم شما مثل من محدود باشه سیستم عامل به دلیل مصرف بیش از حد رم کامند awk شما رو kill میکنه 

```
awk 'FNR==NR{found[$1]++; next} $1 in found' source_huge dest_huge > tmp
```
پس باید به سراغ یه راه حل جایگزین رفت یعنی استفاده از دیتاتایپ یا روش دیگه ای برای برای پردازش دیتا خودمون 

##### استفاده از dask برای پردازش دیتا تو حجم زیاد 

اگه قبلا از pandas که یکی از محبوب ترین پکیج های پایتون برای پردازش dataframe های خودتون استفاده کرده باشین حتما به محدودیت های حافظه برخورد کردین . 
برای رفع این مسئله یه پکیج پایتونی به اسم dask وجود داره که به جای اینکه یبارکی تمام دیتا شما رو تو یه dataframe لود کنه اون رو به پارتیشن های مختلف میشکونه و اینجوری باعث میشه که لود شدن دیتا در مقایسه با set یا panda dataframe خیلی سریعتر باشه ولی یه tradeoff هم داره که به نسبت حجم داده سرعت پردازش هم پایین تر میاد. 

1. خوندن [این مقاله](https://pub.towardsai.net/python-pandas-vs-dask-dataframes-a-comparative-analysis-c0f59dad5eeb#:~:text=Pandas%20is%20better%20suited%20for,choice%20for%20handling%20larger%20datasets.) برای مقایسه pandas و dask رو توصیه میکنم.
1.  خوندن [این مقاله](https://rcpedia.stanford.edu/topicGuides/merging_data_sets_dask.html) برای استفاده از dask برای عملیات merge رو توصیه میکنم.  

یه خوبی دیگه که dask رو میتونه برای استفاده های جدی تر به گزینه خوبی تبدیل کنه اینه که multithread هستش و میتونه distributed روی ماشین های مختلفی اجرا بشه که ضعف سرعت در مقایسه با بقیه ابزارهایی که همه چیز روی RAM لود میشه کمتر بشه. 

اما بریم سراغ کد : 

```
import dask.dataframe as dd

source_data_frame = dd.read_csv(r"./source_huge")
dest_data_frame = dd.read_csv(r"./dest_huge")

merged = dd.merge(source_data_frame, dest_data_frame, on=["log"], how='inner')

merged.to_csv('./report.csv', single_file = True)
```

همون طور که متوجه شدین سرعت بزرگترین مزیت استفاده از dask نیست ولی میتونید مطمعا باشید که برنامه شما به خاطر مصرف تمام حافظه kill نمیشه. 

#### گزارش گیری به وسیله sqlite3
دنیای SQL compatible database ها پر از اسامی پر افتخاری مثل Mysql و MS sql server و Postgresql و Mariadb هستش. 

این بسته به تجربه و راحتی استفاده شما داره که کدوم یکی از این ها رو برای پردازش دیتا خودتون استفاده میکنید ولی برای تعداد خیلی زیادی از سناریو ها به نظر من دیتابیس سبک و قدرتمند sqlite پاسخگو هستش. 

اما بریم سراغ پردازش دیتا خودمون.

```
#copy files to csv format 

cp dest_huge dest_huge.csv
cp source_huge source_huge.csv

#add csv field 
sed  -i '1i log' source_huge.csv
sed  -i '1i log' dest_huge.csv

#create tables and import data 

sqlite3 set.db
create table sourcelog(log text);
create table destlog(log text);
.import source_huge.csv sourcelog --csv
.import dest_huge.csv destlog --csv
.exit 

#run sql query to get intersect between two source and dest tabel 

sqlite3 -header -csv set.db 'SELECT * FROM sourcelog INTERSECT SELECT * FROM destlog;' > intersect.csv
```
همون طور که متوجه شدین sqlite3 در مقایسه با بقیه ابزارها با سرعت خیلی بیشتری جواب میده

###  نتیجه گیری 

شاید بپرسین با وجود اینکه دیدیم sqlite3 سریعتر از بقیه ابزارها جواب میده پس چرا بازم از اونا استفاده میکنیم؟ 

* برای iterate کردن با دیتا کم که معمولا اکثر اوقات دیتا ما حجیم نیست ابزاری مثل awk یا python خیلی کار دیباگ رو راحت و سریع میکنه 

* برای مقایسه sql و dask به نظرم این [مقاله](https://docs.dask.org/en/latest/dataframe-sql.html) خیلی خوب tradeoff ها رو توضیح داده 

درنهایت انتخاب ابزار مناسب برای پردازش دیتا برایندی از مقیاس و پیچیدگی و زمان و منابع شما. 
 
[^1]: خط تو فایل لاگ ما FNR indicates how many records have been read from the current input file
