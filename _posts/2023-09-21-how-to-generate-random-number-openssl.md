---
layout: post
comments: true
title: "ساختن کلید متقارن یا رمز به وسیله openssl ؟"
date: 2023-09-21
categories: development
image: assets/article_images/openssl/openssl-logo.png
toc: true
---

### یه مقدمه کوتاه درمورد اعداد رندوم

خیلی وقت ها پیش میاد که لازم باشه برای انکود و دیکود کردن فایل ها یا ساختن پسورد ها نیاز به یه اپلیکیشن دم دستی داشته باشیم که برامون سریع یه رشته رندوم رو به عنوان کلید متقارن یا رمز بسازه

یکی از بهترین ابزارها برای این کار [openssl rand](https://www.openssl.org/docs/manmaster/man1/openssl-rand.html) هستش که یه [DRBG](https://en.wikipedia.org/wiki/Pseudorandom_number_generator) یا به عبارت دیگه deterministic random bit generator است.

### منظور ازdeterministic random bit generator چیه؟

تو دنیای واقعی برای ساختن عدد رندوم ( رمز یا کلید متقارن ) باید بریم سراغ زبان های برنامه نویسی و الگوریتم هایی که برای ساختن این اعداد ساخته شده
فانکشن های زبان های برنامه نویسی همواره یه ورودی و یه خروجی دارن و اون وسط یه سری عملیات هستش که ورودی ما رو به خروجی تبدیل میکنه.  
با این تفاسیر پس همیشه ما باید انتظار عدد یکسانی رو داشته باشیم چون
`f(x) = x2`
اما برای رفع این مسئله از چیزی استفاده میشه به عنوان [seed](https://en.wikipedia.org/wiki/Random_seed) یا دانه که مقدار اولیه که قراره به فانکشن ما داده بشه رو هربار عوض میکنه تا خروجی فانکشن ما همیشه متفاوت باشه ولی این مقدار اولیه هم خودش رندوم واقعی نیست و از مثلا زمان کامپیوتر یا پوینتر ماوس برای مقدار اولیه استفاده میکنه به همین دلیله که به این الگوریتم ها میگن pseudorandom number generators چون درنهایت اگه ما مقدار اولیه و روش کار الگوریتم رو بدونیم میتونیم که رشته اعداد رو بازتولید کنیم.

توجه کنید که این مبحث اعداد رندوم تو علوم کامپیوتر یکی از مهم ترین و کاربردی ترین قسمت ها هستش و این توضیح بالا ورژن خیلی ساده شده بحثه پس اگه به موضوع علاقه مند شدین توصیه میکنم این [مقاله](https://www.digitalocean.com/community/tutorials/random-number-generator-c-plus-plus) رو درمورد اینکه چطور به وسیله CPP یه random number generator رو بنویسیم بخونید.

### ویژگی های یه عدد رندوم خوب چیه؟

اما یه عدد رندوم مناسب باید چه ویژگی هایی داشته باشه:

1. همه اعداد از شانس برابرانتخاب شدن برخوردار باشن
1. مستقل باشه یعنی نسبت به اعدادی که انتخاب شدن یا انتخاب خواهند شد رابطه ای برقرار نباشه ( مثلا تصاعد هندسی در اعداد برقرار نباشه )

### چطوری به وسیله openssl rand یه رشته تصادفی بسازیم؟

برنامه openssl رو تقریبا میشه روی همه سیستم عامل های مدرن gnu/linux و posix پیدا کرد و کاربرد های زیادی داره که از حوصله این مقاله خارجه ولی اگه سری به man page قسمت openssl rand بزنیم میبینیم که از چند تا اپشن پشتیبانی میکنه

به صورت پیشفرض خروجی که openssl rand داره یه رشته رندوم Bytes هستش تو اکثر مواقع این رشته به درد کار ما نمیخوره چون encoding خاصی نداره و برای اکثر نرم افزارها غیرقابل خوندنه.

یعنی اگه تایپ کنیم `openssl rand 64` برنامه ما یه رشته به اندازه 64 bytes ایجاد میکنه

اما دوتا آپشن کاربردی دیگه hex و base64 هستن یعنی خروجی بایتی رو که برنامه openssl ایجاد کرده به base64 یا hexadecimal تبدیل میکنه

#### base64

اما فرمول سایز رشته خروجی ما چی هستش

تو استاندارد base64 هر کاراکتر 6 bit هستش و از سه تا بلاک 8 bit ای ساخته شده به عبارتی هرکاراکتر ما مثل عدد یا حرف به 24 bit و 4 تا کاراکتر base64 تبدیل میشه.

تصور کنید که ما خروجی یه رشته 32 بایتی رو از base64 انتظار داریم

پس تو فرمول ما `4*(n/3)=32` مقدار n میشه 24 بایت
چرا چون هر 3 تا بایت میشه یه کاراکتر base64 که خودش 4 تا کاراکتر utf8 میشه پس با این حساب ما به 24 بایت مقدار اولیه برای ساختن یه رشته 32 کاراکتری احتیاج داریم.

که به این صورت میتونیم یه رشته رندوم 32 بایتی رو به وسیله openssl بسازیم و انکود کنیم

```
openssl rand -base64 24
```

##### اگه نیاز به یه رشته 64 بیتی یا 31 بیتی داشتیم چی؟

از اونجایی که مقدار 64 رند هستش و باقیمانده در تقسیم نداره کار محاسبه راحته کافیه مقدار 64 رو تو فرمول خودمون قرار بدیم `4*(n/3)=64` که میشه 48

```
openssl rand -base64 48 | tr -d '\n' | wc -m
```

مشاهده میکنیم که اندازه خروجی ما 64 کاراکتر یا به عبارت دیگه 64 بایته.

برای محاسبه 31 بیت باید تو فرمول خودمون عددمون رو گرد کنیم
یعنی `4*(n/3)=31` که خروجیش میشه 32 یعنی به صورت دقیق نمیتونیم 31 بایت داشته باشیم

```
openssl rand -base64 23 | tr -d '\n' | wc -m
```

#### Hex

هر کاراکتر تو مقیاس هگزادسیمال 4bit هستش یعنی هر بایت تبدیل میشه به دو کاراکتر هگزادسیمال
به همین سادگی میتونیم از فرمول n/2 استفاده کنیم
یعنی اگه نیاز به 24 بایت خروجی داشته باشیم کافیه 24/2=12 رو به دست بیاریم

```
openssl rand -hex 12
openssl rand -hex 12 | tr -d '\n' | wc -m
```
