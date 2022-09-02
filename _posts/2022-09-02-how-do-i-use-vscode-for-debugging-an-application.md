---
layout: post
comments: true
title: "من چجوری از vscode برای خطایابی نرم‌افزار استفاده میکنم ؟"
date: 2022-09-02
categories: development
image: assets/article_images/vscode/vscode.svg
---


من از دوران [پیشدادیان](https://fa.wikipedia.org/wiki/%D9%BE%DB%8C%D8%B4%D8%AF%D8%A7%D8%AF%DB%8C%D8%A7%D9%86) طرفدار محیط های توسعه مثل intelij و pycahrm و... نبودم. نه به خاطر اینکه باور دارم نرم افزار های بدی هستن به خاطر اینکه مناسب نیاز من تو شغل DevOps/SRE نیستن و ممکنه نیاز های بقیه رو تو قسمت های دیگه مهندسی نرم افزار پوشش بدن.
 دلیل برجسته برگزیدن [vscode](https://code.visualstudio.com/) برای ادیتور اصلی که ازش استفاده میکنم برمیگرده به مصرف منابع خیلی کمتر نسبت به [IDE](https://en.wikipedia.org/wiki/Integrated_development_environment) و شخصی سازی و سادگی تو استفاده و پشتیبانی کردن زبان ها و ابزار های مختلف و متن باز بودن و جامعه کاربری بزرگی که پلاگین های کابردی رو براش توسعه میدن.

### علت نوشتن این مقاله چیه ؟

به نظرم استفاده از ابزار مناسب تو جای مناسب به بهره وری خیلی کمک میکنه.

و تو این دنیای نرم افزار ممکنه خیلی از ابزارها یا متودولوژی ها وجود داشته باشن که ما از وجودشون بی خبریم یا به تجربه و از همکارهای خودمون یادگرفتیم درحالی که میتونستیم خیلی زودتر در ابتدای شروع کارمون یاد بگیریم و بهتر بشیم.

> چیدمان کیبرد های mac و linux و windows با هم متفاوته  برای مثال این سه یک کار مشابه رو در vscode یعنی اجرای command رو در vscode انجام میدن
* MacOs: `command + shift + p`
*  Windows: `Ctrl +shift + p`
* Gnu/Linux: `Ctrl+ shift + p`


### شخصی سازی vscode

برای باز کردن تنظیمات vscode کافیه که  `command + shift + p`  رو فشار بدین و گزینه `Preferences: Open Settings` (JSON) رو از منو انتخاب کنید به شکل تصویر پایین

![](assets/article_images/vscode/opensetting.gif "opensetting")


من معمولا به انتهای فایل هایی که ویرایش میکنم یه خط اضافه میکنم این باعث میشه که اگه از یک نرم افزار ورژن کنترل مثل git برای blame کردن استفاده میکنید به خطا نیفتید.


#### اضافه کردن خط به انتهای تمامی فایل های ویرایش شده

تو فایلی که بالا بازکردیم این رو جهت اضافه شدن خط به انتهای همه فایل های ویرایش شدمون به صورت خودکار اضافه میکنیم
```
{
    "files.insertFinalNewline": true
}
```
چون فایل json هستش حواستون به این باشه که اگر key جدیدی اضافه میکنید حتما با کاما `,` اون ها رو از هم جدا کنید

#### پاک کردن اسپیس های اضافی در انتهای خطوط

توصیف موضوع اندکی سخته برای فهمیدن چرایی اضافه کردن این خط به تنظیمات توصیه میکنم ویدئو پایین رو مشاهده کنید

<iframe width="560" height="315" src="https://www.youtube.com/embed/jadCrCYKTO4" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

```
{
    "files.trimTrailingWhitespace": true
}
```
####  دنبال نکردن سیمبولیک لینک ها

من معمولا برای پیدا کردن فایل ها تو vscode از `command + p` استفاده میکنم به این صورت که میبینید

![](assets/article_images/vscode/findfile.gif "findfile")

برای اینکه symbolic link ها رو از سرچی که میکنم مجزا کنم این خط رو به کانفیگ اضافه میکنم
```
{
    "search.followSymlinks": false
}
```
علت اینکه دوست ندارم [symbolic link](https://en.wikipedia.org/wiki/Symbolic_link) تو نتایج جست و جو نمایش داده بشه اینه که فایل اصلی تو دایرکتوری وجود داره و علتی نداره که دوست داشته باشم vscode هر دو رو نمایش بده و اگر تعداد این فایل ها زیاد باشه خیلی آزار دهنده میشه


### خطایابی نرم افزار گولنگی به وسیله vscode

ما تو توسعه نرم افزار معمولا با دو مدل خطا روبه رو میشیم

* خطای کامپایل
* خطای اجرا

که هردو رو به وسیله ادیتور میشه سریع تر خطایابی کرد.

برای مثال اگر ما تو املا یا syntax برنامه خطایی داشته باشیم editor به سرعت میتونه به ما خطای ما رو نشون بده و از وجود یه مشکل ما رو با خبر کنه اما این میتونه درمورد خطاهای اجرا کمی پیچیده تر باشه.
در ادامه با مثالی که میزنم درمورد این دو خطا بیشتر صحبت میکنم
اگر همه چیز به خوبی پیش رفته باشه و ما vscode رو روی سیستم خودمون نصب کرده باشیم کافیه مراحل زیر رو دنبال کنیم.

> توجه کنید که من برای اجرای دستورهای فرمان از ترمینال لینوکس استفاده میکنم که تو محیط مک هم مشابه هستش ولی درمورد ویندوز کمی متفاوته پس پیشنهاد میکنم WSL2 رو روی ویندوز نصب کنید تا دستورات به صورت مشابه برای شما عمل کنه و کافیه این دستورات رو در Terminal ویندوز و روی wsl اجرا کنید

```
mkdir helloworld-vscode
cd helloworld-vscode
code .
```
حالا برنامه خودمون رو به که به این صورت هستش تعریف میکنیم `main.go`

```
package main

import (
	"flag"
	"fmt"
)

func main() {

	wordPtr := flag.String("flavor", "vanilla", "select shot flavor")
	numbPtr := flag.Int("quantity", 2, "quantity of shots")
	boolPtr := flag.Bool("cream", false, "decide if you want cream")

	var order string
	flag.StringVar(&order, "order", "complete", "status of order")

	flag.Parse()

	fmt.Println("flavor:", *wordPtr)
	fmt.Println("quantity:", *numbPtr)
	fmt.Println("cream:", *boolPtr)
	fmt.Println("order:", order)
	fmt.Println("tail:", flag.Args())
}
```

> توجه کنید که go  حتما باید روی سیستم عامل شما نصب شده باشه و مقادیر `GOPATH` و `GOROOT` در `environment variables` سیستم شما موجود باشه. برای نصب go  و ست کردن این مقادیر تو سیستم عامل من معمولا از [gvm](https://github.com/moovweb/gvm)  استفاده میکنم که نصب و نگهداری go رو آسون میکنه

اگه همه چیز به خوبی پیش رفته باشه vscode از شما درخواست میکنه که میتونه plugin گولنگ رو نصب کنه که درواقع دیباگر golang هستش و شما این رو بپدیرید.

در این مرحله بعد از پایان نصب نیازمندی ها اگه شما `command + F5` رو فشار بدین دیباگر برنامه شما رو اجرا میکنه و خروجی باید شبیه به تصویر پایین در قسمت `DEBUG CONSOLE` باشه

![](assets/article_images/vscode/simpledebug.gif "simpledebug")


#### دیباگ با flag یا env

در اکثر مواقع برنامه ما نیازی به flag یا env خاصی برای اجرا نداره ولی در مواردی ما دوست داریم مقدایر متغیری رو به برنامه به وسیله `OS.args` پاس بدیم تا رفتار برنامه خودمون رو عوض کنیم

برای اضافه کردن چنین قابلیتی به debugger خودمون کافیه بعد از `command + shift +p` تایپ کنیم `open 'launch.json'` و این مقدایر رو به انتها تنظیمات اضافه کنیم تا `launch.json` به این صورت بشه

```
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "Launch Package",
            "type": "go",
            "request": "launch",
            "mode": "auto",
            "program": "${fileDirname}",
            "args": ["--cream","--flavor","orange","flag1"],
            "env": {
                "TEST_VAR": "foo"
              }
        }
    ]
}
```

حالا اگر برنامه رو اجرا کنیم  `command + F5` مقادیر باید به شکل تصویر زیر تغییر کرده باشه

![](assets/article_images/vscode/argdebug.gif "argdebug")



#### خطایابی اجرا به وسیله breakpoint

گاهی وقت ها ما لازم داریم مقداری رو که یک متغیر در زمان اجرا گرفته رو قبل از خروجی مشاهده کنیم یا از رفتار یه فانکشن مطمعا نیستیم اینجا کافیه سر هر خطی که بهش مشکوکیم یه دایره قرمز بکشیم و نقطه ایست تعریف کنیم تا در زمان اجرا شدن دیباگر روی این نقاط متوقف بشه مثل تصویر زیر

![](assets/article_images/vscode/breakpoint.gif "breakpoint")


اما توجه کنید که این روش زمانی که ما [null pointer](https://www.geeksforgeeks.org/how-to-check-pointer-or-interface-is-nil-or-not-in-golang/)  داریم جواب نمیده چون قبل از رسیدن دیباگر به اون نقطه و گرفتن خطا فانکشن ما به ملکوت اعلی پیوسته پس دیباگر همه کارها منجمله ایرادات منطقی برنامه رو حل نمیکنه پس همیشه یادتون باشه خطاها رو به درستی مدیریت کنید.

#### خطایابی کامپایل syntax
گاهی وقت ها ما از یه پکیج استفاده میکنیم که تو `GOPATH` نصب نشده ادیتور میتونه به ما درباره این موضوع هشدار بده.
یا یه متغیر رو تعریف کردیم ولی هیچ جا از اون استفاده نکردیم.
و مثال های خیلی زیاد دیگه.


### شورتکات هایی که برای ادیت فایل ازشون استفاده میکنم

* وقتی بخوام چند تا لاین رو باهم ادیت کنم مثل تصویر زیر از `command + shift + alt` یا تو مک از `command + option + shift` استفاده میکنم
![](assets/article_images/vscode/editlines.gif "editlines")

* برای انتخاب تعدادی از کلمات مشابه مثل تصویر پایین از `command + d`
![](assets/article_images/vscode/select.gif "select")

* اگر دنبال کلمه خاصی بگردم `command + F`
![](assets/article_images/vscode/find.gif "find")

* اگه بخوام کلمه خاصی رو تو فایل ادیت کنم `command + H`
![](assets/article_images/vscode/replace.gif "replace")


### پلاگین های پیشنهادی

برای اینکه متوجه بشم چه commit ای تو چه PR ای به پروژه اضافه شده مثل تصویر زیر از پلاگین [Gillens](https://gitlens.amod.io/) استفاده میکنم که به همه نصبش رو پیشنهاد میکنم
![](assets/article_images/vscode/gitlens.gif "gitlens")


