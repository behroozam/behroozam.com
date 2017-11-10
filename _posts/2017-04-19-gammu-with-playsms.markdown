---
layout: post
comments: true
title: "آموزش راه اندازی درگاه پیام کوتاه"
date: 2017-04-19
categories: development
image: /assets/article_images/gammu/gammu.png


---
شاید صحبت کردن از gsm  و تکنولوژی های نسل دومی تلفن همراه الان با وجود سرویس های مختلف پوش نوتیفیکیشن و پیام رسان های موبایلی مبتنی بر اینترنت و خدمات نسل سوم و چهارم یه جورایی خاطره بازی و منسوخ به نظر برسه ولی باید توجه کرد که با وجود سه بیلیون خط فعال gsm در دنیا و همچنین هزینه پایین پیاده سازی سلوشن های موبایلی میتونه در کسب کار های ما هم خیلی موثر باشه و البته این موضوع فراتر از ارسال مسیج های گروهی و تبلیغاتی هستش.
من به عنوان یه sysadmin تنبل این وسط حوصله مانیتورینگ رو ندارم و معمولا هم ایمیل هام رو چک نمیکنم.این تکنولوژی زمانی به کمک من اومد که به وسیله پایپلاین ها و ارسال خطاها به من به صورت اتوماتیک خیلی از کارها سروسامان گرفت البته با ترکیب و اندکی خلاقیت . توجه کنید که اینجا فقط میخوام از پیاده سازی یه smsgateway در سطح  سازمان های کوچک و متوسط بگم منتهی مزیتی که این سلوشن نسبت به شرکت های بزرگ ارائه دهنده خدمات مبتنی بر ارزش داره تست و پیاده سازی سرویس هاتون به سرعت agile برای استارتاپ هایی که نمیخوان هزینه زیادی رو انجام بدن ولی کیفیت براشون مهم هست. کاربرد دیگه ای که این سلوشن داره برای دستگاه های IOT هست که در مناطق دور افتاده برای مثال برای مقاصد محیط زیستی و پژوهشی استفاده میشه که امکان دسترسی به اینترنت مقدور نیست. 
صنعت سلامت همگانی public health هم میتونه به عنوان سامانه های اطلاعاتی برای انواع غربالگری ها و مقاصد پژوهشی از این سلوشن استفاده کنه.
این آموزش مناسب توسعه دهنده ها و مدیران سیستم سطح متوسط به بالا هستش 


##نحوه راه اندازی مودم gsm به همراه رابط کاربری playsms 
برای راه اندازی playsms  نیازبه یک پایگاه داده mysql  و وب سرور ترجیهاآپاچی نیاز داریم. 
مراحل نصب playsms :
ابتدا بسته فشرده برنامه را از سایت playsms  دریافت میکنیم سپس استخراج و کپی کردن و اقدام به ساخت سیملینک میکنیم
{% highlight bash %}
tar  -zxf playsms-1.4.tar.gz -C /usr/local/src
ls -l usr/local/src
cd usr/local/src/playsms-1.4
{% endhighlight %}

سپس تنظیمات برنامه را تغییر میدهیم. توجه داشته باشید که پیش نیاز این مرحله نصب و پیکره بندی mysql  میباشد به این منظور میتوان از myphpadmin نیز جهت ایجاد پایگاه داده و کاربران مجاز و تغییر privilege ها نیز استفاده نمود .
{% highlight bash %}
Nano install.conf.dist 
cp install.conf.dist install.conf
{% endhighlight %}
بعد از ثبت تغییرات اقدام به نصب آن میکنیم 
{% highlight bash %}
sudo ./install-playsms.sh
{% endhighlight %}
پس از نصب میتوانید برنامه را به بوت اضافه کنید 
{% highlight bash %}
 Sudo echo /usr/local/bin/playsmsd start > /etc/init.d/rc.local
{% endhighlight %}


سپس ابتدا اقدام به دانلود و نصب gammu  و gammu-smsd  مینمایم .
برای نصب gammu  و gammu-smsd  میتوان در صورت موجود بودن از پکیج منیجر استفاده نمود در غیر این صورت اقدام به نصب به صورت دست میکینم . 
در صورت موجود بودن پکیج منیجر 
<code>
Sudo apt-get install gammu gammu-smsd
</code>
سپس یا متصل کردن پورت com یا usb  به دستگاه پرمیشن های دستگاه را ست میکنیم همانند 
{% highlight bash %}
sudo chmod 777 /dev/ttyUSB0
{% endhighlight %}
دایکرکتوری را جهت دریافت SMS  میسازیم 
{% highlight bash %}
mkdir -p /var/log/gammu /var/spool/gammu/{inbox,outbox,sent,error}
{% endhighlight %}

سپس به پوشه WWW/DATA دسترسی به نوشتار د پوشه gammu میدهیم 
{% highlight bash %}
chown www-data:www-data -R /var/spool/gammu/*
{% endhighlight %}
حال تنظیمان پیشفرض gammu-smsd را دانلود کرده و تغییر میدهیم و در دایرکتوری /etc  کپی میکنیم 
{% highlight bash %}
wget -c https://raw.githubusercontent.com/antonraharja/playSMS/master/contrib/gammu/linux/gammu-smsdrc
 cp gammu-smsdrc /etc/
{% endhighlight %}
تنطیمات پیشفرض را تغییر میدهیم 
{% highlight bash %}
nano /etc/gammu-smsdrc
{% endhighlight %}
میتوانید تنظیمات گوشی یا مودم gsm مورد نظر خودتون رو در [اینجا](https://wammu.eu/phones/) پیدا کنید
در قسمت device=/dev/ttyUSB0 را وارد کرده و در قسمت connection=at19200  را وارد میکنیم ( جهت خطایابی به مسیر لاگ توجه شود)
مهم: برای اینکه تنظیمات توسط gammu هم مورد استفاده قرار کید اقدام به ایجاد سافت لینک سیمبولیک مینماییم 
{% highlight bash %}
ln -s /etc/gammu-smsdrc /etc/gammurc
{% endhighlight %}

برای راه اندازی سرویس میتوان user=gammu  را به سیستم اضافه کرد ولی برای یکپارچگی بهتر است که در تنظیمات 
{% highlight bash %}
nano /etc/init.d/gammu-smsd
{% endhighlight %}
جای user=gammu  با user=root عوض شود 
برای شناسایی تنظیمات یکبار سرویس gammu-smsd را ری استارت میکنیم 
{% highlight bash %}
Sudo systemctl restart gammu-smsd.service
{% endhighlight %}
سپس برای شناسایی مودم  کامند زیر را وارد میکنیم
{% highlight bash %}
gammu -f /var/log/gammulog identify
{% endhighlight %}
عملیات پیکره بندی به پایان رسیده حال برای تست gammu دستور زیر را وارد میکنیم
 {% highlight bash %}
gammu sendsms TEXT 0912*******  -unicode -text "سلام دنیا"
{% endhighlight %}

به جای 0912 ادرس گیرنده را وارد نمایید

##تنظیمات پنل playsms
برای مدیریت پیام های ارسالی و دریافتی وارد پنل میشویم
ادرس پیشفرض 127.0.0.1/playsms و رمز نام کاربری admin  میباشد 
حالا برای تنظیمات شناسایی gammu  توسط playsms به قسمت تنظیمات رفته و در قسمت manage gateway and smsc رویgammu  کلیک کرده و در قسمت spool folder  ادرس /var/spool/gammu را وارد میکنیم  و ذخیره سازی میکنیم . سپس به تنظیمات main رفته و در انجا default smscر را gammu  انتخاب میکنیم . 
پایان 



