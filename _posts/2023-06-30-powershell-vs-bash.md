---
layout: post
comments: true
title: "powershell یا bash مسئله این است ؟"
date: 2023-06-30
categories: development
image: assets/article_images/powershell/powershell.png
toc: true
---
### مقدمه 
به عنوان یه کاربری که سال ها هستش اکه از zsh یا bash استفاده میکنم به تازگی با powershell آشنا شدم و حسابی ازش خوشم اومد
به نظرم بزرگ ترین برتری که powershell نسبت به bash و کلا shell های unix داره اینه که با object سروکار داره یعنی اینکه خروجی کامند صرفا یه plain text نیست. 

### مقایسه لیست کردن سرویس ها 
برای مثال میام از cmdlet پاورشل به اسم Get-Service استفاده میکنم که به من لیست سرویس های درحال اجرا روی ویندوز رو میده
```
Get-Service -Name *
```
خروجی این کامند تو powershell مثل اینه که تو bash و سیستم هایی که از systemd برای process management استفاده میکنن بزنیم

```
systemctl list-unit-files
```
### اما تفاوت چیه ؟

تفاوت اینه که برخلاف bash که داره یه باینری به اسم systemctl  رو صدا میزنه که برای ما خط رو چاپ کنه powershell داره از utility های خودش که اسکریپت های powershell هستن استفاده میکنه که تاثیر گرفته از زبان C  و  شئی گراست
یعنی این cmdlet  ما یه سری Method و Property داره
برای دیدن این ها میتونیم از کامند Get-Member استفاده کنیم به این صورت
```
Get-Service -Name * | Get-Member
```
تصور کنید که ما فقط میخوایم که اسم سرویس به همراه وضعیت فعلی که داره رو مشاهده کنید تو لینوکس یا bash راهی نداریم به جز فیلتر کردن خروجی کامند به این صورت که
```
 systemctl list-unit-files | grep enabled
```
اینجوری میتونیم لیست سرویس های فعالی رو که داریم ببینیم
اما powershell به ما این قابلیت رو میده که بر اساس Property  کار فیلتر کردن رو انجام بدیم
```
Get-Service * | Select-Object -Property Name,Status | Where-Object {.Status -eq 'Running'}
```

### چرا powerhsell ممکنه برای برنامه نویس ها جذاب تر باشه ؟

فکر میکنم این برای کسایی که با زبان های برنامه نویسی بیشتر سروکار دارن تجربه خوشایند تری باشه هرچند میشه تاثیر هردو دنیا رو اینجا دید مثلا توی اغلب زبان های برنامه نویسی ما بلاکی از کد رو به بلاک دیگه pipe نمیکنیم به غیر از شاید Templating Languages که خیلی رایجه که دیتا رو به این شکل تغییر داد 
برای مثال برای تغییر دادن زمان به human readable فرمت تو jekyll

```bash 
page.Date | date: "%-d %B %Y"
```

برای آشنایی با بقیه قابلیت هایی که powershell داره خوندن این [مقاله](https://adamtheautomator.com/powershell-objects/) رو توصیه میکنم.

### نتیجه‌گیری

ابزارها یا زبان های برنامه نویسی که ما بهشون عادت کردیم لزوما بهترین ابزار برای حل مسئله نیستن ولی میشه اینجوری فکر کرد که: 
>* مدت زمان برای یادگیری یه ابزار جدید
 * میزان استفاده اش
 * بهبود عملکرد
* هزینه نگهداری  

مولفه هایی هستن که تو انتخاب تکنولوژی موثر هستن
به نظر من برای یه مدیر سیستم لینوکسی که سال ها با bash و python  کار کرده 

learning curve پاورشل اونقدر زیاد نیست که بهش وقت ندیم

فاکتور دیگه ای که ممکنه استفاده از powershell رو جذاب کنه پشتیبانی خیلی خوبش از سرویس های ماکروسافت و azure هستش

یعنی شما با یه اسکریپت چند خطی میتونید از سرویس های مختلفی که azure داره ریپورت بگیرین یا تقریبا هر کاری که نیاز به اتوماتیک سازی داره رو انجام بدین

اطراف اکوسیستم powershell هم module های خوبی ساخته شده که خیلی کار نصب کردن یا تعامل با ویندوز رو راحت کرده که میتونید خیلی راحت اون ها رو [اینجا](https://www.powershellgallery.com/) پیدا و نصب کنید

پاورشل مولتی پلتفرم و تحت مجوز MIT هستش و اون رو میتونید روی سیستم لینوکسی خودتون هم نصب کنید
