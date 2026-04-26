---
layout: post
comments: true
title: "نصب Proxmox با PXE Boot: وقتی فلش درایو از کار می‌افته!"
date: 2026-04-26
categories: development
image: assets/article_images/proxmox-pxe-boot/proxmox-pxe-boot.png
toc: true
---

یه لپتاپ ThinkPad P14s Gen3 داشتم که بلااستفاده یه گوشه خونه افتاده بود. قبلاً سعی کرده بودم با **Bazzite** ازش یه کنسول خانگی بسازم، ولی از اونجایی که GPU داخلی این لپتاپ یعنی **T550** توانایی اجرای بازی‌های مدرن با کیفیت مناسب رو نداره و صرفاً به درد indie game می‌خوره، این کار برای سخت‌افزار قدرتمند لپتاپ به نظر هدر دادن منابع بود.

پس تصمیم گرفتم **Proxmox** رو روش نصب کنم تا در کنار کلاینت Dell OptiPlex 3060 Micro که تو خونه دارم، یه نود دیگه به کلاستر Proxmox من اضافه بشه. اما روش معمول نصب رو به کار نبردم...



## چرا PXE Boot؟

داستان از اینجا شروع شد که USB stick من از کار افتاد و دیگه روی سیستم mount نمی‌شد. به همین دلیل تصمیم گرفتم برم سراغ **PXE Boot**.

یه نکته مهم: برای PXE boot روی P14s Gen3، تنها راه موجود اینه که از **کابل LAN** برای اتصال کارت شبکه اترنت به سوییچ استفاده کنید. از طریق WLAN این کار رو نمیشه انجام داد، چون حداقل روی BIOS اکثر دستگاه‌های Lenovo، قابلیت PXE boot از طریق WiFi وجود نداره.



## راه‌اندازی اولیه با Serva (ویندوز)

