---
layout: post
comments: true
title: "یکم امنیت "
date: 2015-07-29
categories: featured
image: assets/article_images/modem/modem.jpg


---


اون روز یه یهو به سرم زد ببینم چه تعدادی از کاربرایی که تو رنج ip من هستن از رمز پیشفرض مودمشون که من admin در نظر گرفتم استفاده میکنند .
برای شروع آخرین بویلد برنامه angry ip scanner رو از [اینجا](http://angryip.org/download/#linux "angry ip scanner") دانلود کردم .

خب کامند ip addr ای پی که سویچ/روتر شما بهتون داده رو نشون میده برای پیدا کردن public ip میتونین از کامند

{% highlight ruby %}
wget http://ipecho.net/plain -O - -q ; echo
{% endhighlight %}
استفاده کنید یا از سایت هایی که public ip استفاده کنید .

تو قدم بعدی رنج ای پی که میخواین اسکن کنید رو مشخص کنید میتونین از  [این]("http://www.subnet-calculator.com" ) ابزار استفاده کنید .

بعد از اینکه اسکن تمام شد کافیه از قسمت <code> tools >selection>alive host </code> ای پی ها رو انتخاب کنید و از قسمت <code>scan>export selection </code> تو یه فایل متنی ذخیرشون کنید
در قدم بعدی نیاز هستش که رمز admin رو روی تمامی live ip ها تست کنیم .

برای این کار از ابزار قدرتمند thc hydra استفاده میکنیم . که تو مخازن دبیان و ابونتو به راحتی
<code> sudo apt-get install hydra </code>
در دسترسه .

البته میتونین به وسیله nmap قبلش یه چکی از ای پی ها بکنید

بعد از نصب hydra کافیه یه نگاهی به صفحه منوالش بندازیم حالا خیلی راحت

> hydra -l admin -p admin -v -M /home/yourname/hosts.txt http-head

بعد از به دست اومدن نتیجه هم میتونید با spss یه امار درست حسابی تحویل بدین .

 نمیتونم آماری رو که به دست اوردم رو به دلایلی  منتشر کنم ولی وضعیت خوبی نبود . امیدوارم بقیه سرویس دهنده وضع بهتر باشه

راستی

> قبل از هر کاری فکر کنید . حتی کد زدن
