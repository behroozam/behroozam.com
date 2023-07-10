---
layout: post
comments: true
title: "من چطوری از پروفایل مختلف برای git استفاده میکنم؟ "
date: 2023-07-10
categories: development
image: assets/article_images/git/git.png
toc: true
---

حتما شده رو سیستم شخصی خودتون یا شرکت لازم باشه بین یوزنیم یا ایمیل های  مختلف برای گیت جا به جا بشید و این مسئله معمولا باعث میشه که هربار مجبور بشین به صورت local تنظیمات هرکدوم از مخزن های خودتون رو تغییر بدین یا حداقل این کاری بود که من معمولا انجام میدادم
 
```
git config --local user.name "user"
git config --local user.name "mail@mail.com"
```

اما یه کار ساده تر هم میشه انجام داد و اون ایجاد پروفایل برای جدا کردن کار و زندگیه. 

### چطوری میشه بر اساس path کانفیگ های مختلف git رو از همدیگه تفکیک کرد ؟ 

این ساختار پیشنهادی من برای ساختن و مدیریت مخزن های مختلف روی سیستم خودتونه 

```
`-- projects
    |-- personal
    `-- work
```

حالا کافیه که تو Home dir خودتون یه کانفیگ به اسم `.gitconfig` بسازید 

```
[includeIf "gitdir:~/projects/work/"]
    path = .gitconfig-work
[includeIf "gitdir:~/projects/personal/"]
    path = .gitconfig-personal
```

حالا به ازای هرکدوم از تنظیماتی که برای هرکدوم از مخزن ها لازم دارید فایل کانیفگ رو برای work یا personal میسازید 

```
#.gitconfig-personal
[user]
    email = user@mail.com
    name = username
```
```
#.gitconfig-work 
[user]
        email = work-email
        name = work-username
```

بعد از ذخیره کردن فایل ها برای اینکه ببینیم تنظیماتمون اعمال شده میتونیم این کامند رو اجزا کنیم و تنظیمات گیت خودمون رو ببینیم 

```
git config --list --show-origin
```
