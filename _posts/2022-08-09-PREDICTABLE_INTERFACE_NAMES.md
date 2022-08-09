---
layout: post
comments: true
title: " اینترفیس های حدس زدنی"
date: 2022-08-09
categories: development
image: assets/article_images/PREDICTABLE_INTERFACE_NAMES/systemd-light.png
---

سخت تر از شرح ماجرا انتخاب یه اسم با مسما برای مقاله بود

 راستی این مقاله رو من به وسیله [md.behroozam.com](http://md.behroozam.com) نوشتم که یه markdown editor خیلی ساده است که زبان فارسی و rtl رو پشتیبانی میکنه از قابلیت های اضافی تری هم که نسبت به نسخه اصلی که فورکش کردم داره اینه که تمیز تر نوشته شده و پلاگین فوتر براش فعاله یعنی میتونید به راحتی توش فوتر اینشکلی[^1] اضافه کنید و بعدا احتمال داره قابلیت های دیگه [GFM](https://github.github.com/gfm/) که `markdown engine` گیتهاب هستش رو هم بهش اضافه کنم

### شرح اتفاقی که افتاد ؟

تو هفته گذشته وظیفه داشتم که مشکل race condition بین interface های مختلف رو تو زمان بوت شدن سیستم رفع کنم ولی قضیه از چه قرار بود
ما یه rule عه udev داشتیم به اسم `etc/udev/rules.d/70-persistent-net.rules/` که محتواش به این صورت بود

```
‍‍‍SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="<MAC address>", ATTR{type}=="1", KERNEL=="eth*", NAME="eth0"
‍‍‍SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="<MAC address>", ATTR{type}=="1", KERNEL=="eth*", NAME="eth1"

```
این rule درواقع میگه که زمانی که event شناسایی سخت افزار interface با مختصات `*eth` از سمت کرنل اومد udev اسم این interface رو با MAC address مورد نظر به `eth0` تغییر بده و برای MAC address بعدی به `eth1`

تو این مورد اگر ما دوتا network interface میداشتیم و پارامتری که به grub پاس داده بودیم شامل ‍`net.ifnames=0` میشد یعنی بدین صورت

```
echo 'GRUB_CMDLINE_LINUX="net.ifnames=0"' > /etc/default/grub
```
اتفاقی که میفته اینه که kernel به صورت default مقداری رو که به عنوان interface برمیگردونه به صورت legacy برمیگردونه با schema قدیمی eth*
و اینجوری اگه مثلا من بخوام eth0 رو به eth0 یا eth0 رو به eth1 تغییر اسم بدم مشکل race condition اتفاق میفته چون قبلا این interface توسط لایه kernel تحویل داده شده و حالا ما تو لایه user-space تلاش میکنیم تغییرش بدیم تا بوت بشه

### اما چرا اینکار رو انجام میدادیم ؟

همه چیز برمیگرده به نسخه v197 systemd که تصمیم بر این گرفته شد که به جای استفاده از interface name های legacy از Predictable Network Interface Names استفاده بشه به این صورت که بر اساس این استاندارد به جای استفاده از `*eth` از مقادیری که به آدرس کارت شبکه یا اسمش اشاره میکنه درواقع  `ID_NET_NAME_PATH` یا `ID_NET_NAME` و ... استفاده میشه
برای دیدن جزئیات اینکه systemd-udev بر چه اساسی این نام گذاری رو انجام میده میتونید [این داکیومنت رسمی](https://man7.org/linux/man-pages/man7/systemd.net-naming-scheme.7.html) رو یا [این تکه](https://github.com/systemd/systemd/blob/main/src/udev/udev-builtin-net_id.c) از کد رو بخونید تا دقیق تر متوجه بشید. اینجا هم یه مقاله رسمی از [systemd](https://systemd.io/PREDICTABLE_INTERFACE_NAMES/) که ماجرا رو به تفصیل شرح میده
[این مقاله](https://wiki.debian.org/NetworkInterfaceNames) دبیان هم برای خوندن بیشتر توصیه میشه

### چه راه حل هایی داریم ؟

این البته بسته به نیاز و شرایط شما از تنظیمات سیستم داره مثلا اگه جایی interface رو hard-code کرده باشین یا تنظیمات فایروال رو بر اساس interface name تنظیم کرده باشین لازم هستش که همواره مطمعا باشید که inerface name که تحویل میگیرید اسم مورد نظر رو داشته باشه
برای مثال اگر تنظیمات فایروایل به این صورت هستش
```
iptables -t raw -A PREROUTING -i etch0 -j CT --zone newyork

```
>  ترکیب این راه حل ها باهمدیگه باعث میشه که هیچکدوم به درستی کار نکنند پس فقط یکی از این راه حل ها رو انتخاب کنید

خب اینجا چند تا راه حل دارید

#### راه حل اول
 مثل مثال بالا از `persistent-net.rules‍` استفاده کنید ولی `net.ifnames=0` رو از تنظیمات grub پاک کنید

#### راه حل دوم و پیشنهادی من

 اینه که از systemd link استفاده کنید که روش مدرن تری برای rename کردن interface هست و میتونید مطعما باشید که درست کار میکنه
برای  مثال من میخوام یه interface به اسم `internet0` داشته باشم که ترافیک اینترنتی من رو حمل کنه و چون نمیخوام تنظیمات فایروالم رو عوض کنم یه `AlternativeName` به اون اضافه میکنم که درواقع همون eth0 هستش
`AlternativeName` قابلیت جدیدی که به کرنل لینوکس اضافه شده تا بشه یه نام مستعار رو به interface های لینوکس اضافه کرد
‍‍
```
cat > /etc/systemd/network/10-altname.link <<EOF
[Match]
MACAddress=YourMACAdress

[Link]
Name=internet0
AlternativeName=eth0
AlternativeNamesPolicy=database onboard slot path
EOF
```
و جهت خطایابی و رفع ایرادات احتمالی که ممکنه فایل link ما داشته باشه

```
udevadm control --log-level=debug

udevadm trigger -c add /sys/class/net/internet0

journalctl -xe -f -u systemd-udevd.service
```

#### راه حل سوم

به تنظیمات grub این تکه رو اضافه کنید ‍`net.ifnames=0` تا نام گذاری interface به شکل گذشته خودش یعنی `*eth` برگرده

[^1]:  شرحی بر لینک بالا


