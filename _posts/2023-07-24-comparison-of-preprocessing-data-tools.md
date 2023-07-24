---
layout: post
comments: true
title: "من چطوری دیتا رو پردازش میکنم ؟"
date: 2023-07-24
categories: development
image: assets/article_images/data-pre-processing/data-preparation-process.jpg
toc: true
---

یکی از کارهایی که که تو زیرساخت به تناوب تکرار میشه گزارش گیری و مقایسه منابع هستش مخصوصا زمانی که replication داریم و یا میخوایم از دیتامون بکاپ داشته باشیم

### awk
ساده ترین نوع مقایسه این مجموعه ها اینه که تو unix از `awk` برای گزارش های خودمون استفاده کنیم که ابزار خوب و ساده و سریعیه و میتونه میلیون ها رکورد روبه سرعت مقایسه کنه اما استفاده از `awk` ضعف هایی هم داره مخصوصا زمانی که حجم داده یا منطق کد پیچیده تر میشه
* awk برای مقایسه field ها character های اون ها رو باهم مقایسه میکنه و از hash map و الگوریتم های membership checking استفاده نمیکنه این به خودی خودش ضعف محسوب نمیشه ولی وقتی حجم و پیچیدگی دیتا از یه حدی بیشتر میشه سرعت پردازش رو خیلی کاهش میده
* برای استفاده موثر از awk باید از ابزار های دیگه unix مثل `uniq` و `sort` برای مرتب کردن دیتا استفاده کرد که خوانایی کد رو پایین میاره و نیازمند تکراره

### python
راه حل جایگزین دیگه استفاده از پایتون ( یا هر زبان برنامه نویسی دیگه ای ) هستش
اما پایتون هم با وجود قدرت و انعطاف پذیری که داره محدودیت هایی برای ما داره همون طوری که میدونید پایتون یه زبان سطح بالا هستش که object ها رو تو memory ذخیره میکنه و اگه ما خودمون به صورت منطقی این memory managment رو انجام ندیم احتمال اینکه برنامه ما برای رکورد های حجیم توسط OOM سیستم عامل kill بشه بالا است. و این کار یعنی memory managment هم ساده نیست و نیازه که منطق کد تغییر کنه

### SQL databases
راه حل سوم و پیشنهادی برای دیتای حجیم و پیچیده استفاده از database engine ها برای اینکار هستش به چند دلیل

* این نرم افزارهای عموما DBMS برای کار با دیتا حجیم ساخته شدن و بحث memory managment موقع طراحی نرم افزار اعمال شده
* زبان Query که استفاده میشه معمولا sql هستش و این زبان قدرتمند این قابلیت رو به ما میده که از operator های این زبان برای مجموعه ها استفاده کنیم.
* برای عملیات های پیچیده با شروط مختلف که نیازمند درنظر گرفتن پارامتر های زیادی هستش میشه از کوئری های تودرتو استفاده کرد

برای درک بهتر این مسئله میریم سراغ یه مثال و بعدش راه حل های مختلفی که این سه ابزار یعنی awk و python و sqlite3 جلوی ما میزارن

### گزارش گیری از اشتراک دو مجموعه

موردی که من باهاش مواجه شدم بحث گزارش گیری از دو storage account مختلف روی azure بود و من این کار رو به وسیله ابزار rclone انجام دادم که به مراتب سریع تر از cmdlet های خود مایکروسافت هستش.
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
خوندن این مقاله رو برای فهمیدن اجزای مختلف کامند های AWK توصیه میکنم ولی اگر کد پایین رو بشکونیم ما چند تا منطق رو داریم
* `FNR==NR` به این معنی هستش که آخرین رکوردی[^1]( خط تو فایل لاگ ما | FNR indicates how many records have been read from the current input file )  که `AWK` محاسبه میکنه به تعداد خطوطی که تو فایل اول یعنی `source.txt` وجود داره علت این مسئله هم برمیگرده به رفتار awk که تا زمانی که NR بزرگ میشه به کارش ادامه میده. تو حالت عادی NR مجموع تعداد خطوطی هستش که تو دوتا فایل وجود داره

* مرحله دوم ریختن مقدار اولین field لاگ ما یعنی object[ID] تو یه متغیر به اسم found هستش

* مرحله بعدی مقایسه این متغیر با اولین field فایل دوم یعنی `dest.txt` هستش
```
awk 'FNR==NR{found[$1]++; next} $1 in found' source.txt dest.txt
```

اجرا شدن این کد روی سیستم من حدود 5 ثانیه وقت گرفت که میتونه به نسبت کامپیوتر و میزان فضای پردازشی شما متفاوت باشه ولی برای یه گزارش گیری سریع محسوب میشه و به نظرم روش های بعدی براش overkill محسوب میشن پس سعی میکنم حجم داده و پیچیدگیش رو کمی بیشتر کنم تا محدودیت ها خودش رو بیشتر نشون بده.



#### گزارش گیری به وسیله python

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

#### گزارش گیری به وسیله sqlite3

```
sqlite3 set.db
create table destlog(log text);
import
```