برای PXE boot روی ویندوز رفتم سراغ یه ابزار freemium به اسم **[Serva](https://www.vercot.com/~serva/)**. نسخه رایگان تا ۵۰ دقیقه بدون محدودیت کار می‌کنه که برای نصب Proxmox روی یه کلاینت کافیه.

تنظیمات اولیه Serva ساده بود:
- **TFTP Server** برای لود کردن `initramfs` و `vmlinuz`
- **DHCP Proxy** برای لود کردن ISO مربوط به Proxmox و شروع فرایند نصب

فایل ISO رو مستقیم داخل دایرکتوری `Serva_Root\NWA_PXE` از حالت فشرده خارج کردم.

> ⚠️ **توجه:** WinRAR اسامی فایل‌ها رو تغییر می‌ده. بهتره ISO رو اول به صورت یه disk مجازی mount کنید و بعد با `xcopy` محتواش رو انتقال بدید.



## مشکل اول: پارامترهای kernel کار نمی‌کردن

اولین مشکل این بود که پارامترهایی که به kernel پاس داده بودم کار نمی‌کردن. مثلاً می‌خواستم به صورت خودکار از DHCP server روتر IP بگیرم، ولی این اتفاق نمی‌افتاد.

برای عیب‌یابی رفتم سراغ `dmesg`، ولی مشکلی پیدا نشد و همه درایورها سالم لود شده بودن. در مرحله بعد با دستور `lspci -nn` بررسی کردم چه سخت‌افزارهایی شناسایی شدن و متوجه شدم **درایور کارت شبکه `e1000e` لود نشده**. به همین دلیل هم `ip link show` جز `lo` هیچ اینترفیس دیگه‌ای نشون نمی‌داد.



## راه‌حل: افزودن درایور شبکه به initramfs

تصمیم گرفتم درایور شبکه رو مستقیم داخل `initramfs` قرار بدم تا موقع بوت، IP بتونه گرفته بشه. برای این کار به فایل `proxmox-kernel-6.17.2-1-pve-signed_6.17.2-1_amd64.deb` نیاز داشتم.

**مرحله ۱ - دانلود پکیج kernel:**
```bash
wget http://download.proxmox.com/debian/pve/dists/trixie/pve-no-subscription/binary-amd64/proxmox-kernel-6.17.2-1-pve-signed_6.17.2-1_amd64.deb
```

**مرحله ۲ - استخراج محتوا:**
```bash
ar x proxmox-kernel-6.17.2-1-pve-signed_6.17.2-1_amd64.deb
tar -xvf data.tar.xz
```

درایور مورد نظر در مسیر زیر قرار داره:
```
/lib/modules/6.17.2-1-pve/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko
```

**مرحله ۳ - استخراج initramfs:**
```bash
mkdir initramfs_build
cp initrd.img initramfs_build/
cd initramfs_build
zstd -dc initrd.img | cpio -idmv
```

**مرحله ۴ - افزودن درایور و repack کردن:**
```bash
mkdir -p lib/modules/6.17.2-1-pve/kernel/drivers/net/ethernet/intel/e1000e/
cp ../driver/lib/modules/6.17.2-1-pve/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko \
   lib/modules/6.17.2-1-pve/kernel/drivers/net/ethernet/intel/e1000e/

find . | cpio -o -H newc | zstd -19 -T0 > ../initrd.img

```



## مشکل دوم: DHCP هنوز کار نمی‌کنه

بعد از reboot، اینترفیس `eth0` به خوبی لود شد، ولی مشکل DHCP کماکان ادامه داشت. با بررسی اسکریپت `init` متوجه شدم فرایند لود کردن ISO **مستقل از شبکه** هست و کاملاً مبتنی بر cdrom.

دو راه جلوم بود:

| مشکل | توضیح | راه |
|-----:|------:|----:|
| TFTP خیلی کنده برای این حجم | قرار دادن proxmox.iso (~2GB) کنار initramfs | ادغام ISO با initramfs |
| نیاز به تغییر اسکریپت init | لود initramfs با TFTP، سپس دانلود ISO با `wget` | دانلود ISO بعد از بوت |



## راه‌حل نهایی: دانلود ISO از طریق HTTP

چون TFTP برای انتقال فایل‌های بزرگ مناسب نیست، به سراغ **HTTP** رفتم. HTTP server خود Serva ارور می‌داد، پس از وب‌سرور **[serve](https://github.com/jpillora/serve)** که binary ویندوز هم داشت استفاده کردم؛ اما بعد از دانلود فایل حجیم `initrd.img` crash می‌کرد.

پس رفتم سراغ **راه دوم**: لود اولیه `initramfs` با TFTP و بعد دانلود ISO با `wget`. این تغییرات رو به اسکریپت `init` اضافه کردم:

```sh
# --- Network Injection Start ---
echo "Initializing Network..."
/sbin/ip link set eth0 up
sleep 2
ip addr add 192.168.1.155/24 dev eth0
ip route add default via 192.168.1.1

echo "Downloading ISO via HTTP..."
/bin/mkdir -p /mnt/netboot

wget http://192.168.1.102:3000/proxmox-ve_9.1-1.iso -O /tmp/proxmox.iso

if [ -f /tmp/proxmox.iso ]; then
    echo "ISO Download Successful. Loop-mounting..."
    /bin/mount -o loop,ro /tmp/proxmox.iso /mnt
else
    echo "HTTP Download Failed."
fi
# --- Network Injection End ---
```

و خط `cdrom=""` رو به این تغییر دادم:
```sh
cdrom="/tmp/proxmox.iso"
```

و بعد دوباره initramfs رو ساختم

```
find . | cpio -o -H newc | zstd -19 -T0 > ../initrd.img
```

اینطوری تونستم وارد بخش نصب Proxmox بشم! ✅

البته این ساده‌ترین راه نبود. اگه تعداد زیادی دستگاه با سخت‌افزارهای مختلف داشته باشیم، این روش بهترین گزینه نیست؛ هرچند چیزهای زیادی درباره نحوه بوت شدن لینوکس ازش یاد گرفتم.



## راه‌حل بهتر: netboot.xyz + dnsmasq

برای روش اول (قرار دادن ISO کنار initramfs) به این نتیجه رسیدم که **Serva ابزار مناسبی نیست**، چون:
- بعد از دانلود `initramfs` حجیم crash می‌کنه
- ابزار مورد علاقه‌ام برای DHCP یعنی **dnsmasq** رو پشتیبانی نمی‌کنه

پس بیخیال ویندوز شدم و رفتم سراغ **[netboot.xyz](https://netboot.xyz)**:

1. با **proxyDHCP** پارامترهای boot رو به PXE client ارسال می‌کنم
2. فایل‌های `initramfs` (initrd) و `vmlinuz` (linux26) رو از طریق netboot تحویل PXE client می‌دم

برای ترکیب `dnsmasq` و `netboot.xyz` این [repo](https://github.com/behroozam/netboot-proxmox) رو آماده کردم. کافیه روی یه هاست **لینوکسی** اجراش کنید.

> ⚠️ **نکته:** هاست ویندوز مناسب نیست، چون container روی یه VM اجرا می‌شه و درخواست DHCP Discovery به دست dnsmasq نمی‌رسه.

در آخر کافیه یه دایرکتوری بسازید و فایل‌های `initrd.img` و `linux26` رو که با ISO pack شدن، اونجا قرار بدید:

```bash

cd boot
cd initramfs_build
mv ../proxmox-ve_9.1-1.iso proxmox.iso
find . | cpio -o -H newc | zstd -19 -T0 > ../initrd.img
cd ..
git clone https://github.com/behroozam/netboot-proxmox.git
cd netboot-proxmox
mkdir assets/proxmox/9.1-1/
# initrd.img و linux26 رو اینجا کپی کنید
cp ../{initrd.img,linux26} assets/proxmox/9.1-1/

docker-compose up -d
```

اگه همه چیز درست پیش بره، صفحه نصب زیبای Proxmox رو خواهید دید. 🎉
