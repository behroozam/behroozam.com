---
layout: post
comments: true
title: "اجرا کردن فیدیبو به وسیله Waydroid روی گنو/لینوکس"
date: 2024-05-15
categories: development
image: assets/article_images/waydroid/waydroid.png
toc: true
---

تازگی ها برای تفنن از Arch Linux روی لپتاپ جدیدم استفاده میکنم

1. یه مقداریش برمیگرده به اینکه دوست داشتم تنوع بدم و دیگه از Ubuntu استفاده نکنم چون روی سرور و WSL از ابونتو استفاده میکنم.
1. دلیل دیگه اش هم برمیگشت به تجربه نه چندان دوست داشتنی که با [NixOS](https://nixos.org) داشتم.
1. اگه ارچ وجود نداشت احتمالا انتخابم [Gentoo](https://www.gentoo.org/) میبود.
1. خارج شدن از کنج عافیت[^1]

به نظرم Arch اون تعادلی که بین خیلی ساختار یافته بودن سیستم عامل و سهل گیری رو داره و استفاده از اون برای من دوست داشتنیه.

اما برگردیم به ماجرای اجرا کردن فیدیبو روی لینوکس.
چهار سال قبل درمورد این [نوشتم](/fidibo-anbox) که چطور فیدیبو رو به وسیله anbox روی گنو/لینوکس اجرا کنیم اما دیروز که داشتم نگاه میکردم متوجه شدم که anbox دیگه توسعه داده نمیشه ولی یه پروژه مشابه شده وجود داره که همون مسیر اجرا کردن اندروید به عنوان کانتینر روی لینوکسه.

### چرا Waydroid ؟

برای اجرا کردن اپلیکیشن های اندروید روی کرنل لینوکس ما دوتا راه بیشتر نداریم یا اینکه از مجازی‌ساز[^2] استفاده کنیم یا اینکه پروسه رو به وسیله کانتیتر[^3] اجرا کنیم.

مسیر اول که استفاده از مجازی‌ساز باشه رو تو [مقاله](/fidibo-anbox) قبلی بهش اشاره کردم مناسب سیستم های ضعیف نیست.

فعلا جایگزینی برای Waydroid وجود نداره که ساده تر باشه.

### نصب و اجرای Waydroid روی Arch

```bash
# installing yay aur package manager
pacman -Sy --needed git base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si

#Change the Arch kernel to zen kernel

sudo pacman -S linux-zen linux-zen-headers

reboot

#install Waydroid
yay -S waydroid

#running Waydroid serivce
sudo systemctl start waydroid-container.service

#enable the waydroid service(optional)
sudo systemctl enable waydroid-container.service

#init and usage of waydroid

sudo waydroid init

waydroid show-full-ui

waydroid app install fidibo.apk

```

اگه همه چیز به خوبی و خوشی پیش رفته باشه حالا میتونید کتاب مورد علاقه خودتون رو بخونید

![کتاب طریق شاهان](assets/article_images/waydroid/the-way-of-kings-persian.png)

[^1]: Comfort Zone
[^2]: Virtualization
[^3]: Container
