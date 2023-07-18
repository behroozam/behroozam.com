---
layout: post
comments: true
title: "تعریف کردن class تو powershell"
date: 2023-07-18
categories: development
image: assets/article_images/powershell/powershell.png
toc: true
---

### مقدمه 

به عنوان یه لینوکس ادمین هربار که مجبور میشدم سراغ کارهای پیچیده اسکریپتینگ برم راه حل تو لینوکس استفاده از Python بود به دو دلیل:

1. bash از [OOP](https://en.wikipedia.org/wiki/Object-oriented_programming) ساپورت نمیکنه 
1. bash برای loop  های پی در پی گیج کننده است

 ولی تو اکوسیستم ماکروسافت استفاده از Python به دلیل [cmdlet](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-overview?view=powershell-7.3) های آماده ای که خود ماکروسافت در اختیار توسعه دهنده گذاشته انتخاب غلطیه. 

تو پست قبلی درمورد مقایسه کردن powershell و bash از برتری powershell به خاطر object oriented بودنش گفتم یکی از مثال های بارز این قابلیت powershell تعریف custom object هستش.

میخوام سه مثال مقایسه تعریف variable و objects رو تو Python و Bash و Powershell بزنم تا راحت تر متوجه این تفاوت بشید 


### تعریف class تو python 

```
class Person:
  def __init__(self, name, lastname, eyecolor,  age):
    self.FirstName = name
    self.LastName = lastname
    self.EyeColor = eyecolor
    self.age = age

p1 = Person("John", "Doe", "Brown", 36)

print(p1.FirstName)
print(p1.LastName)
```

### تعریف class تو Powershell 

```
class Person {
    [String]$FirstName
    [String]$LastName
    [String]$EyeColor
    [Int]$Age
}

$johnDoe = New-Object Person
$johnDoe.FirstName = 'John'
$johnDoe.LastName = 'Doe'
$johnDoe.EyeColor = 'Brown'
$johnDoe.Age = 33

$johnDoe.FirstName
$johnDoe.LastName

```

### تعریف variable تو bash

```
name="John" 
lastname="Doe"

echo $name 
echo $lastname 

```

### برتری استفاده از class نسبت به تعریف variable برای هر آبجکت چیه ؟ 

به صورت خلاصه برتری class نسبت به variable 

1. کد ما درنهایت تمیز تر و خوانا تره و برای تغییر کافیه که class تغییر کنه 
1. از تکرار بیهوده جلوگیری میشه 

 اگه تصور کنیم تعداد زیادی instance ما از هرکدوم از این class ها داشته باشیم Powershell و Python سربلند بیرون میان 
 برای مثال ما بخوایم فرد دیگه ای رو ثبت کنیم مثلا تو Powershell
 
```
$mamad = New-Object Person
$mamad.FirstName = 'mamad'
$mamad.LastName = 'gholi'
$mamad.EyeColor = 'Black'
$mamad.Age = 25

$mamad.FirstName
$mamad.LastName
```

ولی تو bash مجبوریم که به ازای هر مقدار جدیدی ما یه variable تعریف کنیم یا این محدودیت های bash رو به روش های دیگه ای دور بزنیم. 
